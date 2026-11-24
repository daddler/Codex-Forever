--------------------------------------------------
-- WeintCodex :: Komfort - Questgegenstaende in den Taschen pruefen (1.0.8.23)
--------------------------------------------------
-- Wunsch: "Dieses Addon soll richtig gut sein. Das muss auch in Codex
-- vorhanden sein" (Quest Item Cleaner Forever, "All Rights Reserved" -
-- nachgebaut wird das VERHALTEN, kein Code, kein Text, kein Bild).
--
-- Was es tut: fuer jeden Questgegenstand in den Taschen sagen, ob er noch
-- gebraucht wird - im Tooltip und auf der Codex-Seite "Taschen" (Eintrag
-- "Questgegenstaende"). Geloescht wird NIE etwas; der Spieler entscheidet.
--
-- Vorsichtig, in dieser Reihenfolge:
--   1. eigene Regel "behalten"                       -> behalten
--   2. eine Quest im Log braucht ihn (Bestand, Ziel
--      des Spiels per Name, Questinfo der Tasche)    -> behalten
--   3. eine wiederholbare Quest nutzt ihn            -> behalten
--   4. eine Quest fuer diesen Charakter ist offen    -> behalten
--   5. sagt der Client bei einer Quest nichts        -> unklar
--   6. alle bekannten Quests erledigt oder nicht fuer
--      diesen Charakter, und es IST ein Questgegen-
--      stand (Klasse 12)                             -> kann weg
--   7. Questgegenstand ohne bekannte Quest           -> unklar
-- Gewoehnliche Ware (kein Questgegenstand) steht nur da, solange eine Quest
-- im Log sie braucht.
-- Unklar ist nie "kann weg".
--
-- Daten: data/questdb.lua (`qi` Gegenstand -> Quests, `rq` wiederholbar),
-- erzeugt von .github/scripts/import_questdb.py, `community`. Ob eine Quest
-- erledigt ist, sagt nur der Client.
--------------------------------------------------

local K = WeintCodex.UIKit
local KEY = "comfort"

WeintCodex.UIQuestItems = {}
local QI = WeintCodex.UIQuestItems

QI.DEFAULTS = { questItemTip = true }
QI.QUEST_CLASS = 12
QI.MAX_QUESTS = 4           -- so viele Quests nennt der Tooltip, Rest "+ n"
QI.LABEL = {
    keep    = "Behalten",
    done    = "Kann weg",
    notmine = "Kann weg",
    unknown = "Unklar",
}
QI.COLOR = { keep = "success", done = "gold", notmine = "gold", unknown = "textMuted" }

local function Plain(v) return K.Plain and K.Plain(v) or v end

function QI.Active() return K.IsActive(KEY) and K.Get(KEY, "questItemTip") ~= false end

--------------------------------------------------
-- Bestand
--------------------------------------------------

local function DB() return WeintCodex.QuestDBData end

local function List(s)
    local out = {}
    for n in tostring(s or ""):gmatch("%d+") do out[#out + 1] = tonumber(n) end
    return out
end

-- Quests zu einem Gegenstand (Liste von Nummern, leer wenn unbekannt).
function QI.QuestsOf(itemID)
    local d = DB()
    return List(d and d.qi and d.qi[itemID])
end

local repeatable
function QI.Repeatable(q)
    if not repeatable then
        repeatable = {}
        local d = DB()
        for _, id in ipairs(List(d and d.rq)) do repeatable[id] = true end
    end
    return repeatable[q] == true
end

local function QH() return WeintCodex.UIQuestHelper end

function QI.QuestName(q)
    local qh = QH()
    local rec = qh and qh.Quest and qh.Quest(q)
    return (qh and qh.Name and qh.Name(rec)) or ("Quest " .. q)
end

-- true / false / nil (Client antwortet nicht).
function QI.Done(q)
    local qh = QH()
    if qh and qh.Done then return qh.Done(q) end
    return nil
end

local function Bit(mask, n)
    if not mask or mask == 0 then return true end
    local b = 2 ^ (n - 1)
    return math.floor(mask / b) % 2 == 1
end

-- Fuer diesen Charakter moeglich? true / false / nil (unbekannt).
function QI.ForMe(q, me)
    local qh = QH()
    local rec = qh and qh.Quest and qh.Quest(q)
    if type(rec) ~= "table" then return nil end
    if qh.RaceOK and not qh.RaceOK(rec[4], me) then return false end
    if rec[5] and rec[5] ~= 0 then
        if not me.class then return nil end
        if not Bit(rec[5], me.class) then return false end
    end
    return true
end

--------------------------------------------------
-- Questlog (auch abgabebereite Quests zaehlen als aktiv)
--------------------------------------------------

function QI.LogSet()
    local set = {}
    local ql = _G.C_QuestLog
    if not (ql and ql.GetNumQuestLogEntries and ql.GetInfo) then return set, false end
    local n = Plain(ql.GetNumQuestLogEntries())
    if type(n) ~= "number" then return set, false end
    for i = 1, n do
        local ok, info = pcall(ql.GetInfo, i)
        if ok and type(info) == "table" and not info.isHeader then
            local id = Plain(info.questID)
            if type(id) == "number" then set[id] = Plain(info.title) or true end
        end
    end
    return set, true
end

--------------------------------------------------
-- Eigene Regeln je Charakter: behalten
--------------------------------------------------

function QI.Rules(create)
    local sd = WeintCodex.SavedData
    local key = K.CharKey and K.CharKey()
    if type(sd) ~= "table" or not key then return nil end
    if not sd.questItemKeep then
        if not create then return nil end
        sd.questItemKeep = {}
    end
    local t = sd.questItemKeep[key]
    if not t and create then t = {} sd.questItemKeep[key] = t end
    return t
end

function QI.IsKept(itemID)
    local t = QI.Rules(false)
    return t ~= nil and t[itemID] == true
end

function QI.SetKept(itemID, on)
    local t = QI.Rules(true)
    if not t then return false end
    t[itemID] = on and true or nil
    return true
end

function QI.ClearRules()
    local t = QI.Rules(false)
    if t then for k in pairs(t) do t[k] = nil end end
end

--------------------------------------------------
-- Bewertung
--------------------------------------------------

local function ClassOf(itemID)
    local ci = _G.C_Item
    local f = (ci and ci.GetItemInfoInstant) or _G.GetItemInfoInstant
    if type(f) ~= "function" then return nil end
    local ok, _, _, _, _, _, classID = pcall(f, itemID)
    classID = ok and Plain(classID) or nil
    return type(classID) == "number" and classID or nil
end
QI.ClassOf = ClassOf

-- Ergebnis: { state = keep|done|notmine|unknown, why = Text,
--             quests = { { id, name, st } } } oder nil (kein Questgegenstand).
-- opts: log (Menge aus QI.LogSet), me (QH.Me()), info (Questinfo der Tasche:
-- { isQuestItem, questID, isActive }), name (Name des Gegenstands).
function QI.Judge(itemID, opts)
    if type(itemID) ~= "number" then return nil end
    opts = opts or {}
    local qs = QI.QuestsOf(itemID)
    local classID = opts.classID or ClassOf(itemID)
    local info = opts.info
    local isQuestItem = classID == QI.QUEST_CLASS or (info and info.isQuestItem == true)
    if #qs == 0 and not isQuestItem then return nil end

    local log = opts.log or QI.LogSet()
    local me = opts.me or (QH() and QH().Me and QH().Me()) or {}
    local r = { state = "unknown", quests = {} }

    if QI.IsKept(itemID) then
        r.state, r.why, r.manual = "keep", "Deine Regel: behalten.", true
    end

    -- Was das Spiel selbst sagt: Questinfo der Tasche, Ziele im Log per Name.
    local active
    if info and type(info.questID) == "number" and log[info.questID] then active = info.questID end
    local QS = WeintCodex.UIQuestSell
    local byName = (not active and opts.name and QS and QS.QuestsFor) and QS.QuestsFor(itemID, opts.name) or {}

    local open, rep, unknown, done, notmine = false, false, false, 0, 0
    for _, q in ipairs(qs) do
        local st
        if log[q] then
            st, active = "aktiv", active or q
        else
            local mine = QI.ForMe(q, me)
            local d = QI.Done(q)
            if mine == false then st, notmine = "nicht für dich", notmine + 1
            elseif QI.Repeatable(q) then st, rep = "wiederholbar", true
            elseif d == true then st, done = "erledigt", done + 1
            elseif d == false and mine == true then st, open = "offen", true
            else st, unknown = "unbekannt", true end
        end
        r.quests[#r.quests + 1] = { id = q, name = QI.QuestName(q), st = st }
    end

    if r.state == "keep" then return r end
    -- Gewoehnliche Ware (Leinenstoff, Fleisch ...): nur nennen, solange eine
    -- Quest im Log sie braucht - sonst stuende "unklar" an jedem Stoff.
    if not isQuestItem and not (active or #byName > 0) then return nil end
    if active or #byName > 0 then
        r.state = "keep"
        r.why = "Eine Quest in deinem Log braucht ihn."
        if #byName > 0 and not active then r.quests[#r.quests + 1] = { name = byName[1], st = "aktiv" } end
    elseif rep then
        r.state, r.why = "keep", "Eine wiederholbare Quest nutzt ihn."
    elseif open then
        r.state, r.why = "keep", "Eine Quest, die du noch machen kannst, nutzt ihn."
    elseif unknown then
        r.state, r.why = "unknown", "Das Spiel sagt nicht, ob jede Quest erledigt ist."
    elseif #qs == 0 then
        r.state, r.why = "unknown", "Keine Quest bekannt, die ihn nutzt."
    elseif notmine == #qs then
        r.state, r.why = "notmine", "Keine seiner Quests ist für diesen Charakter."
    else
        r.state, r.why = "done", "Alle seine Quests sind erledigt."
    end
    return r
end

--------------------------------------------------
-- Taschen des Charakters
--------------------------------------------------

-- { { id, count, name, info, judge } } fuer alle Questgegenstaende.
function QI.Scan()
    local out, byId = {}, {}
    local cc = _G.C_Container
    if not (cc and cc.GetContainerNumSlots and cc.GetContainerItemInfo) then return out, false end
    local log = QI.LogSet()
    local qh = QH()
    local me = (qh and qh.Me and qh.Me()) or {}
    for bag = 0, 4 do
        local ok, n = pcall(cc.GetContainerNumSlots, bag)
        n = ok and Plain(n) or 0
        for slot = 1, (type(n) == "number" and n or 0) do
            local ok2, it = pcall(cc.GetContainerItemInfo, bag, slot)
            local id = ok2 and type(it) == "table" and Plain(it.itemID) or nil
            if type(id) == "number" then
                local e = byId[id]
                if e then
                    e.count = e.count + (Plain(it.stackCount) or 1)
                else
                    local info
                    if cc.GetContainerItemQuestInfo then
                        local ok3, qi = pcall(cc.GetContainerItemQuestInfo, bag, slot)
                        if ok3 and type(qi) == "table" then
                            info = { isQuestItem = Plain(qi.isQuestItem) == true, questID = Plain(qi.questID),
                                     isActive = Plain(qi.isActive) == true }
                        end
                    end
                    local link = Plain(it.hyperlink)
                    local name = type(link) == "string" and link:match("%[(.-)%]") or nil
                    local j = QI.Judge(id, { log = log, me = me, info = info, name = name })
                    if j then
                        e = { id = id, count = Plain(it.stackCount) or 1, name = name, judge = j }
                        byId[id] = e
                        out[#out + 1] = e
                    end
                end
            end
        end
    end
    local rank = { done = 1, notmine = 2, unknown = 3, keep = 4 }
    table.sort(out, function(a, b)
        local ra, rb = rank[a.judge.state] or 9, rank[b.judge.state] or 9
        if ra ~= rb then return ra < rb end
        return (a.name or "~") < (b.name or "~")
    end)
    return out, true
end

-- Zaehlt die Zustaende: { keep = n, done = n, unknown = n }.
function QI.Counts(list)
    local c = { keep = 0, done = 0, unknown = 0 }
    for _, e in ipairs(list or {}) do
        local s = e.judge.state == "notmine" and "done" or e.judge.state
        c[s] = (c[s] or 0) + 1
    end
    return c
end

--------------------------------------------------
-- Tooltip
--------------------------------------------------

function QI.TooltipLines(itemID)
    local j = QI.Judge(itemID)
    if not j then return nil end
    local lines = { { "Questgegenstand: " .. QI.LABEL[j.state], QI.COLOR[j.state] } }
    lines[#lines + 1] = { j.why, "textMuted" }
    for i, q in ipairs(j.quests) do
        if i > QI.MAX_QUESTS then
            lines[#lines + 1] = { "+ " .. (#j.quests - QI.MAX_QUESTS) .. " weitere", "textFaint" }
            break
        end
        lines[#lines + 1] = { "  " .. q.name .. " – " .. q.st, "textMuted" }
    end
    return lines
end

local function OnItem(tt, data)
    if not QI.Active() then return end
    if tt ~= _G.GameTooltip and tt ~= _G.ItemRefTooltip then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local AP = WeintCodex.UIAuctionPrices
    local id
    if AP and AP.ItemIdOf then id = AP.ItemIdOf(tt, data)
    else id = type(data) == "table" and Plain(data.id) end
    if type(id) ~= "number" then return end
    local lines = QI.TooltipLines(id)
    if not lines then return end
    local C = WeintCodex.Colors
    for i, l in ipairs(lines) do
        local c = C[l[2]] or C.textMuted
        tt:AddLine(l[1], c[1], c[2], c[3], i > 1)
    end
end
QI.OnItem = OnItem

function QI.Hook()
    if QI._hooked then return end
    QI._hooked = true
    local tdp, e = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
    if tdp and tdp.AddTooltipPostCall and e and e.Item then
        pcall(tdp.AddTooltipPostCall, e.Item, OnItem)
    elseif _G.GameTooltip and _G.GameTooltip.HookScript then
        _G.GameTooltip:HookScript("OnTooltipSetItem", function(self) OnItem(self) end)
    end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "BAG_UPDATE_DELAYED", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", WeintCodex.Measured("Questgegenstände prüfen", function(_, event)
    if event == "PLAYER_LOGIN" then QI.Hook() return end
    -- Die Taschenseite neu zeichnen, wenn sie die Questgegenstaende zeigt.
    local BG = WeintCodex.Bags
    if BG and BG.sel == BG.QUESTS and BG.Redraw then BG.Redraw() end
end))
QI.events = ev

local mod = K.Module(KEY)
if mod and mod.defaults.questItemTip == nil then mod.defaults.questItemTip = true end
