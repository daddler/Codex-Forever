--------------------------------------------------
-- WeintCodex :: Komfort - Instanz-Tracker und Gruppen-Inspektion
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever "Instance Tracker"
-- und "Group Inspect", Verhalten nachgebaut, eigener Code).
--
-- INSTANZ-TRACKER (instTracker, ab Werk aus): jeder Besuch eines Dungeons
-- oder Schlachtzugs mit Zeit, kontoweit (WeintCodex_SavedData.instanceRuns).
-- Auf Forever gilt eine Grenze von 10 NEUEN Instanzen je Stunde fuer das
-- ganze Konto (laut Naowh Forever gemessen, von uns nicht). Ob es dieselbe
-- Kopie ist, sagt die GUID eines Gegners (Feld "zoneUID"), gelesen aus Ziel
-- und Maus; ohne sie zaehlt derselbe Name binnen 30 Minuten als derselbe
-- Besuch. Beim Betreten ein Hinweis "n/10 in der letzten Stunde", beim
-- Verlassen die Dauer. /wcui instanzen listet die letzte Stunde.
--
-- GRUPPEN-INSPEKTION (/wcui inspekt): ein Fenster mit allen in der Gruppe -
-- Klasse, Stufe, Gegenstandsstufe. Die Stufe der anderen kommt nur ueber
-- Betrachten (NotifyInspect, einer nach dem anderen, in Reichweite, nicht im
-- Kampf); ohne Antwort steht "?" - nie eine geratene Zahl.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIGroupTools = {}

local GT = WeintCodex.UIGroupTools
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
local KEY = "comfort"

GT.CAP, GT.HOUR, GT.SAME_NAME = 10, 3600, 1800
GT.DEFAULTS = { instTracker = false }

local function Get(k) return K.IsActive(KEY) and K.Get(KEY, k) end
local function Time() return _G.time and _G.time() or 0 end
local function Say(t) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. t) end

--------------------------------------------------
-- Instanz-Tracker
--------------------------------------------------

local function Runs()
    local sd = _G.WeintCodex_SavedData
    if type(sd) ~= "table" then return nil end
    sd.instanceRuns = sd.instanceRuns or {}
    return sd.instanceRuns
end

-- zoneUID aus einer GUID "Creature-0-server-instance-zoneUID-id-spawn".
function GT.ZoneUID(guid)
    if type(guid) ~= "string" or K.IsSecret(guid) then return nil end
    local kind, _, _, inst, zuid = guid:match("^(%a+)%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-")
    if not kind or kind == "Player" or inst == "0" then return nil end
    return zuid
end

-- Neue Besuche der letzten Stunde (zum Zeitpunkt now).
function GT.CountHour(now, runs)
    runs = runs or Runs() or {}
    now = now or Time()
    local n = 0
    for _, r in ipairs(runs) do
        if not r.same and now - r.at < GT.HOUR then n = n + 1 end
    end
    return n
end

GT.visit = nil
function GT.Enter(name, now, runs)
    runs = runs or Runs()
    if not runs then return nil end
    now = now or Time()
    -- Aelter als zwei Stunden faellt weg.
    for i = #runs, 1, -1 do if now - runs[i].at > 2 * GT.HOUR then table.remove(runs, i) end end
    local v = { name = name, at = now }
    -- Ohne GUID: derselbe Name kurz danach ist derselbe Besuch.
    for i = #runs, 1, -1 do
        local r = runs[i]
        if r.name == name and now - (r.left or r.at) < GT.SAME_NAME and not r.uid then v.same = true break end
    end
    runs[#runs + 1] = v
    GT.visit = v
    return v
end
function GT.SeeUID(uid, runs)
    local v = GT.visit
    if not (v and uid) or v.uid then return end
    runs = runs or Runs() or {}
    v.uid = uid
    v.same = nil
    for _, r in ipairs(runs) do
        if r ~= v and r.uid == uid then v.same = true break end
    end
end
function GT.Leave(now)
    local v = GT.visit
    if not v then return nil end
    v.left = now or Time()
    GT.visit = nil
    return v.left - v.at
end

local function InInstance()
    if not _G.IsInInstance then return nil end
    local inside, kind = _G.IsInInstance()
    inside, kind = K.Plain(inside), K.Plain(kind)
    if inside and (kind == "party" or kind == "raid") then return true end
    return false
end

local function OnWorld()
    if not Get("instTracker") then return end
    local inside = InInstance()
    if inside and not GT.visit then
        local name = _G.GetInstanceInfo and K.Plain((_G.GetInstanceInfo()))
        local v = GT.Enter(type(name) == "string" and name or "?")
        if v then
            Say(string.format("%s – neue Instanzen in der letzten Stunde: %d/%d%s", v.name, GT.CountHour(), GT.CAP,
                v.same and " (gleicher Besuch wie eben)" or ""))
        end
    elseif inside == false and GT.visit then
        local name = GT.visit.name
        local d = GT.Leave()
        if d then Say(string.format("%s verlassen nach %d:%02d.", name, math.floor(d / 60), d % 60)) end
    end
end

local function OnUnit(unit)
    if not GT.visit or GT.visit.uid then return end
    if not _G.UnitGUID then return end
    GT.SeeUID(GT.ZoneUID(K.Plain(_G.UnitGUID(unit))))
end

function GT.Report()
    local out = { "Instanzen der letzten Stunde (Grenze laut Gemeinschaft: " .. GT.CAP .. " neue je Stunde und Konto)", "" }
    local now = Time()
    for _, r in ipairs(Runs() or {}) do
        if now - r.at < GT.HOUR then
            local m = math.floor((now - r.at) / 60)
            out[#out + 1] = string.format("vor %d min: %s%s", m, r.name, r.same and " (gleicher Besuch)" or "")
        end
    end
    out[#out + 1] = ""
    out[#out + 1] = "Neu in der letzten Stunde: " .. GT.CountHour(now) .. "/" .. GT.CAP
    return out
end

--------------------------------------------------
-- Gruppen-Inspektion
--------------------------------------------------

GT.ilvl = {}        -- [GUID] = Gegenstandsstufe
GT.queue = {}
local win
local rows = {}
GT.ROWS, GT.ROW_H = 40, 18

function GT.Members()
    local out = {}
    local n = _G.GetNumGroupMembers and tonumber(K.Plain(_G.GetNumGroupMembers())) or 0
    local raid = _G.IsInRaid and K.Bool(_G.IsInRaid(), false)
    if raid then for i = 1, n do out[#out + 1] = "raid" .. i end
    else
        out[1] = "player"
        for i = 1, math.max(0, n - 1) do out[#out + 1] = "party" .. i end
    end
    return out
end

local function OwnIlvl()
    if not _G.GetAverageItemLevel then return nil end
    local _, eq = _G.GetAverageItemLevel()
    eq = K.Plain(eq)
    return type(eq) == "number" and eq or nil
end

local asking, askedAt = nil, 0
-- 1.0.7.64 (Bild: "Betrachten zeigt nicht, was der Spieler anhat"): das
-- Betrachten-Fenster des Spielers hat Vorrang - solange es offen ist, wird
-- weder gefragt noch die Antwort geloescht (ClearInspectPlayer leerte die
-- Plaetze im offenen Fenster).
function GT.InspectOpen()
    local f = _G.InspectFrame
    return type(f) == "table" and f.IsShown and K.Bool(f:IsShown(), false) or false
end
function GT.Next()
    if K.InCombat() or GT.InspectOpen() or asking and (_G.GetTime() - askedAt) < 2 then return end
    asking = nil
    for i = #GT.queue, 1, -1 do
        local u = table.remove(GT.queue, i)
        local guid = _G.UnitGUID and K.Plain(_G.UnitGUID(u))
        if type(guid) == "string" and not GT.ilvl[guid] and _G.CanInspect and K.Bool(_G.CanInspect(u), false) and _G.NotifyInspect then
            asking, askedAt = guid, _G.GetTime()
            pcall(_G.NotifyInspect, u)
            return
        end
    end
end
function GT.OnInspect(guid)
    guid = K.Plain(guid)
    -- Nur die eigene Frage - die Antwort auf das Betrachten des Spielers
    -- gehoert dem Fenster.
    if type(guid) ~= "string" or guid ~= asking then return end
    for _, u in ipairs(GT.Members()) do
        if _G.UnitGUID and K.Plain(_G.UnitGUID(u)) == guid then
            local pd = _G.C_PaperDollInfo
            local v = pd and pd.GetInspectItemLevel and K.Plain(pd.GetInspectItemLevel(u))
            if type(v) == "number" and v > 0 then GT.ilvl[guid] = v end
        end
    end
    asking = nil
    if _G.ClearInspectPlayer and not GT.InspectOpen() then pcall(_G.ClearInspectPlayer) end
    GT.Paint()
    GT.Next()
end

function GT.Paint()
    if not (win and win:IsShown()) then return end
    local list = GT.Members()
    for i = 1, GT.ROWS do
        local r = rows[i]
        if not r then
            r = K.NewText(win, 12)
            r:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -34 - (i - 1) * GT.ROW_H)
            r:SetPoint("RIGHT", win, "RIGHT", -12, 0)
            r:SetJustifyH("LEFT")
            rows[i] = r
        end
        local u = list[i]
        if u and _G.UnitExists and K.Bool(_G.UnitExists(u), false) then
            local name = K.Plain(_G.UnitName(u))
            local _, cls = _G.UnitClass(u)
            cls = K.Plain(cls)
            local lvl = K.Plain(_G.UnitLevel(u))
            local guid = K.Plain(_G.UnitGUID(u))
            local il = u == "player" and OwnIlvl() or (type(guid) == "string" and GT.ilvl[guid]) or nil
            local nm = type(name) == "string" and name or "?"
            local ccu = _G.C_ClassColor
            local cc = cls and ccu and ccu.GetClassColor and ccu.GetClassColor(cls)
            if cc and cc.WrapTextInColorCode then nm = cc:WrapTextInColorCode(nm) end
            r:SetText(string.format("%s  ·  Stufe %s  ·  Gegenstandsstufe %s", nm, tostring(lvl or "?"),
                il and string.format("%.0f", il) or "?"))
            r:Show()
        else
            r:Hide()
        end
    end
    win:SetHeight(46 + math.min(#list, GT.ROWS) * GT.ROW_H)
end

function GT.Open()
    if not win then
        win = CreateFrame("Frame", "WeintCodexGroupInspect", UIParent)
        win:SetSize(420, 120)
        win:SetPoint("CENTER")
        win:SetFrameStrata("DIALOG")
        win:EnableMouse(true)
        win:SetMovable(true)
        win:RegisterForDrag("LeftButton")
        win:SetScript("OnDragStart", win.StartMoving)
        win:SetScript("OnDragStop", win.StopMovingOrSizing)
        local bg = win:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(win)
        local p = C.bgPanel
        bg:SetColorTexture(p[1], p[2], p[3], 0.97)
        K.Border(win, 1, 0, 0, 0, 1, "BORDER")
        local t = K.NewText(win, 14)
        t:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -10)
        t:SetText("Gruppe betrachten")
        local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, 0)
    end
    win:Show()
    for i = #GT.queue, 1, -1 do GT.queue[i] = nil end
    for _, u in ipairs(GT.Members()) do if u ~= "player" then GT.queue[#GT.queue + 1] = u end end
    GT.Paint()
    GT.Next()
end

--------------------------------------------------
-- Start
--------------------------------------------------

function GT.Enable()
    if GT.enabled then return end
    GT.enabled = true
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_TARGET_CHANGED",
        "UPDATE_MOUSEOVER_UNIT", "INSPECT_READY", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", K.Measured("Instanzen und Gruppe", function(_, event, a1)
        if event == "INSPECT_READY" then GT.OnInspect(K.Plain(a1)) return end
        if event == "PLAYER_TARGET_CHANGED" then OnUnit("target") return end
        if event == "UPDATE_MOUSEOVER_UNIT" then OnUnit("mouseover") return end
        if event == "GROUP_ROSTER_UPDATE" then GT.Paint() return end
        if event == "PLAYER_REGEN_ENABLED" then if win and win:IsShown() then GT.Next() end return end
        OnWorld()
    end))
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(GT.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    local enable = mod.Enable
    mod.Enable = function(...)
        if enable then enable(...) end
        local ok, err = pcall(GT.Enable)
        if not ok then K.Report("instanzen", err) end
    end
end

-- /wcui speicher: interne Tabellen dieser Datei (1.0.8.27).
WeintCodex.Hold("ui/grouptools.lua", function() return { rows = rows } end)
