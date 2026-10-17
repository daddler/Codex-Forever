--------------------------------------------------
-- WeintCodex :: Questhilfe auf der Weltkarte
--------------------------------------------------
-- Seit 6.30.0.0 (Wunsch des Spielers: "so etwas wie Questie, inklusive der
-- Anzeige auf der Karte - mit einem Filter, was man sehen will"). Nach dem
-- VERHALTEN von Questie, ohne seinen Code (GPL-3.0; WeintCodex steht unter
-- MIT - dieselbe Regel wie bei WIM, DialogueUI, MoveAny).
--
-- WOHER: data/questdb.lua, erzeugt von .github/scripts/import_questdb.py aus
-- der Questdatenbank der Community fuer Forever - nur Namen, Stufen und
-- Lagen. Herkunft `community`: jeder Tooltip sagt "Unbestätigt".
--
-- WAS GEZEIGT WIRD, je Filter (Leiste unter dem Kartenfenster, dieselben
-- Schalter auf der Seite "Questhilfe" im Komfort):
--   Neue Quests  "!" am Geber jeder Quest, die du annehmen kannst: Stufe
--                erreicht, Rasse/Klasse passt, nicht erledigt, nicht im
--                Questlog, Voraussetzungen erledigt, nichts schliesst sie aus.
--   Graue        dazu die, die fuer dich grau (zu leicht) sind - blass.
--   Abgabe       "?" an der Abgabe jeder Quest im Questlog - gold, wenn sie
--                fertig ist, sonst blass.
--   Ziele        Punkte, wo die Gegner, Objekte und Beute einer Quest im
--                Questlog zu finden sind (noch nicht fertige Quests).
-- Was der Client beantwortet (erledigt, im Log, fertig, Stufe), fragt die
-- Hilfe den Client - nie geraten. Fehlt eine Abfrage, wird nichts gezeigt.
--
-- WIE: dieselben Regeln wie Geistheiler und Eingaenge (ui/mapmarks.lua) -
-- eigene Rahmen auf der Flaeche der Karte (QM.Canvas), alle in EINEM
-- Halter, nie AddDataProvider, nie SetMapID. Nur auf der Karte einer Zone.
-- Die Liste je Karte wird nur nach Ereignissen neu gerechnet, nie im Takt.
--------------------------------------------------

local K  = WeintCodex.UIKit
local C  = WeintCodex.Colors
local KEY = "comfort"

WeintCodex.UIQuestHelper = {}
local QH = WeintCodex.UIQuestHelper

QH.DEFAULTS = {
    qhOn      = false,   -- Questhilfe auf der Karte
    qhAvail   = true,    -- neue Quests
    qhLow     = false,   -- auch graue
    qhTurnin  = true,    -- Abgabe
    qhTargets = true,    -- Ziele
    -- 6.30.1.0 (Beta-Test mit Bild: "es wird immer alles angezeigt, egal
    -- welche Quest ich als erstes machen will"): Ziele ab Werk nur der
    -- gewaehlten Quest; alle nur auf Wunsch.
    qhAllTargets = false,
    qhBar     = true,    -- Filterleiste auf der Karte
    qhMinimap = true,    -- dieselben Symbole auf der Minikarte (6.30.7.0)
    -- 6.37.0.0 (Beta-Test: "Urahne Rumblerock" stand ausserhalb des
    -- Mondfests auf der Karte): Quests der Feste nur, solange ihr Fest laut
    -- Kalender des Spiels laeuft - oder auf Wunsch alle.
    qhEvents    = true,  -- Feste: Quests laufender Feste zeigen
    qhEventsAll = false, -- auch Feste, die gerade nicht laufen
    qhBooks     = true,  -- 6.57.0.0: Buecher der Bibliothek, die noch fehlen
}
QH.FILTERS = {
    { key = "qhAvail",   text = "Neue Quests" },
    { key = "qhLow",     text = "Graue" },
    { key = "qhTurnin",  text = "Abgabe" },
    { key = "qhTargets", text = "Ziele" },
    { key = "qhAllTargets", text = "Alle Ziele" },
    { key = "qhEvents",  text = "Feste" },
    { key = "qhBooks",   text = "Bücher" },
}
QH.SIZE = 20          -- "!" und "?" (so gross wie die des Spiels)
QH.DOT = 16           -- Ziel (Bild: Schwert, Beutel, Zahnrad)
QH.TICK = 0.05
QH.GRAY_DIFF = 8      -- Ersatz, wenn der Client keinen Bereich nennt

local function Get(k) return K.Get(KEY, k) end
function QH.Active() return K.IsActive(KEY) and Get("qhOn") and true or false end
local function Data() return WeintCodex.QuestDBData or { q = {}, n = {}, o = {}, i = {} } end
local function QM() return WeintCodex.QuestMap end

--------------------------------------------------
-- Was der Client sagt
--------------------------------------------------

local log, logDone = {}, {}     -- Quest im Log / dort fertig
QH.log, QH.logDone = log, logDone

function QH.ReadLog()
    for k in pairs(log) do log[k] = nil end
    for k in pairs(logDone) do logDone[k] = nil end
    local ql = _G.C_QuestLog
    if not (ql and ql.GetNumQuestLogEntries and ql.GetInfo) then return false end
    local n = K.Plain(ql.GetNumQuestLogEntries())
    if type(n) ~= "number" then return false end
    for i = 1, n do
        local ok, info = pcall(ql.GetInfo, i)
        if ok and type(info) == "table" and not K.Plain(info.isHeader) then
            local id = K.Plain(info.questID)
            if type(id) == "number" and id > 0 then
                log[id] = true
                local done = ql.IsComplete and K.Plain(ql.IsComplete(id))
                if done == true then logDone[id] = true end
            end
        end
    end
    return true
end

-- true erledigt, false nicht, nil weiss nicht.
function QH.Done(id)
    local ql = _G.C_QuestLog
    local f = ql and ql.IsQuestFlaggedCompleted or _G.IsQuestFlaggedCompleted
    if not f then return nil end
    local ok, v = pcall(f, id)
    if not ok then return nil end
    v = K.Plain(v)
    if type(v) ~= "boolean" then return nil end
    return v
end

local function Bit(mask, n)
    if not mask or mask == 0 then return true end
    local b = 2 ^ (n - 1)
    return math.floor(mask / b) % 2 == 1
end

function QH.Me()
    local lvl = _G.UnitLevel and K.Plain(_G.UnitLevel("player"))
    local race = _G.UnitRace and K.Plain(select(3, _G.UnitRace("player")))
    local class = _G.UnitClass and K.Plain(select(3, _G.UnitClass("player")))
    local gray = QH.GRAY_DIFF
    if _G.UnitQuestTrivialLevelRange then
        local r = K.Plain(_G.UnitQuestTrivialLevelRange("player"))
        if type(r) == "number" and r > 0 then gray = r end
    end
    return { level = type(lvl) == "number" and lvl or nil,
             race = type(race) == "number" and race or nil,
             class = type(class) == "number" and class or nil, gray = gray }
end

-- Die gewaehlte Quest: eigener Klick auf ein Symbol, sonst die Quest, die
-- das Spiel verfolgt (Klick im Questlog), sonst die des Questpfeils - nur,
-- solange sie im Questlog steht.
QH.focus = nil
function QH.Focus()
    if QH.focus and log[QH.focus] then return QH.focus end
    local st = _G.C_SuperTrack
    local game = st and st.GetSuperTrackedQuestID and K.Plain(st.GetSuperTrackedQuestID())
    if type(game) == "number" and log[game] then return game end
    local QA = WeintCodex.UIQuestArrow
    local qa = QA and (QA.manual or QA.Chosen)
    if type(qa) == "number" and log[qa] then return qa end
    return nil
end

-- Eine Quest waehlen (nil: Wahl loesen). Der Questpfeil folgt mit.
function QH.SetFocus(id)
    local QA = WeintCodex.UIQuestArrow
    -- 6.60.1.0: eine Quest waehlen loest den Pfeil vom Buch.
    if id and QA then QA.custom = nil end
    -- Loesen gibt den Pfeil nur frei, wenn er noch unserer Wahl folgt.
    if QA and QH.focus and QA.manual == QH.focus then QA.manual = nil end
    QH.focus = id
    if QA and id then QA.manual = id end
    QH.Forget()
    QH.PaintBar()
end

-- "avail", "low" oder nil: kann ich die Quest annehmen?
function QH.Offer(id, q, me)
    if not (me.level and me.race and me.class) then return nil end
    if log[id] then return nil end
    if (q[3] or 0) > me.level then return nil end
    if not Bit(q[4], me.race) or not Bit(q[5], me.class) then return nil end
    local done = QH.Done(id)
    if done ~= false then return nil end
    for _, p in ipairs(q[13] or {}) do
        if QH.Done(p) ~= true then return nil end
    end
    local single = q[14]
    if single and #single > 0 then
        local any = false
        for _, p in ipairs(single) do
            -- 6.61.4.0 (Beta-Test: "Quests, die ich noch nicht annehmen
            -- kann" - Waldweberei, solange Waldwebergift im Log stand):
            -- Voraussetzung heisst ABGEGEBEN, im Log genuegt nicht.
            if QH.Done(p) == true then any = true break end
        end
        if not any then return nil end
    end
    for _, x in ipairs(q[15] or {}) do
        if log[x] or QH.Done(x) == true then return nil end
    end
    local lvl = q[2] or 0
    if lvl > 0 and lvl < me.level - me.gray then return "low" end
    return "avail"
end

--------------------------------------------------
-- Feste (6.37.0.0)
--------------------------------------------------
-- Welche Quest zu welchem Fest gehoert: data/questevents.lua (Classic).
-- Welches Fest laeuft: der Kalender des Spiels, Feiertage des heutigen
-- Tages. Kann der Client das nicht sagen, gilt keines als laufend - eine
-- Festquest ausserhalb ihres Fests waere eine Quest, die es nicht gibt.

local eventOf
function QH.EventOf(id)
    if not eventOf then
        eventOf = {}
        for _, ev in ipairs(WeintCodex.QuestEvents or {}) do
            for _, q in ipairs(ev.quests) do eventOf[q] = ev end
        end
    end
    return eventOf[id]
end

QH.fest = { known = false, active = {}, titles = {} }
function QH.ReadCalendar()
    local E = QH.fest
    local cal, dt = _G.C_Calendar, _G.C_DateAndTime
    if not (cal and cal.GetNumDayEvents and cal.GetDayEvent and dt and dt.GetCurrentCalendarTime) then
        E.known = false
        return E
    end
    local ok, now = pcall(dt.GetCurrentCalendarTime)
    if not ok or type(now) ~= "table" then E.known = false return E end
    -- Monat 0 ist der, den der Kalender gerade zeigt: auf heute stellen,
    -- aber nicht, waehrend der Spieler darin blaettert.
    -- 6.37.0.1 (/wcui speicher: Questhilfe 36 MB/s): SetAbsMonth loest selbst
    -- CALENDAR_UPDATE_EVENT_LIST aus - darauf wurde neu gelesen, wieder
    -- gestellt ... eine Schleife, und die Minikarte rechnete jedes Bild alle
    -- Quests neu. Jetzt nur stellen, wenn der Kalender einen anderen Monat
    -- zeigt, und nie, waehrend er offen ist.
    local cf = _G.CalendarFrame
    local shown = cal.GetMonthInfo and select(2, pcall(cal.GetMonthInfo, 0))
    local month = type(shown) == "table" and K.Plain(shown.month)
    if cal.SetAbsMonth and month ~= now.month and not (type(cf) == "table" and cf.IsShown and cf:IsShown()) then
        pcall(cal.SetAbsMonth, now.month, now.year)
    end
    local okN, n = pcall(cal.GetNumDayEvents, 0, now.monthDay)
    n = okN and K.Plain(n)
    if type(n) ~= "number" then E.known = false return E end
    local before = E.sig
    for k in pairs(E.active) do E.active[k] = nil end
    for i = #E.titles, 1, -1 do E.titles[i] = nil end
    for i = 1, n do
        local okE, ev = pcall(cal.GetDayEvent, 0, now.monthDay, i)
        local title = okE and type(ev) == "table" and K.Plain(ev.title)
        if type(title) == "string" and (ev.calendarType == "HOLIDAY" or ev.calendarType == nil) then
            E.titles[#E.titles + 1] = title
            local low = title:lower()
            for _, def in ipairs(WeintCodex.QuestEvents or {}) do
                for _, w in ipairs(def.words) do
                    if low:find(w, 1, true) then E.active[def.key] = true end
                end
            end
        end
    end
    E.known = true
    local sig = ""
    for _, def in ipairs(WeintCodex.QuestEvents or {}) do
        if E.active[def.key] then sig = sig .. def.key .. " " end
    end
    E.sig, E.changed = sig, sig ~= before
    return E
end

-- Darf eine Festquest als neue Quest erscheinen?
function QH.EventAllowed(ev)
    if not ev then return true end
    if not Get("qhEvents") then return false end
    if Get("qhEventsAll") then return true end
    return QH.fest.active[ev.key] and true or false
end

--------------------------------------------------
-- Liste je Karte
--------------------------------------------------

--------------------------------------------------
-- Bestand lesen (6.30.5.0)
--------------------------------------------------
-- Jeder Eintrag ist EIN Text (data/questdb.lua): als Tabellen belegte der
-- Bestand 7 MB, als Text 1,6 MB. Gelesen wird ein Eintrag erst, wenn die
-- Karte ihn braucht, und nicht aufbewahrt. Tabellen (Pruefung) gehen durch.

local function List(text)
    local out = {}
    if text and text ~= "" then
        for v in text:gmatch("[^,]+") do out[#out + 1] = tonumber(v) end
    end
    return out
end

local fields = {}
function QH.Parse(raw)
    if type(raw) ~= "string" then return raw end
    local n = 0
    for f in (raw .. "\t"):gmatch("([^\t]*)\t") do
        n = n + 1
        fields[n] = f
    end
    local q = { fields[1] }
    for i = 2, 5 do q[i] = tonumber(fields[i]) or 0 end
    for i = 6, 15 do q[i] = List(fields[i]) end
    return q
end
function QH.Quest(id) return QH.Parse(Data().q[id]) end

function QH.Name(rec)
    if type(rec) == "table" then return rec[1] end
    if type(rec) == "string" then return rec:match("^([^\t]*)") end
    return nil
end

-- Wer einen Gegenstand fallen laesst: {NPCs}, {Objekte}.
function QH.Item(raw)
    if type(raw) ~= "string" then return raw end
    local a, b = raw:match("^([^\t]*)\t(.*)$")
    return { List(a), List(b) }
end

-- Lagen eines NPC/Objekts auf `mapID`: ruft add(x, y) je Lage.
function QH.Places(rec, mapID, add)
    if type(rec) == "string" then
        local key = mapID .. ":"
        local at = rec:find("\t" .. key, 1, true) or rec:find(";" .. key, 1, true)
        if not at then return 0 end
        local seg = rec:match("^[^;]*", at + 1 + #key)
        local count, x = 0, nil
        for v in seg:gmatch("[^,]+") do
            if x then
                add(x, tonumber(v))
                count, x = count + 1, nil
            else
                x = tonumber(v)
            end
        end
        return count
    end
    if type(rec) ~= "table" then return 0 end
    local i, n = 2, #rec
    local count = 0
    while i <= n do
        local map = rec[i]
        local j = i + 1
        while j < n and rec[j] ~= 0 do
            if map == mapID then
                add(rec[j], rec[j + 1])
                count = count + 1
            end
            j = j + 2
        end
        i = j + 1
    end
    return count
end

local forMap = {}
QH.stats = { built = 0, avail = 0, turnin = 0, target = 0, book = 0 }

local function Add(out, seen, kind, who, isObj, quest, x, y, faint, sub)
    local key = kind .. (isObj and "o" or "n") .. who .. ":" .. x .. ":" .. y
    local e = seen[key]
    if e then
        e.quests[#e.quests + 1] = quest
        if not faint then e.faint = false end
        return
    end
    e = { kind = kind, who = who, obj = isObj, x = x, y = y, quests = { quest }, faint = faint, sub = sub }
    seen[key] = e
    out[#out + 1] = e
end

-- 6.61.7.0 (Beta-Test: Minikarte und Karte voller Ziel-Punkte - jede
-- Fundstelle eines Pilzes ein eigener Punkt, "sieht scheisse aus, man
-- erkennt nichts mehr"): Ziele derselben Quest und Art, die naeher als
-- QH.CLUSTER (Anteil der Kartenbreite) beieinander liegen, werden EIN
-- Punkt in ihrer Mitte; e.count sagt, wie viele Stellen er vertritt.
QH.CLUSTER = 0.06
function QH.Cluster(list)
    local out, groups = {}, {}
    local r2 = QH.CLUSTER * QH.CLUSTER
    for _, e in ipairs(list) do
        if e.kind ~= "target" then
            out[#out + 1] = e
        else
            local key = (e.quests[1] or 0) .. (e.sub or "")
            local g = groups[key]
            if not g then g = {} groups[key] = g end
            local hit
            for _, c in ipairs(g) do
                local dx, dy = c.x - e.x, c.y - e.y
                if dx * dx + dy * dy <= r2 then hit = c break end
            end
            if hit then
                local n = hit.count
                hit.x = (hit.x * n + e.x) / (n + 1)
                hit.y = (hit.y * n + e.y) / (n + 1)
                hit.count = n + 1
                for _, q in ipairs(e.quests) do
                    local known = false
                    for _, h in ipairs(hit.quests) do if h == q then known = true break end end
                    if not known then hit.quests[#hit.quests + 1] = q end
                end
            else
                e.count = 1
                g[#g + 1] = e
                out[#out + 1] = e
            end
        end
    end
    return out
end

function QH.ForMap(mapID)
    if type(mapID) ~= "number" then return {} end
    local cached = forMap[mapID]
    if cached then return cached end
    local out, seen = {}, {}
    local d = Data()
    local me = QH.Me()
    local wantA, wantL = Get("qhAvail"), Get("qhLow")
    local wantT, wantZ = Get("qhTurnin"), Get("qhTargets")
    local focus = QH.Focus()
    QH.builtFocus = focus
    local allZ = Get("qhAllTargets")
    for id, raw in pairs(d.q) do
        local q = QH.Parse(raw)
        if wantA and QH.EventAllowed(QH.EventOf(id)) then
            local offer = QH.Offer(id, q, me)
            if offer == "avail" or (offer == "low" and wantL) then
                for _, npc in ipairs(q[6]) do
                    QH.Places(d.n[npc], mapID, function(x, y) Add(out, seen, "avail", npc, false, id, x, y, offer == "low") end)
                end
                for _, ob in ipairs(q[7]) do
                    QH.Places(d.o[ob], mapID, function(x, y) Add(out, seen, "avail", ob, true, id, x, y, offer == "low") end)
                end
            end
        end
        if log[id] then
            local done = logDone[id] and true or false
            if wantT then
                for _, npc in ipairs(q[8]) do
                    QH.Places(d.n[npc], mapID, function(x, y) Add(out, seen, "turnin", npc, false, id, x, y, not done) end)
                end
                for _, ob in ipairs(q[9]) do
                    QH.Places(d.o[ob], mapID, function(x, y) Add(out, seen, "turnin", ob, true, id, x, y, not done) end)
                end
            end
            if wantZ and not done and (allZ or id == focus) then
                for _, npc in ipairs(q[10]) do
                    QH.Places(d.n[npc], mapID, function(x, y) Add(out, seen, "target", npc, false, id, x, y, nil, "slay") end)
                end
                for _, ob in ipairs(q[11]) do
                    QH.Places(d.o[ob], mapID, function(x, y) Add(out, seen, "target", ob, true, id, x, y, nil, "object") end)
                end
                for _, item in ipairs(q[12]) do
                    local src = QH.Item(d.i[item])
                    if src then
                        for _, npc in ipairs(src[1]) do
                            QH.Places(d.n[npc], mapID, function(x, y) Add(out, seen, "target", npc, false, id, x, y, nil, "loot") end)
                        end
                        for _, ob in ipairs(src[2]) do
                            QH.Places(d.o[ob], mapID, function(x, y) Add(out, seen, "target", ob, true, id, x, y, nil, "loot") end)
                        end
                    end
                end
            end
        end
    end
    out = QH.Cluster(out)
    -- 6.57.0.0: Buecher der Bibliothek, die noch fehlen (modules/library.lua).
    local LB = WeintCodex.Library
    if Get("qhBooks") and LB and LB.Missing then
        for _, b in ipairs(LB.Missing()) do
            if b[5] == mapID then
                out[#out + 1] = { kind = "book", book = b, x = b[6] / 100, y = b[7] / 100, quests = {} }
            end
        end
    end
    for _, e in ipairs(out) do e.map = mapID end
    -- Ziele unten, Geber oben.
    local order = { target = 1, book = 2, turnin = 3, avail = 4 }
    table.sort(out, function(a, b)
        if a.kind ~= b.kind then return order[a.kind] < order[b.kind] end
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)
    local st = QH.stats
    st.built, st.avail, st.turnin, st.target, st.book = st.built + 1, 0, 0, 0, 0
    for _, e in ipairs(out) do st[e.kind] = st[e.kind] + 1 end
    forMap[mapID] = out
    return out
end

function QH.Forget()
    for k in pairs(forMap) do forMap[k] = nil end
end

--------------------------------------------------
-- Symbole
--------------------------------------------------

local pins = {}
QH.pins = pins

-- 6.55.0.0 (Wunsch: "Questhilfe insgesamt viel besser und
-- professioneller"): Tooltip mit Ordnung - Name, Art, je Quest Stufe in
-- der Schwierigkeitsfarbe des Spiels, bei Quests im Log der Stand der
-- Ziele vom Client ("3/8"), Erledigtes gedaempft mit Haken.
local MEDIA_UI = "Interface\\AddOns\\WeintCodex\\media\\ui\\"
local CHECK = "|T" .. MEDIA_UI .. "icon_check:12:12:0:0|t "

function QH.Hue(id)
    local GC = WeintCodex.GameColors
    return GC["questHue" .. ((tonumber(id) or 0) % 6 + 1)] or C.textBright
end

local function LevelColor(lvl)
    if type(lvl) == "number" and lvl > 0 and _G.GetQuestDifficultyColor then
        local ok, c = pcall(_G.GetQuestDifficultyColor, lvl)
        if ok and type(c) == "table" and type(c.r) == "number" then return c.r, c.g, c.b end
    end
    local n = C.textNormal
    return n[1], n[2], n[3]
end

-- Ziele einer Quest im Log, vom Client: { { text, done } ... } oder nil.
function QH.Objectives(id)
    local ql = _G.C_QuestLog
    if not (log[id] and ql and ql.GetQuestObjectives) then return nil end
    local ok, objs = pcall(ql.GetQuestObjectives, id)
    if not ok or type(objs) ~= "table" then return nil end
    local out = {}
    for _, o in ipairs(objs) do
        local text = type(o) == "table" and K.Plain(o.text)
        if type(text) == "string" and text ~= "" then
            out[#out + 1] = { text = text, done = K.Bool(o.finished, false) }
        end
    end
    return #out > 0 and out or nil
end

local function QuestLine(id)
    local q = QH.Quest(id)
    if not q then return "?" end
    local lvl = q[2] or 0
    return (lvl > 0 and ("[" .. lvl .. "] ") or "") .. q[1]
end

QH.KIND_TEXT = { avail = "Neue Quest", turnin = "Abgabe", target = "Questziel" }

local function Tooltip(self)
    local gt = _G.GameTooltip
    local e = self.entry
    if not (gt and e) then return end
    local d = Data()
    gt:SetOwner(self, "ANCHOR_RIGHT")
    if e.kind == "book" then
        local LB = WeintCodex.Library
        local b = e.book
        local t, m, g = C.textBright, C.textMuted, C.gold
        gt:SetText(LB.BookName(b), t[1], t[2], t[3])
        gt:AddLine("Buch der Bibliothek · noch nicht abgegeben", g[1], g[2], g[3])
        local line = LB.Line(LB.Progress())
        if line then gt:AddLine(line, C.textNormal[1], C.textNormal[2], C.textNormal[3]) end
        gt:AddLine(string.format("%s %.1f, %.1f", LB.ZoneName(b[5]) or "", b[6], b[7]), m[1], m[2], m[3])
        gt:AddLine(" ")
        gt:AddLine("Klick: Questpfeil dorthin", m[1], m[2], m[3])
        gt:AddLine("Unbestätigt – Wissensstand aus der Beta.", m[1], m[2], m[3], true)
        gt:Show()
        return
    end
    local rec = e.obj and d.o[e.who] or d.n[e.who]
    local t, n, m = C.textBright, C.textNormal, C.textMuted
    gt:SetText(QH.Name(rec) or "?", t[1], t[2], t[3])
    local head = QH.KIND_TEXT[e.kind] or "Quest"
    if e.kind == "target" then
        head = ({ slay = "Gegner", loot = "Beute", object = "Gegenstand in der Welt" })[e.sub or "slay"] or head
    end
    local hc = e.kind == "avail" and C.gold or (e.kind == "turnin" and C.green) or C.infoBright
    gt:AddLine(head, hc[1], hc[2], hc[3])
    if (e.count or 1) > 1 then
        gt:AddLine("Gebiet · " .. e.count .. " Fundstellen in der Nähe", m[1], m[2], m[3])
    end
    gt:AddLine(" ")
    for i, id in ipairs(e.quests) do
        if i > 6 then
            gt:AddLine("… und " .. (#e.quests - 6) .. " weitere", m[1], m[2], m[3])
            break
        end
        local q = QH.Quest(id)
        local r, g, b = LevelColor(q and q[2])
        local right, rr, rg, rb = "", m[1], m[2], m[3]
        if e.kind == "turnin" then
            if logDone[id] then right, rr, rg, rb = "fertig", C.green[1], C.green[2], C.green[3]
            else right = "noch offen" end
        end
        local ev = QH.EventOf(id)
        if ev then right = (right ~= "" and (right .. " · ") or "") .. ev.name end
        if e.kind == "target" then
            local hue = QH.Hue(id)
            gt:AddDoubleLine("|cff" .. string.format("%02x%02x%02x", hue[1] * 255, hue[2] * 255, hue[3] * 255)
                .. "●|r " .. QuestLine(id), right, r, g, b, rr, rg, rb)
        else
            gt:AddDoubleLine(QuestLine(id), right, r, g, b, rr, rg, rb)
        end
        if e.kind ~= "avail" then
            for _, o in ipairs(QH.Objectives(id) or {}) do
                if o.done then
                    gt:AddLine("    " .. CHECK .. o.text, m[1], m[2], m[3])
                else
                    gt:AddLine("    " .. o.text, n[1], n[2], n[3])
                end
            end
        end
    end
    gt:AddLine(" ")
    if e.kind == "avail" then
        gt:AddLine("Klick: Questpfeil zu diesem Questgeber", m[1], m[2], m[3], true)
    else
        gt:AddLine("Klick: diese Quest verfolgen · Rechtsklick: lösen", m[1], m[2], m[3], true)
    end
    gt:AddLine("Unbestätigt – Wissensstand der Community.", m[1], m[2], m[3], true)
    gt:Show()
end

function QH.GuideTo(e)
    local QA = WeintCodex.UIQuestArrow
    if not (e and e.map and QA and QA.SetCustom) then return false end
    local d = Data()
    local rec = e.obj and d.o[e.who] or d.n[e.who]
    local quests = e.quests
    QA.SetCustom({ map = e.map, x = e.x, y = e.y,
        title = "Questgeber: " .. (QH.Name(rec) or "?"),
        done = function()
            for _, id in ipairs(quests) do if log[id] then return true end end
            return false
        end })
    return true
end

local function NewPin(holder)
    local p = CreateFrame("Frame", nil, holder)
    p:EnableMouse(true)
    -- Ein Bild je Symbol (6.30.6.0): "!" und "?" vom Spiel, Ziele aus
    -- media/questhelper (siehe QH.ICONS).
    -- 6.55.0.0: "!" und "?" auf weichem Schatten (lesbar auf heller
    -- Karte); Ziele als runde Marke - dunkler Grund, Ring in der Farbe der
    -- Quest, Zeichen hell. Unter der Maus waechst die Marke etwas.
    p.halo = p:CreateTexture(nil, "BACKGROUND")
    p.halo:SetPoint("CENTER")
    p.halo:SetTexture(MEDIA_UI .. "halo")
    p.ring = p:CreateTexture(nil, "BORDER")
    p.ring:SetAllPoints(p)
    p.ring:SetTexture(MEDIA_UI .. "disc")
    p.disc = p:CreateTexture(nil, "BORDER", nil, 1)
    p.disc:SetPoint("TOPLEFT", p, "TOPLEFT", 2, -2)
    p.disc:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -2, 2)
    p.disc:SetTexture(MEDIA_UI .. "disc")
    local pd = WeintCodex.GameColors.pinDisc
    p.disc:SetVertexColor(pd[1], pd[2], pd[3], pd[4])
    p.icon = p:CreateTexture(nil, "ARTWORK")
    p.icon:SetPoint("CENTER")
    p:SetScript("OnEnter", function(self)
        self.icon:SetSize(self._glyph * 1.2, self._glyph * 1.2)
        Tooltip(self)
    end)
    -- Links: diese Quest waehlen (mehrere: bei jedem Klick die naechste);
    -- rechts: Wahl loesen. Nur Quests aus dem Questlog.
    p:SetScript("OnMouseUp", function(self, button)
        local e = self.entry
        if not e then return end
        if e.kind == "book" then
            if button == "LeftButton" and WeintCodex.Library then WeintCodex.Library.Guide(e.book) end
            return
        end
        if button == "RightButton" then QH.SetFocus(nil) return end
        -- 6.61.4.0 (Wunsch: "mit einem Klick diesen Questgeber anwaehlen,
        -- damit mich der Pfeil hinleitet"): Pfeil zum Geber, bis eine
        -- seiner Quests im Questlog steht.
        if e.kind == "avail" then
            QH.GuideTo(e)
            Tooltip(self)
            return
        end
        local mine = {}
        for _, id in ipairs(e.quests) do if log[id] then mine[#mine + 1] = id end end
        if #mine == 0 then return end
        local pick = mine[1]
        for i, id in ipairs(mine) do
            if id == QH.focus then pick = mine[i % #mine + 1] break end
        end
        QH.SetFocus(pick)
        Tooltip(self)
    end)
    p:SetScript("OnLeave", function(self)
        self.icon:SetSize(self._glyph, self._glyph)
        if _G.GameTooltip then _G.GameTooltip:Hide() end
    end)
    p._glyph = QH.SIZE
    p:Hide()
    return p
end

-- 6.30.6.0 (Beta-Test mit Bild: "die Symbole sehen richtig scheisse aus -
-- nutz, was Blizzard zur Verfuegung stellt"). "!" und "?" sind die
-- Questsymbole des Spiels: zuerst als Atlas (nur, wenn der Client ihn
-- kennt - C_Texture.GetAtlasInfo), sonst die Bilder des Gespraechsfensters,
-- die es seit dem ersten Tag gibt. Grau = entsaettigt (zu leicht, nicht
-- fertig). Die Ziele zeigen, was zu tun ist - Schwert (toeten), Beutel
-- (Beute), Zahnrad (Objekt): Bilder aus pfQuest unter MIT
-- (media/questhelper/LICENSE-pfQuest.txt), weiss, hier eingefaerbt.
QH.ICONS = {
    avail  = { atlas = "QuestNormal",  file = "Interface\\GossipFrame\\AvailableQuestIcon" },
    turnin = { atlas = "QuestTurnin",  file = "Interface\\GossipFrame\\ActiveQuestIcon" },
    slay   = { file = "Interface\\AddOns\\WeintCodex\\media\\questhelper\\slay_mono" },
    loot   = { file = "Interface\\AddOns\\WeintCodex\\media\\questhelper\\loot_mono" },
    object = { file = "Interface\\AddOns\\WeintCodex\\media\\questhelper\\object_mono" },
    book   = { file = "Interface\\AddOns\\WeintCodex\\media\\ui\\icon_book" },
}

local function HasAtlas(name)
    local ct = _G.C_Texture
    if not (name and ct and ct.GetAtlasInfo) then return false end
    local ok, info = pcall(ct.GetAtlasInfo, name)
    return ok and type(info) == "table"
end

function QH.SetIcon(tex, which)
    local d = QH.ICONS[which]
    if d.atlas and tex.SetAtlas and HasAtlas(d.atlas) then
        tex:SetAtlas(d.atlas)
        return "atlas"
    end
    tex:SetTexture(d.file)
    tex:SetTexCoord(0, 1, 0, 1)
    return "file"
end

local function Has(list, v)
    for _, x in ipairs(list) do if x == v then return true end end
    return false
end

QH.GLYPH = 10         -- Zeichen in der Zielmarke
QH.DIM = 0.5          -- Ziele anderer Quests, wenn eine gewaehlt ist

local function Dress(p, e)
    local focus = QH.focus
    if p.entry == e and p._focus == focus then return end
    p.entry, p._focus = e, focus
    local book = e.kind == "book"
    local target = e.kind == "target" or book
    local size = target and QH.DOT or QH.SIZE
    if book then size = QH.DOT + 2 end
    p:SetSize(size, size)
    local which = book and "book" or (e.kind == "target" and (e.sub or "slay")) or e.kind
    QH.SetIcon(p.icon, which)
    if p.icon.SetDesaturated then p.icon:SetDesaturated(e.faint and true or false) end
    p.ring:SetShown(target)
    p.disc:SetShown(target)
    p.halo:SetShown(not target)
    local alpha = 1
    if target then
        p._glyph = QH.GLYPH
        local hue = book and C.gold or QH.Hue((focus and Has(e.quests, focus)) and focus or e.quests[1])
        p.ring:SetVertexColor(hue[1], hue[2], hue[3], 1)
        local t = C.textBright
        p.icon:SetVertexColor(t[1], t[2], t[3], 1)
        if not book and focus and not Has(e.quests, focus) then alpha = QH.DIM end
    else
        p._glyph = size
        p.halo:SetSize(size * 1.9, size * 1.9)
        p.halo:SetVertexColor(0, 0, 0, 0.55)
        local v = e.faint and 0.85 or 1
        p.icon:SetVertexColor(v, v, v, 1)
        if e.faint then alpha = 0.75 end
    end
    p.icon:SetSize(p._glyph, p._glyph)
    p:SetAlpha(alpha)
end

local holders = setmetatable({}, { __mode = "k" })
local function Holder(canvas)
    local h = holders[canvas]
    if not h then
        h = CreateFrame("Frame", nil, canvas)
        h:SetAllPoints(canvas)
        holders[canvas] = h
    end
    return h
end

local function HideAll(from)
    for i = from or 1, #pins do pins[i]:Hide() end
end

local shownMap, shownCount = nil, 0
function QH.Place()
    local qm = QM()
    local wm = _G.WorldMapFrame
    if not (QH.Active() and qm and type(wm) == "table" and wm.IsShown and wm:IsShown()) then
        HideAll()
        shownMap, shownCount = nil, 0
        return 0
    end
    local mapID = qm.CurrentMap and qm.CurrentMap()
    local canvas = qm.Canvas and qm.Canvas()
    if not (mapID and canvas) then HideAll() return 0 end
    -- Die Wahl kann sich ohne Ereignis aendern (Questpfeil, Questlog).
    if QH.Focus() ~= QH.builtFocus then QH.Forget() QH.PaintBar() end
    local list = QH.ForMap(mapID)
    local w, h = K.Plain(canvas:GetWidth()), K.Plain(canvas:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w <= 1 or h <= 1 then return 0 end
    local s = 1
    local cs = K.Plain(canvas.GetEffectiveScale and canvas:GetEffectiveScale())
    local ms = K.Plain(wm.GetEffectiveScale and wm:GetEffectiveScale())
    if type(cs) == "number" and type(ms) == "number" and cs > 0 and ms > 0 then s = cs / ms end
    local ME = WeintCodex.UIMapEntrances
    local lvl = ME and ME.BaseLevel and ME.BaseLevel(canvas) or 0
    local holder = Holder(canvas)
    for i, e in ipairs(list) do
        local p = pins[i]
        if not p then
            p = NewPin(holder)
            pins[i] = p
        end
        if p:GetParent() ~= holder then p:SetParent(holder) end
        Dress(p, e)
        p:SetScale(1 / s)
        p:SetFrameLevel(lvl + (e.kind == "target" and 1 or 3))
        p:ClearAllPoints()
        p:SetPoint("CENTER", canvas, "TOPLEFT", w * e.x * s, -h * e.y * s)
        p:Show()
    end
    HideAll(#list + 1)
    shownMap, shownCount = mapID, #list
    return #list
end

--------------------------------------------------
-- Filterleiste auf der Karte
--------------------------------------------------

local bar
function QH.BuildBar()
    if bar then return bar end
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return nil end
    -- 6.30.2.0 (Beta-Test mit Bild: "die Leiste verdeckt meinen
    -- Charakterpfeil"): nicht mehr auf der Karte, sondern unter dem
    -- Fenster - sie verdeckt nichts von der Karte. Am unteren Bildrand
    -- haelt das Spiel sie im Bild (ClampedToScreen).
    bar = CreateFrame("Frame", "WeintCodexQuestFilter", wm)
    bar:SetPoint("TOPLEFT", wm, "BOTTOMLEFT", 0, -4)
    if bar.SetClampedToScreen then bar:SetClampedToScreen(true) end
    bar:SetHeight(28)
    bar:SetFrameStrata("HIGH")
    bar.kachel = K.Kachel(bar, { shadow = 3 })
    bar.mark = bar:CreateTexture(nil, "ARTWORK")
    bar.mark:SetSize(16, 16)
    bar.mark:SetPoint("LEFT", bar, "LEFT", 8, 0)
    QH.SetIcon(bar.mark, "avail")
    bar.title = K.NewText(bar, 12)
    bar.title:SetFont(WeintCodex.Fonts.sansSemi, 12, "")
    bar.title:SetPoint("LEFT", bar.mark, "RIGHT", 4, 0)
    bar.title:SetText("Quests")
    local tc = C.textBright
    bar.title:SetTextColor(tc[1], tc[2], tc[3], 1)
    bar.chips = {}
    local x = 8 + 16 + 4 + 50
    for _, f in ipairs(QH.FILTERS) do
        local b = CreateFrame("Button", nil, bar)
        b.key = f.key
        b.text = K.NewText(b, 11)
        b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
        b.text:SetText(f.text)
        local tw = K.Plain(b.text.GetStringWidth and b.text:GetStringWidth())
        local bw = (type(tw) == "number" and tw > 0 and tw or 60) + 20
        b:SetSize(bw, 18)
        b:SetPoint("LEFT", bar, "LEFT", x, 0)
        x = x + bw + 4
        -- 6.55.0.0: Pille (zwei runde Kappen, Mittelstueck), an = Akzent.
        b.fill = b:CreateTexture(nil, "BACKGROUND")
        b.fill:SetPoint("TOPLEFT", b, "TOPLEFT", 9, 0)
        b.fill:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -9, 0)
        b.capL = b:CreateTexture(nil, "BACKGROUND")
        b.capL:SetSize(18, 18)
        b.capL:SetPoint("LEFT", b, "LEFT", 0, 0)
        b.capL:SetTexture(MEDIA_UI .. "disc")
        b.capR = b:CreateTexture(nil, "BACKGROUND")
        b.capR:SetSize(18, 18)
        b.capR:SetPoint("RIGHT", b, "RIGHT", 0, 0)
        b.capR:SetTexture(MEDIA_UI .. "disc")
        function b:Paint(r, g, bl, a)
            self.fill:SetColorTexture(r, g, bl, a)
            self.capL:SetVertexColor(r, g, bl, a)
            self.capR:SetVertexColor(r, g, bl, a)
        end
        b:SetScript("OnEnter", function(self) self._hot = true QH.PaintBar() end)
        b:SetScript("OnLeave", function(self) self._hot = nil QH.PaintBar() end)
        b:SetScript("OnClick", function(self)
            K.Set(KEY, self.key, not Get(self.key))
        end)
        bar.chips[#bar.chips + 1] = b
    end
    bar.focus = K.NewText(bar, 11)
    bar.focus:SetPoint("LEFT", bar, "LEFT", x + 6, 0)
    bar.focus:SetJustifyH("LEFT")
    bar.base = x + 4
    bar:SetWidth(x + 4)
    QH.bar = bar
    return bar
end

function QH.PaintBar()
    if not bar then return end
    local a, m, n = K.Highlight(), C.textMuted, C.textNormal
    local focus = QH.Focus()
    local q = focus and QH.Quest(focus)
    if Get("qhTargets") and not Get("qhAllTargets") then
        bar.focus:SetText(q and ("Ziele von: " .. q[1]) or "Klick auf ein „?“: Ziele dieser Quest")
    else
        bar.focus:SetText("")
    end
    local tw = K.Plain(bar.focus.GetStringWidth and bar.focus:GetStringWidth())
    bar:SetWidth(bar.base + ((type(tw) == "number" and tw > 0) and (tw + 14) or 0))
    local fc = q and C.textBright or m
    bar.focus:SetTextColor(fc[1], fc[2], fc[3], 1)
    for _, b in ipairs(bar.chips) do
        local on = Get(b.key) and true or false
        if b.key == "qhLow" then b:SetEnabled(Get("qhAvail") and true or false) end
        if b.key == "qhAllTargets" then b:SetEnabled(Get("qhTargets") and true or false) end
        local enabled = not (b.IsEnabled and not b:IsEnabled())
        -- 6.55.1.0 (Beta-Test mit Bild: "die Buttons muessen schoener"):
        -- halb durchsichtig ueberlappten Kappen und Mittelstueck - helle
        -- Ringe an den Enden. Jetzt deckend gemischt (Akzent auf dem Grund
        -- der Leiste), Kappen und Mitte sind eine Flaeche.
        local base = WeintCodex.GameColors.kachelFill
        if on then
            local k = b._hot and 0.55 or 0.40
            b:Paint(base[1] + (a[1] - base[1]) * k, base[2] + (a[2] - base[2]) * k,
                base[3] + (a[3] - base[3]) * k, 1)
        else
            local s1 = b._hot and (C.borderStrong or C.surface3) or C.surface3
            b:Paint(s1[1], s1[2], s1[3], 1)
        end
        local tc = on and C.textBright or n
        b.text:SetTextColor(tc[1], tc[2], tc[3], enabled and (on and 1 or 0.8) or 0.35)
    end
end

function QH.ShowBar()
    local want = QH.Active() and Get("qhBar")
    if want then QH.BuildBar() end
    if bar then
        bar:SetShown(want and true or false)
        QH.PaintBar()
    end
end

--------------------------------------------------
-- Taktgeber und Ereignisse
--------------------------------------------------

local driver
local function EnsureDriver()
    if driver then return driver end
    local wm = _G.WorldMapFrame
    if type(wm) ~= "table" then return nil end
    driver = CreateFrame("Frame", nil, wm)
    local acc = 0
    driver:SetScript("OnUpdate", K.Measured("Karte: Questhilfe", function(_, el)
        acc = acc + (el or 0)
        if acc < QH.TICK then return end
        acc = 0
        QH.Place()
    end))
    driver:SetScript("OnHide", function() HideAll() end)
    QH.driver = driver
    QH.ShowBar()
    return driver
end

--------------------------------------------------
-- Minikarte (6.30.7.0, Wunsch: "die Questhilfe auch auf der Minikarte")
--------------------------------------------------
-- Dieselbe Liste wie auf der Weltkarte, fuer die Karte, auf der du stehst
-- (K.BestMap). Jede Lage wird einmal in Weltkoordinaten umgerechnet
-- (K.ToWorld, im Eintrag gemerkt); im Takt nur der Abstand zum Spieler,
-- in Bildpunkte ueber den Halbmesser der Minikarte in Metern je Zoomstufe.
-- Dreht sich die Minikarte mit (rotateMinimap), dreht der Abstand mit.
-- Was ausserhalb liegt, ist nicht da. Seit 6.61.4.0 nehmen die Symbole
-- auch Klicks (Pfeil zum Geber) - der Ping geht daneben weiter.
QH.MM_RADIUS = {
    outside = { [0] = 233.33, 200, 166.67, 133.33, 100, 66.67 },
    inside  = { [0] = 150, 120, 90, 60, 40, 25 },
}
QH.MM_SCALE = 0.75
QH.MM_TICK = 0.05

local mmPins = {}
QH.mmPins = mmPins
local function MMHide(from) for i = from or 1, #mmPins do mmPins[i]:Hide() end end

function QH.MinimapActive() return QH.Active() and Get("qhMinimap") and true or false end

-- Halbmesser der Minikarte in Metern (Spieleinheiten), oder nil.
function QH.MinimapYards()
    local mm = _G.Minimap
    if type(mm) ~= "table" or not mm.GetZoom then return nil end
    local z = K.Plain(mm:GetZoom())
    if type(z) ~= "number" then return nil end
    local indoors = _G.IsIndoors and K.Plain(_G.IsIndoors())
    local t = indoors and QH.MM_RADIUS.inside or QH.MM_RADIUS.outside
    return t[z] or t[0]
end

-- Lage eines Eintrags auf der Minikarte in Bildpunkten vom Mittelpunkt,
-- oder nil (andere Welt, ausserhalb). `pc, pn, pw`: Spieler in der Welt.
function QH.MinimapOffset(e, mapID, pc, pn, pw, yards, half, facing, square)
    if e.wc == nil then
        local c, n, w = K.ToWorld(mapID, e.x, e.y)
        e.wc, e.wn, e.ww = c or false, n, w
    end
    if e.wc ~= pc then return nil end
    local east, north = pw - e.ww, e.wn - pn
    if facing then
        local cs, sn = math.cos(-facing), math.sin(-facing)
        east, north = east * cs - north * sn, east * sn + north * cs
    end
    local f = half / yards
    local dx, dy = east * f, north * f
    if square then
        if math.abs(dx) > half or math.abs(dy) > half then return nil end
    elseif dx * dx + dy * dy > half * half then
        return nil
    end
    return dx, dy
end

function QH.PlaceMinimap()
    local mm = _G.Minimap
    if not (QH.MinimapActive() and type(mm) == "table" and mm.IsShown and mm:IsShown()) then
        MMHide()
        return 0
    end
    local mapID = K.BestMap and K.BestMap()
    local yards = QH.MinimapYards()
    local pc, pn, pw = K.PlayerWorld()
    local w = K.Plain(mm:GetWidth())
    if not (mapID and yards and pc and type(w) == "number" and w > 1) then MMHide() return 0 end
    local facing
    if _G.GetCVar and K.Plain(_G.GetCVar("rotateMinimap")) == "1" and _G.GetPlayerFacing then
        facing = K.Plain(_G.GetPlayerFacing())
        if type(facing) ~= "number" then MMHide() return 0 end
    end
    local square = K.IsActive("minimap") and K.Get("minimap", "square") and true or false
    local half = w / 2
    local n = 0
    for _, e in ipairs(QH.ForMap(mapID)) do
        -- 6.30.19.0 (Beta-Test: "graues Fragezeichen beim Questgeber auf der
        -- Minimap irritiert - grau heisst dort sonst Abgabe im Gebaeude"):
        -- auf der Minikarte nur abgabebereite Quests, kein graues "?".
        local dx, dy
        if not (e.kind == "turnin" and e.faint) then
            dx, dy = QH.MinimapOffset(e, mapID, pc, pn, pw, yards, half, facing, square)
        end
        if dx then
            n = n + 1
            local p = mmPins[n]
            if not p then
                p = NewPin(mm)
                -- 6.61.4.0: anklickbar (Pfeil zum Geber, Quest waehlen).
                p:SetScale(QH.MM_SCALE)
                mmPins[n] = p
            end
            Dress(p, e)
            p:SetFrameLevel((K.Plain(mm:GetFrameLevel()) or 0) + (e.kind == "target" and 5 or 7))
            p:ClearAllPoints()
            p:SetPoint("CENTER", mm, "CENTER", dx / QH.MM_SCALE, dy / QH.MM_SCALE)
            p:Show()
        end
    end
    MMHide(n + 1)
    return n
end

local mmAcc = 0
local mmTicker = CreateFrame("Frame")
mmTicker:Hide()
mmTicker:SetScript("OnUpdate", K.Measured("Minikarte: Questhilfe", function(_, el)
    mmAcc = mmAcc + (el or 0)
    if mmAcc < QH.MM_TICK then return end
    mmAcc = 0
    QH.PlaceMinimap()
end))
QH.mmTicker = mmTicker

local function Refresh()
    QH.ReadLog()
    QH.Forget()
    for _, p in ipairs(pins) do p.entry = nil end
    for _, p in ipairs(mmPins) do p.entry = nil end
end
QH.Refresh = Refresh

local REFRESH = { "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED", "PLAYER_LEVEL_UP",
                  "SUPER_TRACKING_CHANGED" }
local pending = false
local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == "Blizzard_WorldMap" and QH.Active() then EnsureDriver() end
        return
    end
    -- Kalender: nur neu rechnen, wenn sich die laufenden Feste aendern.
    if event == "CALENDAR_UPDATE_EVENT_LIST" then
        if QH.ReadCalendar().changed then QH.Forget() end
        return
    end
    if event == "PLAYER_LOGIN" then
        -- Der Kalender liefert erst nach einer Anfrage (CALENDAR_UPDATE_EVENT_LIST).
        local cal = _G.C_Calendar
        if QH.Active() and cal and cal.OpenCalendar then pcall(cal.OpenCalendar) end
        if QH.Active() then Refresh() EnsureDriver() mmTicker:SetShown(QH.MinimapActive()) end
        return
    end
    -- QUEST_LOG_UPDATE kommt in Schauern - einmal je Bild genuegt.
    if pending then return end
    pending = true
    local t = _G.C_Timer
    local function run() pending = false Refresh() end
    if t and t.After then t.After(0.2, run) else run() end
end)
ev:RegisterEvent("PLAYER_LOGIN")
QH.events = ev

local function Apply()
    Refresh()
    if QH.Active() then
        pcall(ev.RegisterEvent, ev, "ADDON_LOADED")
        for _, e in ipairs(REFRESH) do pcall(ev.RegisterEvent, ev, e) end
        pcall(ev.RegisterEvent, ev, "CALENDAR_UPDATE_EVENT_LIST")
        EnsureDriver()
        QH.Place()
        mmTicker:SetShown(QH.MinimapActive())
        if not QH.MinimapActive() then MMHide() end
    else
        mmTicker:Hide()
        MMHide()
        pcall(ev.UnregisterEvent, ev, "ADDON_LOADED")
        for _, e in ipairs(REFRESH) do pcall(ev.UnregisterEvent, ev, e) end
        HideAll()
        shownMap, shownCount = nil, 0
    end
    QH.ShowBar()
end
QH.Apply = Apply

--------------------------------------------------
-- Bericht und Seite
--------------------------------------------------

function QH.StatusLines()
    local d = Data()
    local nq = 0
    for _ in pairs(d.q) do nq = nq + 1 end
    local st = QH.stats
    local out = { string.format("Questhilfe: %s · %d Quests im Bestand · zuletzt Karte %s: %d neu, %d Abgabe, %d Ziele",
        QH.Active() and "an" or "aus", nq, tostring(shownMap), st.avail, st.turnin, st.target) }
    local ql = _G.C_QuestLog
    out[#out + 1] = "Erledigt abfragen (IsQuestFlaggedCompleted): "
        .. ((ql and ql.IsQuestFlaggedCompleted or _G.IsQuestFlaggedCompleted) and "ja" or "fehlt – dann keine „!“")
        .. " · Minikarte: " .. (QH.MinimapActive() and "an" or "aus")
        .. " · Halbmesser " .. tostring(QH.MinimapYards())
    local E = QH.ReadCalendar()
    local act = {}
    for _, def in ipairs(WeintCodex.QuestEvents or {}) do if E.active[def.key] then act[#act + 1] = def.name end end
    out[#out + 1] = "Feste: " .. (E.known and ((#act > 0 and table.concat(act, ", ") or "keines läuft")
        .. " · Kalender heute: " .. (#E.titles > 0 and table.concat(E.titles, ", ") or "nichts")) or "Kalender gibt nichts heraus – Festquests aus")
    return out
end

local function Build(B)
    B:Section("Questhilfe", "Auf der Weltkarte: wo neue Quests warten, wo du abgibst und wo die Ziele deiner Quests sind. Unter dem Kartenfenster schaltest du, was du sehen willst.")
    B:Row({ type = "toggle", label = "Questhilfe auf der Karte", key = "qhOn",
            description = "Wissensstand der Community für Forever – unbestätigt. Auf der Karte einer Zone und auf der Minikarte." },
          { type = "toggle", label = "Filterleiste auf der Karte", key = "qhBar",
            disabled = function() return not K.Get(KEY, "qhOn") end })
    B:Row({ type = "toggle", label = "Auch auf der Minikarte", key = "qhMinimap",
            description = "Dieselben Symbole und Filter, solange sie auf der Minikarte liegen.",
            disabled = function() return not K.Get(KEY, "qhOn") end },
          { type = "empty" })
    B:Row({ type = "toggle", label = "Neue Quests", key = "qhAvail",
            description = "Ein „!“ am Geber jeder Quest, die du jetzt annehmen kannst.",
            disabled = function() return not K.Get(KEY, "qhOn") end },
          { type = "toggle", label = "Auch graue Quests", key = "qhLow",
            description = "Quests, die für dich zu leicht sind – blass.",
            disabled = function() return not (K.Get(KEY, "qhOn") and K.Get(KEY, "qhAvail")) end })
    B:Row({ type = "toggle", label = "Abgabe", key = "qhTurnin",
            description = "Ein „?“, wo du eine Quest aus dem Questlog abgibst – gold, wenn sie fertig ist.",
            disabled = function() return not K.Get(KEY, "qhOn") end },
          { type = "toggle", label = "Ziele", key = "qhTargets",
            description = "Blaue Punkte, wo Gegner, Objekte und Beute der gewählten Quest sind. Wählen: Klick auf ihr „?“ oder im Questlog.",
            disabled = function() return not K.Get(KEY, "qhOn") end })
    B:Row({ type = "toggle", label = "Ziele aller Quests", key = "qhAllTargets",
            description = "Statt nur der gewählten Quest die Ziele jeder offenen Quest im Questlog – wird schnell voll.",
            disabled = function() return not (K.Get(KEY, "qhOn") and K.Get(KEY, "qhTargets")) end },
          { type = "empty" })
end

local mod = K.Module(KEY)
if mod then
    for k, v in pairs(QH.DEFAULTS) do
        if mod.defaults[k] == nil then mod.defaults[k] = v end
    end
    mod.pages[#mod.pages + 1] = { key = "questhilfe", label = "Questhilfe", build = Build }
end

K.Listen(function(kind, key)
    if (kind == "active" or kind == "setting") and key == KEY then Apply() end
end)
