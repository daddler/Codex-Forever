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
ER.STACK_LINES = 20    -- Zeilen der Aufrufkette je Fehler (1.0.6.20: 20 statt 14)
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

ER.foreign = {}
local prev
local function Handler(msg, ...)
    if not busy then
        busy = true
        pcall(function()
            local stack = _G.debugstack and _G.debugstack(3) or ""
            if ER.Ours(msg, stack) then ER.Announce(ER.Record("lua", msg, stack, ER.Situation and ER.Situation()))
            else
                -- 1.0.7.41: fremde Fehler nur merken (fuer /wcui pruefen, z. B.
                -- SpartanUI baut seine Minikarte nicht), nie melden, nie aendern.
                local f = ER.foreign
                if #f >= 8 then table.remove(f, 1) end
                f[#f + 1] = tostring(msg):sub(1, 220) .. " | " .. (tostring(stack):match("AddOns[/\\]([^\n]-:%d+)") or "?")
            end
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

--------------------------------------------------
-- UMSTAENDE UND SPUR (1.0.6.20, Wunsch: "detaillierte Fehlerberichte, wir
-- muessen immer raten, was gemacht wurde"). Jeder Bericht bekommt:
--   * Lage im Augenblick des Fehlers: Kampf, Instanz, Gruppe, Leiter, tot,
--     beritten, Ziel (nur die Art), Rahmen unter der Maus, offene Fenster,
--     Gruppenrahmen, Profil, andere geladene Addons.
--   * Spur: die letzten Schritte davor mit Sekunden - Fenster auf/zu,
--     Kampf, Zonenwechsel, Haendler/Post/Bank, gewirkte Zauber, eigene
--     Befehle (/wc, /wcui), Menues und Klickzauber von WeintCodex.
-- Keine Namen anderer Spieler, kein Chat, kein Gold, keine Gegenstaende.
-- Alles haengt am Text der Aufrufkette - so kommt es ohne Aenderung an
-- Companion oder Bot mit.
--------------------------------------------------
ER.TRACE_MAX, ER.TRACE_SECS = 25, 180
local trace = {}
ER.trace = trace
local function TClock()
    local t = _G.GetTime and _G.GetTime()
    if K and K.Plain then t = K.Plain(t) end
    return type(t) == "number" and t or 0
end
function ER.Trace(text)
    if type(text) ~= "string" or text == "" then return end
    local now = TClock()
    local last = trace[#trace]
    if last and last.text == text and now - last.t < 2 then last.n = (last.n or 1) + 1 last.t = now return end
    trace[#trace + 1] = { t = now, text = text:sub(1, 90) }
    while #trace > ER.TRACE_MAX do table.remove(trace, 1) end
end

function ER.TraceLines()
    local now, out = TClock(), {}
    for _, e in ipairs(trace) do
        local ago = now - e.t
        if ago <= ER.TRACE_SECS then
            out[#out + 1] = string.format("  vor %4.1f s  %s%s", ago, e.text, (e.n and e.n > 1) and (" (" .. e.n .. "x)") or "")
        end
    end
    return out
end

local function Q(fn, ...)
    if type(fn) ~= "function" then return nil end
    local r = { pcall(fn, ...) }
    if not r[1] then return nil end
    for i = 2, #r do if K.IsSecret and K.IsSecret(r[i]) then r[i] = nil else r[i] = K.Plain(r[i]) end end
    return r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9]
end

-- Frames, deren "offen" im Bericht interessiert (des Spiels und eigene).
ER.WATCH_FRAMES = { "WorldMapFrame", "CharacterFrame", "PlayerSpellsFrame", "SpellBookFrame", "TalentFrame",
    "ProfessionsFrame", "TradeSkillFrame", "MerchantFrame", "BankFrame", "GuildBankFrame", "MailFrame",
    "AuctionHouseFrame", "TradeFrame", "LootFrame", "GossipFrame", "QuestFrame", "FriendsFrame",
    "CommunitiesFrame", "LFGParentFrame", "PVEFrame", "CollectionsJournal", "SettingsPanel", "GameMenuFrame",
    "MacroFrame", "ClassTrainerFrame", "ContainerFrame1", "ContainerFrameCombinedBags", "StaticPopup1",
    "WeintCodexMainFrame", "WeintCodexBags", "WeintCodexOptions", "WeintCodexMessenger" }

local function FrameName(f)
    if type(f) ~= "table" then return nil end
    local ok, n = pcall(f.GetName, f)
    n = ok and K.Plain(n) or nil
    if type(n) == "string" and n ~= "" then return n end
    local ok2, ot = pcall(f.GetObjectType, f)
    return "(" .. tostring(ok2 and ot or "?") .. ")"
end

function ER.MouseChain()
    local f
    if _G.GetMouseFoci then
        local ok, list = pcall(function() return { _G.GetMouseFoci() } end)
        f = ok and list[1] or nil
        if type(f) == "table" and type(f[1]) == "table" then f = f[1] end
    elseif _G.GetMouseFocus then
        f = Q(_G.GetMouseFocus)
    end
    local parts = {}
    for _ = 1, 4 do
        if type(f) ~= "table" then break end
        parts[#parts + 1] = FrameName(f)
        local ok, p = pcall(f.GetParent, f)
        f = ok and p or nil
        if f == _G.UIParent or f == _G.WorldFrame then break end
    end
    return #parts > 0 and table.concat(parts, " < ") or "nichts (Spielwelt)"
end

function ER.Context()
    local out = {}
    local combat = Q(_G.UnitAffectingCombat, "player")
    local lock = Q(_G.InCombatLockdown)
    local inside, kind = Q(_G.IsInInstance)
    local iname = inside and Q(_G.GetInstanceInfo) or nil
    local raid, party = Q(_G.IsInRaid), Q(_G.IsInGroup)
    local n = Q(_G.GetNumGroupMembers) or 0
    local lead = Q(_G.UnitIsGroupLeader, "player")
    local dead, ghost = Q(_G.UnitIsDead, "player"), Q(_G.UnitIsGhost, "player")
    local mounted = Q(_G.IsMounted)
    local sub = Q(_G.GetSubZoneText)
    out[#out + 1] = "Kampf " .. (combat and "ja" or "nein") .. " (Sperre " .. (lock and "ja" or "nein") .. ")"
        .. " · " .. (inside and ("Instanz " .. tostring(kind) .. ": " .. tostring(iname or "?")) or "keine Instanz")
        .. ((type(sub) == "string" and sub ~= "") and (" · " .. sub) or "")
    out[#out + 1] = "Gruppe " .. (raid and ("Schlachtzug " .. n) or (party and ("Gruppe " .. n) or "allein"))
        .. (lead and " · Leiter" or "") .. (dead and " · tot" or "") .. (ghost and " · Geist" or "")
        .. (mounted and " · beritten" or "")
    local tgt = "keins"
    if Q(_G.UnitExists, "target") then
        local isPlayer = Q(_G.UnitIsPlayer, "target")
        local enemy = Q(_G.UnitCanAttack, "player", "target")
        local cls = Q(_G.UnitClassification, "target")
        tgt = (isPlayer and "Spieler" or "NPC") .. (enemy and ", feindlich" or ", freundlich")
            .. ((type(cls) == "string" and cls ~= "normal") and (", " .. cls) or "")
    end
    out[#out + 1] = "Ziel " .. tgt .. " · Maus über " .. ER.MouseChain()
    local open = {}
    for _, name in ipairs(ER.WATCH_FRAMES) do
        local f = _G[name]
        if type(f) == "table" and f.IsShown then
            local ok, v = pcall(f.IsShown, f)
            if ok and K.Plain(v) == true then open[#open + 1] = name end
        end
    end
    out[#out + 1] = "Offen: " .. (#open > 0 and table.concat(open, ", ") or "nichts")
    local gf = K.Get and K.Get("groupframes", "source")
    local prof = K.Profile and Q(K.Profile)
    out[#out + 1] = "Gruppenrahmen " .. tostring(gf) .. " · Profil " .. tostring(type(prof) == "string" and prof or "?")
        .. " · Oberfläche " .. ((K.UIEnabled and K.UIEnabled()) and "an" or "aus")
    local ca = _G.C_AddOns
    local num = ca and Q(ca.GetNumAddOns) or (Q(_G.GetNumAddOns) or 0)
    local names = {}
    for i = 1, num or 0 do
        local name = ca and Q(ca.GetAddOnInfo, i) or Q(_G.GetAddOnInfo, i)
        local loaded = ca and Q(ca.IsAddOnLoaded, i) or Q(_G.IsAddOnLoaded, i)
        if loaded and type(name) == "string" and name ~= "WeintCodex" and not name:find("^Blizzard_") then
            names[#names + 1] = name
        end
    end
    local list = table.concat(names, ", ")
    if #list > 400 then list = list:sub(1, 400) .. " …" end
    out[#out + 1] = "Andere Addons (" .. #names .. "): " .. (list ~= "" and list or "keine")
    return out
end

-- Was an jeden Bericht gehaengt wird.
function ER.Situation()
    local ok, ctx = pcall(ER.Context)
    local lines = { "--- Umstände ---" }
    if ok and type(ctx) == "table" then
        for _, l in ipairs(ctx) do lines[#lines + 1] = l end
    else
        lines[#lines + 1] = "nicht lesbar: " .. tostring(ctx)
    end
    local tl = ER.TraceLines()
    lines[#lines + 1] = "--- Spur (letzte " .. ER.TRACE_SECS .. " s, neueste unten) ---"
    if #tl == 0 then lines[#lines + 1] = "  (nichts aufgezeichnet)" end
    for _, l in ipairs(tl) do lines[#lines + 1] = l end
    return table.concat(lines, "\n")
end

-- Spur: Ereignisse des Spiels (nur gelesen) und Fenster.
do
    local tf = CreateFrame("Frame")
    ER.traceEvents = tf
    local EV = {
        PLAYER_REGEN_DISABLED = "Kampf begonnen", PLAYER_REGEN_ENABLED = "Kampf vorbei",
        ZONE_CHANGED_NEW_AREA = "Zonenwechsel", PLAYER_ENTERING_WORLD = "Ladebildschirm vorbei",
        GROUP_ROSTER_UPDATE = "Gruppe geändert", ENCOUNTER_START = "Bosskampf begonnen", ENCOUNTER_END = "Bosskampf vorbei",
        LOOT_OPENED = "Beute geöffnet", MERCHANT_SHOW = "Händler geöffnet", BANKFRAME_OPENED = "Bank geöffnet",
        MAIL_SHOW = "Post geöffnet", AUCTION_HOUSE_SHOW = "Auktionshaus geöffnet", GOSSIP_SHOW = "Gespräch geöffnet",
        QUEST_DETAIL = "Quest angeboten", QUEST_COMPLETE = "Quest abgeben", TRADE_SHOW = "Handel geöffnet",
        PLAYER_DEAD = "gestorben", PLAYER_UNGHOST = "wiederbelebt", READY_CHECK = "Bereitschaftscheck",
        PLAYER_TARGET_CHANGED = "Ziel gewechselt", UNIT_SPELLCAST_SUCCEEDED = true,
        PLAYER_MOUNT_DISPLAY_CHANGED = "Reittier auf/ab", UPDATE_BINDINGS = "Tastenbelegung geändert",
    }
    for e in pairs(EV) do pcall(tf.RegisterEvent, tf, e) end
    tf:SetScript("OnEvent", function(_, e, unit, _, spellID)
        if e == "UNIT_SPELLCAST_SUCCEEDED" then
            if unit ~= "player" then return end
            local cs = _G.C_Spell
            local name = cs and cs.GetSpellName and Q(cs.GetSpellName, K.Plain(spellID))
            if type(name) == "string" then ER.Trace("Zauber gewirkt: " .. name) end
            return
        end
        ER.Trace(EV[e])
    end)
    if _G.hooksecurefunc then
        if type(_G.ShowUIPanel) == "function" then
            _G.hooksecurefunc("ShowUIPanel", function(f) ER.Trace("Fenster auf: " .. tostring(FrameName(f))) end)
        end
        if type(_G.HideUIPanel) == "function" then
            _G.hooksecurefunc("HideUIPanel", function(f) ER.Trace("Fenster zu: " .. tostring(FrameName(f))) end)
        end
    end
end

-- Ein Teil probiert etwas, das das Spiel sperren darf, und faengt die
-- Sperre selbst auf: fuer `secs` Sekunden gilt eine Sperre als erwartet.
ER.expectUntil = 0
local function Clock()
    local K = WeintCodex.UIKit
    local t = _G.GetTime and _G.GetTime()
    if K and K.Plain then t = K.Plain(t) end
    return type(t) == "number" and t or 0
end
function ER.Expect(secs) ER.expectUntil = Clock() + (secs or 1) end

-- Name des Menues, das WeintCodex zuletzt geoeffnet hat.
ER.MENU_WINDOW = 120
function ER.NoteMenu(name)
    if type(name) ~= "string" or name == "" then return end
    ER.Trace("Spielermenü von WeintCodex geöffnet")
    ER.menuName, ER.menuAt = name, Clock()
end
function ER.CopyFallback()
    local name = ER.menuName
    if not name or Clock() - (ER.menuAt or -1e9) > ER.MENU_WINDOW then return false end
    local K = WeintCodex.UIKit
    if K and K.ShowReport and pcall(K.ShowReport, "Name kopieren – markiert, Strg+C", { name }) then return true end
    print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " Name: " .. name)
    return true
end
function ER.Expected() return (ER.expectUntil or 0) > 0 and Clock() <= ER.expectUntil end
function ER.ExpectEnd() ER.expectUntil = 0 end

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
    -- 1.0.6.12 (Bericht: "Blockiert: UNKNOWN()" aus dem Senden des
    -- Messengers): ein Teil, der eine Sperre erwartet und selbst auffaengt
    -- (ER.Expect kurz vor dem Versuch), ist kein Fehler.
    if ER.Expected() then return end
    -- 1.0.6.20 (Bericht: "Verboten: CopyToClipboard()" aus dem Menue einer
    -- Einheit): ein Menue, das WeintCodex selbst geoeffnet hat (Rechtsklick
    -- im Fluesterfenster, Menue mit Zusatztaste an Rahmen), gilt dem Spiel
    -- als vom Addon - "Name kopieren" ist darin gesperrt. Statt eines
    -- Fehlers ein Fenster mit dem Namen zum Kopieren (Strg+C).
    if tostring(func) == "CopyToClipboard()" and ER.CopyFallback() then return end
    local msg = (event == "ADDON_ACTION_FORBIDDEN" and "Verboten: " or "Blockiert: ") .. tostring(func or "?")
    local stack = _G.debugstack and _G.debugstack(2) or ""
    local extra = ER.Extra(func, stack)
    local sit = ER.Situation()
    ER.Announce(ER.Record("blocked", msg, stack, extra and (extra .. "\n" .. sit) or sit))
end))
ER.events = ev

-- /wcui speicher: interne Tabellen dieser Datei (1.0.8.27).
WeintCodex.Hold("ui/errors.lua", function() return { shown = shown, session = session, trace = trace } end)
