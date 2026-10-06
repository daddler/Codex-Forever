--------------------------------------------------
-- WeintCodex :: Klassenquests - der zweite Reiter unter "Lehrer"
--------------------------------------------------
-- Seit 6.15.0.0 (Abgleich mit dem Addon ForeverGuide): die Quests nur
-- fuer deine Klasse - manche lehren einen Zauber, den kein Lehrer hat
-- (Begleiter des Hexenmeisters, Zaehmen des Jaegers, Totems des Schamanen,
-- Haltungen des Kriegers, Gestalten des Druiden). Dazu, wo der naechste
-- Klassenlehrer steht.
--
-- ZWEI BESTAENDE, NIE VERMISCHT (wie beim Lehrer und den Berufen):
--   * WAS es gibt steht in data/classquests.lua (`community`, Belohnungen
--     `classic`) - erzeugt, nicht von Hand.
--   * WIE WEIT du bist, sagt der Client (WeintCodex.DungeonPages.QuestState:
--     erledigt, im Questlog, abgabebereit). Antwortet er nicht, steht
--     "Stand unbekannt" da - nie "fehlt noch".
-- Der Name einer Quest kommt vom Client (deutsch), der englische aus dem
-- Bestand ist nur der Rueckfall, bis der Client ihn geladen hat. Ziele und
-- Texte gibt es hier nicht: abgeschrieben wird nicht.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.ClassQuests = {}

local CQ = WeintCodex.ClassQuests
local Q  = WeintCodex.ClassQuestData
local C  = WeintCodex.Colors

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

--------------------------------------------------
-- Bestand
--------------------------------------------------

-- Volk des Spielers als Nummer (dritter Wert von UnitRace) oder nil.
function CQ.PlayerRace()
    if not _G.UnitRace then return nil end
    local ok, _, _, id = pcall(_G.UnitRace, "player")
    id = ok and Plain(id) or nil
    return type(id) == "number" and id > 0 and id or nil
end

-- Gilt eine Quest fuer dieses Volk? Ohne Volksangabe fuer alle; ohne
-- bekanntes Volk des Spielers auch - ausgelassen wird nur, was sicher
-- nicht passt.
function CQ.ForRace(q, race)
    if not q.ra or q.ra == 0 or not race or race > 31 then return true end
    return math.floor(q.ra / 2 ^ (race - 1)) % 2 == 1
end

-- Die Klassenquests fuer Klasse und Volk.
function CQ.List(class, race)
    local out = {}
    local list = Q and Q.CLASSES and class and Q.CLASSES[class]
    for _, q in ipairs(list or {}) do
        if CQ.ForRace(q, race) then out[#out + 1] = q end
    end
    return out
end

-- NPC: { name, map, x, y, faction } oder nil.
function CQ.Npc(id)
    local n = id and Q and Q.NPCS and Q.NPCS[id]
    if not n then return nil end
    return { id = id, name = n[1], map = n[2], x = n[3], y = n[4], faction = n[5] }
end

--------------------------------------------------
-- Client: Namen
--------------------------------------------------

local pending = {}

function CQ.Title(q)
    local ql = _G.C_QuestLog
    if ql and ql.GetTitleForQuestID then
        local ok, t = pcall(ql.GetTitleForQuestID, q.id)
        t = ok and Plain(t) or nil
        if type(t) == "string" and t ~= "" then return t end
        if not pending[q.id] and ql.RequestLoadQuestByID then
            pending[q.id] = true
            pcall(ql.RequestLoadQuestByID, q.id)
        end
    end
    return q.name
end

-- Name einer Quest nach Nummer (Vor- und Folgequest).
function CQ.TitleById(id)
    local ql = _G.C_QuestLog
    if ql and ql.GetTitleForQuestID then
        local ok, t = pcall(ql.GetTitleForQuestID, id)
        t = ok and Plain(t) or nil
        if type(t) == "string" and t ~= "" then return t end
    end
    return "Quest " .. id
end

function CQ.SpellName(q)
    if not q.spell then return nil end
    local cs = _G.C_Spell
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, q.spell)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    end
    if _G.GetSpellInfo then
        local ok, n = pcall(_G.GetSpellInfo, q.spell)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    end
    return q.spellName or ("Zauber " .. q.spell)
end

local function ItemName(id)
    local ci = _G.C_Item
    local get = (ci and ci.GetItemNameByID) or nil
    if get then
        local ok, n = pcall(get, id)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    end
    if _G.GetItemInfo then
        local ok, n = pcall(_G.GetItemInfo, id)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    end
    return "Gegenstand " .. id
end

local function ZoneName(map)
    local QM = WeintCodex.QuestMap
    return map and QM and QM.MapName and QM.MapName(map) or nil
end

-- "Name, Gebiet" / "Name" / ein Satz, wenn der Geber unbekannt ist.
function CQ.GiverText(q)
    if q.start == "item" then return "beginnt an einem Gegenstand" end
    if q.start == "object" then return "beginnt an einem Objekt" end
    local n = CQ.Npc(q.giver)
    if not n then return "Geber nicht hinterlegt" end
    local zone = ZoneName(n.map)
    return "bei " .. n.name .. (zone and (", " .. zone) or "")
end

--------------------------------------------------
-- Einordnen
--------------------------------------------------

CQ.SOON = 5   -- "bald": bis 5 Stufen ueber dir

CQ.SECTIONS = {
    { key = "ready",   label = "Abgabebereit",        color = "successBright" },
    { key = "active",  label = "Im Questlog",         color = "blueBright" },
    { key = "now",     label = "Jetzt möglich",       color = "successBright" },
    { key = "soon",    label = "Bald",                color = "infoBright" },
    { key = "unknown", label = "Stand unbekannt",     color = "textMuted" },
    { key = "chain",   label = "Nach einer Vorquest", color = "textMuted", collapsible = true },
    { key = "later",   label = "Später",              color = "textMuted", collapsible = true },
    { key = "done",    label = "Erledigt",            color = "textDim",   collapsible = true },
}

function CQ.State(q)
    local DP = WeintCodex.DungeonPages
    return DP and DP.QuestState and DP.QuestState({ id = q.id, requires = q.rl }) or nil
end

-- Wartet die Quest auf eine Vorquest? Questie nennt mehrere Vorquests oft
-- als Wahl (je Volk eine) - gesperrt ist sie erst, wenn der Client fuer
-- jede antwortet und keine erledigt ist. Schweigt er: nicht gesperrt.
function CQ.Blocked(q)
    if not q.pre or #q.pre == 0 then return false end
    local DP = WeintCodex.DungeonPages
    if not (DP and DP.QuestState) then return false end
    for _, id in ipairs(q.pre) do
        local s = DP.QuestState({ id = id })
        if s == nil or s == "done" then return false end
    end
    return true
end

local function ByLevel(a, b)
    if a.rl ~= b.rl then return a.rl < b.rl end
    return a.id < b.id
end

-- { sections = { [key] = { q, ... } }, states = { [id] = state }, total }
function CQ.Categorize(list, level)
    local out = { sections = {}, states = {}, total = #list }
    for _, s in ipairs(CQ.SECTIONS) do out.sections[s.key] = {} end
    for _, q in ipairs(list) do
        local st = CQ.State(q)
        out.states[q.id] = st
        local sec
        if st == "done" or st == "ready" or st == "active" then
            sec = st
        elseif st == nil or type(level) ~= "number" then
            sec = "unknown"
        elseif CQ.Blocked(q) then
            sec = "chain"
        elseif q.rl <= level then
            sec = "now"
        elseif q.rl <= level + CQ.SOON then
            sec = "soon"
        else
            sec = "later"
        end
        table.insert(out.sections[sec], q)
    end
    for _, l in pairs(out.sections) do table.sort(l, ByLevel) end
    return out
end

local function PlayerLevel()
    local ok, v = pcall(_G.UnitLevel or function() return nil end, "player")
    v = ok and Plain(v) or nil
    return type(v) == "number" and v > 0 and v or nil
end

local function PlayerClass()
    if not _G.UnitClass then return nil, nil end
    local ok, name, class = pcall(_G.UnitClass, "player")
    if not ok then return nil, nil end
    name, class = Plain(name), Plain(class)
    return type(class) == "string" and class or nil, type(name) == "string" and name or nil
end

local function PlayerFaction()
    local f = _G.UnitFactionGroup and Plain(_G.UnitFactionGroup("player"))
    return (f == "Alliance" or f == "Horde") and f or nil
end

-- Fuer die Startseite: die erste Quest, die jetzt einen Zauber lehrt
-- (abgabebereit, im Questlog oder jetzt moeglich) - nur mit Antwort des
-- Clients. { q, state, title, spell, giver } oder nil.
function CQ.NextSpellQuest()
    local class = PlayerClass()
    if not class then return nil end
    local cat = CQ.Categorize(CQ.List(class, CQ.PlayerRace()), PlayerLevel())
    for _, key in ipairs({ "ready", "active", "now" }) do
        for _, q in ipairs(cat.sections[key]) do
            if q.spell then
                return { q = q, state = key, title = CQ.Title(q), spell = CQ.SpellName(q), giver = CQ.GiverText(q) }
            end
        end
    end
    return nil
end

--------------------------------------------------
-- Klassenlehrer: der naechste zuerst
--------------------------------------------------

local FACTION = { A = "Alliance", H = "Horde" }

-- Lehrer deiner Klasse und Fraktion; Entfernung aus der Weltlage, die der
-- Client rechnet (nur gleicher Kontinent), ohne sie die eigene Karte.
function CQ.Trainers(class, faction)
    local K = WeintCodex.UIKit
    local here = K and K.BestMap and K.BestMap() or nil
    local pc, pn, pw
    if K and K.PlayerWorld then pc, pn, pw = K.PlayerWorld() end
    local out = {}
    for _, id in ipairs(Q and Q.TRAINERS and class and Q.TRAINERS[class] or {}) do
        local n = CQ.Npc(id)
        local fr = n and FACTION[n.faction]
        if n and (not faction or not fr or fr == faction) then
            local dist
            if pc and n.map and K and K.ToWorld then
                local c, wn, ww = K.ToWorld(n.map, n.x / 100, n.y / 100)
                if c and c == pc then dist = math.sqrt((wn - pn) ^ 2 + (ww - pw) ^ 2) end
            end
            n.dist, n.here = dist, here ~= nil and n.map == here
            out[#out + 1] = n
        end
    end
    table.sort(out, function(a, b)
        if (a.dist ~= nil) ~= (b.dist ~= nil) then return a.dist ~= nil end
        if a.dist and a.dist ~= b.dist then return a.dist < b.dist end
        if a.here ~= b.here then return a.here end
        if (a.map ~= nil) ~= (b.map ~= nil) then return a.map ~= nil end
        return a.name < b.name
    end)
    return out
end

--------------------------------------------------
-- Seite
--------------------------------------------------

local page
local showAll = false
local ROW_H, HEAD_H, TRAINER_H = 38, 30, 40
local rowPool, headPool, notePool, trainerPool = {}, {}, {}, {}
local used = { row = 0, head = 0, note = 0, trainer = 0 }
local UI = "Interface\\AddOns\\WeintCodex\\media\\ui\\"

local function ResetPools()
    for _, pool in ipairs({ rowPool, headPool, notePool, trainerPool }) do
        for _, f in ipairs(pool) do f:Hide() end
    end
    used.row, used.head, used.note, used.trainer = 0, 0, 0, 0
end

local function ShowOnMap(npc, title)
    local QM = WeintCodex.QuestMap
    if npc and npc.map and QM and QM.Show then
        QM.Show({ map = npc.map, x = npc.x / 100, y = npc.y / 100, who = npc.name }, nil, title)
    end
end

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    local PAD_X, PAD_Y, GAP = WeintCodex.Metrics.PAD_X, WeintCodex.Metrics.PAD_Y, WeintCodex.Metrics.GAP
    f.Head = WeintCodex.PageHead(f, {
        eyebrow = "Leveln",
        title   = "Klassenquests",
        sub     = "Quests nur für deine Klasse – manche lehren einen Zauber, den kein Lehrer hat.",
        height  = 84,
    })
    local qc = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    qc:SetPoint("TOPLEFT",    f, "TOPLEFT",    PAD_X, -(PAD_Y + 84))
    qc:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD_X, PAD_Y)
    qc:SetWidth(460)
    f.QuestCard = qc
    local qt = WeintCodex.Label(qc, "Quests", { size = 14, color = "textBright", font = WeintCodex.Fonts.sansSemi })
    qt:SetPoint("TOPLEFT", qc, "TOPLEFT", 20, -16)
    f.AllButton = WeintCodex.CreateButton(qc, { kind = "ghost", text = "Alle zeigen", height = 24,
        size = 11, padding = 20, radius = 0, onClick = function()
            showAll = not showAll
            CQ.Draw()
        end })
    f.AllButton:SetPoint("TOPRIGHT", qc, "TOPRIGHT", -16, -12)
    f.QuestScroll, f.QuestBody = WeintCodex.CreateScrollArea(qc, 20, -46, 420, 300, true)

    local tc = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    tc:SetPoint("TOPLEFT",     qc, "TOPRIGHT", GAP, 0)
    tc:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X, PAD_Y)
    f.TrainerCard = tc
    local tt = WeintCodex.Label(tc, "Klassenlehrer", { size = 14, color = "textBright", font = WeintCodex.Fonts.sansSemi })
    tt:SetPoint("TOPLEFT", tc, "TOPLEFT", 20, -16)
    f.TrainerScroll, f.TrainerBody = WeintCodex.CreateScrollArea(tc, 20, -46, 280, 300, true)

    f:SetScript("OnSizeChanged", function(self, width)
        width = Plain(width)
        if self:IsShown() and type(width) == "number" and type(self.drawnWidth) == "number"
           and math.abs(width - self.drawnWidth) > 2 then
            CQ.Redraw()
        end
    end)
    page = f
    return f
end

-- Ein Absatz wie WeintCodex.Paragraph, aber wiederverwendet.
local function Note(body, y, w, text)
    used.note = used.note + 1
    local fs = notePool[used.note]
    if not fs then
        fs = WeintCodex.Paragraph(body, "", { size = 11, color = "textDim" })
        notePool[used.note] = fs
    end
    fs:SetParent(body)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    fs:SetWidth(w)
    fs:SetText(text)
    -- Hoehe geschaetzt wie in Paragraph, nie vom Client gelesen.
    local h = WeintCodex.EstimateLines(text, math.floor(w / (11 * 0.60))) * (11 + 3)
    fs:SetHeight(h)
    fs:Show()
    return y - h - 6
end

local function SectionHead(body, y, w, sec, count)
    used.head = used.head + 1
    local head = headPool[used.head]
    if not head then
        head = CreateFrame("Frame", nil, body)
        head:SetHeight(HEAD_H)
        head.eb = WeintCodex.Eyebrow(head, "", { size = 10 })
        head.eb:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 0, 8)
        head.right = WeintCodex.Label(head, "", { size = 11, color = "textDim", justify = "RIGHT" })
        head.right:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", -4, 7)
        local line = head:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 0, 2)
        line:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", 0, 2)
        line:SetColorTexture(C.border[1], C.border[2], C.border[3], 1)
        headPool[used.head] = head
    end
    head:SetParent(body)
    head:ClearAllPoints()
    head:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    head:SetWidth(w)
    head.eb:SetText(WeintCodex.Spaced and WeintCodex.Spaced(WeintCodex.Upper(sec.label)) or sec.label)
    local c = C[sec.color] or C.textMuted
    head.eb:SetTextColor(c[1], c[2], c[3])
    head.right:SetText(count == 1 and "1 Quest" or (count .. " Quests"))
    head:Show()
    return y - HEAD_H - 4
end

local function Tooltip(row)
    local gt, q = _G.GameTooltip, row.quest
    if not (gt and q) then return end
    gt:SetOwner(row, "ANCHOR_RIGHT")
    local tb = C.textBright
    gt:SetText(CQ.Title(q), tb[1], tb[2], tb[3])
    local function line(text, tone)
        local c = C[tone or "textNormal"] or C.textNormal
        gt:AddLine(text, c[1], c[2], c[3], true)
    end
    line("Stufe " .. q.lv .. (q.rl ~= q.lv and (" · ab Stufe " .. q.rl) or ""), "textMuted")
    if q.spell then line("Lehrt: " .. CQ.SpellName(q), "successBright") end
    line("Beginnt " .. CQ.GiverText(q), "textNormal")
    local t = CQ.Npc(q.turnin)
    if t and q.turnin ~= q.giver then
        local zone = ZoneName(t.map)
        line("Abgabe bei " .. t.name .. (zone and (", " .. zone) or ""), "textNormal")
    end
    if q.pre and #q.pre > 0 then
        local names = {}
        for i, id in ipairs(q.pre) do
            if i > 3 then names[#names + 1] = "…" break end
            names[#names + 1] = "„" .. CQ.TitleById(id) .. "“"
        end
        line((#q.pre > 1 and "Vorher eine von: " or "Vorher: ") .. table.concat(names, ", "), "textMuted")
    end
    if q.next then line("Danach: „" .. CQ.TitleById(q.next) .. "“", "textMuted") end
    local rew = {}
    for _, id in ipairs(q.items or {}) do rew[#rew + 1] = ItemName(id) end
    if #rew > 0 then line("Belohnung: " .. table.concat(rew, ", "), "textMuted") end
    local ch = {}
    for _, id in ipairs(q.choice or {}) do ch[#ch + 1] = ItemName(id) end
    if #ch > 0 then line("Zur Wahl: " .. table.concat(ch, ", "), "textMuted") end
    if q.money and WeintCodex.Trainer and WeintCodex.Trainer.Money then
        line("Geld: " .. WeintCodex.Trainer.Money(q.money), "textMuted")
    end
    if #rew > 0 or #ch > 0 or q.money then line("Belohnungen aus Classic – in Forever vielleicht anders.", "textDim") end
    local g = CQ.Npc(q.giver)
    if g and g.map then line("Klick: Geber auf der Karte", "textDim") end
    gt:Show()
end

local function QuestRow(body, y, w, q, state, dim)
    used.row = used.row + 1
    local row = rowPool[used.row]
    if not row then
        row = CreateFrame("Button", nil, body)
        row:SetHeight(ROW_H)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(row)
        hl:SetColorTexture(C.textBright[1], C.textBright[2], C.textBright[3], 0.05)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(22, 22)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.level = WeintCodex.Label(row, "", { size = 11, justify = "RIGHT", color = "textDim", font = WeintCodex.Fonts.mono })
        row.level:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -5)
        row.state = WeintCodex.Label(row, "", { size = 10, justify = "RIGHT" })
        row.state:SetPoint("RIGHT", row.level, "LEFT", -10, 0)
        row.title = WeintCodex.Label(row, "", { size = 12, font = WeintCodex.Fonts.sansMedium })
        row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 32, -4)
        row.title:SetPoint("RIGHT", row.state, "LEFT", -8, 0)
        row.title:SetWordWrap(false)
        row.sub = WeintCodex.Label(row, "", { size = 10, color = "textMuted" })
        row.sub:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
        row.sub:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.sub:SetWordWrap(false)
        row:SetScript("OnEnter", Tooltip)
        row:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
        row:SetScript("OnClick", function(self)
            local qq = self.quest
            ShowOnMap(qq and CQ.Npc(qq.giver), qq and CQ.Title(qq))
        end)
        rowPool[used.row] = row
    end
    row:SetParent(body)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    row:SetWidth(w)
    row.quest = q
    local icon
    if q.spell and _G.C_Spell and _G.C_Spell.GetSpellTexture then
        local ok, tex = pcall(_G.C_Spell.GetSpellTexture, q.spell)
        tex = ok and Plain(tex) or nil
        if type(tex) == "number" or type(tex) == "string" then icon = tex end
    end
    row.icon:SetTexture(icon or (UI .. "icon_quest"))
    if row.icon.SetDesaturated then row.icon:SetDesaturated(dim and true or false) end
    row.title:SetText(CQ.Title(q))
    local c = dim and C.textDim or C.textNormal
    row.title:SetTextColor(c[1], c[2], c[3])
    row.level:SetText("Stufe " .. q.rl)
    local DP = WeintCodex.DungeonPages
    local def = state and DP and DP.QUEST_STATE and DP.QUEST_STATE[state]
    if def and state ~= "later" and state ~= "open" then
        row.state:SetText(def.text)
        local sc = C[def.color] or C.textMuted
        row.state:SetTextColor(sc[1], sc[2], sc[3])
    else
        row.state:SetText("")
    end
    local sub = CQ.GiverText(q)
    if q.spell then sub = WeintCodex.ColorText(dim and "textDim" or "successBright", "Lehrt " .. CQ.SpellName(q)) .. "  ·  " .. sub end
    row.sub:SetText(sub)
    row:Show()
    return y - ROW_H
end

local function TrainerRow(body, y, w, n, className)
    used.trainer = used.trainer + 1
    local row = trainerPool[used.trainer]
    if not row then
        row = CreateFrame("Frame", nil, body)
        row:SetHeight(TRAINER_H)
        row.name = WeintCodex.Label(row, "", { size = 12, font = WeintCodex.Fonts.sansMedium })
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -4)
        row.sub = WeintCodex.Label(row, "", { size = 10, color = "textMuted" })
        row.sub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
        row.name:SetPoint("RIGHT", row, "RIGHT", -64, 0)
        row.sub:SetPoint("RIGHT", row, "RIGHT", -64, 0)
        row.name:SetWordWrap(false)
        row.sub:SetWordWrap(false)
        row.map = WeintCodex.CreateButton(row, { kind = "secondary", text = "Karte", height = 20, size = 10,
            padding = 18, radius = 0, onClick = function()
                ShowOnMap(row.npc, "Lehrt: " .. (row.className or "deine Klasse"))
            end })
        WeintCodex.DrawSlimBorder(row.map, "accentDim", 1, 1)
        row.map:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        trainerPool[used.trainer] = row
    end
    row:SetParent(body)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    row:SetWidth(w)
    row.npc, row.className = n, className
    row.name:SetText(n.name)
    local zone = ZoneName(n.map)
    row.sub:SetText(zone or (n.map and "" or "Lage unbekannt"))
    row.map:SetShown(n.map ~= nil)
    row:Show()
    return y - (TRAINER_H + 4)
end

local function InspectorBlocks(className, list, cat)
    local spells, done = 0, 0
    local answered = false
    for _, q in ipairs(list) do
        if q.spell then spells = spells + 1 end
        if cat.states[q.id] ~= nil then answered = true end
        if cat.states[q.id] == "done" then done = done + 1 end
    end
    local now = #cat.sections.now + #cat.sections.active + #cat.sections.ready
    return {
        { type = "header", text = "Deine Klasse" },
        { type = "rows", rows = {
            { label = "Klasse", value = className or "—" },
            { label = "Klassenquests", value = tostring(#list) },
            { label = "Lehren einen Zauber", value = tostring(spells) },
            { label = "Jetzt dran", value = answered and tostring(now) or "—" },
            { label = "Erledigt", value = answered and tostring(done) or "—" },
        }},
        { type = "divider" },
        { type = "header", text = "Woher das stammt" },
        { type = "card", lines = {
            "Unbestätigt: Quests, Stufen und Geber stammen",
            "aus dem Addon ForeverGuide (Questie-Datenbank",
            "für Forever) – nicht von Blizzard. Belohnungen",
            "aus Classic. Bei vielen Quests ist der Geber",
            "nicht hinterlegt. Ob du eine Quest erledigt",
            "hast, sagt dein Client.",
        }},
    }
end

-- Zeichnet die Seite (die Reiterleiste baut WeintCodex.Trainer.Show).
function CQ.Draw()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
    local f = BuildPage()
    f:Show()
    WeintCodex.SetBreadcrumb("Lehrer", "Klassenquests")
    local class, className = PlayerClass()
    if f.Head and f.Head.Title then
        f.Head.Title:SetText(className and ("Klassenquests · " .. className) or "Klassenquests")
    end
    local level = PlayerLevel()
    local list = CQ.List(class, CQ.PlayerRace())
    local cat = CQ.Categorize(list, level)
    WeintCodex.Navigation.SetInspector(InspectorBlocks(className, list, cat))

    local total = Plain(f:GetWidth())
    if type(total) == "number" and total > 400 then
        f.QuestCard:SetWidth(math.floor((total - 2 * WeintCodex.Metrics.PAD_X - WeintCodex.Metrics.GAP) * 0.62))
    end
    local qw = (Plain(f.QuestCard:GetWidth()) or 460) - 40
    local tw = (Plain(f.TrainerCard:GetWidth()) or 280) - 40
    local qh = (Plain(f.QuestCard:GetHeight()) or 360) - 62
    local th = (Plain(f.TrainerCard:GetHeight()) or 360) - 62
    f.QuestScroll:SetSize(qw, math.max(60, qh))
    f.QuestBody:SetWidth(qw - 10)
    f.TrainerScroll:SetSize(tw, math.max(60, th))
    f.TrainerBody:SetWidth(tw - 10)

    ResetPools()
    local body, w = f.QuestBody, qw - 14
    local y, hidden, shown = 0, 0, 0
    for _, sec in ipairs(CQ.SECTIONS) do
        local l = cat.sections[sec.key]
        if #l > 0 then
            if sec.collapsible and not showAll then
                hidden = hidden + #l
            else
                shown = shown + 1
                y = SectionHead(body, y, w, sec, #l)
                if sec.key == "unknown" then
                    y = Note(body, y, w, "Dein Client sagt gerade nicht, ob du diese Quests erledigt hast.")
                end
                for _, q in ipairs(l) do
                    y = QuestRow(body, y, w, q, cat.states[q.id], sec.key == "done")
                end
                y = y - 10
            end
        end
    end
    if shown == 0 then
        y = Note(body, y, w, #list == 0 and "Für deine Klasse ist keine Klassenquest hinterlegt."
            or "Alles Weitere steht unter „Alle zeigen“.")
    end
    body:SetHeight(math.max(1, -y))
    f.AllButton:SetText(showAll and "Weniger zeigen" or ("Alle zeigen" .. (hidden > 0 and (" (" .. hidden .. ")") or "")))
    f.AllButton:SetShown(showAll or hidden > 0)

    local trainers = CQ.Trainers(class, PlayerFaction())
    local tb, ty = f.TrainerBody, 0
    if #trainers > 0 then
        ty = Note(tb, ty, tw - 14, trainers[1].dist and "Der nächstgelegene steht oben." or "Deine Fraktion, nach Gebiet.")
    else
        ty = Note(tb, ty, tw - 14, "Für deine Klasse ist kein Lehrer hinterlegt.")
    end
    for _, n in ipairs(trainers) do ty = TrainerRow(tb, ty, tw - 14, n, className) end
    tb:SetHeight(math.max(1, -ty))
    f.drawnWidth = total
    CQ.lastDraw = { class = class, total = #list, rows = used.row, trainers = used.trainer, hidden = hidden, cat = cat }
end

function CQ.ShowAll(v) showAll = v and true or false end
function CQ.Page() return page end

--------------------------------------------------
-- Neu zeichnen, wenn sich etwas aendert
--------------------------------------------------

local queued = false
function CQ.Redraw()
    if queued or not (page and page:IsShown()) then return end
    queued = true
    local function run() queued = false if page and page:IsShown() then CQ.Draw() end end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.3, run) else run() end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "QUEST_TURNED_IN", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_LOG_UPDATE",
                     "QUEST_DATA_LOAD_RESULT", "PLAYER_LEVEL_UP" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, id)
    if event == "QUEST_DATA_LOAD_RESULT" then
        id = Plain(id)
        if not pending[id] then return end
        pending[id] = nil
    end
    CQ.Redraw()
end)
CQ.events = ev
