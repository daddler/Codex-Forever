--------------------------------------------------
-- WeintCodex :: Komfort - Einstimmungen mit Tracker
--------------------------------------------------
-- 1.0.7.0 (Wunsch nach dem Vergleich mit Naowh Forever, Verhalten
-- nachgebaut, eigener Code). Je Zugang (data/attunements.lua) die Kette
-- bis zur Quest, die ihn gibt - rueckwaerts aus der Questdatenbank ("alle
-- vorher", sonst die erste passende "eine vorher"). Stand je Schritt vom
-- Client: erledigt (IsQuestFlaggedCompleted), im Questlog, offen.
--
-- TRACKER: ein kleiner Kasten mit je Zugang dem naechsten Schritt (nur
-- Zugaenge, deren Kette fuer deine Stufe beginnt und die nicht fertig
-- sind). Klick auf eine Zeile: Questpfeil zum Geber des Schritts.
-- Schalter `attuneTracker` (Abklingzeitmanager, Erweitert); verschieben
-- im Gestaltungsmodus; /wcui einstimmung listet alles im Chat.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIAttunements = {}

local AT = WeintCodex.UIAttunements
local K = WeintCodex.UIKit

AT.MAX_STEPS = 25
AT.LEVEL_AHEAD = 3   -- Kette zeigen, wenn ihr erster Schritt bis so viele Stufen ueber dir liegt

local function QH() return WeintCodex.UIQuestHelper end
local function Data() return WeintCodex.QuestDBData end
local function Faction()
    local f = _G.UnitFactionGroup and K.Plain(_G.UnitFactionGroup("player"))
    return f == "Horde" and "H" or (f == "Alliance" and "A" or nil)
end

function AT.FinalQuest(a, side)
    if type(a.quest) == "table" then return a.quest[side or Faction() or "A"] end
    return a.quest
end

-- Quest-Datensatz (geparst) oder nil.
local function Rec(id)
    local q = QH()
    local raw = Data() and Data().q[id]
    if not (q and raw) then return nil end
    return q.Parse(raw)
end

-- Kette in Reihenfolge (erste Quest zuerst) bis zur Schlussquest.
function AT.Chain(final)
    local out, seen = {}, {}
    local function walk(id, depth)
        if seen[id] or depth > AT.MAX_STEPS then return end
        seen[id] = true
        local r = Rec(id)
        if r then
            for _, pre in ipairs(r[13] or {}) do walk(pre, depth + 1) end
            local one = r[14] or {}
            if #one > 0 and #(r[13] or {}) == 0 then walk(one[1], depth + 1) end
        end
        out[#out + 1] = { id = id, name = r and r[1] or ("Quest " .. id), level = r and r[3] or 0,
            giver = r and r[6] and r[6][1] or nil }
    end
    walk(final, 0)
    return out
end

local function InLog(id)
    local ql = _G.C_QuestLog
    if not (ql and ql.GetLogIndexForQuestID) then return false end
    local ok, i = pcall(ql.GetLogIndexForQuestID, id)
    i = ok and K.Plain(i)
    return type(i) == "number" and i > 0
end

-- Stand: { done = n, total = n, next = Schritt|nil, state = "done"|"log"|"open"|"unknown" }
function AT.State(chain, done)
    done = done or function(id) local q = QH() return q and q.Done(id) end
    local st = { done = 0, total = #chain }
    for _, s in ipairs(chain) do
        local d = done(s.id)
        if d == true then st.done = st.done + 1
        elseif not st.next then
            st.next = s
            st.state = d == nil and "unknown" or (InLog(s.id) and "log" or "open")
        end
    end
    if not st.next then st.state = "done" end
    return st
end

-- Erster Ort des Gebers: map, x, y (0..1) oder nil.
function AT.GiverPlace(npc)
    local d = Data()
    local rec = npc and d and d.n[npc]
    if type(rec) ~= "string" then return nil end
    local map, x, y = rec:match("\t(%d+):([%d%.]+),([%d%.]+)")
    if not map then return nil end
    return tonumber(map), tonumber(x), tonumber(y), rec:match("^([^\t]*)")
end

function AT.Guide(step)
    local QA = WeintCodex.UIQuestArrow
    local map, x, y, who = AT.GiverPlace(step and step.giver)
    if not (map and QA and QA.SetCustom) then return false end
    QA.SetCustom({ map = map, x = x, y = y, title = (who or "Questgeber") .. ": " .. step.name })
    return true
end

-- Was der Tracker zeigt: { {att, state}, ... }
function AT.Active(level)
    level = level or (_G.UnitLevel and K.Plain(_G.UnitLevel("player"))) or 0
    local out = {}
    for _, a in ipairs(WeintCodex.AttunementData.list) do
        local final = AT.FinalQuest(a)
        if final then
            local chain = AT.Chain(final)
            local st = AT.State(chain)
            local first = chain[1]
            if st.state ~= "done" and first and (first.level or 0) <= level + AT.LEVEL_AHEAD then
                out[#out + 1] = { att = a, st = st, chain = chain }
            end
        end
    end
    return out
end

--------------------------------------------------
-- Tracker
--------------------------------------------------

local box
local lines = {}
AT.W, AT.LINE = 260, 18

local function On()
    local OC = WeintCodex.UIOwnCooldowns
    return OC and OC.Get and OC.Get("attuneTracker") and true or false
end

local function Line(i)
    local b = CreateFrame("Button", nil, box)
    b:SetSize(AT.W - 12, AT.LINE)
    b:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -22 - (i - 1) * AT.LINE)
    b.text = K.NewText(b, 11)
    b.text:SetPoint("LEFT", b, "LEFT", 0, 0)
    b.text:SetPoint("RIGHT", b, "RIGHT", 0, 0)
    b.text:SetJustifyH("LEFT")
    b.text:SetWordWrap(false)
    b:SetScript("OnClick", function(self) if self.step then AT.Guide(self.step) end end)
    lines[i] = b
    return b
end

function AT.Update()
    if not box then return end
    local show = On() or box._unlock
    local list = show and AT.Active() or {}
    if not box._unlock and #list == 0 then box:Hide() return end
    for i, e in ipairs(list) do
        local b = lines[i] or Line(i)
        local s = e.st.next
        b.step = s
        local mark = e.st.state == "log" and " (im Log)" or ""
        b.text:SetText(e.att.name .. " " .. (e.st.done + 1) .. "/" .. e.st.total .. ": " .. (s and s.name or "") .. mark)
        b:Show()
    end
    for i = #list + 1, #lines do lines[i]:Hide() end
    box:SetHeight(28 + math.max(1, #list) * AT.LINE)
    box:Show()
end

function AT.Print()
    local say = function(t) print(WeintCodex.ColorText("accent", "[WeintCodex]") .. " " .. t) end
    for _, a in ipairs(WeintCodex.AttunementData.list) do
        local final = AT.FinalQuest(a)
        local chain = final and AT.Chain(final) or {}
        local st = AT.State(chain)
        say(a.name .. ": " .. (st.state == "done" and "fertig" or ((st.done) .. "/" .. st.total .. " – als Nächstes " .. (st.next and st.next.name or "?"))))
    end
end

function AT.Enable()
    if box then return end
    box = CreateFrame("Frame", "WeintCodexAttunements", UIParent)
    box:SetSize(AT.W, 46)
    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(box)
    local c = WeintCodex.Colors.bgPanel
    bg:SetColorTexture(c[1], c[2], c[3], 0.8)
    K.Border(box, 1, 0, 0, 0, 1, "BORDER")
    local title = K.NewText(box, 11)
    title:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -5)
    title:SetText("Einstimmungen")
    box:Hide()
    box.WCShowForUnlock = function(self, on) self._unlock = on and true or nil AT.Update() end
    K.RegisterMover(box, "attunements", "Einstimmungen", K.Layout("attunements"))
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "QUEST_TURNED_IN", "QUEST_ACCEPTED", "QUEST_REMOVED", "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    ev:SetScript("OnEvent", K.Measured("Einstimmungen", function()
        if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(1, AT.Update) else AT.Update() end
    end))
end

do
    local m = K.Module("reminders")
    if m then
        local enable = m.Enable
        m.Enable = function(...)
            if enable then enable(...) end
            local ok, err = pcall(AT.Enable)
            if not ok then K.Report("einstimmungen", err) end
        end
    end
end
