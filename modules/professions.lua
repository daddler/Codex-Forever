--------------------------------------------------
-- WeintCodex :: Berufe - Rezepte nach deiner Fertigkeit, Lehrer auf der Karte
--------------------------------------------------
-- Seit 6.14.0.0, aus dem Abgleich mit dem Addon ForeverGuide: je Beruf,
-- was du jetzt lernen kannst, was dir noch Fertigkeit bringt, was neu in
-- Forever ist - und wo der naechste Lehrer steht.
--
-- ZWEI BESTAENDE, NIE VERMISCHT (wie beim Klassenlehrer):
--   * WAS es gibt (Rezepte, Stufen, Reagenzien, Lehrer) steht in
--     data/professions.lua und ist `community` - die Seite sagt das.
--   * WIE WEIT du bist und WAS du kannst, fragt die Seite den Client:
--     Fertigkeit ueber GetProfessions/GetProfessionInfo (sonst die
--     Fertigkeitsliste GetSkillLineInfo), gelernte Rezepte ueber dein
--     Berufsfenster (C_TradeSkillUI, sonst GetTradeSkillRecipeLink) - beim
--     Oeffnen gemerkt, je Charakter. Was der Client nicht beantwortet, wird
--     nicht geraten: ohne Blick ins Berufsfenster heisst "lernbar" "ab
--     deiner Fertigkeit, vielleicht schon gelernt", nie "fehlt".
--
-- Die Schwierigkeit (orange/gelb/gruen/grau) kommt aus den Stufen des
-- Rezepts und deiner Fertigkeit - dieselbe Regel wie im Berufsfenster.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Professions = {}

local PRO = WeintCodex.Professions
local P   = WeintCodex.ProfessionData
local C   = WeintCodex.Colors

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

--------------------------------------------------
-- Bestand
--------------------------------------------------

local byKey, byLine = {}, {}
for _, p in ipairs(P and P.PROFS or {}) do
    byKey[p.key] = p
    if p.line then byLine[p.line] = p.key end
end
PRO.byKey = byKey

-- Die Rezepte eines Berufs, gelesen erst beim ersten Blick (die Zeilen in
-- data/professions.lua kosten als Tabellen ein Vielfaches).
local parsed = {}
local bySpell   -- Zauber -> Beruf, fuer das Auslesen des Berufsfensters
local function Num(s) return s ~= "-" and tonumber(s) or nil end

function PRO.Recipes(key)
    if parsed[key] then return parsed[key] end
    local raw = P and P.RAW and P.RAW[key]
    local out = {}
    for line in (raw or ""):gmatch("[^\n]+") do
        local head, reag, name = line:match("^([^|]*)|([^|]*)|(.*)$")
        if head then
            local f = {}
            for w in head:gmatch("%S+") do f[#f + 1] = w end
            local r = {
                spell = Num(f[1]), item = Num(f[2]), learn = Num(f[3]),
                yellow = Num(f[4]), green = Num(f[5]), grey = Num(f[6]),
                state = f[7], trainer = f[8]:find("t", 1, true) ~= nil, bop = f[8]:find("b", 1, true) ~= nil,
                recipeItem = Num(f[9]), favor = Num(f[10]), name = name, reagents = {}, key = key,
            }
            for id, n in reag:gmatch("(%d+):(%d+)") do
                r.reagents[#r.reagents + 1] = { tonumber(id), tonumber(n) }
            end
            if r.spell then out[#out + 1] = r end
        end
    end
    parsed[key] = out
    return out
end

local function SpellIndex()
    if bySpell then return bySpell end
    bySpell = {}
    for _, p in ipairs(P and P.PROFS or {}) do
        for _, r in ipairs(PRO.Recipes(p.key)) do bySpell[r.spell] = p.key end
    end
    return bySpell
end
PRO.SpellIndex = SpellIndex

-- Name eines Berufs: der Client (Zauber des Berufs), sonst Deutsch aus dem Bestand.
function PRO.ProfName(key)
    local p = byKey[key]
    if not p then return key end
    local cs = _G.C_Spell
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, p.spell)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
    end
    return p.name
end

--------------------------------------------------
-- Client: Fertigkeit
--------------------------------------------------

-- { [key] = { rank, max } } und ob der Client ueberhaupt geantwortet hat.
function PRO.Skills()
    local out, answered = {}, false
    local GP, GPI = _G.GetProfessions, _G.GetProfessionInfo
    if type(GP) == "function" and type(GPI) == "function" then
        local res = { pcall(GP) }
        if res[1] then
            answered = true
            -- Sechs Plaetze (Haupt 1, Haupt 2, Archaeologie, Angeln, Kochen,
            -- Erste Hilfe) MIT Luecken - ipairs braeche an der ersten ab.
            for i = 2, 7 do
                local idx = Plain(res[i])
                if type(idx) == "number" then
                    local ok2, name, _, rank, max, _, _, line = pcall(GPI, idx)
                    rank, max, line = Plain(rank), Plain(max), Plain(line)
                    local key = ok2 and (byLine[line] or PRO.KeyByName(Plain(name))) or nil
                    if key and type(rank) == "number" then out[key] = { rank = rank, max = type(max) == "number" and max or nil } end
                end
            end
        end
    end
    if not answered and type(_G.GetNumSkillLines) == "function" and type(_G.GetSkillLineInfo) == "function" then
        local ok, n = pcall(_G.GetNumSkillLines)
        n = ok and Plain(n) or nil
        if type(n) == "number" then
            answered = true
            for i = 1, n do
                local ok2, name, isHeader, _, rank, _, _, max = pcall(_G.GetSkillLineInfo, i)
                local key = ok2 and not Plain(isHeader) and PRO.KeyByName(Plain(name)) or nil
                rank, max = Plain(rank), Plain(max)
                if key and type(rank) == "number" then out[key] = { rank = rank, max = type(max) == "number" and max or nil } end
            end
        end
    end
    return out, answered
end

-- Beruf zu einem Namen des Clients: Name des Berufszaubers, sonst Deutsch.
function PRO.KeyByName(name)
    if type(name) ~= "string" then return nil end
    for _, p in ipairs(P and P.PROFS or {}) do
        if name == PRO.ProfName(p.key) or name == p.name then return p.key end
    end
    return nil
end

--------------------------------------------------
-- Client: gelernte Rezepte (aus dem Berufsfenster gemerkt)
--------------------------------------------------

local function CharKey()
    local n = _G.UnitName and Plain(_G.UnitName("player"))
    local r = _G.GetRealmName and Plain(_G.GetRealmName())
    if type(n) ~= "string" then return nil end
    return n .. "-" .. (type(r) == "string" and r or "")
end

-- Der Speicher dieses Charakters: { known = { [Zauber] = true }, scanned = { [Beruf] = Zeit } }.
function PRO.Memory()
    local sd = WeintCodex.SavedData
    local who = CharKey()
    if type(sd) ~= "table" or not who then return nil end
    sd.professions = sd.professions or {}
    local m = sd.professions[who]
    if not m then
        m = { known = {}, scanned = {} }
        sd.professions[who] = m
    end
    m.known, m.scanned = m.known or {}, m.scanned or {}
    return m
end

local function Now() return (_G.time and _G.time()) or 0 end

-- Liest das offene Berufsfenster aus. Liefert, wie viele Rezepte erkannt
-- wurden (fuer die Selbstpruefung und den Prueflauf).
function PRO.Scan()
    local m = PRO.Memory()
    if not m then return 0 end
    local index = SpellIndex()
    local seen, count = {}, 0
    local function mark(id, learned)
        id = Plain(id)
        local key = type(id) == "number" and index[id] or nil
        if not key then return end
        seen[key] = true
        if learned then
            m.known[id] = true
            count = count + 1
        else
            m.known[id] = nil
        end
    end
    local ts = _G.C_TradeSkillUI
    if type(ts) == "table" and type(ts.GetAllRecipeIDs) == "function" and type(ts.GetRecipeInfo) == "function" then
        local ok, ids = pcall(ts.GetAllRecipeIDs)
        if ok and type(ids) == "table" then
            for _, id in ipairs(ids) do
                local ok2, info = pcall(ts.GetRecipeInfo, id)
                if ok2 and type(info) == "table" then mark(id, Plain(info.learned) == true) end
            end
        end
    end
    -- Klassische Fenster: die Liste zeigt nur Gelerntes.
    local function classic(numFn, linkFn)
        if type(numFn) ~= "function" or type(linkFn) ~= "function" then return end
        local ok, n = pcall(numFn)
        n = ok and Plain(n) or nil
        for i = 1, (type(n) == "number" and n or 0) do
            local ok2, link = pcall(linkFn, i)
            link = ok2 and Plain(link) or nil
            local id = type(link) == "string" and tonumber(link:match("enchant:(%d+)") or link:match("spell:(%d+)"))
            if id then mark(id, true) end
        end
    end
    classic(_G.GetNumTradeSkills, _G.GetTradeSkillRecipeLink)
    classic(_G.GetNumCrafts, _G.GetCraftRecipeLink)
    for key in pairs(seen) do m.scanned[key] = Now() end
    PRO.lastScan = { count = count, professions = seen }
    return count
end

-- true: gelernt, false: sicher nicht (das Berufsfenster war offen), nil: weiss nicht.
-- Nach einem Blick ins Berufsfenster gilt der Speicher allein (neu Gelerntes
-- traegt NEW_RECIPE_LEARNED nach); vorher fragt die Seite den Client - der
-- sagt nur "ja" sicher.
function PRO.Learned(r, m)
    m = m or PRO.Memory()
    if m and m.known[r.spell] then return true end
    if m and m.scanned[r.key] then return false end
    local TR = WeintCodex.Trainer
    if TR and TR.Known and TR.Known(r.spell) then return true end
    return nil
end

-- Wann das Berufsfenster dieses Berufs zuletzt gelesen wurde (oder nil).
function PRO.ScannedAt(key)
    local m = PRO.Memory()
    return m and m.scanned[key] or nil
end

--------------------------------------------------
-- Einordnen
--------------------------------------------------

-- Farbe eines Rezepts bei dieser Fertigkeit, wie im Berufsfenster.
function PRO.Difficulty(r, skill)
    if type(skill) ~= "number" then return nil end
    if r.learn and skill < r.learn then return "unavailable" end
    if r.yellow and skill < r.yellow then return "orange" end
    if r.green and skill < r.green then return "yellow" end
    if r.grey and skill < r.grey then return "green" end
    return "grey"
end

PRO.SOON = 25   -- "bald": bis 25 Punkte ueber deiner Fertigkeit

PRO.SECTIONS = {
    { key = "now",     label = "Beim Lehrer lernbar",       color = "successBright" },
    { key = "recipe",  label = "Als Rezept lernbar",        color = "successBright" },
    { key = "skillup", label = "Bringt noch Fertigkeit",    color = "infoBright" },
    { key = "soon",    label = "Bald",                      color = "infoBright" },
    { key = "later",   label = "Später",                    color = "textMuted", collapsible = true },
    { key = "unknown", label = "Lernstufe unbekannt",       color = "textMuted", collapsible = true },
    { key = "known",   label = "Gelernt, bringt nichts mehr", color = "textDim", collapsible = true },
}
-- Ohne Fertigkeit (Beruf nicht gelernt oder vom Client nicht genannt):
-- nach den Raengen, wie die Lehrer sie lehren.
PRO.RANKS = {
    { key = "r1", label = "Lehrling · bis 75",   upto = 74 },
    { key = "r2", label = "Geselle · bis 150",   upto = 149 },
    { key = "r3", label = "Experte · bis 225",   upto = 224 },
    { key = "r4", label = "Fachmann · bis 300",  upto = 9999 },
    { key = "unknown", label = "Lernstufe unbekannt" },
}

-- Ordnet die Rezepte eines Berufs. `skill` nil: nach Raengen.
function PRO.Categorize(key, skill)
    local out = { sections = {}, byRank = skill == nil, learnedKnown = PRO.ScannedAt(key) ~= nil }
    local mem = PRO.Memory()
    local defs = skill and PRO.SECTIONS or PRO.RANKS
    for _, s in ipairs(defs) do out.sections[s.key] = {} end
    for _, r in ipairs(PRO.Recipes(key)) do
        local sec
        if not skill then
            if not r.learn then
                sec = "unknown"
            else
                for _, rk in ipairs(PRO.RANKS) do
                    if rk.upto and r.learn <= rk.upto then sec = rk.key break end
                end
            end
        else
            -- Gelernt sein kann nur, was die Fertigkeit schon erlaubt.
            local learned = (not r.learn or r.learn <= skill) and PRO.Learned(r, mem) or nil
            if learned then
                sec = (r.grey and skill < r.grey) and "skillup" or "known"
            elseif not r.learn then
                sec = "unknown"
            elseif r.learn <= skill then
                sec = r.trainer and "now" or "recipe"
            elseif r.learn <= skill + PRO.SOON then
                sec = "soon"
            else
                sec = "later"
            end
        end
        table.insert(out.sections[sec], r)
    end
    return out
end

-- Zahlen fuer Startseite und Detailbereich: { now, recipe, skillup } - nur,
-- wenn das Gelernte bekannt ist (sonst waere "lernbar" geraten).
function PRO.Summary(key, skill)
    if type(skill) ~= "number" then return nil end
    local cat = PRO.Categorize(key, skill)
    return { now = #cat.sections.now, recipe = #cat.sections.recipe, skillup = #cat.sections.skillup,
             soon = #cat.sections.soon, sure = cat.learnedKnown }
end

-- Lehrer eines Berufs fuer eine Fraktion; der deinen naechsten Rang lehrt zuerst.
PRO.RANK_TEXT = { [1] = "Lehrling · bis 75", [2] = "Geselle · bis 150", [3] = "Experte · bis 225", [4] = "Fachmann · bis 300" }
local CAP_RANK = { [75] = 1, [150] = 2, [225] = 3, [300] = 4 }

function PRO.Trainers(key, faction, max)
    local need = max and CAP_RANK[max] and (CAP_RANK[max] + 1) or nil
    local here
    local cm = _G.C_Map
    if cm and cm.GetBestMapForUnit then
        local ok, m = pcall(cm.GetBestMapForUnit, "player")
        here = ok and Plain(m) or nil
    end
    local out = {}
    for _, t in ipairs(P and P.TRAINERS and P.TRAINERS[key] or {}) do
        local fr = t[6]
        if not faction or not fr or fr == faction then
            out[#out + 1] = { id = t[1], name = t[2], map = t[3], x = t[4], y = t[5], faction = fr, rank = t[7],
                              next = need ~= nil and t[7] >= need, here = here ~= nil and t[3] == here }
        end
    end
    table.sort(out, function(a, b)
        if a.next ~= b.next then return a.next end
        if a.here ~= b.here then return a.here end
        if a.rank ~= b.rank then return a.rank > b.rank end
        return a.name < b.name
    end)
    return out, need
end

--------------------------------------------------
-- Namen
--------------------------------------------------

local pending = {}
PRO.pending = pending

function PRO.RecipeName(r)
    local cs = _G.C_Spell
    if cs and cs.GetSpellName then
        local ok, n = pcall(cs.GetSpellName, r.spell)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
        pending[r.spell] = true
        if cs.RequestLoadSpellData then pcall(cs.RequestLoadSpellData, r.spell) end
    end
    return r.name
end

function PRO.ItemName(id)
    local ci = _G.C_Item
    local info = (ci and ci.GetItemInfo) or _G.GetItemInfo
    if info then
        local ok, n = pcall(info, id)
        n = ok and Plain(n) or nil
        if type(n) == "string" and n ~= "" then return n end
        if ci and ci.RequestLoadItemDataByID then pcall(ci.RequestLoadItemDataByID, id) end
    end
    return (P and P.NAMES and P.NAMES[id]) or ("Gegenstand " .. id)
end

local function Icon(r)
    local ci = _G.C_Item
    if r.item and ci and ci.GetItemIconByID then
        local ok, t = pcall(ci.GetItemIconByID, r.item)
        t = ok and Plain(t) or nil
        if t then return t end
    end
    local cs = _G.C_Spell
    if cs and cs.GetSpellTexture then
        local ok, t = pcall(cs.GetSpellTexture, r.spell)
        t = ok and Plain(t) or nil
        if t then return t end
    end
    return nil
end

-- "75 · 95 · 115 · 135" in den Farben des Berufsfensters.
function PRO.StepsText(r)
    local parts = {}
    local function add(v, tone) if v then parts[#parts + 1] = WeintCodex.ColorText(tone, tostring(v)) end end
    add(r.learn, "skillOrange")
    add(r.yellow, "skillYellow")
    add(r.green, "skillGreen")
    add(r.grey, "skillGrey")
    return table.concat(parts, " ")
end

--------------------------------------------------
-- Seite
--------------------------------------------------
-- Links die Berufe (deine zuerst), in der Mitte die Rezepte nach Faechern,
-- rechts die Lehrer. Rezepte und Lehrer rollen; alles andere steht still.
-- Zeilen werden wiederverwendet (500 Rezepte der Lederverarbeitung waeren
-- sonst bei jedem Aufschlagen 500 neue Rahmen).

local page
local selected
local showAll = false
local ROW_H, HEAD_H = 26, 30
local rowPool, headPool, notePool, trainerPool = {}, {}, {}, {}
local used = { row = 0, head = 0, note = 0, trainer = 0 }

local function ResetPools()
    for _, pool in ipairs({ rowPool, headPool, notePool, trainerPool }) do
        for _, f in ipairs(pool) do f:Hide() end
    end
    used.row, used.head, used.note, used.trainer = 0, 0, 0, 0
end

local function BuildPage()
    if page then return page end
    local cp = WeintCodex.ContentPanel
    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    local PAD_X, PAD_Y, GAP = WeintCodex.Metrics.PAD_X, WeintCodex.Metrics.PAD_Y, WeintCodex.Metrics.GAP
    f.Head = WeintCodex.PageHead(f, {
        eyebrow = "Leveln",
        title   = "Berufe",
        sub     = "Was du jetzt lernen kannst, was dir noch Fertigkeit bringt – und wo der nächste Lehrer steht.",
        height  = 84,
    })
    local rc = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    rc:SetPoint("TOPLEFT",    f, "TOPLEFT",    PAD_X, -(PAD_Y + 84))
    rc:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD_X, PAD_Y)
    rc:SetWidth(460)
    f.RecipeCard = rc
    f.RecipeTitle = WeintCodex.Label(rc, "Rezepte", { size = 14, color = "textBright", font = WeintCodex.Fonts.sansSemi })
    f.RecipeTitle:SetPoint("TOPLEFT", rc, "TOPLEFT", 20, -16)
    f.AllButton = WeintCodex.CreateButton(rc, { kind = "ghost", text = "Alle zeigen", height = 24,
        size = 11, padding = 20, radius = 0, onClick = function()
            showAll = not showAll
            PRO.Show()
        end })
    f.AllButton:SetPoint("TOPRIGHT", rc, "TOPRIGHT", -16, -12)
    f.RecipeScroll, f.RecipeBody = WeintCodex.CreateScrollArea(rc, 20, -46, 420, 300, true)

    local tc = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark" })
    tc:SetPoint("TOPLEFT",     rc, "TOPRIGHT", GAP, 0)
    tc:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X, PAD_Y)
    f.TrainerCard = tc
    local tt = WeintCodex.Label(tc, "Lehrer", { size = 14, color = "textBright", font = WeintCodex.Fonts.sansSemi })
    tt:SetPoint("TOPLEFT", tc, "TOPLEFT", 20, -16)
    f.TrainerScroll, f.TrainerBody = WeintCodex.CreateScrollArea(tc, 20, -46, 260, 260, true)

    f:SetScript("OnSizeChanged", function(self, width)
        width = Plain(width)
        if self:IsShown() and type(width) == "number" and type(self.drawnWidth) == "number"
           and math.abs(width - self.drawnWidth) > 2 then
            PRO.Redraw()
        end
    end)
    page = f
    return f
end

local function Tooltip(row)
    local gt = _G.GameTooltip
    local r = row.recipe
    if not (gt and r) then return end
    gt:SetOwner(row, "ANCHOR_RIGHT")
    local tb = C.textBright
    gt:SetText(PRO.RecipeName(r), tb[1], tb[2], tb[3])
    local function line(text, tone)
        local c = C[tone or "textNormal"] or C.textNormal
        gt:AddLine(text, c[1], c[2], c[3], true)
    end
    if r.state == "n" then line("Neu in Forever", "infoBright")
    elseif r.state == "c" then line("In Forever geändert", "textMuted") end
    local steps = PRO.StepsText(r)
    if steps ~= "" then line("Fertigkeit: " .. steps, "textMuted") end
    if #r.reagents > 0 then
        line("Reagenzien:", "textMuted")
        for _, e in ipairs(r.reagents) do line("  " .. e[2] .. "× " .. PRO.ItemName(e[1]), "textNormal") end
    end
    if r.trainer then
        line("Herkunft: beim Lehrer", "textMuted")
    elseif r.recipeItem then
        line("Herkunft: Rezept „" .. PRO.ItemName(r.recipeItem) .. "“" .. (r.bop and " (beim Aufheben gebunden)" or ""), "textMuted")
        local QM = WeintCodex.QuestMap
        for _, npc in ipairs(P.VENDORS[r.recipeItem] or {}) do
            local v = P.VENDOR_NPC[npc]
            if v then
                local zone = v[2] and QM and QM.MapName(v[2])
                line("  Händler: " .. v[1] .. (zone and (", " .. zone) or "") .. " (aus Classic)", "textDim")
            end
        end
        if r.favor then line("  Für " .. r.favor .. " Händlergunst", "textDim") end
    else
        line("Herkunft unbekannt", "textDim")
    end
    gt:Show()
end

local function RecipeRow(body, y, w, r, opts)
    used.row = used.row + 1
    local row = rowPool[used.row]
    if not row then
        row = CreateFrame("Button", nil, body)
        row:SetHeight(ROW_H)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(row)
        hl:SetColorTexture(C.textBright[1], C.textBright[2], C.textBright[3], 0.05)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.steps = WeintCodex.Label(row, "", { size = 11, justify = "RIGHT", font = WeintCodex.Fonts.mono })
        row.steps:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.tag = WeintCodex.Label(row, "", { size = 10, justify = "RIGHT" })
        row.tag:SetPoint("RIGHT", row.steps, "LEFT", -10, 0)
        row.name = WeintCodex.Label(row, "", { size = 12, font = WeintCodex.Fonts.sansMedium })
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.name:SetPoint("RIGHT", row.tag, "LEFT", -8, 0)
        row.name:SetWordWrap(false)
        row:SetScript("OnEnter", Tooltip)
        row:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
        row:SetScript("OnClick", function(self)
            if not (_G.IsModifiedClick and _G.IsModifiedClick("CHATLINK") and _G.ChatEdit_InsertLink) then return end
            local cs = _G.C_Spell
            local link = cs and cs.GetSpellLink and cs.GetSpellLink(self.recipe.spell)
            if type(link) == "string" then _G.ChatEdit_InsertLink(link) end
        end)
        rowPool[used.row] = row
    end
    row:SetParent(body)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    row:SetWidth(w)
    row.recipe = r
    local icon = Icon(r)
    if icon then row.icon:SetTexture(icon) else row.icon:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1) end
    if row.icon.SetDesaturated then row.icon:SetDesaturated(opts.dim and true or false) end
    row.name:SetText(PRO.RecipeName(r))
    local tone = opts.tone or (opts.dim and "textDim" or "textNormal")
    local c = C[tone] or C.textNormal
    row.name:SetTextColor(c[1], c[2], c[3])
    row.steps:SetText(PRO.StepsText(r))
    if r.state == "n" then
        row.tag:SetText("Neu")
        row.tag:SetTextColor(C.infoBright[1], C.infoBright[2], C.infoBright[3])
    elseif r.state == "c" then
        row.tag:SetText("Geändert")
        row.tag:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
    else
        row.tag:SetText("")
    end
    row:Show()
    return y - ROW_H
end

local function SectionHead(body, y, w, label, color, count, note)
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
    head.eb:SetText(WeintCodex.Spaced and WeintCodex.Spaced(WeintCodex.Upper(label)) or label)
    local c = C[color] or C.textMuted
    head.eb:SetTextColor(c[1], c[2], c[3])
    head.right:SetText(count == 1 and "1 Rezept" or (count .. " Rezepte"))
    head:Show()
    y = y - HEAD_H - 4
    if note then
        used.note = used.note + 1
        local fs = notePool[used.note]
        if not fs then
            -- Ein Absatz wie WeintCodex.Paragraph, aber wiederverwendet.
            fs = WeintCodex.Paragraph(body, "", { size = 11, color = "textDim" })
            notePool[used.note] = fs
        end
        fs:SetParent(body)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
        fs:SetWidth(w)
        fs:SetText(note)
        -- Hoehe geschaetzt wie in Paragraph (Groesse 11, Abstand 3), nie vom Client gelesen.
        local h = WeintCodex.EstimateLines(note, math.floor(w / (11 * 0.60))) * (11 + 3)
        fs:SetHeight(h)
        fs:Show()
        y = y - h - 6
    end
    return y
end

local TONE = { orange = "skillOrange", yellow = "skillYellow", green = "skillGreen", grey = "textDim" }

-- Hinweise je Fach; der erste nur, solange das Gelernte unbekannt ist.
local NOTE_UNSURE = "Ob du ein Rezept schon kannst, weiß WeintCodex erst, wenn du einmal dein Berufsfenster öffnest – bis dahin heißt „lernbar“: ab deiner Fertigkeit."
PRO.NOTE_UNSURE = NOTE_UNSURE

local function DrawRecipes(body, w, skill, cat)
    local y, shown, hidden = 0, 0, 0
    local defs = skill and PRO.SECTIONS or PRO.RANKS
    for i, sec in ipairs(defs) do
        local list = cat.sections[sec.key]
        -- Ohne Fertigkeit: der erste Rang offen, die anderen nur mit "Alle zeigen".
        local collapsed = (sec.collapsible or (not skill and i > 1)) and not showAll
        if #list > 0 then
            if collapsed then
                hidden = hidden + #list
            else
                shown = shown + 1
                local note
                if skill and not cat.learnedKnown and (sec.key == "now" or sec.key == "recipe") then note = NOTE_UNSURE end
                y = SectionHead(body, y, w, sec.label, sec.color, #list, note)
                for _, r in ipairs(list) do
                    local d = skill and PRO.Difficulty(r, skill)
                    y = RecipeRow(body, y, w, r, { tone = d and TONE[d], dim = sec.key == "known" })
                end
                y = y - 10
            end
        end
    end
    if shown == 0 then
        local text = hidden > 0 and "Alles Weitere steht unter „Alle zeigen“." or "Für diesen Beruf ist nichts hinterlegt."
        y = SectionHead(body, y, w, "Rezepte", "textMuted", 0, text)
    end
    body:SetHeight(math.max(1, -y))
    return cat, hidden
end

local function TrainerRow(body, y, w, t, profName)
    used.trainer = used.trainer + 1
    local row = trainerPool[used.trainer]
    if not row then
        row = CreateFrame("Frame", nil, body)
        row:SetHeight(40)
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
                local tt = row.trainer
                local QM = WeintCodex.QuestMap
                if tt and tt.map and QM then
                    QM.Show({ map = tt.map, x = tt.x / 100, y = tt.y / 100, who = tt.name }, nil, "Lehrt: " .. (row.prof or ""))
                end
            end })
        WeintCodex.DrawSlimBorder(row.map, "accentDim", 1, 1)
        row.map:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        trainerPool[used.trainer] = row
    end
    row:SetParent(body)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    row:SetWidth(w)
    row.trainer, row.prof = t, profName
    row.name:SetText(t.name)
    local c = t.next and C.successBright or C.textNormal
    row.name:SetTextColor(c[1], c[2], c[3])
    local QM = WeintCodex.QuestMap
    local zone = t.map and QM and QM.MapName(t.map)
    local parts = { PRO.RANK_TEXT[t.rank] or "" }
    if zone then parts[#parts + 1] = zone elseif not t.map then parts[#parts + 1] = "Lage unbekannt" end
    row.map:SetShown(t.map ~= nil)
    if t.next then parts[#parts + 1] = "dein nächster Rang" end
    row.sub:SetText(table.concat(parts, "  ·  "))
    row:Show()
    return y - 44
end

local function DrawTrainers(body, w, key, faction, max)
    local list, need = PRO.Trainers(key, faction, max)
    local y = 0
    local profName = PRO.ProfName(key)
    for _, t in ipairs(list) do y = TrainerRow(body, y, w, t, profName) end
    if #list == 0 then
        y = SectionHead(body, y, w, "Lehrer", "textMuted", 0,
            "Für diesen Beruf ist kein Lehrer deiner Fraktion hinterlegt.")
    end
    body:SetHeight(math.max(1, -y))
    return list, need
end

-- Die Liste links: deine Berufe zuerst (mit Fertigkeit), dann die anderen.
function PRO.SidebarItems(skills)
    local mine, others = {}, {}
    for _, p in ipairs(P and P.PROFS or {}) do
        local s = skills[p.key]
        if s then mine[#mine + 1] = p else others[#others + 1] = p end
    end
    local items, order = {}, {}
    local function add(p, status)
        items[#items + 1] = { label = PRO.ProfName(p.key), status = status, onClick = function()
            selected = p.key
            PRO.Show()
        end }
        order[#order + 1] = p.key
    end
    if #mine > 0 then
        items[#items + 1] = { label = "Deine Berufe", isGroup = true }
        for _, p in ipairs(mine) do
            local s = skills[p.key]
            add(p, { text = s.rank .. (s.max and (" / " .. s.max) or ""), color = "textMuted" })
        end
        items[#items + 1] = { label = "Weitere", isGroup = true }
    end
    for _, p in ipairs(others) do add(p, nil) end
    return items, order
end

local function Faction()
    local f = _G.UnitFactionGroup and Plain(_G.UnitFactionGroup("player"))
    return (f == "Alliance" or f == "Horde") and f or nil
end

local function InspectorBlocks(key, skill, cat)
    local total, new, changed = 0, 0, 0
    for _, r in ipairs(PRO.Recipes(key)) do
        total = total + 1
        if r.state == "n" then new = new + 1 elseif r.state == "c" then changed = changed + 1 end
    end
    local rows = {
        { label = "Beruf", value = PRO.ProfName(key) },
        { label = "Fertigkeit", value = skill and tostring(skill) or "nicht gelernt" },
        { label = "Rezepte", value = tostring(total) },
        { label = "Neu in Forever", value = tostring(new) },
        { label = "Geändert", value = tostring(changed) },
    }
    if skill then
        rows[#rows + 1] = { label = "Jetzt lernbar", value = tostring(#cat.sections.now + #cat.sections.recipe) }
        rows[#rows + 1] = { label = "Bringt Fertigkeit", value = cat.learnedKnown and tostring(#cat.sections.skillup) or "—" }
    end
    local at = PRO.ScannedAt(key)
    return {
        { type = "header", text = "Dein Beruf" },
        { type = "rows", rows = rows },
        { type = "divider" },
        { type = "header", text = "Was du schon kannst" },
        { type = "card", lines = at and {
            "Gelesen aus deinem Berufsfenster",
            (_G.date and _G.date("am %d.%m. um %H:%M", at)) or "",
            "Öffne es nach dem Lernen erneut.",
        } or {
            "Noch unbekannt: öffne einmal dein",
            "Berufsfenster, dann merkt sich WeintCodex,",
            "welche Rezepte du kannst.",
        }},
        { type = "divider" },
        { type = "header", text = "Woher das stammt" },
        { type = "card", lines = {
            "Unbestätigt: Rezepte, Stufen und Lehrer",
            "stammen aus dem Addon ForeverGuide",
            "(Rezepte aus dem Forever-Client, Lehrer aus",
            "der Questie-Datenbank) – nicht von Blizzard.",
            "Händler für Rezepte stammen aus Classic.",
            "Ohne „Season of Discovery“.",
        }},
    }
end

function PRO.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
    local skills = PRO.Skills()
    local items, order = PRO.SidebarItems(skills)
    if not (selected and byKey[selected]) then selected = order[1] end
    local nav = WeintCodex.Navigation
    nav.BuildSidebar("Berufe", items)
    for i, key in ipairs(order) do
        if key == selected and nav.SidebarButtons then
            local btn = nav.SidebarButtons()[i]
            if btn and btn.SetActive then btn:SetActive(true) end
        end
    end

    local f = BuildPage()
    f:Show()
    local name = PRO.ProfName(selected)
    WeintCodex.SetBreadcrumb("Berufe", name)
    local s = skills[selected]
    local skill = s and s.rank or nil
    if f.Head and f.Head.Title then f.Head.Title:SetText("Berufe · " .. name) end

    ResetPools()
    wipe(pending)
    -- Erst der Detailbereich, dann messen (wie beim Lehrer).
    local cat = PRO.Categorize(selected, skill)
    nav.SetInspector(InspectorBlocks(selected, skill, cat))

    local total = Plain(f:GetWidth())
    if type(total) == "number" and total > 400 then
        f.RecipeCard:SetWidth(math.floor((total - 2 * WeintCodex.Metrics.PAD_X - WeintCodex.Metrics.GAP) * 0.62))
    end
    local rw = (Plain(f.RecipeCard:GetWidth()) or 460) - 40
    local tw = (Plain(f.TrainerCard:GetWidth()) or 280) - 40
    local rh = (Plain(f.RecipeCard:GetHeight()) or 360) - 62
    local th = (Plain(f.TrainerCard:GetHeight()) or 360) - 62
    f.RecipeScroll:SetSize(rw, math.max(60, rh))
    f.RecipeBody:SetWidth(rw - 10)
    f.TrainerScroll:SetSize(tw, math.max(60, th))
    f.TrainerBody:SetWidth(tw - 10)

    local _, hidden = DrawRecipes(f.RecipeBody, rw - 14, skill, cat)
    DrawTrainers(f.TrainerBody, tw - 14, selected, Faction(), s and s.max)
    f.AllButton:SetText(showAll and "Weniger zeigen" or ("Alle zeigen" .. (hidden > 0 and (" (" .. hidden .. ")") or "")))
    f.AllButton:SetShown(showAll or hidden > 0)
    f.drawnWidth = total
    PRO.lastDraw = { key = selected, skill = skill, rows = used.row, trainers = used.trainer, hidden = hidden }
end

function PRO.Select(key) if byKey[key] then selected = key end end
function PRO.ShowAll(v) showAll = v and true or false end
function PRO.Page() return page end
function PRO.Selected() return selected end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local redrawQueued = false
local function Redraw()
    if redrawQueued or not (page and page:IsShown()) then return end
    local main = WeintCodex.MainFrame
    if type(main) == "table" and main.IsShown and not main:IsShown() then return end
    redrawQueued = true
    local function run() redrawQueued = false if page and page:IsShown() then PRO.Show() end end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0.2, run) else run() end
end
PRO.Redraw = Redraw

-- Das Berufsfenster liest sich hoechstens alle drei Sekunden aus (das Spiel
-- meldet beim Blaettern viele Aenderungen).
local scanQueued = false
local function QueueScan(delay)
    if scanQueued then return end
    scanQueued = true
    local function run() scanQueued = false PRO.Scan() Redraw() end
    if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(delay, run) else run() end
end
PRO.QueueScan = QueueScan

local ev = CreateFrame("Frame")
for _, e in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_UPDATE", "NEW_RECIPE_LEARNED",
                     "CRAFT_SHOW", "CRAFT_UPDATE", "SKILL_LINES_CHANGED", "SPELL_DATA_LOAD_RESULT",
                     "GET_ITEM_INFO_RECEIVED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, id)
    if event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" then QueueScan(0.3) return end
    if event == "NEW_RECIPE_LEARNED" then
        local m = PRO.Memory()
        id = Plain(id)
        if m and type(id) == "number" then m.known[id] = true end
    end
    if event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_UPDATE" or event == "CRAFT_UPDATE"
       or event == "NEW_RECIPE_LEARNED" then
        QueueScan(3)
        return
    end
    if event == "SPELL_DATA_LOAD_RESULT" and not pending[id] then return end
    Redraw()
end)
PRO.events = ev
