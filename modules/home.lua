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
-- Aufbau (seit 6.11.0.2, siehe "Zeichnen"):
--   * Kachel: die Stufe, der wichtigste Schritt mit Knopf, darunter die
--     uebrigen Schritte als schmale Zeilen (hoechstens drei insgesamt,
--     nach Dringlichkeit), unten die Erfahrung.
--   * "Dein Weg": bis zum unteren Rand die naechsten Stufen, an denen
--     etwas Neues kommt - Zauber beim Namen, Dungeons, die sich oeffnen.
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
HM.MAX_PATH  = 5          -- Vorgabe ohne gemessene Hoehe
HM.PATH_CAP  = 14         -- mehr Stufen zeigt der Weg nie, auch im grossen Fenster

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
    ctx.xp = XB and XB.Experience and XB.Experience() or nil
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
-- Rueckgabe: { { level, spells, ids = { Zauber }, dungeons = { Namen } }, ... },
-- aufsteigend, hoechstens `max` (Vorgabe HM.MAX_PATH) Stufen.

function HM.Path(ctx, max)
    ctx = ctx or {}
    local level = ctx.level
    if type(level) ~= "number" then return nil end
    local by, levels = {}, {}
    local function at(l)
        local m = by[l]
        if not m then
            m = { level = l, spells = 0, ids = {}, dungeons = {} }
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
                    m.ids[#m.ids + 1] = sp.id
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
    for i = 1, math.min(#levels, max or HM.MAX_PATH) do out[i] = by[levels[i]] end
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
-- Zeichnen (6.11.0.2)
--------------------------------------------------
-- Zwei Teile: "was jetzt" und "was kommt".
--
--   Kachel     oben. Der wichtigste Schritt gross (Satz, Einzelheit,
--              Knopf), links das Feld mit der Stufe. Die uebrigen
--              Schritte darunter als schmale Zeilen IN der Kachel (eine
--              eigene Karte "Ausserdem" stand in 6.11.0.1 meist fast leer
--              daneben - Beta-Test). Ganz unten die Erfahrung.
--   Dein Weg   darunter, ueber die ganze Breite bis zum unteren Rand. So
--              viele Stufen, wie Platz haben (HM.PathRows), je Stufe die
--              Zauber beim Namen und die Dungeons, die sich oeffnen - die
--              Breite traegt Namen statt "3 neue Zauber".
--
-- 6.11.0.1 (Beta-Test): eine Tabelle ueber 1.400 Bildpunkte war "nicht
-- schoen"; 6.11.0.1 hatte darunter zwei gleich hohe Karten und eine leere
-- halbe Seite. Innen weiter hoechstens HM.MAX_W breit, mittig.

-- Symbole je Art. Nur solche, die WeintCodex schon zeigt (Tour, Rollen) -
-- ein geratener Pfad zeichnet im Spiel ein gruenes Rechteck.
HM.ICONS = {
    trainer       = "Interface\\Icons\\INV_Misc_Book_09",
    quests        = "Interface\\Icons\\INV_Misc_Note_01",
    repair        = "Interface\\Icons\\INV_Misc_Armorkit_17",
    dungeonQuests = "Interface\\Icons\\INV_Misc_GroupLooking",
    dungeonFit    = "Interface\\Icons\\INV_Misc_GroupLooking",
    weapons       = "Interface\\Icons\\Ability_DualWield",
}

HM.HERO_H   = 148       -- Kachel ohne weitere Schritte
HM.HERO_TOP = 128       -- bis hier Feld und Ueberschrift
HM.EXTRA_H  = 44        -- eine weitere Zeile in der Kachel
HM.HERO_FOOT = 48       -- Erfahrung unten in der Kachel
HM.TILE     = 92        -- Feld der Stufe
HM.TEXT_X   = 24 + 92 + 28
HM.HEAD_H   = 52        -- Kopf der Karte "Dein Weg" bis zur ersten Zeile
HM.PATH_ROW = 38        -- eine Stufe im Weg
HM.PATH_PAD = 16        -- Luft unter der letzten Zeile
HM.MAX_W    = 1180      -- breiter liest sich nicht: Text links, Knopf weit rechts

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

local function Spaced(text)
    return WeintCodex.Spaced(WeintCodex.Upper(text or ""))
end

-- Hoehe der Kachel mit n weiteren Schritten.
function HM.HeroHeight(n)
    if (n or 0) <= 0 then return HM.HERO_H end
    return HM.HERO_TOP + n * HM.EXTRA_H + HM.HERO_FOOT
end

-- Wie viele Stufen passen in eine Karte dieser Hoehe? Die erste Zeile ist
-- "du bist hier", deshalb eine weniger. Mindestens eine, hoechstens
-- HM.PATH_CAP.
function HM.PathRows(h)
    if type(h) ~= "number" or h <= 0 then return HM.MAX_PATH end
    local rows = math.floor((h - HM.HEAD_H - HM.PATH_PAD) / HM.PATH_ROW) - 1
    return math.max(1, math.min(HM.PATH_CAP, rows))
end

-- Breite innen: was der Inhaltsbereich hergibt, hoechstens HM.MAX_W.
function HM.InnerWidth(w)
    local M = WeintCodex.Metrics
    w = type(w) == "number" and w > 0 and (w - 2 * M.PAD_X) or HM.MAX_W
    return math.max(1, math.min(HM.MAX_W, math.floor(w)))
end

-- Eine weitere Zeile in der Kachel: Symbol, Satz, Einzelheit, kleiner Knopf.
local function BuildExtra(h, i)
    local r = CreateFrame("Frame", nil, h)
    r:SetHeight(HM.EXTRA_H)
    local y = -HM.HERO_TOP - (i - 1) * HM.EXTRA_H
    r:SetPoint("TOPLEFT",  h, "TOPLEFT",  HM.TEXT_X, y)
    r:SetPoint("TOPRIGHT", h, "TOPRIGHT", -28, y)
    r.line = WeintCodex.RowLine(r, 0)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(22, 22)
    r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.button = WeintCodex.CreateButton(r, {
        text = "", kind = "secondary", height = 28, backdrop = "accentCardBot",
        onClick = function() Go(r.step) end,
    })
    r.button:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    r.title = WeintCodex.Label(r, "", { font = WeintCodex.Fonts.sansSemi, size = 13, color = "textBright" })
    r.title:SetPoint("LEFT", r.icon, "RIGHT", 12, 0)
    OneLine(r.title)
    r.detail = WeintCodex.Label(r, "", { size = 12, color = "textMuted" })
    r.detail:SetPoint("LEFT", r.title, "RIGHT", 12, 0)
    r.detail:SetPoint("RIGHT", r.button, "LEFT", -16, 0)
    OneLine(r.detail)
    return r
end

local function BuildHero(f)
    local h = WeintCodex.CreateSurface(f.inner, { tone = "accent", radius = 14, backdrop = "bgDark", height = HM.HERO_H })
    h:SetPoint("TOPLEFT",  f.inner, "TOPLEFT",  0, 0)
    h:SetPoint("TOPRIGHT", f.inner, "TOPRIGHT", 0, 0)

    -- Feld der Stufe: die eine Zahl, die beim Leveln zaehlt.
    h.tile = WeintCodex.CreateSurface(h, { tone = "flat", surface = "bgDark", radius = 0,
                                           width = HM.TILE, height = HM.TILE })
    h.tile:SetPoint("TOPLEFT", h, "TOPLEFT", 24, -28)
    h.tileCap = WeintCodex.Eyebrow(h.tile, "Stufe", { size = 9, color = "textDim", justify = "CENTER" })
    h.tileCap:SetPoint("TOP", h.tile, "TOP", 0, -12)
    h.level = WeintCodex.PageTitle(h.tile, "", { size = 38, justify = "CENTER" })
    h.level:SetPoint("CENTER", h.tile, "CENTER", 0, -2)
    h.class = WeintCodex.Label(h.tile, "", { size = 10, color = "textMuted", justify = "CENTER" })
    h.class:SetPoint("BOTTOMLEFT", h.tile, "BOTTOMLEFT", 6, 10)
    h.class:SetPoint("BOTTOMRIGHT", h.tile, "BOTTOMRIGHT", -6, 10)
    if h.class.SetWordWrap then h.class:SetWordWrap(false) end

    h.button = WeintCodex.CreateButton(h, {
        text = "", kind = "primary", backdrop = "accentCardTop",
        onClick = function() Go(h.step) end,
    })
    h.button:SetPoint("TOPRIGHT", h, "TOPRIGHT", -28, -46)
    h.eyebrow = WeintCodex.Eyebrow(h, "", { size = 10, color = "accentBright" })
    h.eyebrow:SetPoint("TOPLEFT", h, "TOPLEFT", HM.TEXT_X, -30)
    h.title = WeintCodex.PageTitle(h, "", { size = 26 })
    h.title:SetPoint("TOPLEFT", h.eyebrow, "BOTTOMLEFT", 0, -8)
    h.title:SetPoint("RIGHT", h.button, "LEFT", -24, 0)
    OneLine(h.title)
    h.detail = WeintCodex.Label(h, "", { size = 13, color = "textMuted" })
    h.detail:SetPoint("TOPLEFT", h.title, "BOTTOMLEFT", 0, -8)
    h.detail:SetPoint("RIGHT", h.button, "LEFT", -24, 0)
    OneLine(h.detail)

    h.extras = {}
    for i = 1, HM.MAX_STEPS - 1 do h.extras[i] = BuildExtra(h, i) end

    -- Fortschritt zur naechsten Stufe, ganz unten neben dem Feld.
    h.meter = WeintCodex.CreateMeter(h, { height = 4, tone = "accent" })
    h.meter:SetPoint("BOTTOMLEFT",  h, "BOTTOMLEFT",  HM.TEXT_X, 22)
    h.meter:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -28, 22)
    h.meter:HookScript("OnSizeChanged", function(self) if h.pct then self:SetValue(h.pct) end end)
    h.xp = WeintCodex.Label(h, "", { size = 11, color = "textDim", justify = "RIGHT" })
    h.xp:SetPoint("BOTTOMRIGHT", h.meter, "TOPRIGHT", 0, 8)
    return h
end

-- Eine Stufe im Weg: Punkt auf der Linie, Stufe, was kommt.
local function BuildSlot(card, i)
    local s = CreateFrame("Frame", nil, card)
    s:SetHeight(HM.PATH_ROW)
    local y = -HM.HEAD_H - (i - 1) * HM.PATH_ROW
    s:SetPoint("TOPLEFT",  card, "TOPLEFT",  0, y)
    s:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, y)
    s.dot = s:CreateTexture(nil, "OVERLAY")
    s.dot:SetSize(9, 9)
    s.dot:SetPoint("TOPLEFT", s, "TOPLEFT", 28, -5)
    s.level = WeintCodex.Label(s, "", { font = WeintCodex.Fonts.sansSemi, size = 13, color = "textBright" })
    s.level:SetPoint("TOPLEFT", s, "TOPLEFT", 54, -2)
    s.level:SetWidth(84)
    OneLine(s.level)
    s.text = WeintCodex.Label(s, "", { size = 12, color = "textMuted" })
    s.text:SetPoint("TOPLEFT", s, "TOPLEFT", 146, -3)
    s.text:SetPoint("RIGHT", s, "RIGHT", -24, 0)
    OneLine(s.text)
    return s
end

local function Build()
    local M = WeintCodex.Metrics
    local f = CreateFrame("Frame", nil, WeintCodex.ContentPanel)
    f:SetAllPoints(WeintCodex.ContentPanel)
    -- Innen hoechstens HM.MAX_W breit, mittig, bis zum unteren Rand.
    f.inner = CreateFrame("Frame", nil, f)
    f.inner:SetPoint("TOP", f, "TOP", 0, -M.PAD_Y)
    f.inner:SetPoint("BOTTOM", f, "BOTTOM", 0, M.PAD_Y)
    f.hero = BuildHero(f)

    f.path = WeintCodex.CreateSurface(f.inner, { tone = "plain", radius = 14, backdrop = "bgDark" })
    f.path:SetPoint("TOPLEFT",  f.hero, "BOTTOMLEFT",  0, -M.GAP)
    f.path:SetPoint("TOPRIGHT", f.hero, "BOTTOMRIGHT", 0, -M.GAP)
    f.path:SetPoint("BOTTOM", f.inner, "BOTTOM", 0, 0)
    f.path.head = WeintCodex.Eyebrow(f.path, "Dein Weg")
    f.path.head:SetPoint("TOPLEFT", f.path, "TOPLEFT", 24, -22)
    -- Die Linie hinter den Punkten: senkrecht, links verankert (eine an
    -- ihrer Mitte verankerte Linie von einem Bildpunkt zeichnet das Spiel
    -- nicht, gemessen 6.10.4.2).
    f.track = f.path:CreateTexture(nil, "ARTWORK")
    f.track:SetWidth(1)
    local lc = C.rowLine or C.textFaint
    f.track:SetColorTexture(lc[1], lc[2], lc[3], 1)
    f.slots = {}
    for i = 1, HM.PATH_CAP + 1 do f.slots[i] = BuildSlot(f.path, i) end
    f.pathEmpty = WeintCodex.Label(f.path, "", { size = 13, color = "textDim" })
    f.pathEmpty:SetPoint("TOPLEFT", f.path, "TOPLEFT", 24, -HM.HEAD_H - 4)
    f.pathEmpty:SetPoint("RIGHT", f.path, "RIGHT", -24, 0)
    OneLine(f.pathEmpty)

    local function resize()
        f.inner:SetWidth(HM.InnerWidth(Plain(f:GetWidth())))
        -- Andere Hoehe, andere Zahl Stufen: neu fuellen, ohne neu zu fragen.
        if HM.lastCtx and f:IsShown() then HM.Fill(f, HM.lastCtx) end
    end
    f:HookScript("OnSizeChanged", resize)
    f.inner:SetWidth(HM.InnerWidth(Plain(f:GetWidth())))
    return f
end

-- Hoehe der Karte "Dein Weg": gemessen, sonst aus dem kleinsten Fenster
-- gerechnet (Prueflauf) - dieselbe Rechnung wie das Budget der Dungeonseite.
function HM.PathHeight(f, heroH)
    local h = f and Plain(f:GetHeight())
    local M = WeintCodex.Metrics
    if type(h) ~= "number" or h <= 0 then
        local limits = WeintCodex.WindowLimits or {}
        h = (limits.minH or 780) - (M.TITLEBAR_H or 40)
    end
    return h - 2 * M.PAD_Y - heroH - M.GAP
end

-- Hoehe der Seite im ungunstigsten Fall: Kachel mit allen Schritten und
-- ein Weg mit mindestens drei Zeilen. Der Prueflauf haelt sie gegen das
-- kleinste Fenster (CLAUDE.md: "Nichts muss scrollen").
function HM.PageHeight()
    local M = WeintCodex.Metrics
    return M.PAD_Y + HM.HeroHeight(HM.MAX_STEPS - 1) + M.GAP + HM.HEAD_H + 3 * HM.PATH_ROW + HM.PATH_PAD
end

local function FillExtra(r, step)
    r.step = step
    if not step then r:Hide() return end
    r:Show()
    r.iconPath = HM.ICONS[step.key] or "Interface\\Icons\\INV_Misc_QuestionMark"
    r.icon:SetTexture(r.iconPath)
    r.title:SetText(step.title or "")
    r.detail:SetText(step.detail or "")
    SetColor(r.detail, step.tone == "danger" and "dangerBright" or "textMuted")
    if step.action then
        r.button:SetText(step.action)
        r.button:Show()
    else
        r.button:Hide()
    end
end

-- Was an einer Stufe kommt, in Worten: die Zauber beim Namen (gleiche
-- Namen - hoehere Raenge - einmal), die Dungeons. Kennt der Client einen
-- Namen noch nicht, steht die Zahl da; er liefert nach
-- (SPELL_DATA_LOAD_RESULT), dann fuellt die Seite neu.
-- `bright`: Dungeons in hellerer Schrift - sie sollen zwischen Zaubern
-- auffallen (Farbe aus core/ui.lua ueber ColorText).
function HM.SlotText(m, bright)
    local parts = {}
    if #m.dungeons > 0 then
        local d = (#m.dungeons == 1 and "Dungeon " or "Dungeons ") .. table.concat(m.dungeons, ", ")
        parts[#parts + 1] = bright and WeintCodex.ColorText("textBright", d) or d
    end
    if m.spells > 0 then
        local TR = WeintCodex.Trainer
        local names, seen, missing = {}, {}, false
        for _, id in ipairs(m.ids or {}) do
            local name = TR and TR.SpellInfo and TR.SpellInfo(id)
            if type(name) ~= "string" then missing = true break end
            if not seen[name] then seen[name] = true names[#names + 1] = name end
        end
        if missing or #names == 0 then
            parts[#parts + 1] = Plural(m.spells, "ein neuer Zauber", "neue Zauber")
        else
            parts[#parts + 1] = table.concat(names, ", ")
        end
    end
    return table.concat(parts, " · ")
end

local function FillSlot(s, m, current)
    s:Show()
    local dc = current and C.accent or C.textFaint
    s.dot:SetColorTexture(dc[1], dc[2], dc[3], 1)
    s.level:SetText("Stufe " .. m.level)
    if current then
        SetColor(s.level, "accentBright")
        s.text:SetText("du bist hier")
        SetColor(s.text, "textDim")
        return
    end
    SetColor(s.level, "textBright")
    SetColor(s.text, "textMuted")
    s.text:SetText(HM.SlotText(m, true))
end

local function FillHero(h, ctx, steps, path)
    local step = steps[1]
    h.step = step
    h.level:SetText(type(ctx.level) == "number" and tostring(ctx.level) or "–")
    h.class:SetText(ctx.className or "")
    if step then
        h.eyebrow:SetText(Spaced("Als Nächstes · " .. (step.label or "")))
        h.title:SetText(step.headline or step.title or "")
        h.detail:SetText(step.detail or "")
        SetColor(h.detail, step.tone == "danger" and "dangerBright" or "textMuted")
    else
        h.eyebrow:SetText(Spaced("Als Nächstes"))
        h.title:SetText(HM.Headline(ctx, steps))
        h.detail:SetText(HM.IdleDetail(ctx, path))
        SetColor(h.detail, "textMuted")
    end
    if step and step.action then
        h.button:SetText(step.action)
        h.button:Show()
    else
        h.button:Hide()
    end
    local n = 0
    for i, r in ipairs(h.extras) do
        FillExtra(r, steps[i + 1])
        if steps[i + 1] then n = n + 1 end
    end
    h:SetHeight(HM.HeroHeight(n))
    -- Erfahrung: dieselbe Auskunft wie der Erfahrungsbalken; ohne sie
    -- (Hoechststufe, gesperrt, keine Antwort) keine Leiste - nie 0 %.
    local xp = ctx.xp
    if xp and type(xp.cur) == "number" and type(xp.max) == "number" and xp.max > 0 then
        h.pct = math.max(0, math.min(1, xp.cur / xp.max))
        h.meter:SetValue(h.pct)
        h.meter:Show()
        local txt = string.format("%d %% bis Stufe %s", math.floor(h.pct * 100),
            type(ctx.level) == "number" and tostring(ctx.level + 1) or "?")
        if type(xp.rested) == "number" and xp.rested > 0 then txt = txt .. " · erholt " .. Thousands(xp.rested) .. " EP" end
        h.xp:SetText(txt)
        h.xp:Show()
    else
        h.pct = nil
        h.meter:Hide()
        h.xp:Hide()
    end
    return n
end

-- Zustand der Seite fuer Pruefung und Bericht.
HM.last = nil

function HM.Fill(f, ctx)
    HM.lastCtx = ctx
    local steps = HM.Steps(ctx)
    local extras = math.max(0, math.min(#steps, HM.MAX_STEPS) - 1)
    local rows = HM.PathRows(HM.PathHeight(f, HM.HeroHeight(extras)))
    local path = HM.Path(ctx, rows)
    FillHero(f.hero, ctx, steps, path)

    local n = 0
    if path and #path > 0 then
        f.pathEmpty:Hide()
        FillSlot(f.slots[1], { level = ctx.level }, true)
        for i, m in ipairs(path) do FillSlot(f.slots[i + 1], m, false) end
        n = #path + 1
    else
        f.pathEmpty:SetText(path and "Keine weitere Stufe mit neuen Zaubern oder einem Dungeon bekannt."
            or "Ohne deine Stufe lässt sich der Weg nicht zeigen.")
        f.pathEmpty:Show()
    end
    for i = n + 1, #f.slots do f.slots[i]:Hide() end
    f.slotCount = n
    -- Die Linie verbindet den ersten und den letzten Punkt.
    f.track:ClearAllPoints()
    if n > 1 then
        -- Ganze Versaetze vom Rand des Punkts (9 breit, Mitte = Bildpunkt 4).
        f.track:SetPoint("TOPLEFT", f.slots[1].dot, "TOPLEFT", 4, -4)
        f.track:SetPoint("BOTTOMLEFT", f.slots[n].dot, "TOPLEFT", 4, -4)
        f.track:Show()
    else
        f.track:Hide()
    end

    HM.last = { steps = steps, path = path, rows = rows, headline = f.hero.title:GetText() }
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
