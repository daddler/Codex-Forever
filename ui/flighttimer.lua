--------------------------------------------------
-- WeintCodex :: Flugzeit - wann lande ich? (6.54.0.0)
--------------------------------------------------
-- Wunsch: "Flugtimer, der anzeigt, wann ich landen werde. Frei platzierbar,
-- auch im Gestaltungsmodus einstellbar."
--
-- ZIEL: der Klick auf der Flugkarte (TakeTaxiNode(Platz)) - welcher Punkt
-- das ist, sagt die Karte selbst (C_TaxiMap.GetAllTaxiNodes, slotIndex).
-- START: der Punkt, an dem man steht (Zustand "Current").
--
-- DAUER, in dieser Reihenfolge:
--   1. selbst gemessen (SavedData.flightTimes["von>nach"], kontoweit -
--      eine Strecke ist fuer jeden Charakter gleich lang),
--   2. vom Routenplaner gemessen (ui/route.lua, je Charakter),
--   3. aus den Reisedaten (data/travel.lua, Art classic).
-- Keine davon: KEINE geschaetzte Landezeit. Dann steht da ehrlich
-- "Flugzeit unbekannt - wird gemessen" und die Zeit seit dem Abflug; nach
-- der Landung ist die Strecke gemessen.
--
-- 1.4.0.0 (Wunsch, nach dem Flugtimer von Naowh Forever - "all rights
-- reserved", also nur das Verhalten, eigener Code): Zwischenstopps mit
-- ihrer Ankunftszeit (GetNumRoutes/TaxiGetNodeSlot), "Landen" am naechsten
-- Halt (TaxiRequestEarlyLanding) und ein Knopf zu den Flugspielen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIFlightTimer = {}

local FT = WeintCodex.UIFlightTimer
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "comfort"

FT.DEFAULTS = { flightTimer = true }
FT.W, FT.H = 270, 62
FT.MIN_MEASURE = 5      -- kuerzer ist kein Flug, sondern ein Abbruch

local frame
local flight            -- { from, to, name, total, start, source }
local pending           -- { from, to, name } zwischen Klick und Abheben
FT.state = function() return flight, pending end

function FT.Active()
    return K.IsActive(KEY) and K.Get(KEY, "flightTimer") ~= false
end

local function Now() return _G.GetTime and K.Plain(_G.GetTime()) or 0 end

local function Store()
    local sd = _G.WeintCodex_SavedData
    if type(sd) ~= "table" then return nil end
    if type(sd.flightTimes) ~= "table" then sd.flightTimes = {} end
    return sd.flightTimes
end

-- Flugzeit von a nach b in Sekunden und woher sie stammt, oder nil.
function FT.Seconds(a, b)
    if type(a) ~= "number" or type(b) ~= "number" then return nil end
    local key = a .. ">" .. b
    local own = Store()
    if own and type(own[key]) == "number" then return own[key], "gemessen" end
    local RT = WeintCodex.UIRoute
    local st = RT and RT.Store and RT.Store()
    if st and type(st.times) == "table" and type(st.times[key]) == "number" then
        return st.times[key], "gemessen"
    end
    local d = WeintCodex.TravelData
    local f = d and d.flights
    if type(f) == "table" then
        for i = 1, #f, 3 do
            if f[i] == a and f[i + 1] == b then return f[i + 2], "classic" end
        end
    end
    return nil
end

function FT.Format(secs)
    secs = math.max(0, math.floor(secs + 0.5))
    return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

-- Etappen (1.4.0.0): ueber Zwischenstopps fliegt man in Etappen. Ihre
-- Dauer misst der Flug selbst - wer an einem Halt vorbeikommt, sagt die
-- Position auf der Flugkarte (C_Map.GetPlayerMapPosition gegen die Lage des
-- Halts aus GetAllTaxiNodes). Kontoweit in SavedData.flightLegs["von>nach"].
-- Sonst gilt fuer eine Etappe, was fuer den Direktflug derselben Strecke gilt.
FT.REACH = 0.012        -- so nah (Kartenbruchteil) gilt ein Halt als erreicht
FT.marks = {}           -- Halte auf dem Balken, im Takt wiederverwendet

local function Legs()
    local sd = _G.WeintCodex_SavedData
    if type(sd) ~= "table" then return nil end
    if type(sd.flightLegs) ~= "table" then sd.flightLegs = {} end
    return sd.flightLegs
end

function FT.LegSeconds(a, b)
    if type(a) ~= "number" or type(b) ~= "number" then return nil end
    local legs = Legs()
    local own = legs and legs[a .. ">" .. b]
    if type(own) == "number" then return own end
    return (FT.Seconds(a, b))
end

-- Ankunft an jedem Halt (Sekunden nach dem Abflug) und die Gesamtdauer.
-- Ein Halt ohne bekannte Zeit hat keine - nie eine geschaetzte.
function FT.Plan(from, stops)
    local whole = FT.Seconds(from, stops[#stops].id)
    local at, sum, prev = {}, 0, from
    for i, st in ipairs(stops) do
        local leg = sum and FT.LegSeconds(prev, st.id)
        sum = leg and (sum + leg) or nil
        at[i] = sum
        prev = st.id
    end
    if whole and sum and sum > 0 then
        for i in ipairs(at) do at[i] = at[i] * whole / sum end
    elseif whole then
        for i = 1, #at - 1 do at[i] = nil end
        at[#at] = whole
    end
    return at, at[#at]
end

--------------------------------------------------
-- Anzeige (1.4.0.0 nach dem Vorbild auf dem Bild: "Start › Ziel", Restzeit,
-- Balken mit den Halten, darunter der naechste Halt und zwei Knoepfe)
--------------------------------------------------

local function SmallButton(parent, text, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(54, 18)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    local s = C.surface2 or C.surface1
    bg:SetColorTexture(s[1], s[2], s[3], 0.95)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(b)
    hl:SetColorTexture(1, 1, 1, 0.08)
    b.text = K.NewText(b, 11)
    b.text:SetPoint("CENTER")
    b.text:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function Build()
    if frame then return frame end
    frame = CreateFrame("Frame", "WeintCodexFlightTimer", UIParent)
    frame:SetSize(FT.W, FT.H)
    frame:SetFrameStrata("MEDIUM")
    frame.kachel = K.Kachel(frame, { shadow = 4 })
    frame.title = K.NewText(frame, 12, "OVERLAY")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -7)
    frame.title:SetPoint("RIGHT", frame, "RIGHT", -64, 0)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetWordWrap(false)
    frame.time = K.NewText(frame, 15, "OVERLAY")
    frame.time:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -5)
    frame.time:SetJustifyH("RIGHT")
    frame.bar = K.NewBar(frame)
    frame.bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28)
    frame.bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -28)
    frame.bar:SetHeight(5)
    frame.bar:SetMinMaxValues(0, 1)
    local a = C.accent
    frame.bar:SetStatusBarColor(a[1], a[2], a[3], 1)
    frame.barBg = frame.bar:CreateTexture(nil, "BACKGROUND")
    frame.barBg:SetAllPoints(frame.bar)
    local s = C.surface1
    frame.barBg:SetColorTexture(s[1], s[2], s[3], 1)
    frame.marks = {}
    frame.next = K.NewText(frame, 11, "OVERLAY")
    frame.next:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
    frame.next:SetPoint("RIGHT", frame, "RIGHT", -124, 0)
    frame.next:SetJustifyH("LEFT")
    frame.next:SetWordWrap(false)
    frame.games = SmallButton(frame, "Spiele", function() FT.OpenGames() end)
    frame.games:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 5)
    frame.land = SmallButton(frame, "Landen", function() FT.RequestLanding() end)
    frame.land:SetPoint("RIGHT", frame.games, "LEFT", -4, 0)
    frame:Hide()
    frame.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then
            FT.Fill("Orgrimmar › Ratchet", "2:10", 0.4, "Nächster Halt: Crossroads · 1:19", { 0.55 })
            self:Show()
        elseif not flight then
            self:Hide()
        else
            FT.Tick()
        end
    end
    frame:SetScript("OnUpdate", function(self, el)
        if self._unlock then return end
        self._acc = (self._acc or 0) + (el or 0)
        if self._acc < 0.25 then return end
        self._acc = 0
        FT.Tick()
    end)
    K.RegisterMover(frame, "flighttimer", "Flugzeit", K.Layout("flighttimer"))
    FT.frame = frame
    return frame
end

-- `marks`: Lage der Zwischenhalte auf dem Balken (0..1), nur bekannte.
function FT.Fill(title, time, part, line, marks)
    frame.title:SetText(title)
    frame.time:SetText(time)
    frame.bar:SetValue(part and math.max(0, math.min(1, part)) or 0)
    frame.next:SetText(line or "")
    local n = 0
    for _, m in ipairs(marks or {}) do
        n = n + 1
        local t = frame.marks[n]
        if not t then
            t = frame.bar:CreateTexture(nil, "OVERLAY")
            t:SetSize(5, 9)
            frame.marks[n] = t
        end
        local c = C.textBright
        t:SetColorTexture(c[1], c[2], c[3], 1)
        t:ClearAllPoints()
        t:SetPoint("CENTER", frame.bar, "LEFT", (frame.bar:GetWidth() or (FT.W - 16)) * m, 0)
        t:Show()
    end
    for i = n + 1, #frame.marks do frame.marks[i]:Hide() end
    frame.land:SetShown(FT.CanLand())
    local FG = WeintCodex.UIFlightGames
    frame.games:SetShown(FG ~= nil and FG.Ask ~= nil)
end

local function OnTaxi()
    return _G.UnitOnTaxi and K.Bool(_G.UnitOnTaxi("player"), false)
end

-- Position auf der Flugkarte, oder nil (in Instanzen, geheim, unbekannt).
local function Position(mapID)
    local m = _G.C_Map
    if not (mapID and m and m.GetPlayerMapPosition) then return nil end
    local ok, pos = pcall(m.GetPlayerMapPosition, mapID, "player")
    if not ok or type(pos) == "nil" then return nil end
    local x, y = K.Plain(pos.x), K.Plain(pos.y)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    return x, y
end

-- Erreichte Halte nachtragen (nur mit Position).
function FT.Track()
    local f = flight
    if not (f and f.stops) then return end
    local x, y = Position(f.map)
    if not x then return end
    for i = f.reached + 1, #f.stops - 1 do
        local st = f.stops[i]
        if st.x and st.y then
            local dx, dy = x - st.x, y - st.y
            if dx * dx + dy * dy <= FT.REACH * FT.REACH then
                f.reached = i
                f.reachedAt[i] = Now() - f.start
            end
        end
    end
end

-- Naechster Halt: nach Position, sonst nach Zeit, sonst der erste offene.
function FT.NextStop(gone)
    local f = flight
    if not (f and f.stops) then return nil end
    for i = f.reached + 1, #f.stops do
        local at = f.at[i]
        if not at or at > gone or i == #f.stops then return i end
    end
    return #f.stops
end

function FT.Tick()
    if not frame or frame._unlock then return end
    if not flight then frame:Hide() return end
    local gone = Now() - flight.start
    -- 6.54.2.0 (Beta-Test: "nach der Landung ist der Balken noch da"):
    -- PLAYER_CONTROL_GAINED kam, waehrend der Client noch "im Flug"
    -- meldete. Gelandet ist, wer nicht mehr auf dem Flugweg ist.
    if gone > 2 and not OnTaxi() then FT.Land() return end
    FT.Track()
    local f = flight
    local title = (f.fromName and f.name) and (f.fromName .. " › " .. f.name) or (f.name and ("Flug nach " .. f.name) or "Im Flug")
    local last = f.early or #f.stops
    local total = f.at[last]
    local marks = FT.marks
    wipe(marks)
    if f.at[#f.stops] then
        for i = 1, #f.stops - 1 do
            if f.at[i] then marks[#marks + 1] = f.at[i] / f.at[#f.stops] end
        end
    end
    local line
    local nxt = FT.NextStop(gone)
    if f.early then
        line = "Landet in " .. f.stops[f.early].name
    elseif nxt and nxt < #f.stops then
        local at = f.at[nxt]
        line = "Nächster Halt: " .. f.stops[nxt].name .. (at and (" · " .. FT.Format(math.max(0, at - gone))) or "")
    elseif #f.stops > 1 then
        line = "Letzte Etappe"
    else
        line = "Direktflug"
    end
    if total then
        local left = total - gone
        FT.Fill(title, left > 0 and FT.Format(left) or "gleich", gone / (f.at[#f.stops] or total), line, marks)
    else
        FT.Fill(title, "unbekannt · " .. FT.Format(gone), nil, line, marks)
    end
    frame:Show()
end

--------------------------------------------------
-- Landen am naechsten Halt (1.4.0.0). TaxiRequestEarlyLanding ist die
-- Funktion des Knopfs, den das Spiel selbst dafuer zeigt - ungemessen auf
-- Forever: fehlt sie, gibt es keinen Knopf.
--------------------------------------------------

function FT.CanLand()
    local f = flight
    return f ~= nil and not f.early and #(f.stops or {}) > 1 and type(_G.TaxiRequestEarlyLanding) == "function"
end

function FT.RequestLanding()
    if not FT.CanLand() then return false end
    local ok = pcall(_G.TaxiRequestEarlyLanding)
    if not ok then return false end
    flight.early = FT.NextStop(Now() - flight.start) or #flight.stops
    FT.Tick()
    return true
end

function FT.OpenGames()
    local FG = WeintCodex.UIFlightGames
    if FG and FG.Ask then FG.Ask(true) end
end

--------------------------------------------------
-- Ablauf
--------------------------------------------------

local function Short(name)
    return type(name) == "string" and name:match("^([^,]+)") or name
end

-- Flugkarte: Start und alle Ziele mit ihrem Platz und ihrer Lage merken.
local nodesBySlot, current, currentName, taxiMap = {}, nil, nil, nil
function FT.ReadMap()
    wipe(nodesBySlot)
    current, currentName = nil, nil
    local tm = _G.C_TaxiMap
    if not (tm and tm.GetAllTaxiNodes) then return end
    local mapID = _G.GetTaxiMapID and K.Plain(_G.GetTaxiMapID()) or nil
    taxiMap = type(mapID) == "number" and mapID or nil
    local ok, list = pcall(tm.GetAllTaxiNodes, mapID)
    if not ok or type(list) ~= "table" then return end
    local E = _G.Enum and _G.Enum.FlightPathState
    local cur = E and E.Current or 0
    for _, info in ipairs(list) do
        local id, slot, state, name = K.Plain(info.nodeID), K.Plain(info.slotIndex), K.Plain(info.state), K.Plain(info.name)
        local pos = info.position
        local x, y
        if type(pos) == "table" then x, y = K.Plain(pos.x), K.Plain(pos.y) end
        if type(slot) == "number" then
            nodesBySlot[slot] = { id = id, name = Short(name),
                                  x = type(x) == "number" and x or nil, y = type(y) == "number" and y or nil }
        end
        if state == cur and type(id) == "number" then current, currentName = id, Short(name) end
    end
end

-- Die Halte bis zum Ziel (ohne den Start), oder nur das Ziel.
function FT.Hops(slot)
    local n = _G.GetNumRoutes and select(2, pcall(_G.GetNumRoutes, slot))
    n = K.Plain(n)
    local stops = {}
    if type(n) == "number" and n > 1 and _G.TaxiGetNodeSlot then
        for i = 1, n do
            local ok, dst = pcall(_G.TaxiGetNodeSlot, slot, i, false)
            local node = ok and nodesBySlot[K.Plain(dst)]
            if not node then stops = {} break end
            stops[#stops + 1] = node
        end
    end
    if #stops == 0 then stops[1] = nodesBySlot[slot] end
    return stops
end

-- Der Klick auf ein Ziel (TakeTaxiNode). Abgehoben ist man erst danach.
function FT.OnTake(slot)
    slot = K.Plain(slot)
    local n = type(slot) == "number" and nodesBySlot[slot]
    if not n then return end
    pending = { from = current, fromName = currentName, to = n.id, name = n.name, at = Now(),
                stops = FT.Hops(slot), map = taxiMap }
end

function FT.Start()
    local p = pending
    pending = nil
    if not (p and FT.Active()) then return false end
    local stops = p.stops or { { id = p.to, name = p.name } }
    local at, total = FT.Plan(p.from, stops)
    local _, source = FT.Seconds(p.from, p.to)
    flight = { from = p.from, fromName = p.fromName, to = p.to, name = p.name, total = total, source = source,
               start = Now(), stops = stops, at = at, map = p.map, reached = 0, reachedAt = {} }
    Build()
    FT.Tick()
    return true
end

-- Gelandet: Gesamtstrecke messen (nicht nach "Landen" - das war eine
-- kuerzere), dazu jede Etappe, deren beide Enden gemessen sind.
function FT.Land()
    local f = flight
    flight = nil
    if frame and not frame._unlock then frame:Hide() end
    if not f then return nil end
    local secs = Now() - f.start
    local legs = Legs()
    if legs and f.stops and #f.stops > 1 then
        local prevId, prevAt = f.from, 0
        local lastIdx = f.early or #f.stops
        for i = 1, lastIdx do
            local t = (i == lastIdx) and secs or f.reachedAt[i]
            local id = f.stops[i].id
            if t and prevAt and type(prevId) == "number" and type(id) == "number" and t - prevAt >= FT.MIN_MEASURE then
                legs[prevId .. ">" .. id] = math.floor(t - prevAt + 0.5)
            end
            prevId, prevAt = id, t
        end
    end
    if f.early then return nil end
    local own = Store()
    if own and type(f.from) == "number" and type(f.to) == "number" and secs >= FT.MIN_MEASURE then
        own[f.from .. ">" .. f.to] = math.floor(secs + 0.5)
        return own[f.from .. ">" .. f.to]
    end
end

local ev = CreateFrame("Frame")
FT.events = ev
for _, e in ipairs({ "PLAYER_LOGIN", "TAXIMAP_OPENED", "PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
local hooked = false
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if not hooked and _G.hooksecurefunc and _G.TakeTaxiNode then
            hooked = true
            _G.hooksecurefunc("TakeTaxiNode", FT.OnTake)
        end
        if FT.Active() then Build() end
        if K.SetMoverEnabled then K.SetMoverEnabled("flighttimer", FT.Active()) end
    elseif event == "TAXIMAP_OPENED" then
        FT.ReadMap()
    elseif event == "PLAYER_CONTROL_LOST" then
        -- Der Flug beginnt einen Augenblick nach dem Verlust der Steuerung.
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0.5, function() if OnTaxi() then FT.Start() end end)
        elseif OnTaxi() then FT.Start() end
    elseif event == "PLAYER_CONTROL_GAINED" then
        if flight and not OnTaxi() then FT.Land() end
    end
end)

--------------------------------------------------
-- Einstellungen: auf der Komfortseite "Karte"
--------------------------------------------------

local function BuildSection(B)
    B:Section("Flugzeit", "Beim Fliegen: wohin, wann du an jedem Halt bist, und auf Wunsch schon am nächsten landen. Verschieben im Gestaltungsmodus.")
    B:Row({ type = "toggle", label = "Flugzeit anzeigen", key = "flightTimer",
            description = "Ist eine Strecke noch nie geflogen, steht „unbekannt“ und die Zeit seit dem Abflug – danach ist sie gemessen." },
          { type = "empty" })
end
FT.BuildSection = BuildSection

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(FT.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    for _, page in ipairs(mod.pages) do
        if page.key == "karte" then
            local orig = page.build
            page.build = function(B, ...)
                if orig then orig(B, ...) end
                BuildSection(B)
            end
        end
    end
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then
        if FT.Active() then Build() end
        if K.SetMoverEnabled then K.SetMoverEnabled("flighttimer", FT.Active()) end
        if not FT.Active() then flight = nil if frame and not frame._unlock then frame:Hide() end end
    end
end)
