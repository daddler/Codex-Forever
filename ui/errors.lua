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
    -- 1.0.5.16 (Bericht: Fehler im Auktionshaus des Spiels, "CanPostItem",
    -- ohne eine Zeile von WeintCodex - trotzdem als unserer gemeldet): die
    -- Aufrufkette wird IN diesem Fehlerweg gelesen und enthielt deshalb
    -- immer ui/errors.lua - jeder Lua-Fehler des Spiels galt als unserer.
    -- Jetzt zaehlen nur Zeilen ausserhalb des Fehlerwegs.
    if msg:find("WeintCodex", 1, true) then return true end
    for line in tostring(stack or ""):gmatch("[^\n]+") do
        if line:find("WeintCodex", 1, true) and not line:find("ui/errors.lua", 1, true)
           and not line:find("ui\\errors.lua", 1, true) then
            return true
        end
    end
    return false
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
        -- 6.54.3.0: der Anhang (Taint-Bericht) gilt fuer DIESE Sperre - ein
        -- aelterer Eintrag ohne ihn bekam ihn bisher nie.
        if type(extra) == "string" and extra ~= "" then e.stack = ER.Trim(stack) .. "\n" .. extra end
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

--------------------------------------------------
-- Melden (1.0.5.28)
--------------------------------------------------
-- Wunsch des Projektinhabers: "Button zum Bug senden - der User klickt nur
-- darauf, und der Report kommt bei mir an." Ein Addon schickt nichts ins
-- Netz: "Melden" merkt den Fehler vor (e.report = "pending") und laedt neu -
-- erst dann steht er in der Datei. Die Companion liest ihn dort und schickt
-- ihn an den Bot (Discord, Forum "Fehlerberichte"). Mitgeschickt wird nur,
-- was im Bericht steht: Fehlertext, Aufrufkette, Fassungen, Klasse, Stufe,
-- Zone - kein Chat, kein Gold, nichts aus dem Spielstand.

-- Laeuft eine Companion? Nur dann kommt ein Bericht an. Die Live-Datei ist
-- im Auslieferungsstand leer; die Companion schreibt ihre Uhrzeit hinein.
function ER.HasCompanion()
    local live = _G.WeintCodex_CompanionLive
    return type(live) == "table" and (tonumber(live.writtenAt) or 0) > 0
end

function ER.MarkReport(entries)
    local v, b = Client()
    local cls, lvl, zone = Who()
    local n = 0
    for _, e in ipairs(entries or {}) do
        if e.report ~= "pending" then
            e.report = "pending"
            e.reportAt = _G.time and _G.time() or 0
            e.client = v .. " (" .. b .. ")"
            e.locale = _G.GetLocale and _G.GetLocale() or "?"
            e.class, e.level, e.zone = cls, lvl, zone
            n = n + 1
        end
    end
    return n
end

local sendBtn
local function SendButton(report)
    if sendBtn then return sendBtn end
    sendBtn = WeintCodex.CreateButton(report, {
        text = "Melden & neu laden", kind = "primary", width = 170, height = 28,
        tooltip = "Schickt den Fehler über die Companion an den Entwickler. Das Spiel lädt dafür einmal neu (wie /reload).",
    })
    sendBtn:SetPoint("BOTTOMLEFT", report, "BOTTOMLEFT", 14, 14)
    WeintCodex.AttachReload(sendBtn, function()
        ER.MarkReport(sendBtn.entries)
    end)
    ER.sendButton = sendBtn
    return sendBtn
end

-- Freundlich zuerst, Technik darunter.
ER.FRIENDLY = "Da ist bei WeintCodex etwas schiefgelaufen – dein Spiel läuft normal weiter."
function ER.Show(entries, title)
    if not (K.ShowReport and entries and #entries > 0) then return false end
    local r = K.ShowReport(title or ER.FRIENDLY, ER.Lines(entries))
    if r and WeintCodex.CreateButton then
        local hasC = ER.HasCompanion()
        local ok, btn = pcall(SendButton, r)
        if ok and btn then
            btn.entries = entries
            btn:SetShown(hasC)
        end
        if r.hint then
            r.hint:SetText(hasC
                and "„Melden & neu laden“ schickt ihn dem Entwickler – das Spiel lädt dafür einmal neu. Du musst nichts kopieren."
                or "Ohne Companion kann WeintCodex nichts selbst senden: Strg+C kopiert, dann im Discord unter #weintcodex-support posten.")
        end
        r._wcErrors = true
    end
    return true
end

-- Alle gespeicherten (oder die dieser Sitzung).
function ER.ShowAll()
    local list = Store() or {}
    if #list == 0 then
        print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Keine Fehler gespeichert.")
        return false
    end
    return ER.Show(list, "Gespeicherte Fehler von WeintCodex (" .. #list .. ")")
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
            .. " Kleiner Fehler im Addon – dein Spiel läuft weiter. Melden geht mit einem Klick im Fenster. Alle: /wcui fehler")
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
-- 1.0.3.7 (Fehlerbericht "Verboten: UNKNOWN()" aus UseContainerItem, ohne
-- Taint-Bericht): der Client nennt die Funktion nicht immer - dann zaehlt,
-- was im Stapel steht.
function ER.Extra(func, stack)
    local f = tostring(K.Plain(func) or "") .. " " .. tostring(stack or "")
    -- 1.0.6.7: Sperren aus der Weltkarte - der Bericht nennt, welches Feld
    -- der Karte verunreinigt ist und nach welcher Aktion es auffiel.
    if (f:find("MapCanvas", 1, true) or f:find("WorldMap", 1, true) or f:find("DataProvider", 1, true)) and K.MapTaintReport then
        local okM, linesM = pcall(K.MapTaintReport)
        if okM and type(linesM) == "table" then return "--- Weltkarte, Taint-Bericht ---\n" .. table.concat(linesM, "\n") end
    end
    -- 1.0.3.8: auch die Bank ("Verboten: PurchaseBankTab()" beim Oeffnen,
    -- dreimal gemeldet, Ursache unbekannt) - der Bericht nennt BankPanel.
    if not (f:find("ContainerItem", 1, true) or f:find("UseItem", 1, true) or f:find("BankTab", 1, true)) then return nil end
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
ev:SetScript("OnEvent", WeintCodex.Measured("Fehlerfenster", function(_, event, addon, func)
    if event == "PLAYER_LOGIN" then
        -- Spaeter geladene Fehlerfaenger (BugGrabber) uebernehmen den Weg
        -- oft ohne Weiterreichen: davor haengen.
        ER.Hook()
        return
    end
    if addon ~= "WeintCodex" then return end
    local msg = (event == "ADDON_ACTION_FORBIDDEN" and "Verboten: " or "Blockiert: ") .. tostring(func or "?")
    local stack = _G.debugstack and _G.debugstack(2) or ""
    ER.Announce(ER.Record("blocked", msg, stack, ER.Extra(func, stack)))
end))
ER.events = ev
