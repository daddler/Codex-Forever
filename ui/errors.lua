--------------------------------------------------
-- WeintCodex :: Fehler fangen und zum Kopieren zeigen (6.50.0.0)
--------------------------------------------------
-- Wunsch des Projektinhabers: "Bugsack/BugGrabber im Addon - Fehler taucht
-- auf, Fenster kommt wie bei /wcui fenster, Spieler kann direkt kopieren
-- und mir zukommen lassen." Eigener Code, kein Code aus BugGrabber/BugSack.
--
-- WAS GEFANGEN WIRD: nur Fehler von WeintCodex - Lua-Fehler, deren Text
-- oder Aufrufkette "WeintCodex" nennt, und vom Spiel blockierte Aufrufe
-- (ADDON_ACTION_BLOCKED/FORBIDDEN) mit Addon "WeintCodex". Fremde Fehler
-- gehen uns nichts an.
--
-- WIE: der Fehlerweg des Spiels (seterrorhandler) bekommt eine Huelle; der
-- vorige Weg wird IMMER weitergerufen - BugSack, das Spiel und andere
-- sehen alles wie vorher. Uebernimmt ein spaeter geladenes Addon den Weg
-- (BugGrabber), haengt sich WeintCodex beim Einloggen erneut davor.
--
-- ANZEIGE: je neuem Fehler einmal je Sitzung ein Fenster zum Kopieren
-- (dasselbe wie /wcui fenster) - nie im Kampf, dann danach. Gleiche Fehler
-- werden gezaehlt, nicht gestapelt. Die letzten GZ Fehler bleiben ueber
-- das Neuladen hinweg (SavedData.errors), /wcui fehler zeigt sie alle.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIErrors = {}

local ER = WeintCodex.UIErrors
local K  = WeintCodex.UIKit

ER.MAX = 20            -- so viele verschiedene Fehler bleiben gespeichert
ER.STACK_LINES = 14    -- Zeilen der Aufrufkette je Fehler
ER.MAX_MSG = 600

local shown = {}       -- [Schluessel] = true: in dieser Sitzung schon gezeigt
local session = {}     -- Fehler dieser Sitzung (Schluessel)
ER.session = session
local busy = false     -- kein Fehler im eigenen Fehlerweg

function ER.Enabled()
    return K.Get("comfort", "errorCatch") ~= false
end

local function Store()
    local sd = _G.WeintCodex_SavedData
    if type(sd) ~= "table" then return nil end
    if type(sd.errors) ~= "table" then sd.errors = {} end
    return sd.errors
end

-- Gehoert der Fehler zu uns?
function ER.Ours(msg, stack)
    msg = tostring(msg or "")
    -- 6.54.2.0 (Bericht: "tainted by 'Questie'" im WeintCodex-Fenster):
    -- nennt der Fehler selbst ein anderes Addon als Verursacher, ist er
    -- nicht unserer - auch wenn WeintCodex irgendwo in der Kette steht.
    local by = msg:match("tainted by '([^']+)'")
    if by and by ~= "WeintCodex" then return false end
    local s = msg .. "\n" .. tostring(stack or "")
    return s:find("WeintCodex", 1, true) ~= nil
end

-- Aufrufkette kuerzen: nur die Zeilen, ohne die Huelle selbst.
function ER.Trim(stack)
    if type(stack) ~= "string" then return "" end
    local out = {}
    for line in stack:gmatch("[^\n]+") do
        if not line:find("ui/errors.lua", 1, true) and not line:find("ui\\errors.lua", 1, true) then
            out[#out + 1] = line
            if #out >= ER.STACK_LINES then break end
        end
    end
    return table.concat(out, "\n")
end

-- Schluessel: Nachricht ohne Zahlen hinter Adressen, damit gleiche Fehler
-- zusammenfallen.
function ER.Key(msg)
    return (tostring(msg or ""):gsub("0x%x+", "0x"):gsub("table: %x+", "table"))
end

local function Now()
    local ok, d = pcall(_G.date, "%d.%m.%Y %H:%M:%S")
    return ok and d or "?"
end

-- Einen Fehler aufnehmen. kind: "lua" oder "blocked". Liefert den Eintrag.
function ER.Record(kind, msg, stack, extra)
    local list = Store() or session
    msg = tostring(msg or "?")
    if #msg > ER.MAX_MSG then msg = msg:sub(1, ER.MAX_MSG) .. " …" end
    local key = ER.Key(msg)
    local e
    for _, x in ipairs(list) do if x.key == key then e = x break end end
    if e then
        e.count = (e.count or 1) + 1
        e.last = Now()
        e.version = WeintCodex.Version
    else
        local st = ER.Trim(stack)
        if type(extra) == "string" and extra ~= "" then st = st .. "\n" .. extra end
        e = { key = key, kind = kind, msg = msg, stack = st, count = 1,
              first = Now(), last = Now(), version = WeintCodex.Version }
        table.insert(list, 1, e)
        while #list > ER.MAX do table.remove(list) end
    end
    session[key] = e
    return e
end

--------------------------------------------------
-- Bericht
--------------------------------------------------

local function Client()
    local v, b = "?", "?"
    if _G.GetBuildInfo then
        local ok, ver, build = pcall(_G.GetBuildInfo)
        if ok then v, b = tostring(ver), tostring(build) end
    end
    return v, b
end

local function Who()
    local cls = _G.UnitClass and select(2, _G.UnitClass("player"))
    local lvl = _G.UnitLevel and _G.UnitLevel("player")
    local zone = _G.GetZoneText and _G.GetZoneText()
    return tostring(K.Plain(cls) or "?"), tostring(K.Plain(lvl) or "?"), tostring(K.Plain(zone) or "?")
end

function ER.Lines(entries)
    local v, b = Client()
    local cls, lvl, zone = Who()
    local out = {
        "WeintCodex " .. tostring(WeintCodex.Version) .. " · Spiel " .. v .. " (" .. b .. ") · "
            .. tostring(_G.GetLocale and _G.GetLocale() or "?"),
        "Klasse " .. cls .. " · Stufe " .. lvl .. " · " .. zone
            .. " · Oberfläche " .. ((K.UIEnabled and K.UIEnabled()) and "an" or "aus"),
        "",
    }
    for i, e in ipairs(entries) do
        out[#out + 1] = string.format("#%d  %s  ·  %dx  ·  zuerst %s, zuletzt %s  ·  Fassung %s",
            i, e.kind == "blocked" and "Vom Spiel blockiert" or "Lua-Fehler", e.count or 1,
            tostring(e.first), tostring(e.last), tostring(e.version))
        out[#out + 1] = e.msg
        if e.stack and e.stack ~= "" then out[#out + 1] = e.stack end
        out[#out + 1] = ""
    end
    return out
end

function ER.Show(entries, title)
    if not (K.ShowReport and entries and #entries > 0) then return false end
    K.ShowReport(title or "WeintCodex-Fehler – Strg+C kopieren und an den Entwickler schicken", ER.Lines(entries))
    return true
end

-- Alle gespeicherten (oder die dieser Sitzung).
function ER.ShowAll()
    local list = Store() or {}
    if #list == 0 then
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Keine Fehler gespeichert.")
        return false
    end
    return ER.Show(list, "Alle gespeicherten WeintCodex-Fehler (" .. #list .. ") – Strg+C kopieren")
end

function ER.Clear()
    local sd = _G.WeintCodex_SavedData
    if type(sd) == "table" then sd.errors = {} end
    wipe(shown)
end

-- Neuen Fehler zeigen: einmal je Sitzung, nie im Kampf, nicht zweimal je Takt.
local pending
function ER.Announce(e)
    if not ER.Enabled() or shown[e.key] then return end
    shown[e.key] = true
    pending = pending or {}
    pending[#pending + 1] = e
    local function Flush()
        if not pending then return end
        if K.InCombat and K.InCombat() then K.AfterCombat(Flush) return end
        local list = pending
        pending = nil
        ER.Show(list)
        print(WeintCodex.ColorText("accent", "[WeintCodex]")
            .. " Ein Fehler ist aufgetreten – das Fenster zeigt ihn zum Kopieren. Alle: /wcui fehler")
    end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.5, Flush) else Flush() end
end

--------------------------------------------------
-- Einhaengen
--------------------------------------------------

local prev
local function Handler(msg, ...)
    if not busy then
        busy = true
        pcall(function()
            local stack = _G.debugstack and _G.debugstack(3) or ""
            if ER.Ours(msg, stack) then ER.Announce(ER.Record("lua", msg, stack)) end
        end)
        busy = false
    end
    if prev and prev ~= Handler then return prev(msg, ...) end
end
ER.Handler = Handler

function ER.Hook()
    if not (_G.seterrorhandler and _G.geterrorhandler) then return false end
    local cur = _G.geterrorhandler()
    if cur == Handler then return true end
    prev = cur
    _G.seterrorhandler(Handler)
    return true
end

ER.Hook()

-- 6.51.2.0 (Fehlerbericht: "Verboten: UseContainerItem()" beim Klick in
-- die Tasche): ein Gegenstand aus der Tasche gesperrt heisst, ein Feld am
-- Taschenknopf ist "tainted". Welches, sagt nur der Taint-Bericht der
-- Taschen - er haengt gleich mit am Fehler, im Augenblick der Sperre.
function ER.Extra(func)
    local f = tostring(K.Plain(func) or "")
    if not (f:find("ContainerItem", 1, true) or f:find("UseItem", 1, true)) then return nil end
    local BG = WeintCodex.UIBags
    if not (BG and BG.TaintReport) then return nil end
    local ok, lines = pcall(BG.TaintReport)
    if not ok or type(lines) ~= "table" then return nil end
    return "--- Taschen, Taint-Bericht ---\n" .. table.concat(lines, "\n")
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, addon, func)
    if event == "PLAYER_LOGIN" then
        -- Spaeter geladene Fehlerfaenger (BugGrabber) uebernehmen den Weg
        -- oft ohne Weiterreichen: davor haengen.
        ER.Hook()
        return
    end
    if addon ~= "WeintCodex" then return end
    local msg = (event == "ADDON_ACTION_FORBIDDEN" and "Verboten: " or "Blockiert: ") .. tostring(func or "?")
    local stack = _G.debugstack and _G.debugstack(2) or ""
    ER.Announce(ER.Record("blocked", msg, stack, ER.Extra(func)))
end)
ER.events = ev
