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
    if #f.lines >= SL.MAX_LINES then
        if not f.cut then f.cut = true f.lines[#f.lines + 1] = "… gekürzt" end
        return
    end
    f.lines[#f.lines + 1] = string.format("%6.2f  %s", Now() - start, text)
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
    if cur then SL.Add("Kampf endet") end
    cur = nil
end

local ev = CreateFrame("Frame")
SL.events = ev
for _, e in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "START_AUTOREPEAT_SPELL",
                     "STOP_AUTOREPEAT_SPELL", "PLAYER_ENTER_COMBAT", "PLAYER_LEAVE_COMBAT",
                     "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED",
                     "UNIT_SPELLCAST_INTERRUPTED", "PLAYER_TARGET_CHANGED", "UI_ERROR_MESSAGE" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
    if event == "PLAYER_REGEN_DISABLED" then SL.Begin() return end
    if event == "PLAYER_REGEN_ENABLED" then SL.End() return end
    if not cur then return end
    if event == "START_AUTOREPEAT_SPELL" then SL.Add("AUTOSHOT AN")
    elseif event == "STOP_AUTOREPEAT_SPELL" then SL.Add("AUTOSHOT AUS")
    elseif event == "PLAYER_ENTER_COMBAT" then SL.Add("NAHKAMPF AN (Autohit)")
    elseif event == "PLAYER_LEAVE_COMBAT" then SL.Add("NAHKAMPF AUS")
    elseif event == "PLAYER_TARGET_CHANGED" then
        local n = _G.UnitName and K.Plain(_G.UnitName("target"))
        SL.Add("Ziel: " .. (type(n) == "string" and n or "keins"))
    elseif event == "UI_ERROR_MESSAGE" then
        local msg = K.Plain(a2)
        if type(msg) == "string" then SL.Add("Meldung: " .. msg) end
    elseif K.Plain(a1) == "player" then
        -- SENT: unit, target, castGUID, spellID; die anderen: unit, castGUID, spellID
        local id = event == "UNIT_SPELLCAST_SENT" and a4 or a3
        local what = ({ UNIT_SPELLCAST_SENT = "gedrückt", UNIT_SPELLCAST_SUCCEEDED = "gewirkt",
                        UNIT_SPELLCAST_FAILED = "gescheitert", UNIT_SPELLCAST_INTERRUPTED = "unterbrochen" })[event]
        SL.Add("Zauber " .. what .. ": " .. SpellName(id))
    end
end)

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
