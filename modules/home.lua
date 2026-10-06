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
-- Aufbau (seit 6.11.0.2 nach dem Entwurf des Spielers, siehe "Zeichnen"):
--   * "Als Naechstes": die Stufe, der wichtigste Schritt mit Knopf, die
--     Erfahrung mit dem, was abgabebereite Quests noch bringen.
--   * "Ausserdem": die uebrigen Schritte (hoechstens drei insgesamt, nach
--     Dringlichkeit) als Karten mit Kosten.
--   * "Dein Weg": die naechsten acht Stufen nebeneinander - neue Zauber,
--     Dungeons, die sich oeffnen.
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

-- Alle Instanzen mit Stufenbereich (Forever und klassische), ohne die
-- der anderen Fraktion (D.ForFaction, 6.13.5.0 - Ragefire Chasm in
-- Orgrimmar ist fuer die Allianz kein Vorschlag). Ohne Fraktion alle.
local function AllDungeons(faction)
    local D = WeintCodex.DungeonData
    if not D then return {} end
    local all = (D.AllInstances and D.AllInstances()) or (D.All and D.All()) or {}
    if not D.ForFaction then return all end
    local out = {}
    for _, d in ipairs(all) do
        if D.ForFaction(d, faction) then out[#out + 1] = d end
    end
    return out
end
HM.AllDungeons = AllDungeons

-- Dungeons fuer die eigene Stufe; passt keiner, der naechste darueber.
function HM.Dungeons(level, faction)
    local D = WeintCodex.DungeonData
    if not (D and type(level) == "number") then return {}, nil end
    local fit, nextUp = {}, nil
    for _, d in ipairs(AllDungeons(faction)) do
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
    ctx.fit, ctx.nextUp = HM.Dungeons(ctx.level, ctx.faction)
    ctx.dungeonQuests = HM.DungeonQuests(ctx.faction)
    ctx.dungeons = AllDungeons(ctx.faction)
    ctx.professions = HM.Professions()
    local CQ = WeintCodex.ClassQuests
    ctx.classQuest = CQ and CQ.NextSpellQuest and CQ.NextSpellQuest() or nil
    return ctx
end

-- Deine Berufe mit Rezepten beim Lehrer (6.14.0.0) - nur, wo das Gelernte
-- aus dem Berufsfenster bekannt ist; sonst waere "lernbar" geraten.
-- { { key, name, rank, max, now }, ... }, die meisten zuerst.
function HM.Professions()
    local PRO = WeintCodex.Professions
    if not (PRO and PRO.Skills and PRO.Summary) then return {} end
    local out = {}
    for key, s in pairs(PRO.Skills()) do
        local sum = PRO.Summary(key, s.rank)
        if sum and sum.sure and sum.now > 0 then
            out[#out + 1] = { key = key, name = PRO.ProfName(key), rank = s.rank, max = s.max, now = sum.now }
        end
    end
    table.sort(out, function(a, b) if a.now ~= b.now then return a.now > b.now end return a.key < b.key end)
    return out
end

--------------------------------------------------
-- Die Schritte (rein)
--------------------------------------------------
-- Reihenfolge = Dringlichkeit:
--   1 Lehrer        Zauber, die man jetzt lernen kann
--   2 Quests        abgabebereit - Erfahrung, die schon verdient ist
--   3 Reparieren    ein zerbrochener Gegenstand wirkt nicht
--   4 Klassenquest  lehrt einen Zauber und ist jetzt dran (6.15.0.0; nur
--                   mit Antwort des Clients zum Queststand) - vor den
--                   Dungeons: einen Zauber gibt es nur hier
--   5 Dungeon       Quests dafuer im Log
--   6 Waffen        Waffenfertigkeiten beim Waffenmeister
--   7 Dungeon       passt zur Stufe (nur ohne Schritt 5)
--   8 Beruf         Rezepte beim Berufslehrer (6.14.0.0; nur mit bekanntem
--                   Gelernten - aus dem Berufsfenster)
-- Hoechstens HM.MAX_STEPS. Ein Schritt: key, label, title, headline,
-- detail (Satz in der Kachel), sub (kurze Zeile auf einer Karte unter
-- "Ausserdem", sonst detail), cost/short (Kupfer: Kosten, Fehlbetrag -
-- short nur, wenn das Gold bekannt ist und nicht reicht), optional
-- (Fehlbetrag in Bernstein statt Rot), tone (nil | "danger"), action
-- (Knopftext), go (Ziel); beim Lehrer und bei den Waffen spells (Zauber-
-- IDs, die jetzt gehen - die Namen nennt beim Zeichnen der Client),
-- unnamed (Wort, solange ein Name fehlt), where (Ort auf der Karte).

function HM.Steps(ctx)
    local steps = {}
    local function add(s)
        if #steps < HM.MAX_STEPS then steps[#steps + 1] = s end
    end
    ctx = ctx or {}

    local tr = ctx.trainer
    local now = tr and tr.cat and tr.cat.sections and tr.cat.sections.now or {}
    if #now > 0 then
        local ids = {}
        for i, sp in ipairs(now) do ids[i] = sp.id end
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
              detail = detail, tone = tone, action = "Zum Lehrer", go = { tab = "lehrer" },
              sub = "Beim Klassenlehrer", cost = b.now, spells = ids, unnamed = "Zauber",
              short = (type(b.rest) == "number" and b.rest < 0) and -b.rest or nil })
    end

    local q = ctx.quests
    if q and type(q.readyCount) == "number" and q.readyCount > 0 then
        local title = Plural(q.readyCount, "Eine Quest abgabebereit", "Quests abgabebereit")
        local xp = (type(q.ready) == "number" and q.ready > 0) and (Thousands(q.ready) .. " EP") or nil
        add({ key = "quests", label = "Quests", title = title, headline = title,
              detail = xp and ("Beim Questgeber abgeben – bringt zusammen " .. WeintCodex.ColorText("textNormal", xp))
                  or "Beim Questgeber abgeben",
              sub = xp and ("bringt zusammen " .. xp) or "beim Questgeber abgeben",
              action = "Auf der Karte zeigen", go = { map = true } })
    end

    local broken = ctx.gear and ctx.gear.broken or {}
    if #broken > 0 then
        local title = Plural(#broken, "Ein Gegenstand zerbrochen", "Gegenstände zerbrochen")
        add({ key = "repair", label = "Ausrüstung", title = title, headline = title,
              detail = table.concat(broken, ", ") .. " – beim Händler reparieren", tone = "danger",
              sub = table.concat(broken, ", ") .. " · beim Händler reparieren",
              action = "Charakter", go = { tab = "charakter" } })
    end

    local cq = ctx.classQuest
    if cq then
        local stateText = (cq.state == "ready" and "abgabebereit") or (cq.state == "active" and "im Questlog")
            or "jetzt möglich"
        add({ key = "classQuest", label = "Klassenquest", title = cq.spell .. " per Quest",
              headline = "Klassenquest: " .. cq.title,
              detail = "Lehrt " .. cq.spell .. " · " .. stateText .. " · " .. cq.giver,
              sub = "Lehrt " .. cq.spell .. " · " .. stateText, action = "Zur Klassenquest",
              go = { tab = "klassenquests" } })
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
        local ids = {}
        for _, wp in ipairs(tr.weapons or {}) do
            if wp.key == "now" then ids[#ids + 1] = wp.id end
        end
        add({ key = "weapons", label = "Waffen", title = title, headline = title,
              detail = detail, action = "Zum Lehrer", go = { tab = "lehrer" },
              sub = "Beim Waffenmeister · optional", optional = true, cost = cost,
              spells = ids, unnamed = "Waffe", where = "optional, beim Waffenmeister",
              short = (type(b.money) == "number" and b.money < cost) and (cost - b.money) or nil })
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

    local pr = ctx.professions and ctx.professions[1]
    if pr then
        local title = Plural(pr.now, "Ein Rezept lernbar", "Rezepte lernbar")
        local detail = pr.name .. " · Fertigkeit " .. pr.rank .. (pr.max and (" / " .. pr.max) or "")
        add({ key = "profession", label = "Beruf", title = title,
              headline = pr.now == 1 and (pr.name .. ": ein Rezept beim Lehrer")
                  or (pr.name .. ": " .. pr.now .. " Rezepte beim Lehrer"),
              detail = detail, sub = "Beim Berufslehrer · " .. detail, action = "Zu den Berufen",
              go = { tab = "berufe", profession = pr.key } })
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
-- Zeichnen (6.11.0.2, nach dem Entwurf "WeintCodex Übersicht")
--------------------------------------------------
-- Der Spieler hat den Entwurf im Design-Werkzeug ausgesucht ("das haette
-- ich gerne so"). Nachgebaut mit seinen Massen, innen hoechstens 1.040
-- breit, mittig:
--
--   Als Naechstes  Karte mit Rahmen: links das Feld mit der Stufe, daneben
--                  Art, Satz und Einzelheit, rechts der Knopf; darunter die
--                  Erfahrung als Leiste mit dem, was die abgabebereiten
--                  Quests noch bringen (schraffiert), und einer Legende.
--   Ausserdem      Ueberschrift mit Zahl, je weiterem Schritt eine Karte:
--                  Symbol im Feld, Satz, kurze Zeile, Kosten und
--                  Fehlbetrag in Muenzen, Knopf. Ohne weiteren Schritt
--                  faellt der Abschnitt weg.
--   Dein Weg       Ueberschrift mit Legende, darunter eine Karte mit den
--                  naechsten acht Stufen nebeneinander: Marke auf einer
--                  Linie (Kreis = du, Quadrat = Zauber, Raute = Dungeon,
--                  kleiner Punkt = nichts), Stufe, was kommt. Die Linie
--                  ist vom Kreis aus so weit gefaerbt, wie die Erfahrung
--                  zur naechsten Stufe reicht.
--
-- Abweichungen vom Entwurf, weil das Spiel es nicht hergibt: keine
-- Laufweite (duenne Leerzeichen statt 0,12 em), Newsreader statt IBM Plex
-- Serif (die Anzeigeschrift des ganzen Addons), Symbole als eigene
-- Texturen statt Vektoren, Knoepfe aus dem Baukasten des Addons. Runde
-- Ecken MIT Rahmen: eigene Masken und Boegen (media/ui/round*_*.tga,
-- .github/scripts/make_ui_media.py) - CutCorners allein schnitte den Rahmen
-- an den Ecken ab.

HM.ICONS = {
    trainer       = "Interface\\AddOns\\WeintCodex\\media\\ui\\icon_book",
    quests        = "Interface\\AddOns\\WeintCodex\\media\\ui\\icon_quest",
    repair        = "Interface\\AddOns\\WeintCodex\\media\\ui\\icon_hammer",
    dungeonQuests = "Interface\\AddOns\\WeintCodex\\media\\ui\\icon_gate",
    dungeonFit    = "Interface\\AddOns\\WeintCodex\\media\\ui\\icon_gate",
    weapons       = "Interface\\AddOns\\WeintCodex\\media\\ui\\icon_combat",
    profession    = "Interface\\AddOns\\WeintCodex\\media\\ui\\icon_hammer",
    classQuest    = "Interface\\AddOns\\WeintCodex\\media\\ui\\icon_quest",
}
local UI = "Interface\\AddOns\\WeintCodex\\media\\ui\\"

HM.MAX_W     = 1040
HM.TOP       = 36       -- Abstand oben
HM.GAP       = 28       -- zwischen den Abschnitten
HM.TILE      = 96
HM.HERO_TOP  = 28 + HM.TILE + 26   -- bis zur Erfahrung
HM.XP_H      = 60                  -- Zeile, Leiste, Legende
HM.HERO_PAD  = 26                  -- unten
HM.HEAD      = 20                  -- Ueberschrift eines Abschnitts
HM.HEAD_GAP  = 12
HM.CARD_H    = 76                  -- eine Karte unter "Ausserdem"
HM.CARD_GAP  = 10
HM.WEG_H     = 140
HM.LINE2_Y   = 96         -- zweite Zeile unter einer Stufe (erste bei 78)
HM.WEG_COLS  = 8
-- 6.11.0.3: was man lernen kann, mit Namen (Beta-Test: "statt erst auf
-- die Lehrerkarte zu klicken"). Eine Zeile unter der Einzelheit; der
-- Textblock rueckt dafuer an die Oberkante der Kachel, die Erfahrung um
-- HM.LIST_H nach unten.
HM.CHIPS     = 8                   -- hoechstens so viele Namen
HM.CHIP_H    = 20
HM.CHIP_GAP  = 18
HM.LIST_H    = 10

local page

local function Go(step)
    local go = step and step.go
    if not go then return end
    if go.map then
        -- Ueber modules/questmap.lua (nur C_Map.OpenWorldMap, nie im Kampf -
        -- alles andere schrieb in die Weltkarte und liess das Spiel im
        -- Kampf blockieren, 6.6.0.1).
        local QM = WeintCodex.QuestMap
        local ok, why = false, "api"
        if QM and QM._OpenMap then ok, why = QM._OpenMap(nil) end
        if not ok then
            print(WeintCodex.ColorText("accent", "[WeintCodex]") .. (why == "combat"
                and " Im Kampf öffnet WeintCodex die Karte nicht."
                or " Die Karte öffnest du mit M."))
        end
        return
    end
    if go.dungeon and WeintCodex.DungeonPages and WeintCodex.DungeonPages.Select then
        WeintCodex.DungeonPages.Select(go.dungeon)
    end
    if go.profession and WeintCodex.Professions and WeintCodex.Professions.Select then
        WeintCodex.Professions.Select(go.profession)
    end
    local nav = WeintCodex.Navigation
    if nav and nav.GoToTab then nav.GoToTab(go.tab) end
end
HM.Go = Go

local function Col(name) return C[name] or C.textMuted end

local function SetColor(fs, name)
    local c = Col(name)
    fs:SetTextColor(c[1], c[2], c[3])
end

local function OneLine(fs, justify)
    fs:SetJustifyH(justify or "LEFT")
    if fs.SetWordWrap then fs:SetWordWrap(false) end
end

-- Versal mit duennem Leerzeichen zwischen den Zeichen - die Laufweite
-- 0,12 em des Entwurfs. IBM Plex Sans hat das Haar-Leerzeichen (U+200A),
-- geprueft mit fontTools; die Monoschrift hat es nicht.
local HAIR = "\226\128\138"
function HM.Tracked(text)
    local s = WeintCodex.Upper(text or "")
    local out = {}
    for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do out[#out + 1] = ch end
    return table.concat(out, HAIR)
end

local function Label(parent, size, color, semi)
    return WeintCodex.Label(parent, "", { size = size, color = color,
        font = semi and WeintCodex.Fonts.sansSemi or nil })
end

-- Kupfer in Muenzen des Spiels; ohne die Funktion in Worten.
function HM.Coins(copper)
    if type(copper) ~= "number" then return "—" end
    local f = _G.GetCoinTextureString
    if type(f) == "function" then
        local ok, s = pcall(f, copper)
        if ok and type(s) == "string" and s ~= "" then return s end
    end
    return Money(copper)
end

-- Name, Rang und Bild eines Zaubers vom Client (modules/trainer.lua fragt
-- und fordert nach); solange der Name fehlt, Wort und Nummer - wie auf
-- der Lehrerseite. SPELL_DATA_LOAD_RESULT fuellt die Seite neu.
function HM.SpellLabel(id, unnamed)
    local TR = WeintCodex.Trainer
    local name, sub, icon
    if TR and TR.SpellInfo then name, sub, icon = TR.SpellInfo(id) end
    return name or ((unnamed or "Zauber") .. " " .. tostring(id)), sub, icon
end

-- Breite eines Textes: gemessen, aber nie schmaler als geschaetzt (wie
-- modules/dungeonpages.lua) - wo die Schaetzung darueber liegt, bleibt
-- Luft, nie fehlt welche.
local function TextWidth(fs, text, size)
    local est = WeintCodex.Utf8Len(text) * size * 0.56
    local ok, w = pcall(fs.GetStringWidth, fs)
    w = ok and Plain(w) or nil
    if type(w) == "number" and w > est then return w end
    return est
end

--------------------------------------------------
-- Kasten mit Rahmen und runden Ecken
--------------------------------------------------
local CORNER_UV = {
    TOPLEFT     = { 0, 1, 0, 1 },
    TOPRIGHT    = { 1, 0, 0, 1 },
    BOTTOMLEFT  = { 0, 1, 1, 0 },
    BOTTOMRIGHT = { 1, 0, 1, 0 },
}

-- opts: radius (8|12|14), fill, border (Name oder nil), backdrop (die
-- Flaeche darunter - in ihr verschwinden die Ecken).
function HM.Box(parent, opts)
    local f = CreateFrame("Frame", nil, parent)
    local r = opts.radius or 12
    local fill, border, back = Col(opts.fill or "surface2"), opts.border and Col(opts.border), Col(opts.backdrop or "bgDark")
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetColorTexture(fill[1], fill[2], fill[3], 1)
    f.bg = bg
    if border then
        local function line(p1, x1, y1, p2, x2, y2, w, h)
            local t = f:CreateTexture(nil, "BORDER")
            t:SetColorTexture(border[1], border[2], border[3], 1)
            t:SetPoint(p1, f, p1, x1, y1)
            t:SetPoint(p2, f, p2, x2, y2)
            if w then t:SetWidth(w) end
            if h then t:SetHeight(h) end
        end
        line("TOPLEFT", r, 0, "TOPRIGHT", -r, 0, nil, 1)
        line("BOTTOMLEFT", r, 0, "BOTTOMRIGHT", -r, 0, nil, 1)
        line("TOPLEFT", 0, -r, "BOTTOMLEFT", 0, r, 1, nil)
        line("TOPRIGHT", 0, -r, "BOTTOMRIGHT", 0, r, 1, nil)
    end
    for point, uv in pairs(CORNER_UV) do
        local m = f:CreateTexture(nil, "OVERLAY", nil, 6)
        m:SetTexture(UI .. "round" .. r .. "_mask")
        m:SetSize(16, 16)
        m:SetPoint(point, f, point, 0, 0)
        m:SetTexCoord(uv[1], uv[2], uv[3], uv[4])
        m:SetVertexColor(back[1], back[2], back[3], 1)
        if border then
            local a = f:CreateTexture(nil, "OVERLAY", nil, 7)
            a:SetTexture(UI .. "round" .. r .. "_ring")
            a:SetSize(16, 16)
            a:SetPoint(point, f, point, 0, 0)
            a:SetTexCoord(uv[1], uv[2], uv[3], uv[4])
            a:SetVertexColor(border[1], border[2], border[3], 1)
        end
    end
    return f
end

local function Shape(parent, file, size, color, layer, sub)
    local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
    t:SetTexture(UI .. file)
    t:SetSize(size, size)
    local c = Col(color)
    t:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
    return t
end

local function Square(parent, size, color, layer, sub)
    local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
    t:SetSize(size, size)
    local c = Col(color)
    t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    return t
end

--------------------------------------------------
-- Als Naechstes
--------------------------------------------------

local TEXT_X = 32 + HM.TILE + 28     -- Textblock rechts der Kachel

-- Ein Zauber in der Namenszeile: Symbol, Name, Rang; beim Drueberfahren
-- der Tooltip des Spiels.
local function BuildChip(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(HM.CHIP_H)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(HM.CHIP_H, HM.CHIP_H)
    b.icon:SetPoint("LEFT", b, "LEFT", 0, 0)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.name = Label(b, 13, "textNormal")
    b.name:SetPoint("LEFT", b.icon, "RIGHT", 7, 0)
    OneLine(b.name)
    b.rank = Label(b, 11, "textDim")
    b.rank:SetPoint("LEFT", b.name, "RIGHT", 5, 0)
    OneLine(b.rank)
    b.spellID = false
    b:SetScript("OnEnter", function(self)
        local gt = _G.GameTooltip
        if not (gt and self.spellID) then return end
        gt:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        if gt.SetSpellByID then gt:SetSpellByID(self.spellID) else gt:SetText(self.name:GetText()) end
        gt:Show()
    end)
    b:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    b:Hide()
    return b
end

-- Die Erfahrung beginnt `top` unter der Oberkante der Kachel.
function HM.PlaceXP(h, top)
    h.xp:ClearAllPoints()
    h.xp:SetPoint("TOPLEFT",  h, "TOPLEFT",  32, -top)
    h.xp:SetPoint("TOPRIGHT", h, "TOPRIGHT", -32, -top)
    h.xpTop = top
end

-- Platz der Namenszeile: gemessen; ohne Antwort der bei voller Breite.
function HM.ChipRoom(h)
    local w = Plain(h.chips:GetWidth())
    if type(w) == "number" and w > 0 then return w end
    local bw = Plain(h.button:GetWidth())
    bw = type(bw) == "number" and bw > 0 and bw or 140
    return HM.MAX_W - TEXT_X - 32 - bw - 28
end

-- Namen nebeneinander, solange sie passen; der Rest als "+N weitere".
-- Der erste steht immer (notfalls gekuerzt). h.chipNames/h.chipRest
-- halten fest, was zu sehen ist.
local MORE_W = 80
function HM.LayoutChips(h)
    local list, room = h.list or {}, HM.ChipRoom(h)
    local x, shown, names = 0, 0, {}
    for i, chip in ipairs(h.chip) do
        local it = list[i]
        local fits = false
        if it then
            chip.spellID = it.id
            chip.name:SetWidth(0)
            chip.name:SetText(it.name)
            chip.rank:SetText(it.sub or "")
            chip.rank:SetShown(it.sub and true or false)
            if it.icon then
                chip.icon:SetTexture(it.icon)
            else
                local c = Col("surface3")
                chip.icon:SetColorTexture(c[1], c[2], c[3], 1)
            end
            local w = HM.CHIP_H + 7 + TextWidth(chip.name, it.name, 13)
                + (it.sub and (5 + TextWidth(chip.rank, it.sub, 11)) or 0)
            local tail = (#list > i) and (HM.CHIP_GAP + MORE_W) or 0
            if shown == 0 and w + tail > room then
                -- Schon der erste passt nicht: gekuerzt, ohne Rang.
                local nw = math.max(24, room - tail - HM.CHIP_H - 7)
                chip.name:SetWidth(nw)
                chip.rank:Hide()
                w = HM.CHIP_H + 7 + nw
                fits = true
            elseif shown == i - 1 and x + w + tail <= room then
                fits = true
            end
            if fits then
                chip:ClearAllPoints()
                chip:SetPoint("LEFT", h.chips, "LEFT", x, 0)
                chip:SetWidth(w)
                x = x + w + HM.CHIP_GAP
                shown = shown + 1
                names[shown] = it.name
            end
        end
        chip:SetShown(fits)
    end
    h.chipNames, h.chipRest = names, #list - shown
    if h.chipRest > 0 then
        h.chipMore:SetText("+" .. h.chipRest .. (h.chipRest == 1 and " weiterer" or " weitere"))
        h.chipMore:ClearAllPoints()
        h.chipMore:SetPoint("LEFT", h.chips, "LEFT", x, 0)
        h.chipMore:Show()
    else
        h.chipMore:Hide()
    end
end

local function BuildHero(f)
    local h = HM.Box(f.inner, { radius = 14, fill = "surface2", border = "border", backdrop = "bgDark" })
    h:SetPoint("TOPLEFT",  f.inner, "TOPLEFT",  0, 0)
    h:SetPoint("TOPRIGHT", f.inner, "TOPRIGHT", 0, 0)
    h:SetHeight(HM.HERO_TOP + HM.XP_H + HM.HERO_PAD)

    h.tile = HM.Box(h, { radius = 12, fill = "bgDark", border = "border", backdrop = "surface2" })
    h.tile:SetSize(HM.TILE, HM.TILE)
    h.tile:SetPoint("TOPLEFT", h, "TOPLEFT", 32, -28)
    h.tileCap = Label(h.tile, 10, "textDim", true)
    -- Untereinander wie im Entwurf: Beschriftung (12), Zahl (40), Klasse
    -- (16), je 2 Abstand, zusammen mittig im Feld.
    h.tileCap:SetPoint("TOP", h.tile, "TOP", 0, -12)
    h.tileCap:SetText(HM.Tracked("Stufe"))
    h.level = WeintCodex.PageTitle(h.tile, "", { size = 40, justify = "CENTER" })
    h.level:SetPoint("TOP", h.tile, "TOP", 0, -26)
    h.class = Label(h.tile, 12, "accent", true)
    h.class:SetPoint("BOTTOMLEFT", h.tile, "BOTTOMLEFT", 4, 11)
    h.class:SetPoint("BOTTOMRIGHT", h.tile, "BOTTOMRIGHT", -4, 11)
    OneLine(h.class, "CENTER")

    h.button = WeintCodex.CreateButton(h, {
        text = "", kind = "primary", height = 42, backdrop = "surface2",
        onClick = function() Go(h.step) end,
    })
    h.button:SetPoint("RIGHT", h, "TOPRIGHT", -32, -(28 + HM.TILE / 2))
    h.eyebrow = Label(h, 11, "accent", true)
    h.eyebrow:SetPoint("TOPLEFT", h, "TOPLEFT", TEXT_X, -37)
    OneLine(h.eyebrow)
    h.title = WeintCodex.PageTitle(h, "", { size = 30 })
    h.title:SetPoint("TOPLEFT", h.eyebrow, "BOTTOMLEFT", 0, -6)
    h.title:SetPoint("RIGHT", h.button, "LEFT", -28, 0)
    OneLine(h.title)
    h.detail = Label(h, 14, "textMuted")
    h.detail:SetPoint("TOPLEFT", h.title, "BOTTOMLEFT", 0, -6)
    h.detail:SetPoint("RIGHT", h.button, "LEFT", -28, 0)
    OneLine(h.detail)

    -- Was man jetzt lernen kann: Symbol, Name, Rang in einer Zeile; was
    -- nicht passt, als Zahl dahinter.
    h.chips = CreateFrame("Frame", nil, h)
    h.chips:SetHeight(HM.CHIP_H)
    h.chips:SetPoint("TOPLEFT", h.detail, "BOTTOMLEFT", 0, -12)
    h.chips:SetPoint("RIGHT", h.button, "LEFT", -28, 0)
    h.chip = {}
    for i = 1, HM.CHIPS do h.chip[i] = BuildChip(h.chips) end
    h.chipMore = Label(h.chips, 12, "textDim")
    OneLine(h.chipMore)
    h.chips:Hide()
    h.list, h.listShown, h.chipNames, h.chipRest = {}, false, {}, 0
    h.chips:HookScript("OnSizeChanged", function() if h.listShown then HM.LayoutChips(h) end end)

    -- Erfahrung: Zeile, Leiste (erreicht + schraffiert nach Abgabe),
    -- Legende - in einem Rahmen, der mit der Namenszeile nach unten rueckt.
    h.xp = CreateFrame("Frame", nil, h)
    h.xp:SetHeight(HM.XP_H)
    HM.PlaceXP(h, HM.HERO_TOP)
    h.xpLeft = Label(h.xp, 13, "textMuted")
    h.xpLeft:SetPoint("TOPLEFT", h.xp, "TOPLEFT", 0, 0)
    OneLine(h.xpLeft)
    h.xpRight = Label(h.xp, 13, "textMuted")
    h.xpRight:SetPoint("TOPRIGHT", h.xp, "TOPRIGHT", 0, 0)
    OneLine(h.xpRight, "RIGHT")
    h.bar = CreateFrame("Frame", nil, h.xp)
    h.bar:SetHeight(10)
    h.bar:SetPoint("TOPLEFT", h.xp, "TOPLEFT", 0, -26)
    h.bar:SetPoint("TOPRIGHT", h.xp, "TOPRIGHT", 0, -26)
    h.barBg = Square(h.bar, 1, "surface3", "BACKGROUND")
    h.barBg:SetAllPoints(h.bar)
    h.barFill = Square(h.bar, 1, "accent", "ARTWORK")
    h.barFill:SetPoint("TOPLEFT", h.bar, "TOPLEFT", 0, 0)
    h.barFill:SetPoint("BOTTOMLEFT", h.bar, "BOTTOMLEFT", 0, 0)
    h.barQuest = Shape(h.bar, "stripes", 1, "accent", "ARTWORK", 1)
    h.barQuest:SetTexture(UI .. "stripes", "REPEAT", "REPEAT")
    h.barQuest:SetVertexColor(Col("accent")[1], Col("accent")[2], Col("accent")[3], 0.55)
    h.barCut = Square(h.bar, 1, "bgDark", "ARTWORK", 2)
    h.barCut:SetWidth(1)
    WeintCodex.CutCorners(h.bar, 5, "surface2")
    h.bar:HookScript("OnSizeChanged", function() HM.PaintBar(h) end)
    h.legend1 = Square(h.xp, 10, "accent")
    h.legend1:SetPoint("TOPLEFT", h.bar, "BOTTOMLEFT", 0, -10)
    h.legend1Text = Label(h.xp, 11, "textDim")
    h.legend1Text:SetPoint("LEFT", h.legend1, "RIGHT", 6, 0)
    h.legend1Text:SetText("erreicht")
    h.legend2 = Shape(h.xp, "stripes", 10, "accent")
    h.legend2:SetTexCoord(0, 10 / 32, 0, 10 / 32)
    h.legend2:SetPoint("LEFT", h.legend1Text, "RIGHT", 18, 0)
    h.legend2Text = Label(h.xp, 11, "textDim")
    h.legend2Text:SetPoint("LEFT", h.legend2, "RIGHT", 6, 0)
    h.legend2Text:SetText("nach Questabgabe")
    return h
end

-- Leiste malen: erreicht bis pct, schraffiert bis after.
function HM.PaintBar(h)
    local w = Plain(h.bar:GetWidth())
    if type(w) ~= "number" or w <= 0 or not h.pct then return end
    h.barFill:SetWidth(math.max(1, math.floor(w * h.pct + 0.5)))
    local extra = (h.after or h.pct) - h.pct
    if extra > 0 then
        local qw = math.max(1, math.floor(w * extra + 0.5))
        h.barQuest:ClearAllPoints()
        h.barQuest:SetPoint("TOPLEFT", h.barFill, "TOPRIGHT", 0, 0)
        h.barQuest:SetSize(qw, 10)
        h.barQuest:SetTexCoord(0, qw / 32, 0, 10 / 32)
        h.barQuest:Show()
        h.barCut:ClearAllPoints()
        h.barCut:SetPoint("TOPLEFT", h.barFill, "TOPRIGHT", 0, 0)
        h.barCut:SetPoint("BOTTOMLEFT", h.barFill, "BOTTOMRIGHT", 0, 0)
        h.barCut:Show()
    else
        h.barQuest:Hide()
        h.barCut:Hide()
    end
end

--------------------------------------------------
-- Ausserdem
--------------------------------------------------

local function BuildCard(parent, i)
    local c = HM.Box(parent, { radius = 12, fill = "surface2", border = "border", backdrop = "bgDark" })
    c:SetHeight(HM.CARD_H)
    local y = -(HM.HEAD + HM.HEAD_GAP) - (i - 1) * (HM.CARD_H + HM.CARD_GAP)
    c:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, y)
    c:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
    c.tile = HM.Box(c, { radius = 8, fill = "surface3", border = "borderStrong", backdrop = "surface2" })
    c.tile:SetSize(44, 44)
    c.tile:SetPoint("LEFT", c, "LEFT", 20, 0)
    c.icon = c.tile:CreateTexture(nil, "ARTWORK")
    c.icon:SetSize(24, 24)
    c.icon:SetPoint("CENTER", c.tile, "CENTER", 0, 0)
    local tc = Col("textNormal")
    c.icon:SetVertexColor(tc[1], tc[2], tc[3], 1)
    c.button = WeintCodex.CreateButton(c, {
        text = "", kind = "secondary", height = 38, backdrop = "surface2",
        onClick = function() Go(c.step) end,
    })
    c.button:SetPoint("RIGHT", c, "RIGHT", -20, 0)
    -- Kosten und Fehlbetrag stehen rechtsbuendig in einer Spalte, so breit
    -- wie der laengere der beiden (HM.FitMoney). Satz und kurze Zeile enden
    -- davor - bis 6.11.0.3 endeten sie vor den Kosten allein, und die Namen
    -- der Waffen liefen unter "es fehlen ..." durch (Beta-Test).
    c.money = CreateFrame("Frame", nil, c)
    c.money:SetSize(1, HM.CARD_H)
    c.money:SetPoint("RIGHT", c.button, "LEFT", -18, 0)
    c.moneyW = 0
    c.cost = Label(c, 14, "textNormal")
    c.cost:SetPoint("BOTTOMRIGHT", c.money, "RIGHT", 0, 2)
    OneLine(c.cost, "RIGHT")
    c.short = Label(c, 12, "warningBright")
    c.short:SetPoint("TOPRIGHT", c.money, "RIGHT", 0, -3)
    OneLine(c.short, "RIGHT")
    c.title = Label(c, 15, "textBright", true)
    c.title:SetPoint("BOTTOMLEFT", c.tile, "RIGHT", 18, 2)
    c.title:SetPoint("RIGHT", c.money, "LEFT", -18, 0)
    OneLine(c.title)
    c.sub = Label(c, 13, "textMuted")
    c.sub:SetPoint("TOPLEFT", c.tile, "RIGHT", 18, -3)
    c.sub:SetPoint("RIGHT", c.money, "LEFT", -18, 0)
    OneLine(c.sub)
    return c
end

--------------------------------------------------
-- Dein Weg
--------------------------------------------------

-- Was eine Stufe bringt, Zeile fuer Zeile (fuer den Tooltip): Zauber mit
-- Symbol und Rang, dann die Dungeons in Blau. Leer fuer "du" und "nichts"
-- (HM.Path kennt nur Stufen ueber der eigenen).
function HM.ColumnLines(m)
    local out = {}
    if type(m) ~= "table" then return out end
    for _, id in ipairs(m.ids or {}) do
        local name, sub, icon = HM.SpellLabel(id, "Zauber")
        local text = (icon and ("|T" .. tostring(icon) .. ":16:16:0:0:64:64:5:59:5:59|t ") or "") .. name
        if sub then text = text .. "  " .. WeintCodex.ColorText("textDim", sub) end
        out[#out + 1] = { text = text, color = "textNormal" }
    end
    for _, d in ipairs(m.dungeons or {}) do
        out[#out + 1] = { text = "Dungeon: " .. d, color = "infoBright" }
    end
    return out
end

local function ColumnTooltip(s)
    local gt = _G.GameTooltip
    local lines = HM.ColumnLines(s.m)
    if not (gt and #lines > 0) then return end
    gt:SetOwner(s, "ANCHOR_BOTTOM")
    local t = Col("textBright")
    gt:SetText("Stufe " .. s.m.level, t[1], t[2], t[3])
    for _, l in ipairs(lines) do
        local c = Col(l.color)
        gt:AddLine(l.text, c[1], c[2], c[3])
    end
    gt:Show()
end
HM.ColumnTooltip = ColumnTooltip

local function BuildColumn(card, i)
    -- Knopf, nicht Rahmen: die Namen stehen im Tooltip (die Spalte selbst
    -- hat nur Platz fuer "3 neue Zauber").
    local s = CreateFrame("Button", nil, card)
    s:SetHeight(HM.WEG_H)
    s.hl = s:CreateTexture(nil, "HIGHLIGHT")
    s.hl:SetPoint("TOPLEFT", s, "TOPLEFT", 4, -12)
    s.hl:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", -4, 12)
    local hc = Col("textBright")
    s.hl:SetColorTexture(hc[1], hc[2], hc[3], 0.04)
    s:SetScript("OnEnter", ColumnTooltip)
    s:SetScript("OnLeave", function() if _G.GameTooltip then _G.GameTooltip:Hide() end end)
    s:EnableMouse(false)
    s.ring = Shape(s, "disc", 20, "accent", "ARTWORK", 1)
    s.gap = Shape(s, "disc", 14, "surface2", "ARTWORK", 2)
    s.core = Shape(s, "disc", 8, "accent", "ARTWORK", 3)
    s.square = Square(s, 12, "textMuted", "ARTWORK", 1)
    s.diamond = Shape(s, "diamond", 15, "infoBright", "ARTWORK", 1)
    s.dot = Shape(s, "disc", 6, "borderStrong", "ARTWORK", 1)
    for _, t in ipairs({ s.ring, s.gap, s.core, s.square, s.diamond, s.dot }) do
        t:SetPoint("CENTER", s, "TOP", 0, -34)
    end
    s.level = Label(s, 13, "textNormal", true)
    s.level:SetPoint("TOPLEFT", s, "TOPLEFT", 2, -52)
    s.level:SetPoint("TOPRIGHT", s, "TOPRIGHT", -2, -52)
    OneLine(s.level, "CENTER")
    s.text = Label(s, 12, "textMuted")
    s.text:SetPoint("TOPLEFT", s, "TOPLEFT", 4, -78)
    s.text:SetPoint("TOPRIGHT", s, "TOPRIGHT", -4, -78)
    OneLine(s.text, "CENTER")
    -- Zweite Zeile als eigener Text (6.13.4.0). Bis dahin standen zwei
    -- Dungeons mit Zeilenumbruch in EINEM einzeiligen Text - das Spiel
    -- zeigte die erste Zeile mit "..." und verschluckte die zweite
    -- (Beta-Test, Stufe 17: "Wailing Caverns..." - The Deadmines fehlte).
    s.text2 = Label(s, 12, "textMuted")
    s.text2:SetPoint("TOPLEFT", s, "TOPLEFT", 4, -HM.LINE2_Y)
    s.text2:SetPoint("TOPRIGHT", s, "TOPRIGHT", -4, -HM.LINE2_Y)
    OneLine(s.text2, "CENTER")
    return s
end

local function Build()
    local M = WeintCodex.Metrics
    local f = CreateFrame("Frame", nil, WeintCodex.ContentPanel)
    f:SetAllPoints(WeintCodex.ContentPanel)
    f.inner = CreateFrame("Frame", nil, f)
    f.inner:SetPoint("TOP", f, "TOP", 0, -HM.TOP)
    f.inner:SetPoint("BOTTOM", f, "BOTTOM", 0, M.PAD_Y)
    f.hero = BuildHero(f)
    -- Felder vorbelegen: false statt nil (ein Rahmen kennt sonst nichts,
    -- und die Attrappe antwortet auf Unbekanntes mit einer Funktion).
    f.hero.pct, f.hero.after, f.wayPct, f.colCount = false, false, 0, 0

    -- Ausserdem: Ueberschrift + Karten.
    f.more = CreateFrame("Frame", nil, f.inner)
    f.more:SetPoint("TOPLEFT",  f.hero, "BOTTOMLEFT",  0, -HM.GAP)
    f.more:SetPoint("TOPRIGHT", f.hero, "BOTTOMRIGHT", 0, -HM.GAP)
    f.more.head = Label(f.more, 15, "textNormal", true)
    f.more.head:SetPoint("TOPLEFT", f.more, "TOPLEFT", 0, 0)
    f.more.head:SetText("Außerdem")
    f.more.count = Label(f.more, 13, "textDim")
    f.more.count:SetPoint("BOTTOMLEFT", f.more.head, "BOTTOMRIGHT", 10, 1)
    f.cards = {}
    for i = 1, HM.MAX_STEPS - 1 do f.cards[i] = BuildCard(f.more, i) end

    -- Dein Weg: Ueberschrift + Legende + Karte.
    f.way = CreateFrame("Frame", nil, f.inner)
    f.way:SetHeight(HM.HEAD + HM.HEAD_GAP + HM.WEG_H)
    f.way.head = Label(f.way, 15, "textNormal", true)
    f.way.head:SetPoint("TOPLEFT", f.way, "TOPLEFT", 0, 0)
    f.way.head:SetText("Dein Weg")
    f.way.sub = Label(f.way, 13, "textDim")
    f.way.sub:SetPoint("BOTTOMLEFT", f.way.head, "BOTTOMRIGHT", 10, 1)
    f.way.sub:SetText("Was die nächsten Stufen bringen")
    f.way.key2 = Label(f.way, 11, "textDim")
    f.way.key2:SetPoint("TOPRIGHT", f.way, "TOPRIGHT", 0, -3)
    f.way.key2:SetText("Dungeon öffnet")
    f.way.key2d = Shape(f.way, "diamond", 11, "infoBright")
    f.way.key2d:SetPoint("RIGHT", f.way.key2, "LEFT", -6, 0)
    f.way.key1 = Label(f.way, 11, "textDim")
    f.way.key1:SetPoint("RIGHT", f.way.key2d, "LEFT", -16, 0)
    f.way.key1:SetText("Zauber beim Lehrer")
    f.way.key1s = Square(f.way, 8, "textMuted")
    f.way.key1s:SetPoint("RIGHT", f.way.key1, "LEFT", -6, 0)
    f.way.card = HM.Box(f.way, { radius = 12, fill = "surface2", border = "border", backdrop = "bgDark" })
    f.way.card:SetPoint("TOPLEFT",  f.way, "TOPLEFT",  0, -(HM.HEAD + HM.HEAD_GAP))
    f.way.card:SetPoint("TOPRIGHT", f.way, "TOPRIGHT", 0, -(HM.HEAD + HM.HEAD_GAP))
    f.way.card:SetHeight(HM.WEG_H)
    local card = f.way.card
    -- Linie (2 hoch, oben verankert - siehe S.PixelY) und der Teil bis zur
    -- naechsten Stufe in der Klassenfarbe.
    f.track = Square(card, 1, "border", "ARTWORK")
    f.track:SetHeight(2)
    f.trackDone = Square(card, 1, "accent", "ARTWORK", 1)
    f.trackDone:SetHeight(2)
    f.cols = {}
    for i = 1, HM.WEG_COLS do f.cols[i] = BuildColumn(card, i) end
    f.wayEmpty = Label(card, 13, "textDim")
    f.wayEmpty:SetPoint("LEFT", card, "LEFT", 24, 0)
    f.wayEmpty:SetPoint("RIGHT", card, "RIGHT", -24, 0)
    OneLine(f.wayEmpty, "CENTER")

    local function resize()
        f.inner:SetWidth(HM.InnerWidth(Plain(f:GetWidth())))
        HM.PlaceColumns(f)
        HM.PaintBar(f.hero)
        if f.hero.listShown then HM.LayoutChips(f.hero) end
    end
    f:HookScript("OnSizeChanged", resize)
    card:HookScript("OnSizeChanged", function() HM.PlaceColumns(f) end)
    resize()
    return f
end

-- Breite innen: was der Inhaltsbereich hergibt, hoechstens HM.MAX_W.
function HM.InnerWidth(w)
    local M = WeintCodex.Metrics
    w = type(w) == "number" and w > 0 and (w - 2 * M.PAD_X) or HM.MAX_W
    return math.max(1, math.min(HM.MAX_W, math.floor(w)))
end

-- Acht gleich breite Spalten; die Linie von der Mitte der ersten bis zur
-- Mitte der letzten, der farbige Teil so lang wie der Anteil der
-- Erfahrung an einer Spalte.
function HM.PlaceColumns(f)
    local card = f.way.card
    local w = Plain(card:GetWidth())
    w = type(w) == "number" and w > 0 and w or HM.MAX_W
    local cw = math.floor((w - 16) / HM.WEG_COLS)
    for i, s in ipairs(f.cols) do
        s:ClearAllPoints()
        s:SetPoint("TOPLEFT", card, "TOPLEFT", 8 + (i - 1) * cw, 0)
        s:SetWidth(cw)
    end
    local half = math.floor(cw / 2)
    f.track:ClearAllPoints()
    f.track:SetPoint("TOPLEFT", card, "TOPLEFT", 8 + half, -33)
    f.track:SetWidth(math.max(1, (HM.WEG_COLS - 1) * cw))
    f.trackDone:ClearAllPoints()
    f.trackDone:SetPoint("TOPLEFT", card, "TOPLEFT", 8 + half, -33)
    f.trackDone:SetWidth(math.max(1, math.floor(cw * (f.wayPct or 0) + 0.5)))
    f.trackDone:SetShown((f.wayPct or 0) > 0 and (f.colCount or 0) > 1)
    f.colWidth = cw
end

-- Die naechsten n Stufen ab der eigenen, jede einzeln (auch ohne Neues).
-- Rueckgabe { { level, spells, dungeons, current } }, nil ohne Stufe.
function HM.Levels(ctx, n)
    if type(ctx.level) ~= "number" then return nil end
    local by = {}
    for _, m in ipairs(HM.Path(ctx, 99) or {}) do by[m.level] = m end
    local out = {}
    for i = 0, (n or HM.WEG_COLS) - 1 do
        local l = ctx.level + i
        local m = by[l]
        out[#out + 1] = { level = l, current = (i == 0), spells = m and m.spells or 0,
                          ids = m and m.ids or {}, dungeons = m and m.dungeons or {} }
    end
    return out
end

-- Hoehe der Seite mit allen Schritten - der Prueflauf haelt sie gegen das
-- kleinste Fenster (CLAUDE.md: "Nichts muss scrollen").
function HM.PageHeight()
    local more = HM.HEAD + HM.HEAD_GAP + (HM.MAX_STEPS - 1) * HM.CARD_H + (HM.MAX_STEPS - 2) * HM.CARD_GAP
    return HM.TOP + HM.HERO_TOP + HM.LIST_H + HM.XP_H + HM.HERO_PAD + HM.GAP + more + HM.GAP
        + HM.HEAD + HM.HEAD_GAP + HM.WEG_H
end

--------------------------------------------------
-- Fuellen
--------------------------------------------------

-- Was von einem Text zu sehen ist: ohne Farbcodes, ein Bild (Muenze) wie
-- zwei Zeichen - fuer die Schaetzung der Breite.
function HM.Visible(text)
    return (tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "00"))
end

-- Spalte fuer Kosten und Fehlbetrag so breit wie der laengere (was fehlt,
-- steht leer da und zaehlt 0).
function HM.FitMoney(c)
    local w = math.max(TextWidth(c.cost, HM.Visible(c.cost:GetText()), 14),
                       TextWidth(c.short, HM.Visible(c.short:GetText()), 12))
    c.moneyW = math.ceil(w)
    c.money:SetWidth(math.max(1, c.moneyW))
end

local function FillCard(c, step)
    c.step = step
    if not step then c:Hide() return end
    c:Show()
    c.iconPath = HM.ICONS[step.key] or (UI .. "icon_check")
    c.icon:SetTexture(c.iconPath)
    c.title:SetText(step.title or "")
    -- Mit Namen: erst was, dann wo ("Bogen, Dolche – optional, beim
    -- Waffenmeister"); zu lang kuerzt die Zeile am Ende.
    local names = {}
    for i, id in ipairs(step.spells or {}) do names[i] = (HM.SpellLabel(id, step.unnamed)) end
    if #names > 0 and step.where then
        c.sub:SetText(table.concat(names, ", ") .. " – " .. step.where)
    else
        c.sub:SetText(step.sub or step.detail or "")
    end
    if type(step.cost) == "number" then
        c.cost:SetText(HM.Coins(step.cost))
        c.cost:Show()
    else
        c.cost:SetText("")
        c.cost:Hide()
    end
    if type(step.short) == "number" and step.short > 0 then
        c.short:SetText("es fehlen " .. HM.Coins(step.short))
        c.shortColor = step.optional and "warningBright" or "dangerBright"
        SetColor(c.short, c.shortColor)
        c.short:Show()
    else
        c.short:SetText("")
        c.short:Hide()
    end
    HM.FitMoney(c)
    if step.action then
        c.button:SetText(step.action)
        c.button:Show()
    else
        c.button:Hide()
    end
end

-- Die zwei Zeilen unter einer Stufe mit Dungeon: erster Dungeon, dann
-- der zweite (bei mehr: "+N weitere", alle im Tooltip) oder die Zauber.
function HM.ColumnText(m)
    local d = m.dungeons or {}
    local l1 = { text = d[1], color = "infoBright" }
    local l2
    if #d == 2 then
        l2 = { text = d[2], color = "infoBright" }
    elseif #d > 2 then
        l2 = { text = "+" .. (#d - 1) .. " weitere", color = "infoBright" }
    elseif (m.spells or 0) > 0 then
        l2 = { text = Plural(m.spells, "ein neuer Zauber", "neue Zauber"), color = "textMuted" }
    end
    return l1, l2
end

local function FillColumn(s, m)
    s.m = m
    if not m then s:Hide() return end
    s:Show()
    s.text2:SetText("")
    local kind = m.current and "current" or (#m.dungeons > 0 and "dungeon") or (m.spells > 0 and "spells") or "none"
    s.kind = kind
    s.ring:SetShown(kind == "current")
    s.gap:SetShown(kind == "current")
    s.core:SetShown(kind == "current")
    s.square:SetShown(kind == "spells")
    s.diamond:SetShown(kind == "dungeon")
    s.dot:SetShown(kind == "none")
    s:EnableMouse(kind == "spells" or kind == "dungeon")
    if kind == "none" then
        s.level:SetText(tostring(m.level))
        SetColor(s.level, "textFaint")
        s.text:SetText("")
        return
    end
    s.level:SetText("Stufe " .. m.level)
    SetColor(s.level, kind == "current" and "accent" or "textNormal")
    if kind == "current" then
        s.text:SetText("du bist hier")
        SetColor(s.text, "textMuted")
    elseif kind == "dungeon" then
        local l1, l2 = HM.ColumnText(m)
        s.text:SetText(l1.text)
        SetColor(s.text, l1.color)
        if l2 then
            s.text2:SetText(l2.text)
            SetColor(s.text2, l2.color)
        end
    else
        s.text:SetText(Plural(m.spells, "ein neuer Zauber", "neue Zauber"))
        SetColor(s.text, "textMuted")
    end
end

local function FillHero(h, ctx, steps, path)
    local step = steps[1]
    h.step = step
    h.level:SetText(type(ctx.level) == "number" and tostring(ctx.level) or "–")
    h.class:SetText(ctx.className or "")
    if step then
        h.eyebrow:SetText(HM.Tracked("Als Nächstes · " .. (step.label or "")))
        h.title:SetText(step.headline or step.title or "")
        h.detail:SetText(step.detail or "")
        SetColor(h.detail, step.tone == "danger" and "dangerBright" or "textMuted")
    else
        h.eyebrow:SetText(HM.Tracked("Als Nächstes"))
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

    -- Die Namen (Lehrer, Waffen): Textblock an die Oberkante der Kachel,
    -- die Erfahrung um HM.LIST_H tiefer.
    local list = {}
    for i, id in ipairs(step and step.spells or {}) do
        local name, sub, icon = HM.SpellLabel(id, step.unnamed)
        list[i] = { id = id, name = name, sub = sub, icon = icon }
    end
    h.list, h.listShown = list, #list > 0
    h.chips:SetShown(h.listShown)
    h.eyebrow:ClearAllPoints()
    h.eyebrow:SetPoint("TOPLEFT", h, "TOPLEFT", TEXT_X, h.listShown and -28 or -37)
    if h.listShown then
        HM.LayoutChips(h)
    else
        h.chipNames, h.chipRest = {}, 0
    end
    local top = HM.HERO_TOP + (h.listShown and HM.LIST_H or 0)
    HM.PlaceXP(h, top)

    -- Erfahrung: dieselbe Auskunft wie der Erfahrungsbalken; ohne sie
    -- (Hoechststufe, gesperrt, keine Antwort) kein Block - nie 0 %.
    local xp = ctx.xp
    local show = xp and type(xp.cur) == "number" and type(xp.max) == "number" and xp.max > 0
    for _, r in ipairs({ h.xpLeft, h.xpRight, h.bar, h.legend1, h.legend1Text }) do r:SetShown(show and true or false) end
    if not show then
        h.pct, h.after = false, false
        h.legend2:Hide()
        h.legend2Text:Hide()
        h:SetHeight(top)
        return
    end
    h:SetHeight(top + HM.XP_H + HM.HERO_PAD)
    h.pct = math.max(0, math.min(1, xp.cur / xp.max))
    local nextLevel = type(ctx.level) == "number" and tostring(ctx.level + 1) or "?"
    h.xpLeft:SetText(WeintCodex.ColorText("textNormal", Thousands(xp.cur)) .. " / " .. Thousands(xp.max)
        .. " EP bis Stufe " .. nextLevel .. " · " .. math.floor(h.pct * 100) .. " %")
    local q = ctx.quests
    local ready = q and type(q.ready) == "number" and q.ready > 0 and q.ready or nil
    local right = {}
    if ready then
        local sum = xp.cur + ready
        h.after = math.min(1, sum / xp.max)
        if sum >= xp.max then
            right[#right + 1] = "nach Abgabe " .. WeintCodex.ColorText("accent", "Stufe " .. nextLevel)
        else
            right[#right + 1] = "nach Abgabe " .. WeintCodex.ColorText("accent", math.floor(h.after * 100) .. " %")
        end
    else
        h.after = false
    end
    if type(xp.rested) == "number" and xp.rested > 0 then
        right[#right + 1] = "erholt " .. Thousands(xp.rested) .. " EP"
    end
    h.xpRight:SetText(table.concat(right, " · "))
    h.legend2:SetShown(ready and true or false)
    h.legend2Text:SetShown(ready and true or false)
    HM.PaintBar(h)
end

-- Zustand der Seite fuer Pruefung und Bericht.
HM.last = nil

function HM.Fill(f, ctx)
    HM.lastCtx = ctx
    local steps = HM.Steps(ctx)
    local path = HM.Path(ctx)
    FillHero(f.hero, ctx, steps, path)

    -- Ausserdem
    local extra = math.max(0, #steps - 1)
    for i, c in ipairs(f.cards) do FillCard(c, steps[i + 1]) end
    f.way:ClearAllPoints()
    if extra > 0 then
        f.more:Show()
        f.more.count:SetText(extra == 1 and "1 weiterer Schritt" or (extra .. " weitere Schritte"))
        local h = HM.HEAD + HM.HEAD_GAP + extra * HM.CARD_H + (extra - 1) * HM.CARD_GAP
        f.more:SetHeight(h)
        f.way:SetPoint("TOPLEFT",  f.more, "BOTTOMLEFT",  0, -HM.GAP)
        f.way:SetPoint("TOPRIGHT", f.more, "BOTTOMRIGHT", 0, -HM.GAP)
    else
        f.more:Hide()
        f.way:SetPoint("TOPLEFT",  f.hero, "BOTTOMLEFT",  0, -HM.GAP)
        f.way:SetPoint("TOPRIGHT", f.hero, "BOTTOMRIGHT", 0, -HM.GAP)
    end

    -- Dein Weg
    local levels = HM.Levels(ctx, HM.WEG_COLS)
    local hasAny = false
    for _, m in ipairs(levels or {}) do
        if not m.current and (m.spells > 0 or #m.dungeons > 0) then hasAny = true end
    end
    if levels and hasAny then
        f.wayEmpty:Hide()
        for i, s in ipairs(f.cols) do FillColumn(s, levels[i]) end
        f.colCount = #levels
        f.track:Show()
    else
        for _, s in ipairs(f.cols) do FillColumn(s, nil) end
        f.colCount = 0
        f.track:Hide()
        f.wayEmpty:SetText(levels and "In den nächsten Stufen ist nichts Neues bekannt."
            or "Ohne deine Stufe lässt sich der Weg nicht zeigen.")
        f.wayEmpty:Show()
    end
    f.wayPct = (f.colCount > 1 and f.hero.pct) or 0
    HM.PlaceColumns(f)

    HM.last = { steps = steps, path = path, levels = levels, headline = f.hero.title:GetText() }
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
    -- Nachrichten an die Companion warten: der Punkt steht an Companion
    -- (bis 6.12 an Import, das seit 6.13.0.0 keinen Eintrag mehr hat).
    nav.SetTabBadge("companion", queue > 0, "accent")
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
