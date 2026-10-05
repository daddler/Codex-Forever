--------------------------------------------------
-- WeintCodex :: Startseite (6.11.0.0)
--------------------------------------------------
-- Die Uebersicht beantwortet EINE Frage: "Was mache ich als Naechstes?"
--
-- Forever ist ein neues Spiel - alle fangen bei Stufe 1 an. Die Seite
-- richtet sich danach: Leveln, Lehrer, Quests, Dungeons. Schlachtzug,
-- Anmeldung, Gildenbank und Companion stehen links in der Spalte, nicht
-- hier.
--
-- Aufbau von oben nach unten:
--   * Kopf: Stufe und Klasse, als Ueberschrift der wichtigste Schritt.
--   * "Als Naechstes": hoechstens drei Schritte, nach Dringlichkeit -
--     ein Satz, eine Einzelheit, ein Knopf.
--   * "Dein Weg": die naechsten Stufen, an denen etwas Neues kommt
--     (Zauber beim Lehrer, ein Dungeon oeffnet sich).
--
-- Bis 6.10.4.9 (core/navigation.lua) stand hier ein Armaturenbrett:
-- Datum, Erfahrungsleiste, drei gleich schwere Spalten, Companion-Zeile.
-- Beta-Test mit Stufe 3: "11 Dinge sind noch offen" - gemeint waren
-- leere Plaetze (Kopf, Hals, Umhang ...), die mit Stufe 3 jeder hat.
-- Leere Plaetze sind deshalb KEIN Schritt mehr; zerbrochene schon.
--
-- Getrennt in drei Teile, damit der Prueflauf die Auswahl ohne Zeichnen
-- pruefen kann:
--   HM.Context()   fragt Client und Bestaende (Lehrer, Quests, Dungeons)
--   HM.Steps(ctx)  waehlt die Schritte - rein, ohne Client
--   HM.Path(ctx)   die naechsten Meilensteine - rein, ohne Client
--
-- Was der Client nicht beantwortet, wird kein Schritt: ohne Stufe kein
-- Dungeon, ohne Gold kein "reicht" (CLAUDE.md, erste Regel).
--
-- Gezeichnet wird EINMAL gebaut und danach nur gefuellt - die alte Seite
-- legte bei jedem Oeffnen einen neuen Rahmen an.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Home = {}

local HM = WeintCodex.Home
local C  = WeintCodex.Colors

HM.MAX_STEPS = 3
HM.MAX_PATH  = 5
HM.ROW_H     = 68
HM.PATH_H    = 112
HM.LABEL_W   = 120       -- Spalte der Art ("Lehrer", "Quests") in einer Zeile

local function Plain(v)
    local K = WeintCodex.UIKit
    if K and K.Plain then return K.Plain(v) end
    return v
end

local function Can(featureKey)
    if not (WeintCodex.Access and WeintCodex.Access.Can) then return true end
    return WeintCodex.Access.Can(featureKey)
end

-- 12345 -> "12.345"
local function Thousands(n)
    local s = tostring(math.floor(n))
    local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
    return (out:gsub("^%.", ""))
end
HM.Thousands = Thousands

-- "1 G 20 S" -> "1g 20s": auf der Startseite steht Geld im Satz, nicht
-- rechts in einer Spalte.
local function Money(copper)
    local TR = WeintCodex.Trainer
    local s = TR and TR.Money and TR.Money(copper) or tostring(copper)
    return (s:gsub(" G", "g"):gsub(" S", "s"):gsub(" K", "k"))
end
HM.Money = Money

local function Plural(n, one, many)
    return n == 1 and one or (n .. " " .. many)
end

--------------------------------------------------
-- Fragen an Client und Bestaende
--------------------------------------------------

-- Was die Startseite vom Lehrer wissen will; nil, wenn der Client Klasse
-- oder Stufe nicht nennt.
function HM.Trainer()
    local TR = WeintCodex.Trainer
    if not (TR and TR.PlayerState and TR.Categorize) then return nil end
    local ok, state = pcall(TR.PlayerState)
    if not ok or not (state and state.class and state.level) then return nil end
    local cat = TR.Categorize(state)
    local weapons = TR.WeaponState and TR.WeaponState(state) or {}
    local budget = TR.Budget and TR.Budget(state, cat, weapons) or nil
    return { state = state, cat = cat, weapons = weapons, budget = budget }
end

-- Alle Instanzen mit Stufenbereich (Forever und klassische).
local function AllDungeons()
    local D = WeintCodex.DungeonData
    if not D then return {} end
    return (D.AllInstances and D.AllInstances()) or (D.All and D.All()) or {}
end

-- Dungeons fuer die eigene Stufe; passt keiner, der naechste darueber.
function HM.Dungeons(level)
    local D = WeintCodex.DungeonData
    if not (D and type(level) == "number") then return {}, nil end
    local fit, nextUp = {}, nil
    for _, d in ipairs(AllDungeons()) do
        if D.FitsLevel(d, level) then
            fit[#fit + 1] = d
        elseif type(d.minLevel) == "number" and d.minLevel > level
               and (not nextUp or d.minLevel < nextUp.minLevel) then
            nextUp = d
        end
    end
    return fit, nextUp
end

-- Dungeons, fuer die Quests im Questlog stehen. Gezaehlt wird nur, was
-- der Client beantwortet (DungeonPages.QuestState) - eine Quest ohne
-- Antwort ist nicht "nicht im Log".
function HM.DungeonQuests(faction)
    local J, DP = WeintCodex.DungeonJournal, WeintCodex.DungeonPages
    if not (J and J.Quests and DP and DP.QuestState) then return {} end
    local out = {}
    for _, d in ipairs(AllDungeons()) do
        local active, ready = 0, 0
        for _, q in ipairs(J.Quests(d.id, faction)) do
            local st = DP.QuestState(q)
            if st == "active" then active = active + 1
            elseif st == "ready" then ready = ready + 1 end
        end
        if active + ready > 0 then
            out[#out + 1] = { dungeon = d, active = active, ready = ready }
        end
    end
    table.sort(out, function(a, b)
        if a.ready ~= b.ready then return a.ready > b.ready end
        if a.active ~= b.active then return a.active > b.active end
        return (a.dungeon.minLevel or 0) < (b.dungeon.minLevel or 0)
    end)
    return out
end

function HM.Context()
    local ctx = { trainer = HM.Trainer() }
    local st = ctx.trainer and ctx.trainer.state
    ctx.level = st and st.level
    if type(ctx.level) ~= "number" then
        local ok, v = pcall(UnitLevel, "player")
        v = ok and Plain(v) or nil
        ctx.level = type(v) == "number" and v > 0 and v or nil
    end
    ctx.className = st and st.className
    if not ctx.className and UnitClass then
        local ok, n = pcall(UnitClass, "player")
        if ok and type(n) == "string" then ctx.className = n end
    end
    ctx.faction = st and st.faction
    if not ctx.faction and UnitFactionGroup then
        local ok, f = pcall(UnitFactionGroup, "player")
        if ok and (f == "Alliance" or f == "Horde") then ctx.faction = f end
    end
    if WeintCodex.Charakter and WeintCodex.Charakter.Snapshot then
        local ok, g = pcall(WeintCodex.Charakter.Snapshot)
        if ok then ctx.gear = g end
    end
    local XB = WeintCodex.UIXPBar
    ctx.quests = XB and XB.QuestXP and XB.QuestXP() or nil
    ctx.fit, ctx.nextUp = HM.Dungeons(ctx.level)
    ctx.dungeonQuests = HM.DungeonQuests(ctx.faction)
    ctx.dungeons = AllDungeons()
    return ctx
end

--------------------------------------------------
-- Die Schritte (rein)
--------------------------------------------------
-- Reihenfolge = Dringlichkeit:
--   1 Lehrer        Zauber, die man jetzt lernen kann
--   2 Quests        abgabebereit - Erfahrung, die schon verdient ist
--   3 Reparieren    ein zerbrochener Gegenstand wirkt nicht
--   4 Dungeon       Quests dafuer im Log
--   5 Waffen        Waffenfertigkeiten beim Waffenmeister
--   6 Dungeon       passt zur Stufe (nur ohne Schritt 4)
-- Hoechstens HM.MAX_STEPS. Ein Schritt: key, label, title, headline,
-- detail, tone (nil | "danger"), action (Knopftext), go (Ziel).

function HM.Steps(ctx)
    local steps = {}
    local function add(s)
        if #steps < HM.MAX_STEPS then steps[#steps + 1] = s end
    end
    ctx = ctx or {}

    local tr = ctx.trainer
    local now = tr and tr.cat and tr.cat.sections and tr.cat.sections.now or {}
    if #now > 0 then
        local b = tr.budget or {}
        local cost = "zusammen " .. Money(b.now or 0)
        local detail, tone
        if type(b.money) ~= "number" or type(b.rest) ~= "number" then
            detail = cost .. " · dein Gold ist unbekannt"
        elseif b.rest < 0 then
            detail, tone = cost .. " · es fehlen " .. Money(-b.rest), "danger"
        else
            detail = cost .. " · dein Gold reicht"
        end
        add({ key = "trainer", label = "Lehrer",
              title = Plural(#now, "Ein Zauber lernbar", "Zauber lernbar"),
              headline = #now == 1 and "Ein Zauber wartet beim Lehrer" or (#now .. " Zauber warten beim Lehrer"),
              detail = detail, tone = tone, action = "Zum Lehrer", go = { tab = "lehrer" } })
    end

    local q = ctx.quests
    if q and type(q.readyCount) == "number" and q.readyCount > 0 then
        local title = Plural(q.readyCount, "Eine Quest abgabebereit", "Quests abgabebereit")
        add({ key = "quests", label = "Quests", title = title, headline = title,
              detail = (type(q.ready) == "number" and q.ready > 0)
                  and ("zusammen " .. Thousands(q.ready) .. " EP – beim Questgeber abgeben")
                  or "beim Questgeber abgeben" })
    end

    local broken = ctx.gear and ctx.gear.broken or {}
    if #broken > 0 then
        local title = Plural(#broken, "Ein Gegenstand zerbrochen", "Gegenstände zerbrochen")
        add({ key = "repair", label = "Ausrüstung", title = title, headline = title,
              detail = table.concat(broken, ", ") .. " – beim Händler reparieren", tone = "danger",
              action = "Charakter", go = { tab = "charakter" } })
    end

    local D = WeintCodex.DungeonData
    local dq = ctx.dungeonQuests and ctx.dungeonQuests[1]
    if dq then
        local d = dq.dungeon
        local n = dq.active + dq.ready
        local parts = { Plural(n, "Eine Quest im Log", "Quests im Log") }
        if dq.ready > 0 then parts[#parts + 1] = dq.ready .. " abgabebereit" end
        if D and D.LevelRange then parts[#parts + 1] = "Stufe " .. D.LevelRange(d) end
        add({ key = "dungeonQuests", label = "Dungeon", title = d.name,
              headline = d.name .. ": " .. Plural(n, "eine Quest im Log", "Quests im Log"),
              detail = table.concat(parts, " · "), action = "Ansehen",
              go = { tab = "dungeons", dungeon = d.id } })
    end

    local b = tr and tr.budget
    if b and type(b.weaponCount) == "number" and b.weaponCount > 0 then
        local title = Plural(b.weaponCount, "Eine Waffenfertigkeit lernbar", "Waffenfertigkeiten lernbar")
        local cost = b.weapons or 0
        local detail = "beim Waffenmeister · zusammen " .. Money(cost)
        -- Ohne Ton: Waffen sind kein Muss, Rot waere Alarm (Beta-Test,
        -- Stufe 3: 1s 83k gegen 40s).
        if type(b.money) == "number" then
            detail = detail .. (b.money < cost and (" · es fehlen " .. Money(cost - b.money)) or " · dein Gold reicht")
        end
        add({ key = "weapons", label = "Waffen", title = title, headline = title,
              detail = detail, action = "Zum Lehrer", go = { tab = "lehrer" } })
    end

    local fit = ctx.fit or {}
    if not dq and #fit > 0 then
        local d = fit[1]
        local parts = {}
        if D and D.LevelRange then parts[#parts + 1] = "Stufe " .. D.LevelRange(d) end
        if D and D.ZoneLabel then
            local z = D.ZoneLabel(d)
            if type(z) == "string" and z ~= "" then parts[#parts + 1] = z end
        end
        if #fit > 1 then parts[#parts + 1] = Plural(#fit - 1, "ein weiterer passt", "weitere passen") end
        add({ key = "dungeonFit", label = "Dungeon", title = d.name,
              headline = d.name .. " passt zu deiner Stufe",
              detail = table.concat(parts, " · "), action = "Ansehen",
              go = { tab = "dungeons", dungeon = d.id } })
    end

    return steps
end

--------------------------------------------------
-- Dein Weg (rein)
--------------------------------------------------
-- Die naechsten Stufen, an denen etwas kommt: neue Zauber beim Lehrer
-- (ohne Talente und Tierausbildung - die haengen nicht an der Stufe) und
-- Dungeons, die sich oeffnen. Ohne Stufe kein Weg (nil).
-- Rueckgabe: { { level, spells, dungeons = { Namen } }, ... }, aufsteigend.

function HM.Path(ctx)
    ctx = ctx or {}
    local level = ctx.level
    if type(level) ~= "number" then return nil end
    local by, levels = {}, {}
    local function at(l)
        local m = by[l]
        if not m then
            m = { level = l, spells = 0, dungeons = {} }
            by[l] = m
            levels[#levels + 1] = l
        end
        return m
    end
    local tr = ctx.trainer
    local sections = tr and tr.cat and tr.cat.sections
    if sections then
        for _, key in ipairs({ "soon", "later" }) do
            for _, sp in ipairs(sections[key] or {}) do
                if type(sp.level) == "number" and sp.level > level then
                    local m = at(sp.level)
                    m.spells = m.spells + 1
                end
            end
        end
    end
    for _, d in ipairs(ctx.dungeons or {}) do
        if type(d.minLevel) == "number" and d.minLevel > level then
            local m = at(d.minLevel)
            m.dungeons[#m.dungeons + 1] = d.name
        end
    end
    table.sort(levels)
    local out = {}
    for i = 1, math.min(#levels, HM.MAX_PATH) do out[i] = by[levels[i]] end
    return out
end

-- Ueberschrift: der erste Schritt, sonst ein ehrlicher Zustand.
function HM.Headline(ctx, steps)
    if steps[1] then return steps[1].headline end
    if type(ctx.level) ~= "number" then return "Willkommen zurück" end
    return "Nichts offen – weiter leveln"
end

-- Zeile, wenn kein Schritt ansteht.
function HM.IdleDetail(ctx, path)
    if type(ctx.level) ~= "number" then
        return "Deine Stufe meldet der Client gerade nicht – ohne sie gibt es keine Empfehlung."
    end
    for _, m in ipairs(path or {}) do
        if m.spells > 0 then
            return "Der nächste Zauber kommt mit Stufe " .. m.level .. "."
        end
    end
    return "Beim Lehrer und in den Dungeons steht gerade nichts an."
end

--------------------------------------------------
-- Zeichnen
--------------------------------------------------

local page

local function Go(step)
    local go = step and step.go
    if not go then return end
    if go.dungeon and WeintCodex.DungeonPages and WeintCodex.DungeonPages.Select then
        WeintCodex.DungeonPages.Select(go.dungeon)
    end
    local nav = WeintCodex.Navigation
    if nav and nav.GoToTab then nav.GoToTab(go.tab) end
end
HM.Go = Go

local function SetColor(fs, name)
    local c = C[name] or C.textMuted
    fs:SetTextColor(c[1], c[2], c[3])
end

local function OneLine(fs)
    fs:SetJustifyH("LEFT")
    if fs.SetWordWrap then fs:SetWordWrap(false) end
end

local function BuildRow(card, i)
    local r = CreateFrame("Frame", nil, card)
    r:SetHeight(HM.ROW_H)
    r:SetPoint("TOPLEFT",  card, "TOPLEFT",  0, -(i - 1) * HM.ROW_H)
    r:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, -(i - 1) * HM.ROW_H)
    r.label = WeintCodex.Eyebrow(r, "", { size = 10, color = "accentBright" })
    r.label:SetPoint("LEFT", r, "LEFT", 24, 0)
    r.button = WeintCodex.CreateButton(r, {
        text = "", kind = i == 1 and "primary" or "secondary", height = 34, backdrop = "cardTop",
        onClick = function() Go(r.step) end,
    })
    r.button:SetPoint("RIGHT", r, "RIGHT", -20, 0)
    r.title = WeintCodex.Label(r, "", { font = WeintCodex.Fonts.sansSemi, size = 15, color = "textBright" })
    r.title:SetPoint("TOPLEFT", r, "TOPLEFT", 24 + HM.LABEL_W, -15)
    r.title:SetPoint("RIGHT", r.button, "LEFT", -20, 0)
    OneLine(r.title)
    r.detail = WeintCodex.Label(r, "", { size = 12, color = "textMuted" })
    r.detail:SetPoint("TOPLEFT", r.title, "BOTTOMLEFT", 0, -6)
    r.detail:SetPoint("RIGHT", r.button, "LEFT", -20, 0)
    OneLine(r.detail)
    if i > 1 then r.line = WeintCodex.RowLine(r, 0) end
    return r
end

local function BuildSlot(card, i)
    local s = CreateFrame("Frame", nil, card)
    s:SetHeight(HM.PATH_H)
    s.dot = card:CreateTexture(nil, "OVERLAY")
    s.dot:SetSize(9, 9)
    s.dot:SetPoint("TOPLEFT", s, "TOPLEFT", 0, -26)
    s.level = WeintCodex.Label(s, "", { font = WeintCodex.Fonts.sansSemi, size = 14, color = "textBright" })
    s.level:SetPoint("TOPLEFT", s, "TOPLEFT", 0, -46)
    s.level:SetPoint("RIGHT", s, "RIGHT", -12, 0)
    OneLine(s.level)
    s.line1 = WeintCodex.Label(s, "", { size = 12, color = "textMuted" })
    s.line1:SetPoint("TOPLEFT", s.level, "BOTTOMLEFT", 0, -6)
    s.line1:SetPoint("RIGHT", s, "RIGHT", -12, 0)
    OneLine(s.line1)
    s.line2 = WeintCodex.Label(s, "", { size = 12, color = "textMuted" })
    s.line2:SetPoint("TOPLEFT", s.line1, "BOTTOMLEFT", 0, -4)
    s.line2:SetPoint("RIGHT", s, "RIGHT", -12, 0)
    OneLine(s.line2)
    return s
end

local function Build()
    local M = WeintCodex.Metrics
    local f = CreateFrame("Frame", nil, WeintCodex.ContentPanel)
    f:SetAllPoints(WeintCodex.ContentPanel)

    f.eyebrow = WeintCodex.Eyebrow(f, "")
    f.eyebrow:SetPoint("TOPLEFT", f, "TOPLEFT", M.PAD_X, -M.PAD_Y)
    f.title = WeintCodex.PageTitle(f, "")
    f.title:SetPoint("TOPLEFT", f.eyebrow, "BOTTOMLEFT", 0, -6)
    f.title:SetPoint("RIGHT", f, "RIGHT", -M.PAD_X, 0)
    OneLine(f.title)

    f.nextLabel = WeintCodex.Eyebrow(f, "Als Nächstes")
    f.nextLabel:SetPoint("TOPLEFT", f, "TOPLEFT", M.PAD_X, -(M.PAD_Y + 84))
    f.steps = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark", height = HM.ROW_H })
    f.steps:SetPoint("TOPLEFT",  f.nextLabel, "BOTTOMLEFT", 0, -12)
    f.steps:SetPoint("RIGHT", f, "RIGHT", -M.PAD_X, 0)
    f.rows = {}
    for i = 1, HM.MAX_STEPS do f.rows[i] = BuildRow(f.steps, i) end

    f.pathLabel = WeintCodex.Eyebrow(f, "Dein Weg")
    f.pathLabel:SetPoint("TOPLEFT", f.steps, "BOTTOMLEFT", 0, -28)
    f.path = WeintCodex.CreateSurface(f, { tone = "plain", radius = 14, backdrop = "bgDark", height = HM.PATH_H })
    f.path:SetPoint("TOPLEFT", f.pathLabel, "BOTTOMLEFT", 0, -12)
    f.path:SetPoint("RIGHT", f, "RIGHT", -M.PAD_X, 0)
    -- Die Bahn: oben verankert, nicht an der Mitte - eine Linie von einem
    -- Bildpunkt, deren Mitte auf einem ganzen Bildpunkt liegt, zeichnet das
    -- Spiel nicht (gemessen 6.10.4.2, Zauberbuch).
    f.track = WeintCodex.RowLine(f.path, -30)
    f.slots = {}
    for i = 1, HM.MAX_PATH + 1 do f.slots[i] = BuildSlot(f.path, i) end
    f.pathEmpty = WeintCodex.Label(f.path, "", { size = 13, color = "textMuted" })
    f.pathEmpty:SetPoint("LEFT", f.path, "LEFT", 24, 0)
    f.pathEmpty:SetPoint("RIGHT", f.path, "RIGHT", -24, 0)
    OneLine(f.pathEmpty)

    -- Die Breite steht beim ersten Fuellen oft noch nicht fest.
    f.path:HookScript("OnSizeChanged", function() if f.slotCount then HM.PlaceSlots(f, f.slotCount) end end)
    return f
end

-- Hoehe der vollen Seite (drei Schritte), gerechnet aus denselben
-- Abstaenden wie Build() - der Prueflauf haelt sie gegen das kleinste
-- Fenster (CLAUDE.md: "Nichts muss scrollen"). Schriften geschaetzt:
-- Kopf 84, Abschnittsname 12.
function HM.PageHeight()
    local M = WeintCodex.Metrics
    return M.PAD_Y + 84 + 12 + 12 + HM.MAX_STEPS * HM.ROW_H + 28 + 12 + 12 + HM.PATH_H
end

-- Gleich breite Spalten: Stufen in gleichem Abstand lesen sich leichter
-- als massstabsgetreue, die bei 4, 5 und 6 aufeinanderkleben.
function HM.PlaceSlots(f, n)
    local w = Plain(f.path:GetWidth())
    w = type(w) == "number" and w > 0 and w or 600
    local cw = (w - 48) / math.max(1, n)
    for i, s in ipairs(f.slots) do
        s:ClearAllPoints()
        if i <= n then
            s:SetPoint("TOPLEFT", f.path, "TOPLEFT", 24 + (i - 1) * cw, 0)
            s:SetWidth(math.max(1, math.floor(cw)))
            s:Show()
            s.dot:Show()
        else
            s:Hide()
            s.dot:Hide()
        end
    end
end

local function FillRow(r, step, idle)
    r.step = step
    if not step then r:Hide() return end
    r:Show()
    r.label:SetText(WeintCodex.Spaced(WeintCodex.Upper(step.label or "")))
    r.title:SetText(step.title or "")
    r.detail:SetText(step.detail or "")
    SetColor(r.detail, step.tone == "danger" and "dangerBright" or "textMuted")
    SetColor(r.title, idle and "textNormal" or "textBright")
    if step.action then
        r.button:SetText(step.action)
        r.button:Show()
    else
        r.button:Hide()
    end
end

local function FillSlot(s, m, current)
    local dc = current and C.accent or C.textFaint
    s.dot:SetColorTexture(dc[1], dc[2], dc[3], 1)
    if current then
        s.level:SetText("Stufe " .. m.level)
        SetColor(s.level, "accentBright")
        s.line1:SetText("Jetzt")
        s.line2:SetText("")
        return
    end
    SetColor(s.level, "textBright")
    s.level:SetText("Stufe " .. m.level)
    local a, b = "", ""
    if m.spells > 0 then a = Plural(m.spells, "Ein neuer Zauber", "neue Zauber") end
    if #m.dungeons > 0 then
        local d = #m.dungeons == 1 and m.dungeons[1] or (#m.dungeons .. " Dungeons")
        if a == "" then a = d else b = d end
    end
    s.line1:SetText(a)
    s.line2:SetText(b)
end

-- Zustand der Seite fuer Pruefung und Bericht.
HM.last = nil

function HM.Fill(f, ctx)
    local steps = HM.Steps(ctx)
    local path = HM.Path(ctx)

    local meta
    if type(ctx.level) == "number" then
        meta = "Stufe " .. ctx.level .. (ctx.className and (" · " .. ctx.className) or "")
    else
        meta = "Stufe unbekannt"
    end
    f.eyebrow:SetText(WeintCodex.Spaced(WeintCodex.Upper(meta)))
    f.title:SetText(HM.Headline(ctx, steps))

    local idle = #steps == 0
    for i, r in ipairs(f.rows) do
        if idle and i == 1 then
            FillRow(r, { label = "", title = "Nichts offen", detail = HM.IdleDetail(ctx, path) }, true)
        else
            FillRow(r, steps[i])
        end
    end
    f.steps:SetHeight(math.max(1, #steps) * HM.ROW_H)

    if path and #path > 0 then
        f.pathEmpty:Hide()
        f.track:Show()
        FillSlot(f.slots[1], { level = ctx.level }, true)
        for i, m in ipairs(path) do FillSlot(f.slots[i + 1], m, false) end
        f.slotCount = #path + 1
    else
        f.track:Hide()
        f.slotCount = 0
        f.pathEmpty:SetText(path and "Keine weitere Stufe mit neuen Zaubern oder einem Dungeon bekannt."
            or "Ohne deine Stufe lässt sich der Weg nicht zeigen.")
        f.pathEmpty:Show()
    end
    HM.PlaceSlots(f, f.slotCount)

    HM.last = { steps = steps, path = path, headline = f.title:GetText() }
    return steps, path
end

-- Punkte und Zahlen in der Spalte links, aus echtem Zustand.
local function Badges(ctx)
    local nav = WeintCodex.Navigation
    if not nav then return end
    local broken = ctx.gear and #(ctx.gear.broken or {}) or 0
    -- Nur Zerbrochenes: leere Plaetze hat mit Stufe 3 jeder (Beta-Test).
    nav.SetTabBadge("charakter", broken > 0, "red")
    local shortages = 0
    if Can("materials.view") then
        local md = WeintCodex.SavedData and WeintCodex.SavedData.materialData
        for _, item in ipairs(md and md.items or {}) do
            local target = tonumber(item.target) or 0
            if target > 0 and (tonumber(item.count) or 0) / target < 0.30 then shortages = shortages + 1 end
        end
    end
    nav.SetTabBadge("materialien", shortages > 0, "red")
    local CP = WeintCodex.Companion
    local queue = CP and CP.GetQueueSize and CP.GetQueueSize() or 0
    nav.SetTabBadge("import", queue > 0, "accent")
    local now = ctx.trainer and #ctx.trainer.cat.sections.now or 0
    nav.SetTabCount("lehrer", now > 0 and now or nil, "successBright")
    -- Schlachtzuege: in einem neuen Spiel erst einmal nicht dran - keine Zahl.
    nav.SetTabCount("raids", nil)
end

function HM.Show()
    local cp = WeintCodex.ContentPanel
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
    local nav = WeintCodex.Navigation
    if nav then
        nav.ClearSidebar()
        nav.ClearTitleActions()
        nav.ClearInspector()
        if nav.RefreshAccount then nav.RefreshAccount() end
    end
    if WeintCodex.SetBreadcrumb then WeintCodex.SetBreadcrumb("Übersicht") end
    page = page or Build()
    local ctx = HM.Context()
    HM.Fill(page, ctx)
    Badges(ctx)
    page:Show()
end

function HM.Page() return page end
WeintCodex.ShowHome = HM.Show

-- Neu gefuellt (nicht neu gebaut) nur bei offener Seite und wenn sich das
-- Gezeigte aendern kann: Stufe, Zauber, Quests, Gold, Haltbarkeit.
-- Gebuendelt: Questereignisse kommen in Schueben.
do
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_LEVEL_UP", "SPELL_DATA_LOAD_RESULT", "LEARNED_SPELL_IN_SKILL_LINE",
                         "QUEST_LOG_UPDATE", "PLAYER_MONEY", "UPDATE_INVENTORY_DURABILITY" }) do
        pcall(ev.RegisterEvent, ev, e)
    end
    local queued = false
    ev:SetScript("OnEvent", function(_, event, id)
        if event == "SPELL_DATA_LOAD_RESULT" then
            local TR = WeintCodex.Trainer
            if not (TR and TR.pending and TR.pending[id]) then return end
        end
        if queued or not (page and page:IsShown()) then return end
        local main = WeintCodex.MainFrame
        if type(main) == "table" and main.IsShown and not main:IsShown() then return end
        queued = true
        local function run()
            queued = false
            if page and page:IsShown() then
                local ctx = HM.Context()
                HM.Fill(page, ctx)
                Badges(ctx)
            end
        end
        if C_Timer and C_Timer.After then C_Timer.After(0.5, run) else run() end
    end)
end
