--------------------------------------------------
-- WeintCodex :: Endgame (Seite im Codex, 1.0.10.0)
--------------------------------------------------
-- Wunsch: "eine Rubrik Level 60 oder Endgame auf der linken Seite". Vorher
-- geprueft: keines der verglichenen Addons hat einen Leitfaden fuer Stufe
-- 60 - darum KEIN Text "mach erst X, dann Y" (dafuer gibt es fuer Forever
-- keine Quelle). Die Seite fuehrt zusammen, was belegt ist, und der Stand
-- kommt vom Client:
--   Einstimmungen  - Ketten aus data/attunements.lua und der Questdaten-
--                    bank (ui/attunements.lua: AT.Chain, AT.State), Stand
--                    je Schritt vom Client, Questpfeil zum Geber.
--   Tier 0         - Dungeon-Set 1 deiner Klasse (Gegenstaende aus
--                    data/loot.lua, Set je Klasse wie in Classic), was du
--                    hast (Client: Taschen, Bank, angelegt), wo der Rest
--                    faellt. Dungeon-Set 2 (Tier 0.5): laut gesammelten
--                    Daten noch nicht in Forever (data/loot_ofa.lua).
--   Dungeons       - ab Stufe 55 (data/dungeons.lua), mit dem Stand ihrer
--                    Quests (DungeonPages.QuestState).
--   Ruf            - Fraktionen mit Belohnungen beim Ruestmeister
--                    (modules/reppage.lua), Rufstufe vom Client.
-- Unbekannt bleibt unbekannt: antwortet der Client nicht, steht "?".
--------------------------------------------------

WeintCodex.Endgame = {}
local EG = WeintCodex.Endgame
local C = WeintCodex.Colors

EG.HEAD = 84
EG.ROW_H = 44
EG.MIN_DUNGEON = 55       -- Dungeons, deren Bereich bis mindestens hierhin reicht
EG.cat = "next"
EG.sel = nil              -- Schluessel der gewaehlten Zeile

-- Dungeon-Set 1 (Tier 0) und 2 (Tier 0.5) je Klasse - Setnummern wie in
-- Classic (Art `classic`), die Gegenstaende stehen in data/loot.lua.
EG.T0 = { WARRIOR = 189, PALADIN = 188, HUNTER = 186, ROGUE = 184, PRIEST = 182,
          SHAMAN = 187, MAGE = 181, WARLOCK = 183, DRUID = 185 }
EG.T05 = { WARRIOR = 511, PALADIN = 516, HUNTER = 515, ROGUE = 512, PRIEST = 514,
           SHAMAN = 519, MAGE = 517, WARLOCK = 518, DRUID = 513 }

EG.CATS = {
    { key = "next", label = "Als Nächstes" },
    { key = "att",  label = "Einstimmungen" },
    { key = "t05",  label = "Tier 0.5 (Questreihe)" },
    { key = "tier", label = "Tier 0" },
    { key = "dung", label = "Dungeons ab Stufe 55" },
    { key = "rep",  label = "Ruf" },
}

local page
local rows = {}
EG.rows = rows

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end
local function Col(name) return C[name] or C.textNormal end
local function Ask(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, ...)
    if not ok then return nil end
    return Plain(v)
end

function EG.Level()
    local l = Ask(_G.UnitLevel, "player")
    return type(l) == "number" and l > 0 and l or nil
end
function EG.Class()
    if not _G.UnitClass then return nil end
    local ok, _, token = pcall(_G.UnitClass, "player")
    token = ok and Plain(token) or nil
    return type(token) == "string" and token or nil
end
local function Faction()
    local f = Ask(_G.UnitFactionGroup, "player")
    return (f == "Alliance" or f == "Horde") and f or nil
end

--------------------------------------------------
-- Einstimmungen
--------------------------------------------------

-- { { att, chain, st } } in der Reihenfolge des Bestands.
function EG.Attunements()
    local AT, d = WeintCodex.UIAttunements, WeintCodex.AttunementData
    local out = {}
    if not (AT and d) then return out end
    for _, a in ipairs(d.list) do
        local final = AT.FinalQuest(a)
        local chain = final and AT.Chain(final) or {}
        out[#out + 1] = { att = a, chain = chain, st = AT.State(chain) }
    end
    return out
end

local STATE_TEXT = { done = "fertig", log = "im Questlog", open = "offen", unknown = "Stand unbekannt" }
local QUEST_TEXT = { done = "erledigt", ready = "abgabebereit", active = "im Questlog", open = "offen", later = "später" }
function EG.AttLine(e)
    local st = e.st
    if st.state == "done" then return "Fertig – " .. st.total .. " von " .. st.total .. " Schritten" end
    local n = st.next
    return st.done .. " von " .. st.total .. " · als Nächstes: " .. (n and n.name or "?")
        .. (n and n.level and n.level > 0 and (" (Stufe " .. n.level .. ")") or "")
        .. (st.state == "log" and " – im Questlog" or "")
end

--------------------------------------------------
-- Tier 0.5: die Questreihe zu Dungeon-Set 2 (data/tier05.lua, ab 1.0.10.0)
--------------------------------------------------
-- Ein Schritt ist erledigt, wenn der Client eine seiner Quests als
-- abgeschlossen meldet (bei "einer von" reicht eine, bei Klassenquests die
-- von Forever oder die aus Classic). Namen: Client, sonst Questdatenbank.

local function QuestRec(id)
    local QH = WeintCodex.UIQuestHelper
    return QH and QH.Quest and QH.Quest(id) or nil
end
function EG.QuestTitle(id)
    local ql = _G.C_QuestLog
    local t = ql and Ask(ql.GetTitleForQuestID, id)
    if type(t) == "string" and t ~= "" then return t end
    local r = QuestRec(id)
    return r and r[1] or ("Quest " .. id)
end
local function Side()
    local f = Faction()
    return f == "Horde" and "H" or (f == "Alliance" and "A") or nil
end

-- { { ids = {..}, any = bool, name, level, giver } } fuer Klasse und Seite.
function EG.Tier05Steps(class, side)
    local d = WeintCodex.Tier05Data
    class, side = class or EG.Class(), side or Side()
    if not (d and class and side) then return nil end
    local mine = d.class[side] and d.class[side][class]
    local out = {}
    for _, s in ipairs(d.steps) do
        local ids, any
        if type(s) == "number" then ids = { s }
        elseif type(s) == "string" then ids = mine and mine[s] or nil any = true
        elseif s.any then ids, any = s.any, true
        elseif s[side] then ids = { s[side] } end
        if ids and #ids > 0 then
            local r = QuestRec(ids[1])
            out[#out + 1] = { ids = ids, any = any and #ids > 1 and type(s) == "table" and s.any ~= nil,
                name = EG.QuestTitle(ids[1]), level = r and r[3] or nil,
                giver = r and r[6] and r[6][1] or nil }
        end
    end
    return out
end

-- Stand eines Schritts: true/false/nil (Client antwortet nicht).
function EG.StepDone(step)
    local QH = WeintCodex.UIQuestHelper
    if not (QH and QH.Done) then return nil end
    local any = false
    for _, id in ipairs(step.ids) do
        local v = QH.Done(id)
        if v == true then return true end
        if v == false then any = true end
    end
    if any then return false end
    return nil
end

-- { steps, done, total, next, index, known }
function EG.Tier05()
    local steps = EG.Tier05Steps()
    if not steps then return nil end
    local st = { steps = steps, done = 0, total = #steps, known = true }
    for i, s in ipairs(steps) do
        local d = EG.StepDone(s)
        s.state = d
        if d == true then st.done = st.done + 1
        else
            if d == nil then st.known = false end
            if not st.next then st.next, st.index = s, i end
        end
    end
    return st
end

function EG.GuideStep(step)
    local AT = WeintCodex.UIAttunements
    if not (AT and step) then return false end
    return AT.Guide({ giver = step.giver, name = step.name })
end

--------------------------------------------------
-- Tier 0
--------------------------------------------------

local function LootBook() return WeintCodex.LootBook end

-- Teile eines Sets: { id, ... } aus der Beute, oder nil.
function EG.SetItems(setId)
    local LB = LootBook()
    if not (LB and setId) then return nil end
    local n = LB.FindInstance("DungeonSets")
    if not n then return nil end
    for _, b in ipairs(LB.Bosses(n)) do
        if b.set == setId then
            local ids = {}
            for _, it in ipairs(b.items) do ids[#ids + 1] = it.id end
            return ids, b.name
        end
    end
    return nil
end

-- Hast du den Gegenstand (Taschen, Bank, angelegt)? true/false/nil.
function EG.Owned(id)
    local ci = _G.C_Item
    local f = (ci and ci.GetItemCount) or _G.GetItemCount
    if type(f) ~= "function" then return nil end
    local ok, n = pcall(f, id, true)
    n = ok and Plain(n) or nil
    if type(n) ~= "number" then return nil end
    return n > 0
end

-- Wo faellt er? "Dungeon · Boss" aus der Beute, sonst nil.
function EG.DropText(id)
    local LB = LootBook()
    if not (LB and LB.SourceOf) then return nil end
    local n, bi = LB.SourceOf(id)
    local inst = n and LB.Instance(n)
    if not inst or inst.cat == "s" then return nil end
    local b = LB.Bosses(n)[bi]
    return LB.InstanceName(inst) .. " · " .. LB.BossName(b), inst
end

-- { set, name, items = { { id, owned, drop } }, have, known, status }
function EG.Tier(class)
    class = class or EG.Class()
    local setId = class and EG.T0[class]
    local ids, setName = EG.SetItems(setId)
    if not ids then return nil end
    local out = { set = setId, name = setName, items = {}, have = 0, known = true }
    for _, id in ipairs(ids) do
        local o = EG.Owned(id)
        if o == nil then out.known = false elseif o then out.have = out.have + 1 end
        out.items[#out.items + 1] = { id = id, owned = o, drop = EG.DropText(id) }
    end
    local D = WeintCodex.LootData
    out.status = D and D.SET_STATUS and D.SET_STATUS[setId]
    return out
end

local function ItemName(id)
    local ci = _G.C_Item
    local n = ci and Ask(ci.GetItemNameByID, id)
    if type(n) == "string" and n ~= "" then return n end
    return nil
end

--------------------------------------------------
-- Dungeons ab Stufe 55
--------------------------------------------------

-- { { dungeon, quests, counts = { done, ready, active, open, later }, known } }
function EG.Dungeons()
    local D, J, DP = WeintCodex.DungeonData, WeintCodex.DungeonJournal, WeintCodex.DungeonPages
    local out = {}
    if not (D and D.All) then return out end
    local faction = Faction()
    for _, d in ipairs(D.All()) do
        if (d.maxLevel or 0) >= EG.MIN_DUNGEON and (not D.ForFaction or D.ForFaction(d, faction) ~= false) then
            local quests = (J and J.Quests and J.Quests(d.id, faction)) or {}
            local counts, known = {}, true
            for _, q in ipairs(quests) do
                local s = DP and DP.QuestState and DP.QuestState(q)
                if s then counts[s] = (counts[s] or 0) + 1 else known = false end
            end
            out[#out + 1] = { dungeon = d, quests = quests, counts = counts, known = known }
        end
    end
    table.sort(out, function(a, b)
        if (a.dungeon.minLevel or 0) ~= (b.dungeon.minLevel or 0) then return (a.dungeon.minLevel or 0) < (b.dungeon.minLevel or 0) end
        return tostring(a.dungeon.id) < tostring(b.dungeon.id)
    end)
    return out
end

function EG.DungeonName(d) return d.name or d.id end

function EG.QuestLine(e)
    if #e.quests == 0 then return "Keine Quests im Bestand" end
    if not e.known then return #e.quests .. " Quests · Stand unbekannt" end
    local c = e.counts
    local parts = {}
    if (c.ready or 0) > 0 then parts[#parts + 1] = c.ready .. " abgabebereit" end
    if (c.active or 0) > 0 then parts[#parts + 1] = c.active .. " im Questlog" end
    if (c.open or 0) > 0 then parts[#parts + 1] = c.open .. " offen" end
    if (c.later or 0) > 0 then parts[#parts + 1] = c.later .. " später" end
    if (c.done or 0) > 0 then parts[#parts + 1] = c.done .. " erledigt" end
    return table.concat(parts, " · ")
end

--------------------------------------------------
-- Ruf
--------------------------------------------------

function EG.Factions()
    local BP = WeintCodex.BooksPage
    if not (BP and BP.RepFactions and WeintCodex.RepRewardsData) then return {} end
    return (BP.RepFactions())
end

--------------------------------------------------
-- Als Naechstes: aus dem Stand im Spiel, das Dringendste zuerst
--------------------------------------------------
-- Keine Ratschlaege, nur Folgerungen aus Daten und Client: was abgabebereit
-- ist, was im Questlog steht, der naechste Schritt jeder begonnenen Kette,
-- fehlende Teile und Belohnungen, die du schon kaufen kannst.

EG.T05_NOTES = {
    [8961] = "Auf Forever verlangt dieser Schritt einen anderen Gegenstand als in Classic: ihn lässt Asharell fallen, in einer Höhle in der Brennenden Steppe (72.4, 68.5).",
}
EG.NEXT_MAX = 8

function EG.Next()
    local out = {}
    local lvl = EG.Level() or 0
    local AT = WeintCodex.UIAttunements
    local function Add(l) if #out < EG.NEXT_MAX then l.key = "next:" .. (#out + 1) out[#out + 1] = l end end
    -- 1. Abgabebereite Dungeonquests
    for _, e in ipairs(EG.Dungeons()) do
        local n = e.counts.ready or 0
        if n > 0 then
            local d = e.dungeon
            Add({ name = n .. (n == 1 and " Quest" or " Quests") .. " abgeben: " .. EG.DungeonName(d), sub = "erledigt, wartet beim Geber",
                color = "success", why = "Diese Quests sind fertig – beim Geber abgeben bringt Erfahrung oder Belohnung.",
                go = { text = "Zum Dungeon", fn = function() EG.GoDungeon(d.id) end } })
        end
    end
    -- 2./4. Einstimmungen: erst was im Questlog steht, dann was beginnen kann
    local att = EG.Attunements()
    for pass = 1, 2 do
        for _, e in ipairs(att) do
            local st, nx = e.st, e.st.next
            local inLog = st.state == "log"
            local fits = st.state == "open" and nx and (nx.level or 0) <= lvl + 2
            if nx and ((pass == 1 and inLog) or (pass == 2 and fits)) then
                Add({ name = (st.done > 0 and "Weiter: " or "Beginnen: ") .. e.att.name,
                    sub = "Schritt " .. (st.done + 1) .. " von " .. st.total .. ": " .. nx.name .. (inLog and " – im Questlog" or ""),
                    color = "accent", entry = e, why = "Die Einstimmung öffnet " .. e.att.name .. ". Rechts die ganze Kette.",
                    go = (AT and AT.GiverPlace(nx.giver)) and { text = "Pfeil zum Geber", fn = function() AT.Guide(nx) end } or nil })
            end
        end
        -- 3. Tier 0.5 nach den Einstimmungen im Questlog
        if pass == 1 then
            local t5 = EG.Tier05()
            if t5 and t5.next and lvl >= 58 then
                local nx = t5.next
                Add({ name = "Tier 0.5: Schritt " .. t5.index .. " von " .. t5.total, sub = nx.name,
                    color = "accent", why = "Die Questreihe zu Dungeon-Set 2 deiner Klasse. Alle Schritte unter „Tier 0.5“.",
                    go = (AT and AT.GiverPlace(nx.giver)) and { text = "Pfeil zum Geber", fn = function() EG.GuideStep(nx) end } or nil })
            end
        end
    end
    -- 5. Tier 0: was fehlt, und wo das erste davon faellt
    local t = EG.Tier()
    if t and t.known and t.have < #t.items then
        local first
        for _, it in ipairs(t.items) do if it.owned == false and it.drop then first = it break end end
        Add({ name = "Tier 0: " .. (#t.items - t.have) .. " von " .. #t.items .. " Teilen fehlen",
            sub = first and ("z. B. " .. (ItemName(first.id) or ("Gegenstand " .. first.id)) .. " – " .. first.drop) or (t.name or ""),
            color = "textNormal", why = "Dein Dungeon-Set 1. Unter „Tier 0“ jedes Teil mit Fundort.",
            go = { text = "Tier 0 zeigen", fn = function() EG.cat, EG.sel = "tier", nil EG.Show() end } })
    end
    -- 6. Ruf: Belohnungen, die du schon kaufen kannst
    for _, e in ipairs(EG.Factions()) do
        if e.reach > 0 then
            local fid = e.fid
            Add({ name = "Ruf: " .. e.name, sub = e.reach .. " von " .. e.total .. " Belohnungen mit deinem Ruf erhältlich",
                color = "textNormal", why = "Was der Rüstmeister dir mit deiner Rufstufe schon verkauft.",
                go = { text = "Belohnungen", fn = function() EG.GoRep(fid) end } })
        end
    end
    return out
end

function EG.GoDungeon(id)
    local DP, nav = WeintCodex.DungeonPages, WeintCodex.Navigation
    if nav and nav.GoToTab then nav.GoToTab("dungeons") end
    if DP and DP.Select then DP.Select(id) end
end
function EG.GoRep(fid)
    local BP, nav = WeintCodex.BooksPage, WeintCodex.Navigation
    if BP then BP.cat, BP.repSel = "rep", fid end
    if nav and nav.GoToTab then nav.GoToTab("buecher") end
end

--------------------------------------------------
-- Zusammenfassung oben
--------------------------------------------------

function EG.Summary()
    local parts = {}
    local att = EG.Attunements()
    local done, unknown = 0, false
    for _, e in ipairs(att) do
        if e.st.state == "done" then done = done + 1 elseif e.st.state == "unknown" then unknown = true end
    end
    if #att > 0 then parts[#parts + 1] = "Einstimmungen " .. (unknown and "?" or tostring(done)) .. "/" .. #att end
    local t5 = EG.Tier05()
    if t5 then parts[#parts + 1] = "Tier 0.5 " .. (t5.known and tostring(t5.done) or "?") .. "/" .. t5.total end
    local t = EG.Tier()
    if t then parts[#parts + 1] = "Tier 0 " .. (t.known and tostring(t.have) or "?") .. "/" .. #t.items end
    return table.concat(parts, "  ·  ")
end

--------------------------------------------------
-- Seite
--------------------------------------------------

local function Pill(parent, text, opts)
    local BP = WeintCodex.BooksPage
    return BP.Pill(parent, text, opts)
end

function EG.PaintRow(r)
    local on = r.key ~= nil and r.key == EG.sel
    local s = (on and C.surface3) or (r._hot and C.surface2) or C.surface1
    r.bg:SetColorTexture(s[1], s[2], s[3], (on or r._hot) and 1 or 0)
end

local function Row(i, body)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, body)
    r:SetHeight(EG.ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r)
    r.dot = r:CreateTexture(nil, "ARTWORK")
    r.dot:SetTexture("Interface\\AddOns\\WeintCodex\\media\\ui\\disc")
    r.dot:SetSize(8, 8)
    r.dot:SetPoint("LEFT", r, "LEFT", 12, 0)
    r.name = WeintCodex.Label(r, "", { size = 13, color = "textBright" })
    r.name:SetPoint("TOPLEFT", r, "TOPLEFT", 28, -7)
    r.name:SetPoint("RIGHT", r, "RIGHT", -120, 0)
    r.name:SetJustifyH("LEFT")
    r.sub = WeintCodex.Label(r, "", { size = 11, color = "textMuted" })
    r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3)
    r.sub:SetPoint("RIGHT", r, "RIGHT", -120, 0)
    r.sub:SetJustifyH("LEFT")
    r.go = Pill(r, "", { height = 24 })
    r.go:SetWidth(106)
    r.go:SetPoint("RIGHT", r, "RIGHT", -10, 0)
    r.key, r.item = false, false
    r:SetScript("OnEnter", function(self)
        self._hot = true
        EG.PaintRow(self)
        local tt = _G.GameTooltip
        if self.item and tt and tt.SetItemByID then
            tt:SetOwner(self, "ANCHOR_RIGHT")
            pcall(tt.SetItemByID, tt, self.item)
            tt:Show()
        end
    end)
    r:SetScript("OnLeave", function(self)
        self._hot = nil
        EG.PaintRow(self)
        if self.item and _G.GameTooltip then _G.GameTooltip:Hide() end
    end)
    r:SetScript("OnClick", function(self)
        if not self.key then return end
        EG.sel = (EG.sel ~= self.key) and self.key or nil
        EG.Show()
    end)
    rows[i] = r
    return r
end
EG.Row = Row

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    local M = WeintCodex.Metrics
    f.Head = WeintCodex.PageHead(f, {
        eyebrow = "Endgame",
        title   = "Endgame",
        sub     = "Einstimmungen, Tier 0, die Dungeons ab Stufe 55 und dein Ruf – der Stand kommt aus dem Spiel.",
        height  = EG.HEAD,
    })
    local card = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    card:SetPoint("TOPLEFT", f, "TOPLEFT", M.PAD_X, -(M.PAD_Y + EG.HEAD))
    card:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -M.PAD_X, M.PAD_Y)
    f.Card = card
    f.Count = WeintCodex.Label(card, "", { size = 15, color = "textBright" })
    f.Count:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -18)
    f.Goal = WeintCodex.Label(card, "", { size = 12, color = "textMuted" })
    f.Goal:SetPoint("TOPLEFT", f.Count, "BOTTOMLEFT", 0, -6)
    f.Goal:SetPoint("RIGHT", card, "RIGHT", -20, 0)
    f.Goal:SetJustifyH("LEFT")
    f.ListScroll, f.ListBody = WeintCodex.CreateScrollArea(card, 12, -72, 400, 300, true)
    f.Foot = WeintCodex.Label(card, "", { size = 11, color = "textFaint" })
    f.Foot:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 20, 12)
    f:SetScript("OnSizeChanged", function(self, width)
        width = Plain(width)
        if self:IsShown() and type(width) == "number" and type(self.drawnWidth) == "number"
           and math.abs(width - self.drawnWidth) > 2 then
            EG.Show()
        end
    end)
    page = f
    EG.page = f
    return f
end

-- Die Zeilen der gewaehlten Rubrik: { key, name, sub, color, go = { text, fn }, item }
function EG.Lines(cat)
    local out = {}
    if cat == "next" then
        return EG.Next()
    elseif cat == "t05" then
        local t5 = EG.Tier05()
        for i, st in ipairs(t5 and t5.steps or {}) do
            local cur = t5.next == st
            local AT = WeintCodex.UIAttunements
            out[#out + 1] = { key = "t05:" .. i, name = i .. ". " .. st.name .. (st.any and " (eine von " .. #st.ids .. ")" or ""),
                sub = ((st.state == true and "erledigt") or (st.state == nil and "Stand unbekannt") or (cur and "als Nächstes") or "offen")
                    .. (st.level and (" · Stufe " .. st.level) or "") .. (EG.T05_NOTES[st.ids[1]] and " · Hinweis rechts" or ""),
                color = (st.state == true and "success") or (cur and "accent") or "textMuted", t05 = st,
                go = (st.state ~= true and AT and AT.GiverPlace(st.giver)) and { text = "Pfeil zum Geber", fn = function() EG.GuideStep(st) end } or nil }
        end
        return out
    elseif cat == "att" then
        local AT = WeintCodex.UIAttunements
        for _, e in ipairs(EG.Attunements()) do
            local st = e.st
            local color = (st.state == "done" and "success") or (st.state == "log" and "accent")
                or (st.state == "unknown" and "textMuted") or "textNormal"
            local nxt = st.next
            out[#out + 1] = { key = "att:" .. e.att.id, name = e.att.name, sub = EG.AttLine(e), color = color,
                entry = e,
                go = (nxt and st.state ~= "done" and AT and AT.GiverPlace(nxt.giver)) and
                    { text = "Pfeil zum Geber", fn = function() AT.Guide(nxt) end } or nil }
        end
    elseif cat == "tier" then
        local t = EG.Tier()
        if t then
            for _, it in ipairs(t.items) do
                local color = (it.owned == true and "success") or (it.owned == nil and "textMuted") or "textNormal"
                local _, inst = EG.DropText(it.id)
                out[#out + 1] = { key = "item:" .. it.id, item = it.id, name = ItemName(it.id) or ("Gegenstand " .. it.id),
                    sub = (it.owned == true and "hast du" or it.owned == false and "fehlt" or "Stand unbekannt")
                        .. " · " .. (it.drop or "Quelle unbekannt"),
                    color = color, tierItem = it,
                    go = (it.owned ~= true and inst) and { text = "Zur Beute", fn = function()
                        local LB = LootBook()
                        if LB and LB.Open then LB.Open(inst.key, it.id) end
                        local nav = WeintCodex.Navigation
                        if nav and nav.GoToTab then nav.GoToTab("beute") end
                    end } or nil }
            end
        end
    elseif cat == "dung" then
        for _, e in ipairs(EG.Dungeons()) do
            local d = e.dungeon
            local open = (e.counts.open or 0) + (e.counts.active or 0) + (e.counts.ready or 0)
            out[#out + 1] = { key = "dung:" .. d.id, name = EG.DungeonName(d),
                sub = "Stufe " .. (d.minLevel or "?") .. "–" .. (d.maxLevel or "?") .. " · " .. EG.QuestLine(e),
                color = (not e.known and "textMuted") or (open > 0 and "accent") or "success", entry = e,
                go = { text = "Zum Dungeon", fn = function()
                    local DP = WeintCodex.DungeonPages
                    local nav = WeintCodex.Navigation
                    if nav and nav.GoToTab then nav.GoToTab("dungeons") end
                    if DP and DP.Select then DP.Select(d.id) end
                end } }
        end
    elseif cat == "rep" then
        local BP = WeintCodex.BooksPage
        for _, e in ipairs(EG.Factions()) do
            local fid = e.fid
            out[#out + 1] = { key = "rep:" .. fid, name = e.name,
                sub = (BP and BP.StandingName(e.standing) or "?") .. " · " .. e.reach .. " von " .. e.total .. " Belohnungen erreichbar",
                color = (e.reach > 0 and "success") or (e.standing and "textNormal") or "textMuted",
                go = { text = "Belohnungen", fn = function()
                    if BP then BP.cat, BP.repSel = "rep", fid end
                    local nav = WeintCodex.Navigation
                    if nav and nav.GoToTab then nav.GoToTab("buecher") end
                end } }
        end
    end
    return out
end

local function SidebarItems()
    local items = { { isGroup = true, label = "Endgame" } }
    local att, t = EG.Attunements(), EG.Tier()
    local attDone = 0
    for _, e in ipairs(att) do if e.st.state == "done" then attDone = attDone + 1 end end
    local status = {
        att = { text = attDone .. "/" .. #att, color = (#att > 0 and attDone == #att) and "success" or "textMuted" },
        tier = t and { text = (t.known and t.have or "?") .. "/" .. #t.items, color = (t.have == #t.items) and "success" or "textMuted" } or nil,
        dung = { text = tostring(#EG.Dungeons()), color = "textMuted" },
        rep = { text = tostring(#EG.Factions()), color = "textMuted" },
        next = { text = tostring(#EG.Next()), color = "accent" },
    }
    local t5 = EG.Tier05()
    if t5 then
        status.t05 = { text = (t5.known and t5.done or "?") .. "/" .. t5.total,
                       color = (t5.done == t5.total) and "success" or "textMuted" }
    end
    for _, c in ipairs(EG.CATS) do
        local key = c.key
        items[#items + 1] = { label = c.label, status = status[key],
            onClick = function() EG.cat, EG.sel = key, nil EG.Show() end }
    end
    return items
end

-- Detailbereich: die gewaehlte Zeile.
function EG.Inspector(line)
    if not line then
        local lvl = EG.Level()
        return {
            { type = "header", text = "Endgame" },
            { type = "card", lines = {
                lvl and ("Du bist Stufe " .. lvl .. ".") or "Deine Stufe nennt das Spiel nicht.",
                "Viele Ketten beginnen schon",
                "vor Stufe 60 – die Liste zeigt sie,",
                "sobald sie im Bestand stehen.",
            }},
            { type = "divider" },
            { type = "header", text = "Woher das stammt" },
            { type = "card", lines = {
                "Was erledigt ist und was du hast,",
                "sagt das Spiel. Ketten, Sets und",
                "Fundorte: wie in Classic bzw.",
                "von Spielern gesammelt.",
            }},
        }
    end
    local blocks = { { type = "header", text = line.name } }
    if line.why then blocks[#blocks + 1] = { type = "text", text = line.why } end
    if line.sub and line.key and line.key:find("^next:") then blocks[#blocks + 1] = { type = "text", text = line.sub } end
    if line.entry and line.entry.chain then
        local e = line.entry
        local items = {}
        for i, s in ipairs(e.chain) do
            local QH = WeintCodex.UIQuestHelper
            local d = QH and QH.Done and QH.Done(s.id)
            items[#items + 1] = { label = i .. ". " .. s.name,
                value = (d == true and "erledigt") or (e.st.next == s and "als Nächstes")
                    or (s.level and s.level > 0 and ("Stufe " .. s.level)) or "",
                labelColor = d == true and "textMuted" or (e.st.next == s and "textBright" or "textNormal"),
                valueColor = d == true and "green" or (e.st.next == s and "accent" or "textDim") }
        end
        blocks[#blocks + 1] = { type = "rows", rows = {
            { label = "Stand", value = STATE_TEXT[e.st.state] or "?" },
            { label = "Schritte", value = e.st.done .. " von " .. e.st.total },
        }}
        blocks[#blocks + 1] = { type = "list", title = "Die Kette", items = items }
    elseif line.t05 then
        local st = line.t05
        local AT = WeintCodex.UIAttunements
        local who
        if AT then who = select(4, AT.GiverPlace(st.giver)) end
        local rows = {
            { label = "Stand", value = (st.state == true and "erledigt") or (st.state == nil and "unbekannt") or "offen" },
            { label = "Stufe", value = st.level and tostring(st.level) or "?" },
            { label = "Geber", value = who or "unbekannt" },
        }
        blocks[#blocks + 1] = { type = "rows", rows = rows }
        if st.any then
            local items = {}
            for _, id in ipairs(st.ids) do items[#items + 1] = { label = EG.QuestTitle(id) } end
            blocks[#blocks + 1] = { type = "list", title = "Eine davon – je nachdem, was Bodley dir gibt", items = items }
        end
        if EG.T05_NOTES[st.ids[1]] then blocks[#blocks + 1] = { type = "text", text = EG.T05_NOTES[st.ids[1]] } end
    elseif line.tierItem then
        local t = EG.Tier()
        blocks[#blocks + 1] = { type = "rows", rows = {
            { label = "Set", value = t and t.name or "?" },
            { label = "Stand", value = line.tierItem.owned == true and "hast du" or line.tierItem.owned == false and "fehlt" or "unbekannt" },
            { label = "Fällt bei", value = line.tierItem.drop or "unbekannt" },
        }}
    elseif line.entry and line.entry.quests then
        local items = {}
        for _, q in ipairs(line.entry.quests) do
            local J = WeintCodex.DungeonJournal
            local DP = WeintCodex.DungeonPages
            local s = DP and DP.QuestState and DP.QuestState(q)
            local name = (J and J.QuestName and J.QuestName(q.id)) or q.name or ("Quest " .. tostring(q.id))
            items[#items + 1] = { label = name, value = s and QUEST_TEXT[s] or "?",
                labelColor = s == "done" and "textMuted" or "textNormal",
                valueColor = (s == "done" and "green") or (s == "ready" and "accent") or "textDim" }
        end
        blocks[#blocks + 1] = { type = "list", title = "Quests", items = items }
    end
    if line.go then
        blocks[#blocks + 1] = { type = "button", label = line.go.text, style = "primary", onClick = line.go.fn }
    end
    return blocks
end

function EG.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
    local nav = WeintCodex.Navigation
    local f = BuildPage()
    f:Show()
    nav.BuildSidebar("Endgame", SidebarItems())
    local label
    for i, c in ipairs(EG.CATS) do
        if c.key == EG.cat then
            label = c.label
            local btn = nav.SidebarButtons and nav.SidebarButtons()[i]
            if btn and btn.SetActive then btn:SetActive(true) end
        end
    end
    WeintCodex.SetBreadcrumb("Endgame", label)
    f.Head.Title:SetText(label or "Endgame")

    local lvl = EG.Level()
    f.Count:SetText(lvl and ("Stufe " .. lvl .. (lvl >= 60 and " – Endgame" or (" – noch " .. (60 - lvl) .. " bis 60"))) or "Stufe unbekannt")
    local goal = EG.Summary()
    if EG.cat == "tier" then
        local t = EG.Tier()
        if not t then
            goal = "Für deine Klasse kennt der Bestand kein Dungeon-Set."
        else
            goal = (t.name or "Dungeon-Set 1") .. ": " .. (t.known and t.have or "?") .. " von " .. #t.items .. " Teilen"
        end
    elseif EG.cat == "t05" then
        local t5 = EG.Tier05()
        goal = t5 and ("Die Questreihe zu Dungeon-Set 2 für deine Klasse – ab Stufe 58, mit Tier 0 als Voraussetzung. "
            .. (t5.known and t5.done or "?") .. " von " .. t5.total .. " Schritten.")
            or "Für deine Klasse und Fraktion kennt der Bestand keine Tier-0.5-Reihe."
    elseif EG.cat == "next" then
        goal = "Was du jetzt tun kannst – aus deinem Stand im Spiel, das Dringendste zuerst. " .. EG.Summary()
    elseif EG.cat == "dung" then
        goal = "Dungeons, deren Stufenbereich bis mindestens " .. EG.MIN_DUNGEON .. " reicht, mit dem Stand ihrer Quests."
    elseif EG.cat == "rep" then
        goal = "Fraktionen mit Belohnungen beim Rüstmeister – Klick: alle Belohnungen."
    end
    f.Goal:SetText(goal)

    local lines = EG.Lines(EG.cat)
    local chosen
    for _, l in ipairs(lines) do if l.key == EG.sel then chosen = l end end
    nav.SetInspector(EG.Inspector(chosen))

    local w = Plain(f.Card:GetWidth()) or 460
    local h = Plain(f.Card:GetHeight()) or 360
    w = (type(w) == "number" and w or 460) - 24
    h = (type(h) == "number" and h or 360) - 72 - 34
    f.ListScroll:SetSize(w, math.max(60, h))
    f.ListBody:SetWidth(w - 10)
    for i, l in ipairs(lines) do
        local r = Row(i, f.ListBody)
        r.key, r.item = l.key, l.item or false
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", f.ListBody, "TOPLEFT", 0, -(i - 1) * EG.ROW_H)
        r:SetPoint("RIGHT", f.ListBody, "RIGHT", 0, 0)
        local c = Col(l.color)
        r.dot:SetVertexColor(c[1], c[2], c[3], 1)
        r.name:SetText(l.name)
        r.sub:SetText(l.sub or "")
        if l.go then
            r.go.label:SetText(l.go.text)
            r.go:SetScript("OnClick", l.go.fn)
            r.go:Show()
        else
            r.go:Hide()
        end
        EG.PaintRow(r)
        r:Show()
    end
    for i = #lines + 1, #rows do rows[i]:Hide() end
    f.ListBody:SetHeight(math.max(1, #lines * EG.ROW_H))
    f.Foot:SetText(#lines == 0 and "Hier ist nichts." or "Klick auf eine Zeile: Einzelheiten rechts.")
    f.drawnWidth = Plain(f:GetWidth())
end

-- /wcui speicher: interne Tabellen dieser Datei.
WeintCodex.Hold("modules/endgame.lua", function() return { rows = rows } end)
