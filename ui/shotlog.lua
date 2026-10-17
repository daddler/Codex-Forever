--------------------------------------------------
-- WeintCodex :: Kampfprotokoll Autoshot (6.61.20.0)
--------------------------------------------------
-- Beta-Test: "nach Schlangengift oder Arkanem Schuss geht der Jaeger in
-- den Autohit statt Autoshot - kein Makro. Kannst du etwas einbauen, damit
-- du nach einem Kampf sehen kannst, was ich meine?"
--
-- Schreibt je Kampf mit, was der Client ueber Angriffe meldet: Autoshot an
-- und aus (START/STOP_AUTOREPEAT_SPELL), Nahkampf an und aus
-- (PLAYER_ENTER/LEAVE_COMBAT), jeder eigene Zauber (gesendet, gewirkt,
-- gescheitert), Zielwechsel und rote Fehlermeldungen ("zu nah" ...).
-- Nur im Speicher, die letzten zwei Kaempfe; nichts verlaesst den Client.
-- Abruf nach dem Kampf: /wcui schuss - ein Fenster zum Kopieren.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIShotLog = {}

local SL = WeintCodex.UIShotLog
local K = WeintCodex.UIKit

SL.MAX_LINES = 250
SL.fights = {}      -- die letzten zwei, neuester zuletzt
local cur, start

local function Now() return _G.GetTime and K.Plain(_G.GetTime()) or 0 end

local function SpellName(id)
    id = K.Plain(id)
    if type(id) ~= "number" then return "?" end
    local cs = _G.C_Spell
    local ok, n = pcall(function()
        if cs and cs.GetSpellName then return cs.GetSpellName(id) end
        return _G.GetSpellInfo and (_G.GetSpellInfo(id)) or nil
    end)
    n = ok and K.Plain(n) or nil
    return (type(n) == "string" and n ~= "") and (n .. " (" .. id .. ")") or tostring(id)
end

function SL.Add(text)
    local f = cur
    if not f then return end
    -- Gleiche Zeile direkt hintereinander (der Client wiederholt "zu nah"
    -- bis zu 100-mal je Sekunde): eine Zeile mit Zaehler.
    if f.last == text then
        f.rep = (f.rep or 1) + 1
        f.lines[#f.lines] = f.lastLine .. "  (" .. f.rep .. "×)"
        return
    end
    f.last, f.rep = text, 1
    if #f.lines >= SL.MAX_LINES then
        if not f.cut then f.cut = true f.lines[#f.lines + 1] = "… gekürzt" end
        return
    end
    f.lastLine = string.format("%6.2f  %s", Now() - start, text)
    f.lines[#f.lines + 1] = f.lastLine
end

function SL.Begin()
    start = Now()
    cur = { lines = {}, at = _G.date and _G.date("%H:%M:%S") or "" }
    local _, class = nil, nil
    if _G.UnitClass then _, class = _G.UnitClass("player") end
    cur.class = class
    SL.fights[#SL.fights + 1] = cur
    while #SL.fights > 2 do table.remove(SL.fights, 1) end
    SL.Add("Kampf beginnt")
end

function SL.End()
    if cur and SL.pendingFail then SL.Add("Zauber gescheitert: " .. SL.pendingFail) end
    SL.pendingFail = nil
    if cur then SL.Add("Kampf endet") end
    cur = nil
end

local ev = CreateFrame("Frame")
SL.events = ev
for _, e in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "START_AUTOREPEAT_SPELL",
                     "STOP_AUTOREPEAT_SPELL", "PLAYER_ENTER_COMBAT", "PLAYER_LEAVE_COMBAT",
                     "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED",
                     "UNIT_SPELLCAST_INTERRUPTED", "PLAYER_TARGET_CHANGED", "UI_ERROR_MESSAGE",
                     "UNIT_HEALTH", "PLAYER_SOFT_ENEMY_CHANGED", "PLAYER_SOFT_INTERACT_CHANGED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
    if event == "PLAYER_REGEN_DISABLED" then SL.Begin() return end
    if event == "PLAYER_REGEN_ENABLED" then SL.End() return end
    if not cur then return end
    -- Gescheitert + Meldung des Spiels werden eine Zeile (die Meldung kommt
    -- gleich danach); so faellt die Wiederholung zu einer Zeile mit Zaehler.
    local fail = SL.pendingFail
    if fail and event ~= "UI_ERROR_MESSAGE" then
        SL.pendingFail = nil
        SL.Add("Zauber gescheitert: " .. fail)
    end
    -- 6.61.24.0: stirbt das Ziel? (Ziel verloren kam immer kurz nach einem
    -- Treffer.) Und die weiche Zielerfassung des Spiels, falls sie wechselt.
    if event == "UNIT_HEALTH" then
        if K.Plain(a1) == "target" and not SL.deadSaid and _G.UnitIsDead and K.Bool(_G.UnitIsDead("target"), false) then
            SL.deadSaid = true
            SL.Add("ZIEL STIRBT")
        end
        return
    end
    if event == "PLAYER_SOFT_ENEMY_CHANGED" then SL.Add("weiche Zielerfassung (Gegner) wechselt") return end
    if event == "PLAYER_SOFT_INTERACT_CHANGED" then return end
    if event == "PLAYER_TARGET_CHANGED" then SL.deadSaid = nil end
    if event == "START_AUTOREPEAT_SPELL" then SL.Add("AUTOSHOT AN")
    elseif event == "STOP_AUTOREPEAT_SPELL" then SL.Add("AUTOSHOT AUS · Ziel: " .. SL.TargetText())
    elseif event == "PLAYER_ENTER_COMBAT" then SL.Add("NAHKAMPF AN (Autohit) · Ziel: " .. SL.TargetText())
    elseif event == "PLAYER_LEAVE_COMBAT" then SL.Add("NAHKAMPF AUS")
    elseif event == "PLAYER_TARGET_CHANGED" then
        SL.Add("Ziel: " .. SL.TargetText())
    elseif event == "UI_ERROR_MESSAGE" then
        local msg = K.Plain(a2)
        msg = type(msg) == "string" and msg or "?"
        if fail then
            SL.pendingFail = nil
            SL.Add("Zauber gescheitert: " .. fail .. " – " .. msg)
        else
            SL.Add("Meldung: " .. msg)
        end
    elseif event == "UNIT_SPELLCAST_FAILED" and K.Plain(a1) == "player" then
        SL.pendingFail = SpellName(a3)
    elseif K.Plain(a1) == "player" then
        -- SENT: unit, target, castGUID, spellID; die anderen: unit, castGUID, spellID
        local id = event == "UNIT_SPELLCAST_SENT" and a4 or a3
        local what = ({ UNIT_SPELLCAST_SENT = "gedrückt", UNIT_SPELLCAST_SUCCEEDED = "gewirkt",
                        UNIT_SPELLCAST_FAILED = "gescheitert", UNIT_SPELLCAST_INTERRUPTED = "unterbrochen" })[event]
        SL.Add("Zauber " .. what .. ": " .. SpellName(id))
    end
end)

-- 6.61.21.0: "Ziel: keins" war mehrdeutig - im Kampf ist der Name eines
-- Gegners oft geheim. Jetzt: gibt es ein Ziel, Freund/Feind, tot, Name
-- wenn lesbar, und grob die Entfernung (Nahkampf/Wurf/weiter weg).
function SL.TargetText()
    local ex = _G.UnitExists and K.Bool(_G.UnitExists("target"), nil)
    if ex == false then return "keins (Ziel verloren)" end
    if ex == nil then return "unbekannt" end
    local parts = {}
    local n = _G.UnitName and K.Plain(_G.UnitName("target"))
    parts[#parts + 1] = type(n) == "string" and n or "Name verborgen"
    local enemy = _G.UnitCanAttack and K.Bool(_G.UnitCanAttack("player", "target"), nil)
    if enemy ~= nil then parts[#parts + 1] = enemy and "Gegner" or "kein Gegner" end
    if _G.UnitIsDead and K.Bool(_G.UnitIsDead("target"), false) then parts[#parts + 1] = "tot" end
    if _G.CheckInteractDistance then
        local ok, near = pcall(_G.CheckInteractDistance, "target", 3)
        near = ok and K.Bool(near, nil)
        if near == true then parts[#parts + 1] = "Nahkampfnähe (unter 10 m)"
        elseif near == false then parts[#parts + 1] = "über 10 m" end
    end
    return table.concat(parts, ", ")
end

function SL.Lines()
    local out = { "WeintCodex " .. tostring(WeintCodex.Version) .. " · Kampfprotokoll Autoshot/Nahkampf" }
    if #SL.fights == 0 then
        out[#out + 1] = "Noch kein Kampf mitgeschrieben (seit dem letzten Laden)."
        return out
    end
    for i = #SL.fights, 1, -1 do
        local f = SL.fights[i]
        out[#out + 1] = ""
        out[#out + 1] = string.format("Kampf um %s%s%s", f.at or "?", f.class and (" · " .. f.class) or "",
            f == cur and " · läuft noch" or "")
        for _, l in ipairs(f.lines) do out[#out + 1] = l end
    end
    return out
end

function SL.Report()
    local lines = SL.Lines()
    K.ShowReport("Kampfprotokoll Autoshot", lines)
    return lines
end
