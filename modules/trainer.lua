--------------------------------------------------
-- WeintCodex :: Lehrer - was es beim Klassenlehrer zu lernen gibt
--------------------------------------------------
-- Seit 6.6.0.0, nach dem Vorbild von "What's Training?": welche Zauber
-- der Lehrer jetzt lehrt, was fehlt, was in den naechsten Stufen kommt,
-- was es kostet - und welche Waffenfertigkeiten wo zu lernen sind.
--
-- ZWEI BESTAENDE, NIE VERMISCHT.
--   * WAS es gibt (Stufe, Kosten, Voraussetzung, Waffenmeister) steht in
--     data/trainer.lua und ist `community` - die Seite sagt das.
--   * OB etwas gelernt ist, fragt die Seite den Client (C_SpellBook,
--     IsPlayerSpell). Der Bestand behauptet darueber nichts.
-- Was der Client nicht beantworten kann, wird nicht geraten: die
-- Tierausbildung des Jaegers (ob der Begleiter eine Faehigkeit kennt,
-- zeigt nur der Tierausbilder) steht ohne Zustand da, nicht als
-- "nicht gelernt".
--
-- Nicht uebernommen aus der Vorlage: Hexenmeister-Grimoires (Kauf beim
-- Haendler, gelernt vom Begleiter - der Client sagt es uns nicht),
-- Rufrabatte beim Lehrer, die Ignorierliste (der Beta-Client speichert
-- nichts ueber ein Neuladen hinaus) und die Einbindung ins Zauberbuch.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Trainer = {}

local TR = WeintCodex.Trainer
local T  = WeintCodex.TrainerData
local C  = WeintCodex.Colors

--------------------------------------------------
-- Client
--------------------------------------------------

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

local function IsTrue(ok, v)
    return ok and Plain(v) == true
end

-- Ist der Zauber im Zauberbuch des Spielers? Mehrere Wege, weil die
-- Clientfassungen sie verschieden anbieten; keiner davon wird geraten.
function TR.Known(id)
    local sb = _G.C_SpellBook
    local bank = _G.Enum and _G.Enum.SpellBookSpellBank and _G.Enum.SpellBookSpellBank.Player
    if sb and type(bank) ~= "nil" then
        if sb.IsSpellKnown and IsTrue(pcall(sb.IsSpellKnown, id, bank)) then return true end
        if sb.IsSpellInSpellBook and IsTrue(pcall(sb.IsSpellInSpellBook, id, bank, false)) then return true end
    end
    if _G.IsPlayerSpell and IsTrue(pcall(_G.IsPlayerSpell, id)) then return true end
    if _G.IsSpellKnown and IsTrue(pcall(_G.IsSpellKnown, id)) then return true end
    return false
end

-- Gelernt - oder durch einen hoeheren Rang ersetzt, den der Spieler hat.
local function KnownOrReplaced(class, id)
    if TR.Known(id) then return true end
    local chain, pos = T.RankChain(class, id)
    if chain then
        for i = pos + 1, #chain do
            if TR.Known(chain[i]) then return true end
        end
    end
    return false
end

-- Name, Rang und Bild vom Client. Fehlt der Name noch, wird er
-- angefordert; SPELL_DATA_LOAD_RESULT zeichnet die Seite neu.
local pending = {}
TR.pending = pending
function TR.SpellInfo(id)
    local cs = _G.C_Spell
    local name, sub, icon
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, id)
        if ok and type(n) == "string" and n ~= "" then name = n end
    end
    if cs and cs.GetSpellSubtext then
        local ok, s = pcall(cs.GetSpellSubtext, id)
        if ok and type(s) == "string" and s ~= "" then sub = s end
    end
    if cs and cs.GetSpellTexture then
        local ok, t = pcall(cs.GetSpellTexture, id)
        if ok and type(t) ~= "nil" then icon = t end
    end
    if not name then
        pending[id] = true
        if cs and cs.RequestLoadSpellData then pcall(cs.RequestLoadSpellData, id) end
    end
    return name, sub, icon
end

local function PlayerState()
    local class = _G.UnitClass and select(2, _G.UnitClass("player"))
    local className = _G.UnitClass and _G.UnitClass("player")
    local race = _G.UnitRace and select(3, _G.UnitRace("player"))
    local faction = _G.UnitFactionGroup and _G.UnitFactionGroup("player")
    local level = Plain(_G.UnitLevel and _G.UnitLevel("player"))
    local money = Plain(_G.GetMoney and _G.GetMoney())
    return {
        class = type(class) == "string" and class or nil,
        className = type(className) == "string" and className or nil,
        race = type(race) == "number" and race or nil,
        faction = (faction == "Alliance" or faction == "Horde") and faction or nil,
        level = type(level) == "number" and level or nil,
        money = type(money) == "number" and money or nil,
    }
end
TR.PlayerState = PlayerState

--------------------------------------------------
-- Einordnen
--------------------------------------------------
-- Dieselben Faecher wie die Vorlage, auf Deutsch und in der Reihenfolge,
-- in der man sie liest: erst was jetzt geht, dann was bald kommt.

TR.SECTIONS = {
    { key = "now",     label = "Jetzt lernbar",      color = "successBright" },
    { key = "missing", label = "Vorstufe fehlt",     color = "warningBright" },
    { key = "soon",    label = "Nächste Stufen",     color = "infoBright", byLevel = true },
    { key = "later",   label = "Später",             color = "textMuted",  byLevel = true },
    { key = "talent",  label = "Braucht ein Talent", color = "textMuted" },
    { key = "pet",     label = "Tierausbildung",     color = "textMuted" },
    { key = "known",   label = "Gelernt",            color = "textDim" },
}

local SOON = 2   -- "naechste Stufen": bis zwei Stufen ueber der eigenen

function TR.Categorize(state)
    state = state or PlayerState()
    local out = { sections = {}, total = {} }
    for _, s in ipairs(TR.SECTIONS) do out.sections[s.key] = {} ; out.total[s.key] = 0 end
    if not (state.class and state.level) then return out end
    for _, sp in ipairs(T.Spells(state.class, state.race, state.faction)) do
        local key
        if sp.pet then
            key = "pet"
        elseif KnownOrReplaced(state.class, sp.id) then
            key = "known"
        elseif sp.requiredTalentId and not TR.Known(sp.requiredTalentId) then
            key = "talent"
        elseif sp.level > state.level then
            key = sp.level <= state.level + SOON and "soon" or "later"
        else
            local ok = true
            for _, req in ipairs(sp.requiredIds or {}) do
                if not KnownOrReplaced(state.class, req) then ok = false break end
            end
            key = ok and "now" or "missing"
        end
        table.insert(out.sections[key], sp)
        out.total[key] = out.total[key] + sp.cost
    end
    return out
end

-- Waffenfertigkeiten: gelernt / jetzt / ab Stufe N, mit den Meistern
-- der eigenen Fraktion.
function TR.WeaponState(state)
    state = state or PlayerState()
    local out = {}
    if not state.class then return out end
    for _, w in ipairs(T.Weapons(state.class)) do
        local key
        if TR.Known(w.id) then
            key = "known"
        elseif state.level and w.level > state.level then
            key = "later"
        else
            key = "now"
        end
        out[#out + 1] = { id = w.id, level = w.level, cost = w.cost, key = key,
                          masters = state.faction and T.MastersFor(w.id, state.faction) or {} }
    end
    -- Lernbare zuerst, Gelerntes zuletzt; innerhalb in der Reihenfolge der Vorlage.
    local rank = { now = 1, later = 2, known = 3 }
    table.sort(out, function(a, b)
        if rank[a.key] ~= rank[b.key] then return rank[a.key] < rank[b.key] end
        return (T.WEAPONS[a.id].order or 99) < (T.WEAPONS[b.id].order or 99)
    end)
    return out
end

-- "1 G 20 S 5 K" - kurz, weil es in einer Zeile rechts steht.
function TR.Money(copper)
    if type(copper) ~= "number" then return "—" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. " G" end
    if s > 0 then parts[#parts + 1] = s .. " S" end
    if c > 0 or #parts == 0 then parts[#parts + 1] = c .. " K" end
    return table.concat(parts, " ")
end

--------------------------------------------------
-- Seite
--------------------------------------------------
-- Zwei Karten: links die Zauber, nach Faechern, rechts die Waffen-
-- fertigkeiten mit ihren Meistern. Beide rollen; alles andere steht
-- still. Der Detailbereich fasst zusammen und nennt die Herkunft.

local page
local rows = {}
local showKnown = false
local ROW_H, HEAD_H, LEVEL_H = 26, 30, 20

local function ClearRows()
    for _, r in ipairs(rows) do r:Hide() end
    wipe(rows)
end

local function Keep(r) rows[#rows + 1] = r return r end

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    local PAD_X, PAD_Y, GAP = WeintCodex.Metrics.PAD_X, WeintCodex.Metrics.PAD_Y, WeintCodex.Metrics.GAP

    f.Head = WeintCodex.PageHead(f, {
        eyebrow = "Charakter",
        title   = "Lehrer",
        sub     = "Was dir dein Klassenlehrer beibringt, was es kostet – und wo du Waffen lernst.",
        height  = 84,
    })

    local spellCard = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    spellCard:SetPoint("TOPLEFT",    f, "TOPLEFT",    PAD_X, -(PAD_Y + 84))
    spellCard:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD_X, PAD_Y)
    spellCard:SetWidth(460)
    f.SpellCard = spellCard
    local st = WeintCodex.Label(spellCard, "Zauber", { size = 14, color = "textBright", font = WeintCodex.Fonts.sansSemi })
    st:SetPoint("TOPLEFT", spellCard, "TOPLEFT", 20, -16)
    f.KnownButton = WeintCodex.CreateButton(spellCard, { kind = "ghost", text = "Gelernte zeigen", height = 24,
        size = 11, padding = 20, radius = 0, onClick = function()
            showKnown = not showKnown
            TR.Show()
        end })
    f.KnownButton:SetPoint("TOPRIGHT", spellCard, "TOPRIGHT", -16, -12)
    f.SpellScroll, f.SpellBody = WeintCodex.CreateScrollArea(spellCard, 20, -46, 420, 300, true)

    local weaponCard = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    weaponCard:SetPoint("TOPLEFT",     spellCard, "TOPRIGHT", GAP, 0)
    weaponCard:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X, PAD_Y)
    f.WeaponCard = weaponCard
    local wt = WeintCodex.Label(weaponCard, "Waffenfertigkeiten", { size = 14, color = "textBright", font = WeintCodex.Fonts.sansSemi })
    wt:SetPoint("TOPLEFT", weaponCard, "TOPLEFT", 20, -16)
    f.WeaponScroll, f.WeaponBody = WeintCodex.CreateScrollArea(weaponCard, 20, -46, 300, 260, true)

    page = f
    return f
end

local function SpellRow(body, y, w, sp, opts)
    local row = Keep(CreateFrame("Button", nil, body))
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    row:SetWidth(w)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(row)
    hl:SetColorTexture(C.textBright[1], C.textBright[2], C.textBright[3], 0.05)
    local name, sub, icon = TR.SpellInfo(sp.id)
    local ic = row:CreateTexture(nil, "ARTWORK")
    ic:SetSize(20, 20)
    ic:SetPoint("LEFT", row, "LEFT", 2, 0)
    ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if icon then ic:SetTexture(icon) else ic:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1) end
    if opts.dim then ic:SetDesaturated(true) end

    local cost = WeintCodex.Label(row, TR.Money(sp.cost), { size = 11, justify = "RIGHT",
        color = opts.costColor or "textMuted", font = WeintCodex.Fonts.mono })
    cost:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    local label = name or ("Zauber " .. sp.id)
    local nm = WeintCodex.Label(row, label, { size = 12, color = opts.dim and "textDim" or "textNormal",
        font = WeintCodex.Fonts.sansMedium })
    nm:SetPoint("LEFT", ic, "RIGHT", 8, sub and 6 or 0)
    nm:SetPoint("RIGHT", cost, "LEFT", -10, sub and 6 or 0)
    nm:SetWordWrap(false)
    if sub then
        local rk = WeintCodex.Label(row, sub, { size = 10, color = "textFaint" })
        rk:SetPoint("TOPLEFT", nm, "BOTTOMLEFT", 0, -1)
    end
    row.spellID = sp.id
    row:SetScript("OnEnter", function(self)
        local gt = _G.GameTooltip
        if not gt then return end
        gt:SetOwner(self, "ANCHOR_RIGHT")
        if gt.SetSpellByID then gt:SetSpellByID(self.spellID) else gt:SetText(label) end
        if opts.note then gt:AddLine(opts.note, C.textMuted[1], C.textMuted[2], C.textMuted[3], true) end
        gt:Show()
    end)
    row:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    row:SetScript("OnClick", function(self)
        local cs = _G.C_Spell
        if not (_G.IsModifiedClick and _G.IsModifiedClick("CHATLINK") and _G.ChatEdit_InsertLink) then return end
        local link = cs and cs.GetSpellLink and cs.GetSpellLink(self.spellID)
        if type(link) == "string" then _G.ChatEdit_InsertLink(link) end
    end)
    TR.drawnRows = (TR.drawnRows or 0) + 1
    return y - ROW_H
end

local SECTION_NOTE = {
    missing = "Erst die Vorstufe lernen – der Lehrer bietet diesen Rang sonst nicht an.",
    talent  = "Der Lehrer lehrt das erst, wenn du das Talent dazu hast.",
    pet     = "Lehrt der Tierausbilder deinem Begleiter. Ob er es schon kann, weiß nur der Tierausbilder.",
}

local function SectionHead(body, y, w, sec, count, cost)
    local head = Keep(CreateFrame("Frame", nil, body))
    head:SetHeight(HEAD_H)
    head:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    head:SetWidth(w)
    local eb = WeintCodex.Eyebrow(head, sec.label, { color = sec.color, size = 10 })
    eb:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 0, 8)
    local info = count .. (count == 1 and " Zauber" or " Zauber")
    if sec.key ~= "pet" and sec.key ~= "known" then info = info .. " · " .. TR.Money(cost) end
    local right = WeintCodex.Label(head, info, { size = 11, color = "textDim", justify = "RIGHT" })
    right:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", -4, 7)
    local line = head:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 0, 2)
    line:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", 0, 2)
    line:SetColorTexture(C.border[1], C.border[2], C.border[3], 1)
    return y - HEAD_H - 4
end

local function LevelHead(body, y, level)
    local fs = Keep(WeintCodex.Label(body, "Stufe " .. level, { size = 11, color = "textMuted",
        font = WeintCodex.Fonts.sansSemi }))
    fs:SetPoint("TOPLEFT", body, "TOPLEFT", 2, y - 4)
    return y - LEVEL_H
end

local function DrawSpells(body, w, cat, state)
    local y = 0
    local shown = 0
    for _, sec in ipairs(TR.SECTIONS) do
        local list = cat.sections[sec.key]
        if #list > 0 and (sec.key ~= "known" or showKnown) then
            shown = shown + 1
            y = SectionHead(body, y, w, sec, #list, cat.total[sec.key])
            if SECTION_NOTE[sec.key] then
                local fs, h = WeintCodex.Paragraph(body, SECTION_NOTE[sec.key], { width = w, size = 11, color = "textDim" })
                fs:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
                Keep(fs)
                y = y - h - 4
            end
            local lastLevel
            for _, sp in ipairs(list) do
                if sec.byLevel and sp.level ~= lastLevel then
                    y = LevelHead(body, y, sp.level)
                    lastLevel = sp.level
                end
                local costColor
                if sec.key == "now" and state.money and sp.cost > state.money then costColor = "dangerBright" end
                y = SpellRow(body, y, w, sp, { dim = sec.key == "known", costColor = costColor })
            end
            y = y - 10
        end
    end
    if shown == 0 then
        local text = state.class and "Für deine Klasse ist nichts hinterlegt." or "Deine Klasse meldet der Client gerade nicht."
        if (cat.sections.known and #cat.sections.known > 0) then
            text = "Du hast alles gelernt, was der Lehrer bis Stufe 60 lehrt."
        end
        local fs = Keep(WeintCodex.Label(body, text, { size = 12, color = "textMuted" }))
        fs:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -4)
        y = -30
    end
    body:SetHeight(math.max(1, -y))
end

local WEAPON_TAG = {
    now   = { "Lernbar", "successBright" },
    later = { nil, "textMuted" },
    known = { "Gelernt", "textDim" },
}

local function MasterRow(body, y, w, m, skillName)
    local row = Keep(CreateFrame("Frame", nil, body))
    row:SetHeight(22)
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 28, y)
    row:SetWidth(w - 28)
    local zone = WeintCodex.QuestMap and WeintCodex.QuestMap.MapName(m.map)
    local fs = WeintCodex.Label(row, m.name .. (zone and ("  ·  " .. zone) or ""), { size = 11, color = "textMuted" })
    fs:SetPoint("LEFT", row, "LEFT", 0, 0)
    local QM = WeintCodex.QuestMap
    if QM then
        local b = WeintCodex.CreateButton(row, { kind = "secondary", text = "Karte", height = 20, size = 10,
            padding = 18, radius = 0, onClick = function()
                QM.Show({ map = m.map, x = m.x / 100, y = m.y / 100, who = m.name }, nil, "Lehrt: " .. skillName)
            end })
        WeintCodex.DrawSlimBorder(b, "accentDim", 1, 1)
        b:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        TR.mapButtons = (TR.mapButtons or 0) + 1
    end
    return y - 24
end

local function DrawWeapons(body, w, list)
    local y = 0
    for _, wp in ipairs(list) do
        if wp.key ~= "known" or showKnown then
            local sp = { id = wp.id, cost = wp.cost, level = wp.level }
            local tag = WEAPON_TAG[wp.key]
            local label = tag[1] or ("ab Stufe " .. wp.level)
            local costColor = wp.key ~= "now" and "textFaint" or nil
            y = SpellRow(body, y, w, sp, { dim = wp.key == "known", costColor = costColor })
            local fs = Keep(WeintCodex.Label(body, label, { size = 10, color = tag[2], justify = "RIGHT" }))
            fs:SetPoint("TOPRIGHT", body, "TOPRIGHT", -80, y + ROW_H - 7)
            if wp.key ~= "known" then
                local skillName = TR.SpellInfo(wp.id) or ("Waffe " .. wp.id)
                if #wp.masters == 0 then
                    local n = Keep(WeintCodex.Label(body, "Kein Waffenmeister deiner Fraktion bekannt.", { size = 11, color = "textFaint" }))
                    n:SetPoint("TOPLEFT", body, "TOPLEFT", 28, y)
                    y = y - 20
                end
                for _, m in ipairs(wp.masters) do y = MasterRow(body, y, w, m, skillName) end
            end
            y = y - 8
        end
    end
    if y == 0 then
        local fs = Keep(WeintCodex.Label(body, "Alle Waffenfertigkeiten deiner Klasse sind gelernt.", { size = 12, color = "textMuted" }))
        fs:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -4)
        y = -30
    end
    body:SetHeight(math.max(1, -y))
end

local function InspectorBlocks(state, cat, weapons)
    local now = #cat.sections.now
    local wnow = 0
    for _, wp in ipairs(weapons) do if wp.key == "now" then wnow = wnow + 1 end end
    local afford = state.money and cat.total.now > 0 and state.money >= cat.total.now
    return {
        { type = "header", text = "Beim Lehrer" },
        { type = "rows", rows = {
            { label = "Klasse", value = state.className or "—" },
            { label = "Stufe", value = state.level and tostring(state.level) or "—" },
            { label = "Gold", value = TR.Money(state.money) },
            { label = "Jetzt lernbar", value = now .. " · " .. TR.Money(cat.total.now),
              valueColor = now > 0 and (afford and "successBright" or "warningBright") or "textFaint" },
            { label = "Nächste Stufen", value = tostring(#cat.sections.soon) },
            { label = "Waffen lernbar", value = tostring(wnow) },
        }},
        { type = "divider" },
        { type = "header", text = "Woher das stammt" },
        { type = "card", lines = {
            "Unbestätigt: Stufen, Kosten und Voraussetzungen stammen",
            "aus dem Addon „What's Training?“ (Forever-Fassung) und aus",
            "Beobachtung in der Beta – nicht von Blizzard.",
            "Ob du etwas schon kannst, sagt dein Client.",
            "Rufrabatte beim Lehrer sind nicht eingerechnet.",
        }},
    }
end

function TR.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
    local f = BuildPage()
    f:Show()
    WeintCodex.SetBreadcrumb("Charakter", "Lehrer")

    local state = PlayerState()
    local cat = TR.Categorize(state)
    local weapons = TR.WeaponState(state)
    if f.Head and f.Head.Title then
        f.Head.Title:SetText(state.className and ("Lehrer · " .. state.className) or "Lehrer")
    end
    f.KnownButton:SetText(showKnown and "Gelernte ausblenden" or ("Gelernte zeigen (" .. #cat.sections.known .. ")"))

    -- Breite teilen: die Zauber bekommen gut die Haelfte.
    local total = Plain(f:GetWidth())
    if type(total) == "number" and total > 400 then
        f.SpellCard:SetWidth(math.floor((total - 2 * WeintCodex.Metrics.PAD_X - WeintCodex.Metrics.GAP) * 0.56))
    end
    local sw = (Plain(f.SpellCard:GetWidth()) or 460) - 40
    local ww = (Plain(f.WeaponCard:GetWidth()) or 340) - 40
    local sh = (Plain(f.SpellCard:GetHeight()) or 360) - 62
    local wh = (Plain(f.WeaponCard:GetHeight()) or 360) - 62
    f.SpellScroll:SetSize(sw, math.max(60, sh))
    f.SpellBody:SetWidth(sw - 10)
    f.WeaponScroll:SetSize(ww, math.max(60, wh))
    f.WeaponBody:SetWidth(ww - 10)

    ClearRows()
    wipe(pending)
    TR.drawnRows, TR.mapButtons = 0, 0
    DrawSpells(f.SpellBody, sw - 14, cat, state)
    DrawWeapons(f.WeaponBody, ww - 14, weapons)

    WeintCodex.Navigation.SetInspector(InspectorBlocks(state, cat, weapons))
end

function TR.ShowKnown(v) showKnown = v and true or false end
function TR.Page() return page end

--------------------------------------------------
-- Neu zeichnen, wenn sich etwas aendert
--------------------------------------------------
-- Nur bei offener Seite; mehrere Ereignisse kurz hintereinander (Stufen-
-- aufstieg lernt oft mehrere Raenge) fassen sich zu einem Neuzeichnen.

local redrawQueued = false
local function Redraw()
    if redrawQueued or not (page and page:IsShown()) then return end
    local main = WeintCodex.MainFrame
    if type(main) == "table" and main.IsShown and not main:IsShown() then return end
    redrawQueued = true
    local function run() redrawQueued = false if page and page:IsShown() then TR.Show() end end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.2, run) else run() end
end
TR.Redraw = Redraw

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LEVEL_UP", "LEARNED_SPELL_IN_SKILL_LINE", "SPELLS_CHANGED", "PLAYER_MONEY",
                     "SKILL_LINES_CHANGED", "SPELL_DATA_LOAD_RESULT" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, id)
    if event == "SPELL_DATA_LOAD_RESULT" and not pending[id] then return end
    Redraw()
end)
TR.events = ev
