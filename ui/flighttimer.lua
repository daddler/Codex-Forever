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
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIFlightTimer = {}

local FT = WeintCodex.UIFlightTimer
local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "comfort"

FT.DEFAULTS = { flightTimer = true }
FT.W, FT.H = 240, 38
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

--------------------------------------------------
-- Anzeige
--------------------------------------------------

local function Build()
    if frame then return frame end
    frame = CreateFrame("Frame", "WeintCodexFlightTimer", UIParent)
    frame:SetSize(FT.W, FT.H)
    frame:SetFrameStrata("MEDIUM")
    frame.kachel = K.Kachel(frame, { shadow = 4 })
    frame.title = K.NewText(frame, 12, "OVERLAY")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
    frame.title:SetPoint("RIGHT", frame, "RIGHT", -60, 0)
    frame.title:SetJustifyH("LEFT")
    frame.time = K.NewText(frame, 12, "OVERLAY")
    frame.time:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -6)
    frame.time:SetJustifyH("RIGHT")
    frame.bar = K.NewBar(frame)
    frame.bar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 7)
    frame.bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 7)
    frame.bar:SetHeight(6)
    frame.bar:SetMinMaxValues(0, 1)
    local a = C.accent
    frame.bar:SetStatusBarColor(a[1], a[2], a[3], 1)
    frame.barBg = frame.bar:CreateTexture(nil, "BACKGROUND")
    frame.barBg:SetAllPoints(frame.bar)
    local s = C.surface1
    frame.barBg:SetColorTexture(s[1], s[2], s[3], 1)
    frame:Hide()
    frame.WCShowForUnlock = function(self, on)
        self._unlock = on and true or nil
        if on then
            FT.Fill("Flug nach Eisenschmiede", "Landung in 2:34", 0.4)
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

function FT.Fill(title, time, part)
    frame.title:SetText(title)
    frame.time:SetText(time)
    frame.bar:SetShown(part ~= nil)
    if part then frame.bar:SetValue(math.max(0, math.min(1, part))) end
end

local function OnTaxi()
    return _G.UnitOnTaxi and K.Bool(_G.UnitOnTaxi("player"), false)
end

function FT.Tick()
    if not frame or frame._unlock then return end
    if not flight then frame:Hide() return end
    local gone = Now() - flight.start
    -- 6.54.2.0 (Beta-Test: "nach der Landung ist der Balken noch da"):
    -- PLAYER_CONTROL_GAINED kam, waehrend der Client noch "im Flug"
    -- meldete. Gelandet ist, wer nicht mehr auf dem Flugweg ist.
    if gone > 2 and not OnTaxi() then FT.Land() return end
    local title = flight.name and ("Flug nach " .. flight.name) or "Im Flug"
    if flight.total then
        local left = flight.total - gone
        local text = left > 0 and ("Landung in " .. FT.Format(left)) or "Landung gleich"
        FT.Fill(title, text, gone / flight.total)
    else
        FT.Fill(title, "unbekannt · " .. FT.Format(gone), nil)
    end
    frame:Show()
end

--------------------------------------------------
-- Ablauf
--------------------------------------------------

-- Flugkarte: Start und alle Ziele mit ihrem Platz merken.
local nodesBySlot, current = {}, nil
function FT.ReadMap()
    wipe(nodesBySlot)
    current = nil
    local tm = _G.C_TaxiMap
    if not (tm and tm.GetAllTaxiNodes) then return end
    local mapID = _G.GetTaxiMapID and K.Plain(_G.GetTaxiMapID()) or nil
    local ok, list = pcall(tm.GetAllTaxiNodes, mapID)
    if not ok or type(list) ~= "table" then return end
    local E = _G.Enum and _G.Enum.FlightPathState
    local cur = E and E.Current or 0
    for _, info in ipairs(list) do
        local id, slot, state, name = K.Plain(info.nodeID), K.Plain(info.slotIndex), K.Plain(info.state), K.Plain(info.name)
        if type(slot) == "number" then nodesBySlot[slot] = { id = id, name = name } end
        if state == cur and type(id) == "number" then current = id end
    end
end

-- Der Klick auf ein Ziel (TakeTaxiNode). Abgehoben ist man erst danach.
function FT.OnTake(slot)
    slot = K.Plain(slot)
    local n = type(slot) == "number" and nodesBySlot[slot]
    if not n then return end
    local name = type(n.name) == "string" and n.name:match("^([^,]+)") or n.name
    pending = { from = current, to = n.id, name = name, at = Now() }
end

function FT.Start()
    local p = pending
    pending = nil
    if not (p and FT.Active()) then return false end
    local total, source = FT.Seconds(p.from, p.to)
    flight = { from = p.from, to = p.to, name = p.name, total = total, source = source, start = Now() }
    Build()
    FT.Tick()
    return true
end

function FT.Land()
    local f = flight
    flight = nil
    if frame and not frame._unlock then frame:Hide() end
    if not f then return nil end
    local secs = Now() - f.start
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
    B:Section("Flugzeit", "Beim Fliegen: wohin, wann du landest und wie weit du bist. Verschieben im Gestaltungsmodus.")
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
