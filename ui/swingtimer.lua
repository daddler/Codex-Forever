--------------------------------------------------
-- WeintCodex :: Oberflaeche - Swing-Timer
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever, Verhalten nach
-- dessen Swing Timer, eigener Code - dort "All Rights Reserved").
--
-- WOHER: Forever meldet jeden Schlag selbst mit PLAYER_SWING (Dauer,
-- Art aus Enum.PlayerSwingType: Haupthand, Nebenhand, Distanz) - Tempo,
-- Parierhast und Zuruecksetzen sind darin schon enthalten. Ein Kampflog
-- gibt es fuer Addons nicht; ohne dieses Ereignis bleibt der Swing-Timer
-- aus (nie geraten). Eine geheime Dauer heisst "weiss nicht": kein Balken.
--
-- Eine Leiste je Waffe, gestapelt, verschiebbar im Gestaltungsmodus
-- ("Swing-Timer"). Schalter `swing` auf der Seite des
-- Abklingzeitmanagers (Erweitert), je Charakter.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UISwingTimer = {}

local SW = WeintCodex.UISwingTimer
local K = WeintCodex.UIKit
local C = WeintCodex.Colors

SW.W, SW.H, SW.GAP = 200, 10, 3
SW.ROWS = { "main", "off", "ranged" }
SW.LABEL = { main = "Haupthand", off = "Nebenhand", ranged = "Distanz" }
SW.IDLE_GRACE = 0.4   -- der naechste Schlag kommt oft kurz nach dem Ende

local function Now() return _G.GetTime and _G.GetTime() or 0 end
local function On()
    local OC = WeintCodex.UIOwnCooldowns
    return OC and OC.Get and OC.Get("swing") and true or false
end

-- Ob der Client meldet, was es braucht.
function SW.Supported()
    local E = _G.Enum
    return (E and E.PlayerSwingType) and true or false
end

-- Art des Ereignisses -> Zeile. Nur ueber die Namen des Enums.
function SW.RowOf(kind)
    local E = _G.Enum and _G.Enum.PlayerSwingType
    if not E or type(kind) ~= "number" then return nil end
    if kind == E.MainHand then return "main" end
    if kind == E.OffHand then return "off" end
    if kind == E.Ranged then return "ranged" end
    return nil
end

local host
local bars = {}

local function Bar(key, i)
    local f = CreateFrame("Frame", nil, host)
    f:SetSize(SW.W, SW.H)
    f:SetPoint("TOP", host, "TOP", 0, -(i - 1) * (SW.H + SW.GAP))
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    local bg = C.bgPanel
    f.bg:SetColorTexture(bg[1], bg[2], bg[3], 0.85)
    f.bar = K.NewBar(f)
    f.bar:SetAllPoints(f)
    f.bar:SetMinMaxValues(0, 1)
    f.bar:SetValue(0)
    local col = key == "off" and C.accentBright or key == "ranged" and C.info or C.accent
    col = col or C.accent
    K.PaintBar(f.bar, col[1], col[2], col[3])
    K.Border(f, 1, 0, 0, 0, 1, "OVERLAY")
    local top = CreateFrame("Frame", nil, f)
    top:SetAllPoints(f)
    top:SetFrameLevel((f.bar:GetFrameLevel() or 1) + 2)
    f.time = K.NewText(top, 9)
    f.time:SetPoint("RIGHT", f, "RIGHT", -3, 0)
    f.name = K.NewText(top, 9)
    f.name:SetPoint("LEFT", f, "LEFT", 3, 0)
    f.name:SetText(SW.LABEL[key])
    f:SetAlpha(0)
    f.key = key
    bars[key] = f
    return f
end

-- Ein Schlag: Dauer vom Client. Gibt true zurueck, wenn eine Leiste lief.
function SW.OnSwing(dur, kind, now)
    if K.IsSecret(dur) or K.IsSecret(kind) then return false end
    if type(dur) ~= "number" or dur <= 0 then return false end
    local key = SW.RowOf(kind)
    local b = key and bars[key]
    if not (b and On()) then return false end
    b.start, b.dur = now or Now(), dur
    b.shownTenth = nil
    b:SetAlpha(1)
    return true
end

-- Ein ruhiger Lauf je Bild nur, solange eine Leiste laeuft; keine Tabelle,
-- Text nur bei neuer Zehntelsekunde.
local function Tick()
    local now = Now()
    local running = false
    for i = 1, #SW.ROWS do
        local b = bars[SW.ROWS[i]]
        if b and b.start then
            local p = (now - b.start) / b.dur
            if p >= 1 then
                b.bar:SetValue(1)
                if now - b.start - b.dur > SW.IDLE_GRACE then
                    b.start = nil
                    if not host._unlock then b:SetAlpha(0) end
                    b.time:SetText("")
                else
                    running = true
                end
            else
                running = true
                b.bar:SetValue(p)
                local tenth = math.ceil((b.dur - (now - b.start)) * 10)
                if tenth ~= b.shownTenth then
                    b.shownTenth = tenth
                    b.time:SetText(string.format("%.1f", tenth / 10))
                end
            end
        end
    end
    if not running and not host._unlock then host:SetScript("OnUpdate", nil) host._ticking = nil end
end

function SW.Wake()
    if host and not host._ticking then
        host._ticking = true
        host:SetScript("OnUpdate", Tick)
    end
end

function SW.Unlock(on)
    host._unlock = on and true or nil
    for _, key in ipairs(SW.ROWS) do
        local b = bars[key]
        if on then b:SetAlpha(1) b.bar:SetValue(0.6) b.time:SetText("2.4")
        elseif not b.start then b:SetAlpha(0) b.time:SetText("") end
    end
end

function SW.Enable()
    if host or not SW.Supported() then return end
    host = CreateFrame("Frame", "WeintCodexSwingTimer", UIParent)
    host:SetSize(SW.W, #SW.ROWS * (SW.H + SW.GAP))
    for i, key in ipairs(SW.ROWS) do Bar(key, i) end
    host.WCShowForUnlock = function(_, on) SW.Unlock(on) end
    K.RegisterMover(host, "swing", "Swing-Timer", K.Layout("swing"))
    local ev = CreateFrame("Frame")
    pcall(ev.RegisterEvent, ev, "PLAYER_SWING")
    pcall(ev.RegisterEvent, ev, "PLAYER_DEAD")
    ev:SetScript("OnEvent", K.Measured("Swing-Timer", function(_, event, a1, a2)
        if event == "PLAYER_SWING" then
            if SW.OnSwing(a1, a2) then SW.Wake() end
        else
            for _, b in pairs(bars) do b.start = nil b:SetAlpha(0) end
        end
    end))
end

do
    local m = K.Module("reminders")
    if m then
        local enable = m.Enable
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(SW.Enable)
            if not ok then K.Report("swing-timer", err) end
        end
    end
end

-- /wcui speicher: interne Tabellen dieser Datei (1.0.8.27).
WeintCodex.Hold("ui/swingtimer.lua", function() return { bars = bars } end)
