--------------------------------------------------
-- WeintCodex :: Oberflaeche - Fenster des Spiels
--------------------------------------------------
-- Das Charakterfenster (Taste C) mit seinen Reitern Ruf, Fertigkeiten,
-- PvP und Abzeichen im Stil der Oberflaeche (Beta-Test: "auch hier soll
-- das neue Design Einheit gebieten"): Kachel statt Holz und Metall, ohne
-- das runde Portraet, der Titel in unserer Schrift.
--
-- ERSTE STUFE (6.3.1.6) WAR NUR DIE HUELLE; die zweite (6.3.1.7, unten)
-- blendet im Inneren aus, was /wcui fenster im Beta-Test benannt hat.
-- Urspruenglich: Wie die Fenster dieses Clients
-- innen aufgebaut sind, hat niemand gemessen. Ausgeblendet werden deshalb
-- nur Teile, die in der Fenstervorlage des Spiels Schmuck sind
-- (NineSlice, Bg, Inset, Portraet) - nie Inhalte: Plaetze, Balken,
-- Listen und Modell bleiben unberuehrt. Was danach noch nach Holz
-- aussieht, nennt /wcui fenster (Maus ueber das Fenster).
--
-- 6.4.1.2: auch das Zauberbuch (Beta-Test: "auch hier soll das UI
-- einheitlich mit WeintCodex sein"). Wie es im Forever-Client heisst und
-- aufgebaut ist, hat niemand gemessen - der Screenshot sieht anders aus
-- als das Zauberbuch im Quelltext des Spiels. Deshalb dieselbe Vorsicht:
-- beide Namen des Spiels (PlayerSpellsFrame, SpellBookFrame), die Atlanten
-- des Quelltexts als Muster, und was allgemein gilt, allgemein: dunkle
-- Schrift fuer Pergament wird auf der dunklen Kachel hell, Zaubersymbole
-- bekommen den eckigen Rand der Aktionsleisten. Was danach noch nach
-- Pergament aussieht, nennt /wcui fenster.
--
-- Nur Aussehen, nur Deckkraft: nichts wird versteckt, umgehaengt oder
-- verschoben. Die Einstellung liegt beim Modul "general" (Seite
-- "Fenster"), wie der Tooltip - die Seitenleiste ist voll.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.UIWindows = {}

local W = WeintCodex.UIWindows
local K = WeintCodex.UIKit
local C = WeintCodex.Colors
-- Bausteine der Designsprache (6.7.0.0): ui/style.lua.
local S = WeintCodex.UIStyle
local scoped = S.scoped

W.DEFAULTS = {
    windowSkin = true,
    -- 6.4.1.4: Talent-Landschaften gedaempft statt weg, Schein in der
    -- Klassenfarbe oben in jedem Fenster ("nur schwarz ist langweilig").
    windowArt  = true,
    -- 6.6.2.1: die Weltkarte (M) einzeln abschaltbar. Die Karte war schon
    -- einmal empfindlich (6.6.0.1: Questmarken im Kampf blockiert, weil
    -- Addon-Code die Karte umgestellt hatte). Hier wird nur Aussehen
    -- geaendert - sollte trotzdem "Aktion blockiert" an der Karte
    -- auftauchen, geht sie mit einem Schalter zurueck.
    mapSkin    = true,
}

local function Opt(k) return K.Get("general", k) end

-- Fenster und ihre Teilfenster. Was der Client nicht kennt, faellt heraus.
W.WINDOWS = { "CharacterFrame", "PVPFrame", "HonorFrame", "PlayerSpellsFrame", "SpellBookFrame",
              "PlayerTalentFrame", "TalentFrame", "ClassTalentFrame",
              "GossipFrame", "QuestFrame", "ItemTextFrame", "MerchantFrame",
              -- 6.6.2.1: Berufe (Blizzard_Professions) und Gilde & Communitys
              -- (Blizzard_Communities), beide erst beim ersten Oeffnen geladen.
              "ProfessionsFrame", "CommunitiesFrame",
              -- 6.6.2.2: "Suche nach Gruppe" (Dungeonbrowser). Im Forever-Client
              -- LFGParentFrame (gemessen), im Quelltext des Spiels PVEFrame.
              "LFGParentFrame", "PVEFrame",
              -- 6.6.3.3: das Spielmenue (Esc), Beta-Test: "Redesign soll auch im
              -- Optionsmenue Einheit finden".
              "GameMenuFrame",
              -- 6.6.3.3: Sammlung (Blizzard_Collections, erst beim Oeffnen geladen).
              "CollectionsJournal" }

-- SPIELMENUE (6.6.3.3, gemessen mit /wcui fenster): rote Knoepfe
-- ("128-RedButton-Left/Center/Right/Highlight"), Rahmen und Kopf aus
-- Diamantmetall ("UI-Frame-DiamondMetal-*") und ein Grund am Rahmen (Bild
-- 131071). Rahmen und Kopf weg, Kachel wie jedes Fenster, die Knoepfe
-- flach wie "Aenderungen anwenden". Ueber das Menue laufen Ausloggen,
-- Beenden und der Bearbeitungsmodus - geaendert werden nur Bilder, kein
-- Skript und kein Feld am Menue.
-- Kein Schatten ausserhalb: das Menue ordnet seine Knoepfe selbst an und
-- richtet seine Groesse danach; ein Bild, das ueber den Rand ragt, soll
-- dabei nicht mitgerechnet werden koennen.
W.EXTRA_DECOR = { GameMenuFrame = { "Border", "Header" } }

-- SAMMLUNG (6.6.3.3, gemessen mit /wcui fenster): aussen Metallrahmen,
-- Portraet, Marmor (Bild 374155) - das nimmt die Kachel. Innen, unter den
-- Vorlagen, Leder (Bild 374154) mit Kachelmuster, Schatten und
-- Eckverzierungen ("collections-background-*"). Die Flaeche innen wird
-- eine Innenflaeche wie ueberall: eigene Bilder weg, etwas dunkler.
-- Pfade statt globaler Namen: die Teilfenster haben keine.
W.OWN_BG_PATHS = { "WardrobeCollectionFrame.ItemsCollectionFrame" }
W.NO_SHADOW = { GameMenuFrame = true }

-- GESPRAECHE (6.6.1.4, Beta-Test: "die normale Interaktion von
-- Questgebern, Gastwirten etc. muss angeglichen werden"). Gespraech,
-- Questtext, Buecher und Briefe stehen im Spiel auf Pergament mit
-- dunkelbrauner Schrift. Dieselbe Behandlung wie das Zauberbuch: das
-- Pergament (ein grosses Bild) weg, dunkle Schrift hell - dazu die
-- Farbcodes IM Text: die Gespraechsoptionen setzen Questnamen als
-- |cff000000...|r in den Text, nicht als Schriftfarbe. Der Haendler hat
-- kein Pergament; er bekommt nur die Huelle und die Knoepfe.
W.DIALOGS = { GossipFrame = true, QuestFrame = true, ItemTextFrame = true }
-- Teile, die beim Blaettern im offenen Fenster erscheinen (Quest
-- annehmen -> abgeben): beim Zeigen sofort nachziehen, nicht erst mit
-- dem Takt.
W.SHOW_HOOKS = { "QuestFrameDetailPanel", "QuestFrameRewardPanel", "QuestFrameProgressPanel",
                 "QuestFrameGreetingPanel" }

-- Zauberbuch und Talente (6.4.1.3): ihre Hintergruende heissen im
-- Forever-Client anders als im Quelltext des Spiels (Beta-Test 6.4.1.2:
-- das Pergament blieb). Dort werden deshalb zusaetzlich GROSSE Bilder
-- ausgeblendet - erkannt an der Flaeche, nicht am Namen: Pergament,
-- Buchseiten, die Landschaften hinter den Talentbaeumen. Symbole, Pfeile,
-- Reiter und Knoepfe sind klein und bleiben. Gefunden werden die Fenster
-- auch ueber ihren Namen, wenn der nicht in der Liste steht (Haken auf
-- ShowUIPanel).
-- 6.6.2.1: auch die Berufe - hinter Rezept und Uebersicht liegen grosse
-- Bilder (Amboss, Werkbank), die wie die Talent-Landschaften gedaempft
-- werden statt zu verschwinden.
local LARGE_PATTERNS = { "Spell", "Talent", "Profession" }
function W.WantsLarge(name)
    if type(name) ~= "string" then return false end
    for _, pat in ipairs(LARGE_PATTERNS) do
        if name:find(pat, 1, true) then return true end
    end
    return false
end
W.LARGE_SHARE = 0.15   -- ab diesem Anteil an der Fensterflaeche ist ein Bild Hintergrund
-- Teilfenster, deren eigene Bilder der Grund sind (gemessen, 6.6.2.2):
-- die Liste im Dungeonbrowser liegt auf Marmor (Bild 374155).
W.OWN_BG = { "LFGListingFrame" }
W.PANELS  = { "PaperDollFrame", "ReputationFrame", "SkillFrame", "SkillsFrame", "TokenFrame", "PVPFrame", "HonorFrame",
              "CharacterStatsPane" }

-- Schmuck in der Fenstervorlage des Spiels, als Schluessel am Rahmen.
local DECOR = { "NineSlice", "Bg", "Background", "TopTileStreaks", "Inset", "InsetBg",
                "PortraitContainer", "PortraitFrame", "PortraitButton", "portrait", "TitleBg", "TopBorder" }

local done = {}
W.done = done
-- Reiter des Charakterfensters mit eigener Gestaltung: { Update(f), Report(f, out) }.
-- Sie tragen sich selbst ein (ui/register.lua, ui/pvp.lua).
W.TABS = {}
-- Register in anderen Fenstern (6.7.5.0, Berufe): Name des Fensters ->
-- Liste von Modulen {Update(f), Report(f, out)}. W.Inner ruft sie, wenn
-- das Fenster offen ist.
W.HOSTED = {}
local own = S.own   -- unsere eigenen Flaechen (dieselbe Tabelle wie in ui/style.lua)
W.own = own

-- Was die zweite Stufe tut, fuer /wcui fenster (6.3.1.8: im Beta-Test
-- blieb 6.3.1.7 ohne sichtbare Wirkung, und ohne Zahlen ist nicht zu
-- unterscheiden, ob sie nicht lief, nichts fand oder das Spiel die
-- Deckkraft zuruecksetzt).
local stats = { runs = 0, hidden = 0, stuck = 0, last = nil, err = nil }
W.stats = stats

--------------------------------------------------
-- Listen ohne Muell (6.6.2.6)
--------------------------------------------------
-- Beta-Test: "egal welches Fenster ich oeffne, der Speicher geht super
-- schnell Richtung 40 MB, kleine Ruckler, FPS von 90 auf 75". Der Takt
-- unten lief alle 0,5 s ueber JEDES gestaltete Fenster (auch geschlossene)
-- und legte fuer jeden Rahmen zwei neue Tabellen und fuer jede Flaeche
-- eine neue Funktion an (pcall(function() return { f:GetRegions() } end)).
-- Bei Hunderten Flaechen je Fenster und einem Dutzend Durchlaeufen sind
-- das Megabyte Muell je Sekunde, und der Sammler raeumt ihn in Rucken weg.
-- Jetzt: je Durchlauf und Tiefe EINE Liste, die wiederverwendet wird, und
-- Pruefungen als feste Funktionen - pcall(Fn, r) legt nichts an.
local regionPool, childPool = {}, {}

local function Pack(t, ok, ...)
    local n = 0
    if ok then
        n = select("#", ...)
        for i = 1, n do t[i] = (select(i, ...)) end
    end
    for i = n + 1, t.n do t[i] = nil end
    t.n = n
    return t
end

local function Slot(pool, key, depth)
    local p = pool[key]
    if not p then p = {} pool[key] = p end
    local t = p[depth]
    if not t then t = { n = 0 } p[depth] = t end
    return t
end

local function GetRegionsOf(f) return f:GetRegions() end
local function GetChildrenOf(f) return f:GetChildren() end

-- Flaechen bzw. Kindrahmen von f in einer wiederverwendeten Liste. key
-- nennt den Durchlauf, depth seine Tiefe: die Liste gilt, bis derselbe
-- Durchlauf in derselben Tiefe wieder fragt. Wer sie behalten will, kopiert.
local function Regions(f, key, depth)
    return Pack(Slot(regionPool, key, depth or 0), pcall(GetRegionsOf, f))
end
local function Children(f, key, depth)
    return Pack(Slot(childPool, key, depth or 0), pcall(GetChildrenOf, f))
end
W.Regions, W.Children = Regions, Children

local function IsTexture(r) return r:GetObjectType() == "Texture" end
local function IsFontString(r) return r:GetObjectType() == "FontString" end
local function IsButton(r) return r:GetObjectType() == "Button" end
local function TextureAtlas(r)
    if r:GetObjectType() ~= "Texture" then return nil end
    return r.GetAtlas and r:GetAtlas()
end
local BLACK = { 0, 0, 0 }

local function Hide(r)
    if type(r) ~= "table" or not r.SetAlpha or (r.IsForbidden and r:IsForbidden()) then return end
    local AB = WeintCodex.UIActionBars
    if AB and AB.KeepHidden then AB.KeepHidden(r) else r:SetAlpha(0) end
    if K.Plain(r:GetAlpha()) ~= 0 then stats.stuck = stats.stuck + 1 end
end

-- Alle Texturen direkt an einem Rahmen (nicht an seinen Kindern).
local function HideOwnTextures(f)
    if type(f) ~= "table" or not f.GetRegions then return end
    for _, r in ipairs(Regions(f, "ownTex")) do
        local tok, isTex = pcall(IsTexture, r)
        if tok and isTex then Hide(r) end
    end
end

-- Ein Schmuckteil: ist es ein Rahmen, seine Texturen (und die seiner
-- NineSlice); ist es eine Textur, sie selbst.
local function HideDecor(part)
    if type(part) ~= "table" then return end
    local ok, kind = pcall(function() return part:GetObjectType() end)
    if not ok then return end
    if kind == "Texture" then
        Hide(part)
    else
        HideOwnTextures(part)
        if type(part.NineSlice) == "table" then HideOwnTextures(part.NineSlice) end
        if type(part.Bg) == "table" then Hide(part.Bg) end
        if type(part.portrait) == "table" then Hide(part.portrait) end
    end
end

-- Portraet-Rahmen ganz ausblenden, nicht nur ihre Texturen: im
-- Talentfenster blieb das runde Symbol oben links stehen (Beta-Test
-- 6.4.1.4) - es liegt tiefer als eine Textur des Rahmens.
-- Das Gildenwappen oben links an Gilde & Communitys (PortraitOverlay)
-- bleibt: 6.6.2.2 hatte es ausgeblendet, der Beta-Test wollte es zurueck.
local WHOLE = { PortraitContainer = true, PortraitFrame = true, PortraitButton = true }

W.Hide, W.HideDecor = Hide, HideDecor

local function HideDecorOf(f)
    local fname = f.GetName and f:GetName()
    for _, key in ipairs(type(fname) == "string" and W.EXTRA_DECOR[fname] or {}) do
        HideDecor(f[key])
    end
    for _, key in ipairs(DECOR) do
        HideDecor(f[key])
        if WHOLE[key] and type(f[key]) == "table" and f[key].GetObjectType then Hide(f[key]) end
    end
    local name = f.GetName and f:GetName()
    if type(name) == "string" then
        for _, suffix in ipairs({ "Bg", "Inset", "InsetRight", "InsetLeft", "Portrait", "TitleBg" }) do
            HideDecor(_G[name .. suffix])
        end
    end
end

local function StyleTitle(f)
    local title = (type(f.TitleContainer) == "table" and f.TitleContainer.TitleText) or f.TitleText
        or (f.GetName and f:GetName() and _G[f:GetName() .. "TitleText"])
    -- Spielmenue: der Titel steht im Kopf (.Header.Text), der ueber dem
    -- oberen Rand sass - ohne den Kopf rueckt er in die Kachel.
    local header = type(f.Header) == "table" and f.Header.Text
    if type(title) ~= "table" and type(header) == "table" and header.SetPoint then
        title = header
        pcall(function()
            title:ClearAllPoints()
            title:SetPoint("TOP", f, "TOP", 0, -14)
        end)
    end
    if type(title) == "table" and title.SetTextColor then
        K.SetFont(title, 13)
        title:SetTextColor(unpack(C.textBright))
    end
end

-- Ein Fenster: Schmuck weg, eine Kachel darunter, Titel in unserer
-- Schrift. `panel` = Teilfenster in einem anderen Fenster: keine eigene
-- Kachel, nur der Schmuck weg.
function W.Skin(f, panel)
    if type(f) ~= "table" or done[f] or (f.IsForbidden and f:IsForbidden()) then return done[f] end
    local d = {}
    done[f] = d
    HideDecorOf(f)
    if not panel then
        HideOwnTextures(f)
        local fname = f.GetName and f:GetName()
        d.kachel = K.Kachel(f, { alpha = 0.94, shadow = (type(fname) == "string" and W.NO_SHADOW[fname]) and 0 or 8 })
        own[d.kachel.bg], own[d.kachel.light] = true, true
        if d.kachel.shadow and d.kachel.shadow.tex then own[d.kachel.shadow.tex] = true end
        W.AddGlow(f, d)
        StyleTitle(f)
    end
    -- Innenflaechen (Inset): etwas heller als die Kachel, damit Spalten
    -- lesbar getrennt bleiben.
    for _, key in ipairs({ "Inset", "InsetRight", "InsetLeft" }) do
        local inset = f[key]
        if type(inset) ~= "table" and f.GetName and f:GetName() then inset = _G[f:GetName() .. key] end
        if type(inset) == "table" and inset.CreateTexture and not d[key] then
            local t = inset:CreateTexture(nil, "BACKGROUND", nil, -8)
            t:SetAllPoints(inset)
            local s = C.surface1
            t:SetColorTexture(s[1], s[2], s[3], 0.45)
            own[t] = true
            d[key] = t
        end
    end
    return d
end

--------------------------------------------------
-- Zweite Stufe: das Innere, nach Namen (6.3.1.7)
--------------------------------------------------
-- /wcui fenster im Beta-Test nannte, was im Charakterfenster nach Holz
-- und Stein aussieht - alles Atlanten des Spiels mit sprechenden Namen.
-- Ausgeblendet wird genau das, jeweils als Muster (Klassenhintergrund:
-- "UI-Character-Info-Warrior-BG" gibt es je Klasse). Der Hintergrund der
-- Modellszene (RaceBG) bleibt: er ist die Buehne des Modells, kein Rahmen.
W.HIDE_ATLAS = {
    "^UI%-Character%-Info%-General%-BG",     -- linke Haelfte
    "^UI%-Character%-Info%-Stat%-BG",        -- rechte Haelfte
    "^UI%-Character%-Info%-Stat%-StoneBG",
    "^UI%-Character%-Info%-%a+%-BG$",        -- Klassenhintergrund der Werte
    "^UI%-Character%-Info%-Title",           -- Holzbalken "Allgemein" usw.
    "^common%-button%-list%-collapseExpand", -- Grund der Kopfzeilen in Ruf und Fertigkeiten (6.6.2.9)
    "^UI%-Character%-Info%-Line%-Bounce",    -- Streifen hinter den Werten
    "^UI%-Character%-Info%-GearSlot",        -- Metallrahmen der Plaetze
    "^UI%-Character%-Info%-Divider",
    "^UI%-Character%-Info%-ScrollLine",      -- Linien ueber/unter Listen
    "^common%-insideframe",
    "^common%-framedivider",                 -- senkrechte Trennlinie
    "^common%-stat%-bar%-BG",                -- Rahmen der Ruf-/Fertigkeitsbalken
    "^common%-sidetab",                      -- Goldrahmen der Reiter rechts
    "^_?128%-RedButton%-",                   -- rote Knoepfe im Spielmenue (6.6.3.3)
    "^collections%-background%-",            -- Leder, Schatten, Ecken der Sammlung (6.6.3.3)
    "^!?_?UI%-Frame%-DiamondMetal%-",        -- Rahmen und Kopf des Spielmenues
    "^UI%-DiamondDialogBox%-",               -- Rahmen der Dialoge (6.6.3.4)
    "^UI%-DialogBox%-Background",            -- Grund der Dialoge
    -- Zauberbuch (Blizzard_PlayerSpells, Quelltext des Spiels 12.x):
    "^spellbook%-background",                -- Pergament, Buchseiten, Band
    "^spellbook%-corner",                    -- Eselsohr zum Blaettern
    "^spellbook%-divider",
    "^spellbook%-list%-backplate",
    "^spellbook%-item%-backplate",           -- Schatten hinter jedem Zauber
    "^UI%-HUD%-RotationHelper%-SpellbookDivider",
    -- Gemessen im Beta-Client mit /wcui fenster (6.4.1.3): Goldschmuck.
    "^spellbook%-Tab%-Frame%-C60$",          -- Goldrahmen der Kategorie-Reiter (der Schein bleibt: er zeigt die Wahl)
    "^Talents%-Main%-Ring",                  -- Goldring um die Spezialisierungen
    "^Talents%-divider",                     -- Goldlinien links/rechts
    "^Talents%-small%-divider",
    "^Talents%-Square%-Box",                 -- Goldkasten "Unverteilte Talentpunkte"
    -- Weltkarte und Questlog, gemessen im Beta-Client mit /wcui fenster
    -- (6.6.2.1): Pergament hinter der Karte, Rahmen und Grund der
    -- Questliste, Metallkante oben und unten.
    "^gamepad%-mapquestlog%-bg",             -- Pergament und Vignette ausserhalb der Karte
    "^QuestLog%-main%-background",           -- Grund der Questliste
    "^QuestLog%-frame",                      -- Rahmen der Questliste
    "^_UI%-Frame%-Metal%-Edge",              -- Metallkante des Fensters
    -- Berufe, gemessen mit /wcui fenster (6.6.2.1): Metallrahmen (auch die
    -- senkrechten Kanten und Ecken), Rahmen der Fortschrittsbalken, der
    -- Goldrahmen um die Berufssymbole, der Hintergrund der Uebersicht.
    "^!?_?UI%-Frame%-Metal%-",
    "^Profession%-ProgressBar%-",            -- Balken: Rahmen und Grund (flach ersetzt)
    "^Profession%-square%-frame",            -- Goldrahmen ums Symbol (1 px Rand statt)
    "^Profession%-Background%-Overview",
    -- 6.7.5.0, gemessen auf der Rezeptseite: Grund der Seite, Grund der
    -- Rezeptliste und das grosse Bild hinter dem Rezept (Kochkunst: Topf
    -- und Loeffel) - die ruhigen Flaechen des Registers ersetzen sie, und
    -- hinter Text steht kein Bild.
    "^Profession%-Background%-Template",
    "^Professions%-background%-summarylist",
    "^Profession%-background%-card%-",
    -- 6.7.6.0, gemessen auf der Uebersicht: die braune Flaeche der
    -- Hauptberufe (Profession-overview-Card) und die Bilder der Nebenberufe
    -- (Profession-overview-card-generic-*) - bis 6.7.5.0 gedaempft, aber sie
    -- standen hinter Text. Die Karten tragen jetzt die Flaeche des Registers
    -- (ui/profbook.lua), der Titel sagt, welcher Beruf es ist.
    "^Profession%-overview%-[Cc]ard",
    -- 6.6.2.2, gemessen: Dungeonbrowser ("Suche nach Gruppe") und Questlog.
    "^UI%-Frame%-PortraitMetal",             -- Metallecke am Portrait
    "^_?UI%-Frame%-TopTileStreaks",          -- Streifen unter dem Titel
    "^groupfinder%-background",              -- Grund der Liste
    "^groupfinder%-roles%-background",       -- Grund der Rollenwahl
    "^groupfinder%-button%-cover",           -- Goldrahmen um die Kategorien (1 px Rand statt)
    "^common%-search%-border",               -- Goldrand um das Suchfeld (flach statt)
    "^MapCornerShadow",                      -- Schatten am Knopf der Seitenleiste
    -- 6.6.2.3, gemessen: die Eintraege der Liste links an Gilde & Communitys
    -- (gruen, blau) - statt dessen eine kleine Kachel, der gewaehlte mit
    -- Rand im Akzent (W.NavEntry). Das Wappen im Eintrag bleibt.
    "^communities%-nav%-button",
}
-- Gedaempft statt weg (mit "Stimmung statt Schwarz"): die Bilder der
-- Kategorien im Dungeonbrowser (Quests & Zonen, Schlachtfelder,
-- Benutzerdefiniert) - 6.6.2.2. Die Karten der Berufsuebersicht standen
-- hier bis 6.7.5.0; seit 6.7.6.0 sind sie weg (hinter Text, W.HIDE_ATLAS).
W.TONE_ATLAS = { "^groupfinder%-button%-" }
function W.TonesAtlas(atlas)
    if type(atlas) ~= "string" or W.HidesAtlas(atlas) then return false end
    for _, pat in ipairs(W.TONE_ATLAS) do
        if atlas:find(pat) then return true end
    end
    return false
end
local KEEP_ATLAS = { "RaceBG" }

function W.HidesAtlas(atlas)
    if type(atlas) ~= "string" then return false end
    for _, k in ipairs(KEEP_ATLAS) do
        if atlas:find(k, 1, true) then return false end
    end
    for _, pat in ipairs(W.HIDE_ATLAS) do
        if atlas:find(pat) then return true end
    end
    return false
end

-- Alle Texturen mit einem dieser Atlanten, bis in die Tiefe. Zeilen einer
-- Liste legt das Spiel beim Blaettern neu an - deshalb laeuft das bei
-- jedem Zeigen und, solange das Fenster offen ist, zweimal je Sekunde.
-- Balken in Ruf und Fertigkeiten: statt des Rahmens des Spiels ein
-- flacher Grund mit 1 px Rand, wie jeder Balken der Oberflaeche.
-- Mit Stil (6.7.0.0, ui/style.lua) ist die Bahn dunkler (barTrack) - die
-- Farbe der Fuellung, beim Ruf die Stufe, hebt sich deutlicher ab - und der
-- Rand weicher (barEdge, 6.7.0.1: keine harten schwarzen Rechtecke).
local barDone = setmetatable({}, { __mode = "k" })
W.FlatBars = barDone
local function FlatBar(bar, sc)
    if type(bar) ~= "table" or barDone[bar] or not bar.CreateTexture then return end
    local bg = bar:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints(bar)
    local c = WeintCodex.GameColors[(sc and sc.barTrack) or "plateBg"] or WeintCodex.GameColors.plateBg
    bg:SetColorTexture(c[1], c[2], c[3], 1)
    own[bg] = true
    local edge = K.Border(bar, 1, 0, 0, 0, (sc and sc.barEdge) or 1, "OVERLAY")
    barDone[bar] = { track = bg, edge = edge, style = sc }
end

-- Ein Eintrag der Liste links an Gilde & Communitys: kleine Kachel statt
-- des gruenen oder blauen Bildes. Gewaehlt ist er, wenn sein Bild "pressed"
-- oder "select" heisst und gezeigt wird - je Durchlauf neu bestimmt.
local entries = setmetatable({}, { __mode = "k" })
W.Entries = entries
-- `sc` (6.7.8.0): der Stil des Bereichs - der gewaehlte Eintrag traegt
-- dessen Akzent (Gilde: Gold), sonst die Klassenfarbe.
function W.NavEntry(f, r, atlas, sc)
    if type(f) ~= "table" or not f.CreateTexture then return end
    local d = entries[f]
    if not d then
        d = { kachel = K.Kachel(f, { shadow = 0 }) }
        own[d.kachel.bg], own[d.kachel.light] = true, true
        local s1 = C.surface1
        d.kachel.bg:SetColorTexture(s1[1], s1[2], s1[3], 0.95)
        local hl = f:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(f)
        local h = WeintCodex.GameColors.hoverFill
        hl:SetColorTexture(h[1], h[2], h[3], h[4] * 0.5)
        own[hl] = true
        entries[f] = d
    end
    if d.run ~= stats.runs then d.run, d.onNow = stats.runs, false end
    local low = atlas:lower()
    if (low:find("pressed", 1, true) or low:find("select", 1, true)) and r.IsShown and K.Bool(r:IsShown(), false) then
        d.onNow = true
    end
    local accent = S.Accent(sc and sc.accent)
    if d.on ~= d.onNow or (d.on and d.accent ~= accent) then
        d.on, d.accent = d.onNow, d.onNow and accent or nil
        local c = d.on and accent or BLACK
        d.kachel.border:SetColor(c[1], c[2], c[3], 1)
    end
end

-- 1 px schwarzer Rand statt eines Goldrahmens (Berufssymbole), einmal.
local edged = setmetatable({}, { __mode = "k" })
--------------------------------------------------
-- Kategorien (6.6.2.7)
--------------------------------------------------
-- Beta-Test: "ein Design fuer die einzelnen Kategorien, damit es besser
-- gelesen werden kann - jetzt steht Allgemein, Primaere Eigenschaften
-- einfach nur in weiss da". Die Kopfzeile trug den Holzbalken des Spiels
-- (UI-Character-Info-Title, ausgeblendet seit 6.4); uebrig blieb der
-- blanke Text. Jetzt an seiner Stelle eine Zierlinie (siehe W.Header).
-- Erkannt am Atlas des Balkens (W.HEADER_ATLAS), nicht an einem
-- Namen - jede Kopfzeile, die ihn traegt, in jedem Fenster. Der Text des
-- Spiels bleibt, wie er ist (kein SetText auf fremde Zeilen).
W.HEADER_ATLAS = { "^UI%-Character%-Info%-Title", "^common%-button%-list%-collapseExpand" }

-- Nur offene Fenster (6.6.2.6): vorher lief jeder Durchlauf auch ueber
-- alle geschlossenen, die schon einmal gestaltet waren.
local function Open(f)
    local ok, v = pcall(f.IsVisible, f)
    return ok and K.Bool(v, false)
end
W.Open = Open
function W.HeaderAtlas(atlas)
    if type(atlas) ~= "string" then return false end
    for _, pat in ipairs(W.HEADER_ATLAS) do
        if atlas:find(pat) then return true end
    end
    return false
end

local headerDone = setmetatable({}, { __mode = "k" })
W.Headers = headerDone

local function HeaderTitle(f)
    if type(f.Title) == "table" and f.Title.GetText then return f.Title end
    for _, r in ipairs(Regions(f, "hdrTitle")) do
        local ok, isText = pcall(IsFontString, r)
        if ok and isText then return r end
    end
    return nil
end

-- Zweite Fassung (6.6.2.8, Beta-Test zum dunklen Band mit weissem
-- Streifen: "sieht richtig scheisse aus - Verzierungen, etwas, das sich
-- ins Interface einarbeitet"). Kein Block mehr: der Titel steht mittig
-- wie im Spiel, links und rechts laeuft je eine feine Linie nach aussen
-- aus, am Titel sitzt eine kleine Raute. Farbe der Hervorhebung, aber
-- gedaempft - eine Zierlinie, keine Markierung.
W.HEADER_GAP, W.HEADER_INSET, W.HEADER_ALPHA = 8, 10, 0.7

-- Ruf und Fertigkeiten (6.6.2.9, gemessen mit /wcui fenster): ihre
-- Kopfzeilen sind Zeilen der Liste mit dem Grund
-- "common-button-list-collapseExpand" (zweimal je Kopfzeile) und rechts
-- dem Zeichen zum Auf- und Zuklappen ("common-button-list-minus"/"-plus").
-- Das Zeichen bleibt - es sagt, was ein Klick tut; die rechte Linie endet
-- vor ihm.
W.HEADER_ICON = "^common%-button%-list%-[mp]"

local function HeaderIcon(f)
    for _, r in ipairs(Regions(f, "hdrIcon")) do
        local ok, atlas = pcall(TextureAtlas, r)
        atlas = ok and K.Plain(atlas) or nil
        if type(atlas) == "string" and atlas:find(W.HEADER_ICON) then return r end
    end
    return nil
end

-- Dritte Fassung (6.6.3.0, Beta-Test: "kann das alles noch etwas
-- auffaelliger? das ist noch zu wenig"): Titel 14 pt mit Schatten, hinter
-- ihm ein weicher Lichthof in der Hervorhebung; je Seite eine Raute mit
-- dunklem Kern, ein kleiner Punkt davor und die Linie mit einem Schein
-- darunter. Passt ein langer Titel nicht in die Spalte, wird er 12 pt und
-- die kleinen Punkte gehen (W.FitHeader, jeder Durchlauf).
W.HEADER_SIZE, W.HEADER_SIZE_SMALL, W.HEADER_HALO = 14, 12, 0.28

-- Raute und auslaufende Linie: seit 6.7.0.0 Bausteine in ui/style.lua.
local Diamond, Fade = S.Diamond, S.Fade
W.Diamond, W.Fade = Diamond, Fade

-- Eine Seite: Linie (1 px) mit Schein (3 px), Punkt, Raute mit Kern.
local function Side(f, c, outward)
    local e = {}
    e.glow = f:CreateTexture(nil, "ARTWORK", nil, 0)
    e.glow:SetHeight(3)
    Fade(e.glow, c, 0.3, outward)
    e.line = f:CreateTexture(nil, "ARTWORK", nil, 1)
    e.line:SetHeight(1)
    Fade(e.line, c, 0.95, outward)
    local dark = C.surface1
    e.pip = Diamond(f, 3, c, 0.85, 2)
    e.dot = Diamond(f, 7, c, 1, 2)
    e.hole = Diamond(f, 2, dark, 1, 3)
    own[e.glow], own[e.line] = true, true
    return e
end

-- Abstaende vom Rand des Titels: Raute, Punkt, Linie.
local DOT_AT, PIP_AT, LINE_AT = 6, 15, 19

local function PlaceSide(e, fs, beam, sign, stop)
    local edge = sign < 0 and "LEFT" or "RIGHT"
    for _, t in ipairs({ e.dot, e.hole, e.pip, e.line, e.glow }) do t:ClearAllPoints() end
    e.dot:SetPoint("CENTER", fs, edge, sign * (W.HEADER_GAP + DOT_AT - 6), 0)
    e.hole:SetPoint("CENTER", e.dot, "CENTER", 0, 0)
    e.pip:SetPoint("CENTER", fs, edge, sign * (W.HEADER_GAP + PIP_AT - 6), 0)
    local inner = sign * (W.HEADER_GAP + LINE_AT - 6)
    if sign < 0 then
        e.line:SetPoint("RIGHT", fs, "LEFT", inner, 0)
        e.line:SetPoint("LEFT", beam, "LEFT", W.HEADER_INSET, 0)
    else
        e.line:SetPoint("LEFT", fs, "RIGHT", inner, 0)
        if stop then e.line:SetPoint("RIGHT", stop, "LEFT", -6, 0)
        else e.line:SetPoint("RIGHT", beam, "RIGHT", -W.HEADER_INSET, 0) end
    end
    e.glow:SetPoint("LEFT", e.line, "LEFT", 0, 0)
    e.glow:SetPoint("RIGHT", e.line, "RIGHT", 0, 0)
end

-- Titel und Verzierung an einen Balken legen. Traegt die Kopfzeile
-- mehrere (Ruf: zwei), gilt der breiteste.
local function Place(d, beam)
    local fs = d.title
    pcall(function()
        fs:SetJustifyH("CENTER")
        fs:ClearAllPoints()
        fs:SetPoint("CENTER", beam, "CENTER", 0, 0)
    end)
    PlaceSide(d.l, fs, beam, -1)
    PlaceSide(d.r, fs, beam, 1, d.icon)
    d.halo:ClearAllPoints()
    d.halo:SetPoint("CENTER", fs, "CENTER", 0, 0)
    d.hover:ClearAllPoints()
    d.hover:SetAllPoints(beam)
    d.beam = beam
    d.fitW = nil
end

local function WidthOf(r)
    local ok, w = pcall(r.GetWidth, r)
    w = ok and K.Plain(w) or nil
    return type(w) == "number" and w or 0
end

local function TextWidth(fs)
    local ok, w = pcall(fs.GetStringWidth, fs)
    w = ok and K.Plain(w) or nil
    return type(w) == "number" and w or 0
end

-- Passt der Titel samt Verzierung in den Balken? Sonst kleiner, dann
-- ohne Punkte. Der Lichthof ist so breit wie der Titel plus Rand.
function W.FitHeader(d)
    local tw, bw = TextWidth(d.title), WidthOf(d.beam)
    if tw <= 0 or bw <= 0 or (d.fitW == tw and d.fitB == bw) then return end
    local need = function(w) return w + 2 * (W.HEADER_GAP + LINE_AT + 12) end
    local avail = bw - 2 * W.HEADER_INSET
    if not d.small and need(tw) > avail then
        d.small = true
        pcall(K.SetFont, d.title, W.HEADER_SIZE_SMALL)
        tw = TextWidth(d.title)
    end
    local pips = need(tw) <= avail
    d.l.pip:SetShown(pips)
    d.r.pip:SetShown(pips)
    d.halo:SetSize(math.min(tw + 60, bw), 26)
    d.fitW, d.fitB = TextWidth(d.title), bw
end

function W.Header(f, beam)
    if type(f) ~= "table" or not f.CreateTexture or type(beam) ~= "table" then return nil end
    local d = headerDone[f]
    if d then
        if beam ~= d.beam and WidthOf(beam) > WidthOf(d.beam) then Place(d, beam) end
        W.FitHeader(d)
        return d
    end
    local fs = HeaderTitle(f)
    if not fs then return nil end
    d = { title = fs, icon = HeaderIcon(f) }
    pcall(function()
        K.SetFont(fs, W.HEADER_SIZE)
        local t = C.textBright
        fs:SetTextColor(t[1], t[2], t[3], 1)
        if fs.SetShadowOffset then fs:SetShadowOffset(1, -1) end
        if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0.9) end
    end)
    local c = K.Highlight()
    -- Lichthof: der weiche Schein der Oberflaeche (glow_wide), gedehnt.
    d.halo = f:CreateTexture(nil, "BORDER", nil, 1)
    d.halo:SetTexture(K.GLOW_WIDE_TEXTURE)
    d.halo:SetVertexColor(c[1], c[2], c[3], W.HEADER_HALO)
    own[d.halo] = true
    d.l = Side(f, c, "LEFT")
    d.r = Side(f, c, "RIGHT")
    -- Kopfzeilen, die man klickt (Ruf, Fertigkeiten): heller unter der
    -- Maus - der Grund des Spiels, der das zeigte, ist weg.
    d.hover = f:CreateTexture(nil, "HIGHLIGHT")
    local h = WeintCodex.GameColors.hoverFill
    d.hover:SetColorTexture(h[1], h[2], h[3], h[4] * 0.5)
    own[d.hover] = true
    Place(d, beam)
    headerDone[f] = d
    W.FitHeader(d)
    return d
end

-- Fuer /wcui fenster: welche Kopfzeilen gestaltet sind (sichtbare).
function W.HeaderReport()
    local names = {}
    for f, d in pairs(headerDone) do
        if Open(f) and #names < 8 then
            local text = d.title and K.Plain(d.title:GetText())
            names[#names + 1] = type(text) == "string" and text or "?"
        end
    end
    if #names == 0 then return {} end
    table.sort(names)
    return { string.format("   Kategorien: %d (%s)", #names, table.concat(names, ", ")) }
end

--------------------------------------------------
-- Kopfzeile einer Liste (6.7.0.0, Stile S.CALM und S.CHARACTER_INFO)
--------------------------------------------------
-- Im Ruf (und spaeter jeder informationslastigen Liste) steht die
-- Kopfzeile nicht mittig mit Lichthof, sondern wie eine Zeile der Liste:
-- der Text bleibt, WO das Spiel ihn hinsetzt - die Einrueckung sagt, dass
-- eine Gruppe in einer anderen steckt (6.6.2.9 ging sie mittig verloren).
-- Dahinter eine Raute mit dunklem Kern und eine feine Linie im Akzent des
-- Stils, die vor dem Zeichen zum Auf- und Zuklappen endet. Kein Lichthof:
-- nichts leuchtet hinter Text.
W.LIST_HEADER_SIZE = 13
W.LIST_LINE, W.LIST_DOT = 0.55, 0.9
W.LIST_GAP = 8          -- Abstand Text -> Raute, Raute -> Linie
local listHeads = setmetatable({}, { __mode = "k" })
W.ListHeaders = listHeads

-- Linie und Raute haengen am Ende des TEXTES (nicht der Zeile: die kann
-- breiter sein als ihr Text). Neu gelegt nur, wenn sich die Breite des
-- Textes aendert - die Liste verwendet ihre Zeilen fuer andere Gruppen.
local function FitList(d)
    local tw = TextWidth(d.title)
    if d.tw == tw and d.placedBeam == d.beam then return end
    d.tw, d.placedBeam = tw, d.beam
    d.dot:ClearAllPoints()
    d.dot:SetPoint("CENTER", d.title, "LEFT", tw + W.LIST_GAP + 3, 0)
    d.hole:ClearAllPoints()
    d.hole:SetPoint("CENTER", d.dot, "CENTER", 0, 0)
    d.line:ClearAllPoints()
    d.line:SetPoint("LEFT", d.dot, "CENTER", W.LIST_GAP, 0)
    if d.icon then d.line:SetPoint("RIGHT", d.icon, "LEFT", -6, 0)
    else d.line:SetPoint("RIGHT", d.beam, "RIGHT", -W.HEADER_INSET, 0) end
    d.hover:ClearAllPoints()
    d.hover:SetAllPoints(d.beam)
end
W.FitList = FitList

function W.ListHeader(f, beam, sc)
    if type(f) ~= "table" or not f.CreateTexture or type(beam) ~= "table" then return nil end
    local d = listHeads[f]
    if d then
        if beam ~= d.beam and WidthOf(beam) > WidthOf(d.beam) then d.beam = beam end
        FitList(d)
        return d
    end
    local fs = HeaderTitle(f)
    if not fs then return nil end
    d = { title = fs, icon = HeaderIcon(f), beam = beam, style = sc, accent = S.Accent(sc and sc.accent) }
    S.Title(fs, (sc and sc.headerSize) or W.LIST_HEADER_SIZE, C.textBright)
    -- Die Gruppe als eigene Sektion (6.7.0.2): Licht von links, Haarlinie oben.
    if sc and sc.band then d.band = S.Band(f) end
    pcall(fs.SetJustifyH, fs, "LEFT")
    local c = d.accent
    d.dot = Diamond(f, 6, c, W.LIST_DOT, 2)
    d.hole = Diamond(f, 2, C.surface1, 1, 3)
    d.line = f:CreateTexture(nil, "ARTWORK", nil, 1)
    d.line:SetHeight(1)
    Fade(d.line, c, W.LIST_LINE, "RIGHT")
    own[d.line] = true
    d.hover = S.Hover(f)
    listHeads[f] = d
    FitList(d)
    return d
end

function W.EdgeBorder(f)
    if type(f) ~= "table" or edged[f] or not f.CreateTexture then return end
    edged[f] = true
    K.Border(f, 1, 0, 0, 0, 1, "OVERLAY")
end

-- `sc`: der Stil des Bereichs (ui/style.lua), von oben nach unten
-- durchgereicht - ein Rahmen mit eigenem Stil gibt ihn an alles darunter
-- weiter. Ohne Stil: wie bis 6.6.4.5.
local seen = setmetatable({}, { __mode = "k" })
local HideByAtlas
function HideByAtlas(f, depth, sc)
    if depth > 8 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    for _, r in ipairs(Regions(f, "atlas", depth)) do
        local ok, atlas = pcall(TextureAtlas, r)
        if ok and W.HidesAtlas(atlas) then
            Hide(r)
            if not seen[r] then
                seen[r] = true
                stats.hidden = stats.hidden + 1
            end
            if atlas:find("^common%-stat%-bar%-BG") or atlas:find("^Profession%-ProgressBar%-BG") then FlatBar(f, sc) end
            if atlas:find("^Profession%-square%-frame") or atlas:find("^groupfinder%-button%-cover") then W.EdgeBorder(f) end
            if atlas:find("^common%-search%-border") then FlatBar(f) end
            if atlas:find("^communities%-nav%-button") then W.NavEntry(f, r, atlas, sc) end
            if W.HeaderAtlas(atlas) then
                if sc and sc.header == "list" then W.ListHeader(f, r, sc) else W.Header(f, r) end
            end
            if atlas:find("^_?128%-RedButton%-") and W.SkinPanelButton then pcall(W.SkinPanelButton, f) end
        elseif ok and W.TonesAtlas(atlas) then
            if Opt("windowArt") then W.Tone(r) else Hide(r) end
            if not seen[r] then
                seen[r] = true
                stats.hidden = stats.hidden + 1
            end
        end
    end
    for _, ch in ipairs(Children(f, "atlas", depth)) do HideByAtlas(ch, depth + 1, scoped[ch] or sc) end
end
W.HideByAtlas = function(f) HideByAtlas(f, 0, scoped[f]) end

-- Ausruestungsplaetze: flach wie die Aktionsknoepfe, 1 px schwarzer Rand.
-- Erkannt am Namen (Character...Slot), nicht an einer Liste: welche Plaetze
-- es gibt, sagt der Client.
local slotDone = {}
-- Die gefundenen Plaetze in Reihenfolge und ihr Rand - das
-- Charakterfenster (ui/character.lua) faerbt ihn nach Zustand.
W.SlotList, W.SlotBorder = {}, setmetatable({}, { __mode = "k" })
local function SkinSlots(f, depth)
    depth = depth or 0
    if depth > 12 then return end
    for _, ch in ipairs(Children(f, "slots", depth)) do
        local n = type(ch) == "table" and ch.GetName and ch:GetName()
        if type(n) == "string" and n:find("^Character[%a%d]+Slot$") and not slotDone[ch] then
            slotDone[ch] = true
            local normal = ch.GetNormalTexture and ch:GetNormalTexture()
            if type(normal) == "table" then Hide(normal) end
            local border = K.Border(ch, 1, 0, 0, 0, 1, "OVERLAY")
            W.SlotList[#W.SlotList + 1] = ch
            W.SlotBorder[ch] = border
        end
        if type(ch) == "table" then SkinSlots(ch, depth + 1) end
    end
end
W.SkinSlots = SkinSlots

-- Die Reiter rechts am Charakterfenster (CharacterFrameModeTab1..):
-- eine kleine Kachel statt des Goldrahmens, der gewaehlte mit Rand im
-- Akzent, unter der Maus heller.
local tabDone = {}
local function SkinModeTabs()
    for i = 1, 10 do
        local tab = _G["CharacterFrameModeTab" .. i]
        if type(tab) == "table" and not (tab.IsForbidden and tab:IsForbidden()) then
            local d = tabDone[tab]
            if not d then
                d = { kachel = K.Kachel(tab, { shadow = 3 }) }
                local hl = tab:CreateTexture(nil, "HIGHLIGHT")
                hl:SetAllPoints(tab)
                local h = WeintCodex.GameColors.hoverFill
                hl:SetColorTexture(h[1], h[2], h[3], h[4])
                tabDone[tab] = d
            end
            local sel = tab.SelectedTexture
            local on = type(sel) == "table" and sel.IsShown and K.Bool(sel:IsShown(), false)
            local c = on and K.Highlight() or BLACK
            d.kachel.border:SetColor(c[1], c[2], c[3], 1)
        end
    end
end
W.SkinModeTabs = SkinModeTabs

-- Schrift fuer Pergament (dunkelbraun, SPELLBOOK_FONT_COLOR) ist auf der
-- dunklen Kachel unlesbar. Jede dunkle Schriftzeile im Fenster wird hell;
-- setzt das Spiel sie wieder dunkel, zieht ein Haken nach. Helle und
-- farbige Schrift (Gold, Gruen, Rot) bleibt, wie sie ist - sie traegt
-- Bedeutung.
local function IsDark(r, g, b)
    r, g, b = K.Plain(r), K.Plain(g), K.Plain(b)
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return false end
    -- Dazu kein Kanal hell (6.6.2.1): reines Rot ("fehlt", Reagenzien im
    -- Berufefenster) ist nach Helligkeit dunkel, traegt aber Bedeutung.
    return (0.299 * r + 0.587 * g + 0.114 * b) < 0.4 and math.max(r, g, b) < 0.5
end
W.IsDark = IsDark

local lit = setmetatable({}, { __mode = "k" })
local litGuard = false
local function Lighten(fs)
    if lit[fs] then return end
    local ok, r, g, b = pcall(fs.GetTextColor, fs)
    if not ok or not IsDark(r, g, b) then return end
    lit[fs] = true
    local c = C.textNormal
    litGuard = true
    fs:SetTextColor(c[1], c[2], c[3])
    litGuard = false
    if _G.hooksecurefunc then
        _G.hooksecurefunc(fs, "SetTextColor", function(self, nr, ng, nb)
            if litGuard or not IsDark(nr, ng, nb) then return end
            litGuard = true
            self:SetTextColor(c[1], c[2], c[3])
            litGuard = false
        end)
    end
end

-- Dunkle Farbcodes im Text hell machen. Gibt den Text und die Zahl der
-- ersetzten Codes zurueck; helle und farbige Codes bleiben.
local function HexOf(c)
    return string.format("%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end
function W.LightCodes(text)
    if type(text) ~= "string" or not text:find("|c", 1, true) then return text, 0 end
    local n = 0
    -- Strenger als IsDark: nur fast Schwarz und Dunkelbraun. Reines Rot
    -- ist nach Helligkeit "dunkel", traegt aber Bedeutung.
    local out = text:gsub("|c%x%x(%x%x)(%x%x)(%x%x)", function(r, g, b)
        if math.max(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)) < 0x50 then
            n = n + 1
            return "|cff" .. HexOf(C.textNormal)
        end
    end)
    return out, n
end

local function LightenCodes(fs)
    local ok, text = pcall(fs.GetText, fs)
    if not ok then return end
    local cok, out, n = pcall(W.LightCodes, text)
    if cok and n > 0 then pcall(fs.SetText, fs, out) end
end

local function LightenText(f, depth, codes)
    if depth > 10 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    for _, r in ipairs(Regions(f, "light", depth)) do
        local ok, isText = pcall(IsFontString, r)
        if ok and isText then
            Lighten(r)
            if codes then LightenCodes(r) end
        end
    end
    for _, ch in ipairs(Children(f, "light", depth)) do LightenText(ch, depth + 1, codes) end
end
W.LightenText = function(f, codes) LightenText(f, 0, codes) end

-- Zaubersymbole im Zauberbuch (SpellBookItemTemplate: Button mit Icon,
-- Border und IconMask): Zierrahmen weg, Maske ab (Passive waren rund),
-- 1 px schwarzer Rand wie auf den Aktionsleisten. Erkannt an diesen drei
-- Teilen, nicht an einem Namen - die Eintraege legt das Spiel beim
-- Blaettern neu an.
local spellDone = setmetatable({}, { __mode = "k" })
local function SkinSpellButton(b)
    if spellDone[b] then return end
    spellDone[b] = true
    Hide(b.Border)
    local icon = b.Icon
    if type(b.IconMask) == "table" and icon.RemoveMaskTexture then pcall(icon.RemoveMaskTexture, icon, b.IconMask) end
    if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    local border = K.Border(b, 1, 0, 0, 0, 1, "OVERLAY")
    if border.top and border.top.SetDrawLayer then
        for _, t in ipairs({ border.top, border.bottom, border.left, border.right }) do
            t:ClearAllPoints()
        end
        -- Rand am Bild, nicht am Knopf: der Knopf ist groesser als das Bild.
        border.top:SetPoint("BOTTOMLEFT", icon, "TOPLEFT", -1, 0)
        border.top:SetPoint("BOTTOMRIGHT", icon, "TOPRIGHT", 1, 0)
        border.top:SetHeight(1)
        border.bottom:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", -1, 0)
        border.bottom:SetPoint("TOPRIGHT", icon, "BOTTOMRIGHT", 1, 0)
        border.bottom:SetHeight(1)
        border.left:SetPoint("TOPRIGHT", icon, "TOPLEFT", 0, 0)
        border.left:SetPoint("BOTTOMRIGHT", icon, "BOTTOMLEFT", 0, 0)
        border.left:SetWidth(1)
        border.right:SetPoint("TOPLEFT", icon, "TOPRIGHT", 0, 0)
        border.right:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 0, 0)
        border.right:SetWidth(1)
    end
end

local function SkinSpellItems(f, depth)
    if depth > 10 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    local b = f.Button
    if type(b) == "table" and type(b.Icon) == "table" and type(b.Border) == "table" and b.Icon.SetTexCoord then
        pcall(SkinSpellButton, b)
    end
    for _, ch in ipairs(Children(f, "spells", depth)) do SkinSpellItems(ch, depth + 1) end
end
W.SkinSpellItems = function(f) SkinSpellItems(f, 0) end

-- Grosse Bilder im Fenster (siehe LARGE_PATTERNS). Nur sichtbare, nur
-- Texturen, nie unsere eigenen.
-- Ein Bild des Spiels gedaempft statt ausgeblendet: entsaettigt, dunkler,
-- halb durchsichtig - Stimmung ohne Konkurrenz zur Schrift. Setzt das
-- Spiel die Deckkraft neu, zieht ein Haken nach.
local toned = setmetatable({}, { __mode = "k" })
local toneGuard = false
local function Tone(r)
    if toned[r] then return end
    toned[r] = true
    local t = WeintCodex.GameColors.artTone
    if r.SetDesaturation then pcall(r.SetDesaturation, r, 0.6)
    elseif r.SetDesaturated then pcall(r.SetDesaturated, r, true) end
    if r.SetVertexColor then r:SetVertexColor(t[1], t[2], t[3]) end
    toneGuard = true
    r:SetAlpha(t[4])
    toneGuard = false
    if _G.hooksecurefunc then
        _G.hooksecurefunc(r, "SetAlpha", function(self)
            if toneGuard then return end
            toneGuard = true
            self:SetAlpha(t[4])
            toneGuard = false
        end)
    end
end
W.toned = toned
W.Tone = Tone

local function IsBig(r, limit)
    if r:GetObjectType() ~= "Texture" then return false end
    if not K.Bool(r:IsShown(), false) or K.Plain(r:GetAlpha()) == 0 then return false end
    local w, h = K.Plain(r:GetWidth()), K.Plain(r:GetHeight())
    return type(w) == "number" and type(h) == "number" and w * h >= limit
end

local function HideLarge(f, limit, depth, toneRoot, tone)
    if depth > 10 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    tone = tone or (toneRoot ~= nil and f == toneRoot)
    for _, r in ipairs(Regions(f, "large", depth)) do
        if not own[r] and not toned[r] then
            local ok, big = pcall(IsBig, r, limit)
            if ok and big then
                if tone then Tone(r) else Hide(r) end
                if not seen[r] then
                    seen[r] = true
                    stats.hidden = stats.hidden + 1
                end
            end
        end
    end
    for _, ch in ipairs(Children(f, "large", depth)) do HideLarge(ch, limit, depth + 1, toneRoot, tone) end
end
-- Pergament des Zauberbuchs: weg (entsaettigt waere es graues Papier).
-- Landschaften hinter den Talentbaeumen: gedaempft, wenn windowArt an ist.
function W.HideLarge(f)
    local w, h = K.Plain(f:GetWidth()), K.Plain(f:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" or w * h <= 0 then return end
    local toneRoot
    if Opt("windowArt") then
        local name = f.GetName and f:GetName()
        if type(f.TalentsFrame) == "table" then toneRoot = f.TalentsFrame
        elseif type(name) == "string" and (name:find("Talent", 1, true) or name:find("Profession", 1, true)) then
            toneRoot = f
        end
    end
    HideLarge(f, w * h * W.LARGE_SHARE, 0, toneRoot, false)
end

-- Schein in der Klassenfarbe oben im Fenster, nach unten auslaufend: das
-- Fenster gehoert dem Charakter. Die Farbe nennt das Spiel
-- (RAID_CLASS_COLORS); ohne Antwort bleibt der Schein aus.
local function ClassRGB()
    local _, class = nil, nil
    if _G.UnitClass then _, class = _G.UnitClass("player") end
    class = K.Plain(class)
    local cc = type(class) == "string" and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class]
    if type(cc) ~= "table" then return nil end
    return cc.r, cc.g, cc.b
end

function W.AddGlow(f, d)
    if d.glow or not Opt("windowArt") or not f.CreateTexture then return end
    local r, g, b = ClassRGB()
    if not r then return end
    local a = WeintCodex.GameColors.windowGlow[4]
    local t = f:CreateTexture(nil, "BACKGROUND", nil, -6)
    t:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    t:SetHeight(260)
    t:SetColorTexture(1, 1, 1, 1)
    if t.SetGradient and _G.CreateColor then
        t:SetGradient("VERTICAL", _G.CreateColor(r, g, b, 0), _G.CreateColor(r, g, b, a))
    else
        t:SetColorTexture(r, g, b, a * 0.4)
    end
    own[t] = true
    d.glow = t
end

--------------------------------------------------
-- Dritte Stufe: Bedienelemente (6.4.1.5)
--------------------------------------------------
-- Was neben der Kachel noch nach Gold aussah (Beta-Test 6.4.1.4): Reiter
-- ("Primaer/Sekundaer"), Knoepfe ("Aenderungen anwenden"), die gelben
-- Pfeilknoepfe und die roten Schliessen-Knoepfe.

-- Rot und Gelb des Spiels an Knoepfen werden grau: die Form bleibt, die
-- Bedeutung (schliessen, aufklappen) auch.
-- 6.6.2.2: die braunen Pfeilknoepfe am Questlog (Seitenleiste auf/zu).
-- Dazu die goldenen Pfeile und Bahnen der schmalen Bildlaufleisten
-- (!minimal-scrollbar-*, gemessen am Questlog) - Gilde & Communitys hat drei.
local DESAT_ATLAS = { "^[Rr]ed[Bb]utton%-", "^common%-dropdown%-a%-button", "^QuestCollapse%-",
                      "^!?minimal%-scrollbar", "^common%-button%-list%-[mp]" }
local desat = setmetatable({}, { __mode = "k" })
function W.Desaturates(atlas)
    if type(atlas) ~= "string" then return false end
    for _, pat in ipairs(DESAT_ATLAS) do
        if atlas:find(pat) then return true end
    end
    return false
end

local function Grey(f, depth)
    if depth > 10 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    for _, r in ipairs(Regions(f, "grey", depth)) do
        if not desat[r] then
            local ok, atlas = pcall(TextureAtlas, r)
            if ok and W.Desaturates(K.Plain(atlas)) and r.SetDesaturated then
                desat[r] = true
                r:SetDesaturated(true)
            end
        end
    end
    for _, ch in ipairs(Children(f, "grey", depth)) do Grey(ch, depth + 1) end
end
W.Grey = function(f) Grey(f, 0) end

-- Reiter einer Reiterleiste (TabSystem des Spiels: .tabs, jeder mit
-- Left/Middle/Right, *Active und *Highlight): eine kleine Kachel, der
-- gewaehlte mit Rand im Akzent - wie die Reiter am Charakterfenster.
local TAB_PARTS = { "Left", "Middle", "Right", "LeftActive", "MiddleActive", "RightActive",
                    "LeftHighlight", "MiddleHighlight", "RightHighlight" }
local tabSkin = setmetatable({}, { __mode = "k" })
-- Reiter mit Bild statt Text (Kategorien im Zauberbuch des Forever-
-- Clients, Beta-Test 6.4.1.5: die Bilder stiessen aneinander, der
-- gewaehlte trug Goldschein UND unseren Rand). Das Bild ist die
-- groesste Textur ohne Atlas; ihr Rahmen und Schein des Spiels
-- (spellbook-Tab-Frame-*) gehen, ein Rand INNEN am Bild trennt die
-- Nachbarn und zeigt die Wahl.
-- Ein Bild zaehlt nur, wenn es sichtbar ist und etwas zeigt. Die Reiter
-- "Primaer"/"Sekundaer" im Talentfenster haben dieselbe Vorlage und damit
-- ein .Icon - leer und versteckt. 6.4.1.7 nahm es trotzdem: keine Kachel,
-- der Rand um ein unsichtbares Bild mitten auf dem Text (Beta-Test 6.5.0.0).
local function PictureShown(r)
    if r:GetObjectType() ~= "Texture" then return false end
    if r.IsShown and not K.Bool(r:IsShown(), true) then return false end
    local tex = K.Plain(r.GetTexture and r:GetTexture())
    local atlas = K.Plain(r.GetAtlas and r:GetAtlas())
    local hasTex = (type(tex) == "number" and tex > 0) or (type(tex) == "string" and tex ~= "")
    return hasTex or (type(atlas) == "string" and atlas ~= "")
end
local function ShowsPicture(r)
    local ok, yes = pcall(PictureShown, r)
    return ok and yes == true
end
W.ShowsPicture = ShowsPicture

-- Eine sichtbare Beschriftung macht den Reiter zum Textreiter, egal was
-- er sonst traegt.
local function LabelShown(tab)
    local fs = tab.Text
    if type(fs) ~= "table" and tab.GetFontString then fs = tab:GetFontString() end
    if type(fs) ~= "table" or not fs.GetText then return false end
    if fs.IsShown and not K.Bool(fs:IsShown(), true) then return false end
    local a = K.Plain(fs.GetAlpha and fs:GetAlpha())
    if type(a) == "number" and a <= 0 then return false end
    local t = K.Plain(fs:GetText())
    return type(t) == "string" and t:find("%S") ~= nil
end
local function HasLabel(tab)
    local ok, yes = pcall(LabelShown, tab)
    return ok and yes == true
end
W.HasLabel = HasLabel

local function IconArea(r)
    if r:GetObjectType() ~= "Texture" then return 0 end
    if r.IsShown and not K.Bool(r:IsShown(), true) then return 0 end
    local atlas = K.Plain(r.GetAtlas and r:GetAtlas())
    if type(atlas) == "string" and atlas ~= "" then return 0 end
    if type(K.Plain(r:GetTexture())) ~= "number" then return 0 end
    local w, h = K.Plain(r:GetWidth()), K.Plain(r:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" then return 0 end
    return w * h
end

local function TabIcon(tab)
    if HasLabel(tab) then return nil end
    -- Gemessen im Beta-Client (/wcui maus, 6.4.1.7): der Reiter traegt
    -- sein Bild als .Icon.
    local key = tab.Icon
    if type(key) == "table" and key.GetObjectType and ShowsPicture(key) then return key end
    local best, area = nil, 0
    for _, r in ipairs(Regions(tab, "tabIcon")) do
        local tok, a = pcall(IconArea, r)
        if tok and a > area then best, area = r, a end
    end
    return best
end
W.TabIcon = TabIcon

local function InnerRim(host, region)
    local r = {}
    for _, side in ipairs({ "top", "bottom", "left", "right" }) do
        local t = host:CreateTexture(nil, "OVERLAY", nil, 7)
        own[t] = true
        r[side] = t
    end
    function r:Set(width, c)
        self.top:ClearAllPoints()
        self.top:SetPoint("TOPLEFT", region, "TOPLEFT", 0, 0)
        self.top:SetPoint("TOPRIGHT", region, "TOPRIGHT", 0, 0)
        self.top:SetHeight(width)
        self.bottom:ClearAllPoints()
        self.bottom:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", 0, 0)
        self.bottom:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", 0, 0)
        self.bottom:SetHeight(width)
        self.left:ClearAllPoints()
        self.left:SetPoint("TOPLEFT", region, "TOPLEFT", 0, 0)
        self.left:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", 0, 0)
        self.left:SetWidth(width)
        self.right:ClearAllPoints()
        self.right:SetPoint("TOPRIGHT", region, "TOPRIGHT", 0, 0)
        self.right:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", 0, 0)
        self.right:SetWidth(width)
        for _, t in ipairs({ self.top, self.bottom, self.left, self.right }) do
            t:SetColorTexture(c[1], c[2], c[3], 1)
        end
    end
    return r
end

-- Rand vom Bild schneiden, RELATIV zum Ausschnitt, den das Spiel setzt.
-- 6.4.1.6 setzte ihn absolut (0,08..0,92) - beim Klassen-Reiter kommt das
-- Bild aber aus einem Bogen mit vielen Bildern (bzw. einem Atlas), und das
-- Spiel setzt seinen Ausschnitt bei jeder Auffrischung neu: unser Schnitt
-- war weg, die dunklen Raender des Bildes blieben als Balken links und
-- rechts (Beta-Test 6.4.1.6). Jetzt: den Ausschnitt des Spiels lesen, 10 %
-- je Seite abziehen, und neu schneiden, sobald das Spiel ihn aendert.
local CROP = 0.10
local function CropRelative(tex, d)
    if not (tex.GetTexCoord and tex.SetTexCoord) then return end
    local ok, a, b, c, e, f, g, h, i = pcall(tex.GetTexCoord, tex)
    if not ok then return end
    a, b, c, e = K.Plain(a), K.Plain(b), K.Plain(c), K.Plain(e)
    f, g, h, i = K.Plain(f), K.Plain(g), K.Plain(h), K.Plain(i)
    -- Einzeln pruefen: ipairs haelt beim ersten nil an und liesse alles durch.
    if type(a) ~= "number" or type(b) ~= "number" or type(c) ~= "number" or type(e) ~= "number"
       or type(f) ~= "number" or type(g) ~= "number" or type(h) ~= "number" or type(i) ~= "number" then
        return
    end
    -- UL(a,b) LL(c,e) UR(f,g) LR(h,i)
    local l, r = math.min(a, c), math.max(f, h)
    local t, btm = math.min(b, g), math.max(e, i)
    local last = d.tc
    if last and math.abs(l - last[1]) < 1e-4 and math.abs(r - last[2]) < 1e-4
       and math.abs(t - last[3]) < 1e-4 and math.abs(btm - last[4]) < 1e-4 then
        return   -- noch unser Schnitt
    end
    local dx, dy = (r - l) * CROP, (btm - t) * CROP
    local nl, nr, nt, nb = l + dx, r - dx, t + dy, btm - dy
    tex:SetTexCoord(nl, nr, nt, nb)
    d.tc = { nl, nr, nt, nb }
end
W.CropRelative = CropRelative

-- Alles am Bildreiter ausser dem Bild und unseren Flaechen: Goldrahmen,
-- Goldschein und die dunkle Flaeche dahinter. Die Flaeche fuellt den
-- ganzen Reiter, und der ist so breit wie seine (leere) Beschriftung -
-- der gewaehlte Reiter hat eine andere Schrift, also eine andere Breite.
-- Wo er breiter war als sein Bild, sah man sie als Balken links und
-- rechts, mal an diesem, mal an jenem Reiter (Beta-Test 6.4.1.7, mit
-- /wcui maus gemessen: "FileData ID 0 (BACKGROUND)").
local function HideTabArt(tab, icon)
    for _, r in ipairs(Regions(tab, "tabArt")) do
        if r ~= icon and not own[r] then
            local tok, isTex = pcall(IsTexture, r)
            if tok and isTex then Hide(r) end
        end
    end
end

local function SkinTab(tab)
    local d = tabSkin[tab]
    if not d then
        for _, k in ipairs(TAB_PARTS) do Hide(tab[k]) end
        local icon = TabIcon(tab)
        if icon then
            d = { icon = icon, rim = InnerRim(tab, icon) }
        else
            d = { kachel = K.Kachel(tab, { shadow = 0 }) }
            own[d.kachel.bg], own[d.kachel.light] = true, true
            -- Eine Stufe heller als die Fensterkachel, sonst verschwindet er darin.
            local s1 = C.surface1
            d.kachel.bg:SetColorTexture(s1[1], s1[2], s1[3], 0.95)
        end
        local hl = tab:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(d.icon or tab)
        local h = WeintCodex.GameColors.hoverFill
        hl:SetColorTexture(h[1], h[2], h[3], h[4] * 0.5)
        own[hl] = true
        tabSkin[tab] = d
    end
    if d.icon then
        HideTabArt(tab, d.icon)   -- Schein des Spiels kommt beim Wechsel wieder
        CropRelative(d.icon, d)
    end
    local on = tab.isSelected
    if type(tab.IsSelected) == "function" then
        local ok, v = pcall(tab.IsSelected, tab)
        if ok and type(v) ~= "nil" then on = v end
    end
    on = K.Bool(on, false)
    local c = on and K.Highlight() or BLACK
    if d.rim then
        if d.sel ~= on then
            d.sel = on
            d.rim:Set(on and 2 or 1, c)
        end
    else
        d.kachel.border:SetColor(c[1], c[2], c[3], 1)
    end
end
W.TabSkin = tabSkin

local function SkinTabSystems(f, depth)
    if depth > 8 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    if type(f.tabs) == "table" and type(f.AddTab) == "function" then
        for _, tab in ipairs(f.tabs) do
            if type(tab) == "table" and tab.CreateTexture then pcall(SkinTab, tab) end
        end
    end
    for _, ch in ipairs(Children(f, "tabSys", depth)) do SkinTabSystems(ch, depth + 1) end
end
W.SkinTabSystems = function(f) SkinTabSystems(f, 0) end

-- Knoepfe der Vorlage UIPanelButtonTemplate (Left/Middle/Right, Text):
-- flache Kachel, heller unter der Maus. Zustaende (gedrueckt, gesperrt)
-- tauschen die Bilder des Spiels - die bleiben unsichtbar, der Text zeigt
-- den gesperrten Zustand weiter grau.
local btnSkin = setmetatable({}, { __mode = "k" })
-- states: auch die Zustandsbilder des Knopfs (normal, gedrueckt,
-- gesperrt) ausblenden - Knoepfe, deren Bild eine Datei ist statt drei
-- Teilen (Dialoge, 6.6.3.4).
local STATE_GETTERS = { "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }
local function SkinPanelButton(b, states)
    if btnSkin[b] then return end
    btnSkin[b] = true
    for _, k in ipairs({ "Left", "Middle", "Right" }) do Hide(b[k]) end
    local hl = b.GetHighlightTexture and b:GetHighlightTexture()
    if type(hl) == "table" then Hide(hl) end
    if states then
        for _, g in ipairs(STATE_GETTERS) do
            local ok, t = pcall(function() return b[g] and b[g](b) end)
            if ok and type(t) == "table" then Hide(t) end
        end
    end
    local d = K.Kachel(b, { shadow = 0 })
    own[d.bg], own[d.light] = true, true
    local s1 = C.surface1
    d.bg:SetColorTexture(s1[1], s1[2], s1[3], 0.95)
    local mine = b:CreateTexture(nil, "HIGHLIGHT")
    mine:SetAllPoints(b)
    local h = WeintCodex.GameColors.hoverFill
    mine:SetColorTexture(h[1], h[2], h[3], h[4] * 0.5)
    own[mine] = true
end

W.SkinPanelButton, W.ButtonSkin = SkinPanelButton, btnSkin

--------------------------------------------------
-- Dialoge des Spiels (6.6.3.4)
--------------------------------------------------
-- Beta-Test: "19 Sekunden bis zum Verlassen" soll auch gestaltet werden.
-- Gemessen mit /wcui fenster: Rahmen und Grund in StaticPopup1.BG
-- ("UI-DiamondDialogBox-Border", "UI-DialogBox-Background-Dark"), rote
-- Knoepfe als Bilddateien an StaticPopup1Button1/2. Dieselben vier
-- Dialoge tragen Bestaetigungen, die das Spiel schuetzt (Gegenstand
-- zerstoeren, Einladung annehmen, Geist freilassen, Spiel verlassen):
-- geaendert werden nur Bilder - kein Skript, kein Feld am Dialog, nichts
-- an StaticPopupDialogs. Die eigenen Bilder des Dialogs (etwa das
-- Warnzeichen) bleiben; nur der Grund (.BG) geht.
-- Kachel ohne Schatten nach aussen. Seit 6.7.9.0 in der ruhigen Sprache:
-- Dialoge gehoeren nicht zur Klasse - statt des Scheins in der Klassenfarbe
-- (fuellte den Dialog ganz) ein Hauch neutrales Licht von oben und oben
-- eine feine Kante in Gold (S.CALM), wie das Spielmenue.
W.POPUP_LIGHT = 60          -- Hoehe des Lichts von oben
W.POPUP_EDGE = 0.5          -- Deckkraft der Kante in Gold
W.POPUPS = { "StaticPopup1", "StaticPopup2", "StaticPopup3", "StaticPopup4" }
local popupDone = setmetatable({}, { __mode = "k" })
W.PopupDone = popupDone

function W.SkinPopup(f)
    if type(f) ~= "table" or popupDone[f] or not f.CreateTexture or (f.IsForbidden and f:IsForbidden()) then
        return popupDone[f]
    end
    local d = {}
    popupDone[f] = d
    HideDecor(f.BG)
    HideByAtlas(f, 0)
    d.kachel = K.Kachel(f, { alpha = 0.96, shadow = 0 })
    own[d.kachel.bg], own[d.kachel.light] = true, true
    S.Scope(f, S.CALM)
    local l = WeintCodex.GameColors.atmosLight
    d.light = S.TopLight(f, f, l, l[4], W.POPUP_LIGHT, -5)
    d.edge = S.Under(S.Divider(f, S.Accent(S.CALM.accent), W.POPUP_EDGE, 0), -3)
    S.PlaceTop(d.edge, f, 10, -1)
    local name = f.GetName and f:GetName()
    for i = 1, 4 do
        local b = (type(name) == "string" and _G[name .. "Button" .. i]) or f["button" .. i]
        if type(b) == "table" and b.CreateTexture and not (b.IsForbidden and b:IsForbidden()) then
            pcall(SkinPanelButton, b, true)
        end
    end
    return d
end

local function SkinPanelButtons(f, depth)
    if depth > 10 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    local ok, isButton = pcall(IsButton, f)
    if ok and isButton and type(f.Left) == "table" and type(f.Middle) == "table" and type(f.Right) == "table"
       and not (type(f.LeftActive) == "table") and f.CreateTexture then
        pcall(SkinPanelButton, f)
    end
    for _, ch in ipairs(Children(f, "panelBtn", depth)) do SkinPanelButtons(ch, depth + 1) end
end
W.SkinPanelButtons = function(f) SkinPanelButtons(f, 0) end

-- Werte im Charakterfenster: Name links, Zahl rechts. Blizzard laesst den
-- Namen frei laufen - "Bewegungsgeschwindigkeit" lief in "125%" hinein
-- (Beta-Test 6.4.1.4). Der Name endet jetzt vor der Zahl und wird dort
-- gekuerzt. Erkannt an Label und Value, nicht an einer Liste.
local statDone = setmetatable({}, { __mode = "k" })
W.StatLabels = {}   -- Namen der Werte, fuer ui/character.lua
local function FitStats(f, depth)
    if depth > 8 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    local label, value = f.Label, f.Value
    if not statDone[f] and type(label) == "table" and type(value) == "table"
       and label.SetPoint and value.GetObjectType then
        statDone[f] = true
        W.StatLabels[#W.StatLabels + 1] = label
        pcall(function()
            label:SetPoint("RIGHT", value, "LEFT", -6, 0)
            if label.SetWordWrap then label:SetWordWrap(false) end
            if label.SetJustifyH then label:SetJustifyH("LEFT") end
        end)
    end
    for _, ch in ipairs(Children(f, "stats", depth)) do FitStats(ch, depth + 1) end
end
W.FitStats = function(f) FitStats(f, 0) end

--------------------------------------------------
-- Weicher Rand ums Modell (6.6.2.1)
--------------------------------------------------
-- Beta-Test: "ein Weichzeichner zwischen dem Charakterbild und dem Rahmen
-- herum - das sieht zu abgehakt aus". Der Hintergrund des Modells (RaceBG,
-- bleibt als Buehne) endet mit harter Kante an der Kachel. An jeder seiner
-- vier Kanten liegt deshalb ein Verlauf in der Farbe der Kachel, der nach
-- innen ausblendet. Echte Unschaerfe kann der Client nicht; ein Verlauf
-- ist, was ein Weichzeichner an einer Kante sieht.
-- 6.6.2.3: 44 px waren zu wenig, und der Rand sass an den Kanten des
-- Rahmens, der das Bild traegt - oben und rechts endet das Bild aber
-- vorher (Beta-Test: "oben und rechts immer noch abgehakt"). Jetzt: an den
-- Kanten des BILDES (die Vereinigung aller RaceBG-Teile), gemessen bei
-- jedem Durchlauf, solange das Fenster offen ist.
-- 6.6.2.4: sass der Rand richtig (Ausgabe "am Bild 0:0:397:464" = das
-- ganze Modellfeld) und blieb trotzdem unsichtbar; auch auf OVERLAY/7,
-- sichtbar, Deckkraft 1 (gemessen). Grund, aus den Pixeln der Screenshots:
-- das Bild ist an seinen Raendern selbst fast schwarz, ein Verlauf nach
-- Fast-Schwarz aendert dort nichts. Hart wirkt die Kante gegen das, was
-- daneben HELLER ist - den Schein in der Klassenfarbe oben im Fenster
-- und die Werte rechts.
-- 6.6.2.5: statt etwas darueberzulegen, laufen die Bilder selbst aus -
-- eine eigene Maske (media/ui/softmask, innen voll, zu den Raendern weich
-- auf null) auf jedem Bild des Modellfelds. Darunter liegt der Grund des
-- Fensters samt Schein; das Bild geht in ihn ueber. Das 3D-Modell ist
-- keine Textur und bleibt scharf.
W.SOFT_MASK = K.MEDIA .. "softmask"

local soft = setmetatable({}, { __mode = "k" })
W.soft = soft

local function FindRaceBG(f, depth, out)
    if depth > 8 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    for _, r in ipairs(Regions(f, "raceBG", depth)) do
        local ok, atlas = pcall(TextureAtlas, r)
        atlas = ok and K.Plain(atlas) or nil
        if type(atlas) == "string" and atlas:find("RaceBG", 1, true) then out[#out + 1] = r end
    end
    for _, ch in ipairs(Children(f, "raceBG", depth)) do FindRaceBG(ch, depth + 1, out) end
end

-- Die Maske auf jedes Bild am Modellfeld, das sie noch nicht traegt. Das
-- Spiel tauscht die Bilder je Volk per SetTexture; die Maske bleibt dabei
-- haengen, neue Flaechen bekommen sie beim naechsten Durchlauf.
local function MaskAll(e, host)
    if not e.mask then return end
    for _, r in ipairs(Regions(host, "mask")) do
        if not own[r] and not e.masked[r] then
            local tok, isTex = pcall(IsTexture, r)
            if tok and isTex and pcall(r.AddMaskTexture, r, e.mask) then
                e.masked[r] = true
                e.count = e.count + 1
            end
        end
    end
end

-- Die Kanten des Bildes: kleinster linker, groesster rechter Rand usw.
-- ueber alle Teile. nil, solange der Client noch keine Lage kennt.
local function EdgesOf(r) return r:GetLeft(), r:GetRight(), r:GetTop(), r:GetBottom() end
local function Bounds(list)
    local L, R, T, B
    for _, r in ipairs(list) do
        local ok, l, rr, t, b = pcall(EdgesOf, r)
        l, rr, t, b = K.Plain(l), K.Plain(rr), K.Plain(t), K.Plain(b)
        if ok and type(l) == "number" and type(rr) == "number" and type(t) == "number" and type(b) == "number" then
            L = L and math.min(L, l) or l
            R = R and math.max(R, rr) or rr
            T = T and math.max(T, t) or t
            B = B and math.min(B, b) or b
        end
    end
    if L and R and T and B and R > L and T > B then return L, R, T, B end
    return nil
end
W.Bounds = Bounds

-- Der Anker (unsichtbarer Rahmen) auf die Kanten des Bildes legen; ohne
-- Lage: der ganze Traeger.
local function PlaceBox(e, host)
    local L, R, T, B = Bounds(e.parts)
    local hl, hb = K.Plain(host:GetLeft()), K.Plain(host:GetBottom())
    local key
    if L and type(hl) == "number" and type(hb) == "number" then
        key = string.format("%d:%d:%d:%d", L - hl, B - hb, R - L, T - B)
    else
        key = "host"
    end
    if e.key == key then return end
    e.key = key
    e.box:ClearAllPoints()
    if key == "host" then
        e.box:SetAllPoints(host)
    else
        e.box:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", L - hl, B - hb)
        e.box:SetSize(R - L, T - B)
    end
end

local softRoot = setmetatable({}, { __mode = "k" })
-- Liefert die Rahmen, die jetzt einen weichen Rand tragen (Prueflauf).
function W.SoftenModel(f)
    local cached = softRoot[f]
    if cached then
        for _, host in ipairs(cached) do
            PlaceBox(soft[host], host)
            MaskAll(soft[host], host)
        end
        return cached
    end
    local found = {}
    FindRaceBG(f, 0, found)
    -- Der Rahmen, auf dem der Hintergrund liegt.
    local hosts, order = {}, {}
    for _, r in ipairs(found) do
        local ok, p = pcall(r.GetParent, r)
        if ok and type(p) == "table" and p.CreateTexture then
            if not hosts[p] then hosts[p] = {} order[#order + 1] = p end
            table.insert(hosts[p], r)
        end
    end
    for _, host in ipairs(order) do
        local e = soft[host]
        if not e then
            e = { parts = hosts[host], box = CreateFrame("Frame", nil, host),
                  masked = setmetatable({}, { __mode = "k" }), count = 0 }
            local mok, mask = pcall(function() return host:CreateMaskTexture() end)
            if mok and type(mask) == "table" then
                mask:SetTexture(W.SOFT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                mask:SetAllPoints(e.box)
                own[mask] = true
                e.mask = mask
            end
            soft[host] = e
        end
        PlaceBox(e, host)
        MaskAll(e, host)
    end
    if #order > 0 then softRoot[f] = order end
    return order
end

-- Ebene einer Flaeche als "OVERLAY/7"; "?" ohne Antwort.
local function LayerOf(r)
    local ok, layer, sub = pcall(function() return r:GetDrawLayer() end)
    layer, sub = ok and K.Plain(layer) or nil, ok and K.Plain(sub) or nil
    if type(layer) ~= "string" then return "?" end
    return type(sub) == "number" and (layer .. "/" .. sub) or layer
end
W.LayerOf = LayerOf

-- Name einer Flaeche fuer den Bericht: Atlas oder Datei-Nummer.
local function PictureOf(r)
    local ok, atlas, file = pcall(function() return r:GetAtlas(), r:GetTexture() end)
    atlas, file = ok and K.Plain(atlas) or nil, ok and K.Plain(file) or nil
    if type(atlas) == "string" and atlas ~= "" then return atlas end
    if type(file) == "number" or type(file) == "string" then return tostring(file) end
    return "Farbe"
end

-- Fuer /wcui fenster: wo der weiche Rand sitzt, an wie vielen Bildern
-- die Maske haengt - und auf welchen Ebenen die Bilder liegen.
function W.SoftReport(f)
    local out = {}
    local CS = WeintCodex.UICharacter
    if CS and CS.ReportFrame then CS.ReportFrame(f, out) end
    for _, tab in ipairs(W.TABS) do tab.Report(f, out) end
    local nok, fname = pcall(function() return f:GetName() end)
    local hosted = nok and type(fname) == "string" and W.HOSTED[fname] or nil
    if hosted then
        for _, tab in ipairs(hosted) do tab.Report(f, out) end
    end
    if type(f) == "table" and f.ScrollContainer and W.mapMask and W.mapMask.report then
        out[#out + 1] = W.mapMask.report
    end
    for _, host in ipairs(softRoot[f] or {}) do
        local e = soft[host]
        out[#out + 1] = string.format("   Weicher Rand: %d Teile, %s", #e.parts,
            e.key == "host" and "am Träger (Lage des Bildes unbekannt)" or ("am Bild " .. tostring(e.key)))
        -- Szene und Licht des Charakterfensters (ui/character.lua).
        local CS = WeintCodex.UICharacter
        if CS and CS.ReportScene then CS.ReportScene(e, out) end
        if e.mask then
            out[#out + 1] = string.format("   Maske an %d %s", e.count, e.count == 1 and "Bild" or "Bildern")
        else
            out[#out + 1] = "   Maske fehlt: der Client legt keine an (CreateMaskTexture)"
        end
        local rok, regions = pcall(function() return { host:GetRegions() } end)
        local parts = {}
        for _, r in ipairs(rok and regions or {}) do
            local tok, isTex = pcall(function() return r:GetObjectType() == "Texture" end)
            if tok and isTex and not own[r] and #parts < 8 then
                parts[#parts + 1] = PictureOf(r) .. " " .. LayerOf(r)
            end
        end
        if #parts > 0 then out[#out + 1] = "   Darunter: " .. table.concat(parts, ", ") end
    end
    return out
end

--------------------------------------------------
-- Weltkarte (6.6.2.1)
--------------------------------------------------
-- Beta-Test: "auch dieses Fenster muss neu gemacht werden" (Karte &
-- Questlog, M). Die Karte selbst - Kacheln, Symbole, Questmarken - ist
-- Inhalt und bleibt unberuehrt: keine Suche nach grossen Bildern (die
-- Kartenkacheln sind gross), nur Rahmen, Pergament und Holz nach Namen.
-- Die Karte laedt das Spiel erst beim ersten Oeffnen (Blizzard_WorldMap).
--
-- Der Rahmen haengt nicht am Fenster, sondern an seinem Kind BorderFrame
-- (Titel, Portraet, Metallkante); die Leiste "Welt > Oestliche
-- Koenigreiche > ..." ist die NavBar. Beide werden wie ein Fenster des
-- Spiels behandelt: Schmuck weg, Titel in unserer Schrift, Knoepfe der
-- Leiste als flache Kachel. Was danach noch nach Holz aussieht, nennt
-- /wcui fenster - seit 6.6.2.1 ohne die Kartenkacheln.
W.MAP = "WorldMapFrame"

local navDone = setmetatable({}, { __mode = "k" })
local function SkinNavButton(b)
    if type(b) ~= "table" or navDone[b] or not b.CreateTexture or (b.IsForbidden and b:IsForbidden()) then return end
    navDone[b] = true
    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }) do
        local t = b[getter] and b[getter](b)
        if type(t) == "table" then Hide(t) end
    end
    HideOwnTextures(b)
    local d = K.Kachel(b, { shadow = 0 })
    own[d.bg], own[d.light] = true, true
    local s1 = C.surface1
    d.bg:SetColorTexture(s1[1], s1[2], s1[3], 0.95)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(b)
    local h = WeintCodex.GameColors.hoverFill
    hl:SetColorTexture(h[1], h[2], h[3], h[4] * 0.5)
    own[hl] = true
end
W.SkinNavButton = SkinNavButton

local function SkinNavBar(nav)
    if type(nav) ~= "table" or (nav.IsForbidden and nav:IsForbidden()) then return end
    if not navDone[nav] then
        navDone[nav] = true
        HideDecorOf(nav)
        HideOwnTextures(nav)
        if type(nav.overlay) == "table" then HideOwnTextures(nav.overlay) end
        for _, key in ipairs({ "InsetBorderBottomLeft", "InsetBorderBottomRight", "InsetBorderBottom",
                               "InsetBorderLeft", "InsetBorderRight" }) do
            if type(nav[key]) == "table" then Hide(nav[key]) end
        end
    end
    -- Die Knoepfe entstehen beim Wechseln der Zone neu.
    SkinNavButton(nav.homeButton)
    for _, b in ipairs(type(nav.navList) == "table" and nav.navList or {}) do
        if b ~= nav.homeButton then SkinNavButton(b) end
    end
end
W.SkinNavBar = SkinNavBar

--------------------------------------------------
-- Weicher Rand um Inhalte des Spiels (6.6.3.1)
--------------------------------------------------
-- Beta-Test: "Alles, was das Spiel mitbringt und nicht geaendert wird,
-- soll genauso weich gezeichnet werden wie beim Charakterfenster" -
-- zuerst die Karte (M). Anders als das Modellbild (fast schwarz am Rand,
-- deshalb dort eine Maske) ist die Karte hell: ein Verlauf in der Farbe
-- des Fensters, der nach innen ausblendet, laesst sie weich in den Rahmen
-- uebergehen. Er liegt in einem eigenen Rahmen UEBER der Karte - an den
-- Kartenbildern selbst aendert sich nichts (die Weltkarte ist empfindlich,
-- 6.6.0.1), und neue Kacheln beim Zoomen sind von selbst mit drin.
-- Ebene: ueber Kacheln und Marken, unter den Knoepfen auf der Karte
-- (overlayFrames des Spiels) - sonst verschwaenden die in der Ecke im
-- Schatten. /wcui fenster nennt die Ebenen.
W.SOFT_OVERLAY = 48
local softOverlay = setmetatable({}, { __mode = "k" })
W.softOverlay = softOverlay

local function OverlayEdge(o, side, c, size)
    local t = o:CreateTexture(nil, "OVERLAY", nil, 7)
    if side == "LEFT" or side == "RIGHT" then
        t:SetPoint("TOP" .. side, o, "TOP" .. side, 0, 0)
        t:SetPoint("BOTTOM" .. side, o, "BOTTOM" .. side, 0, 0)
        t:SetWidth(size)
    else
        t:SetPoint(side .. "LEFT", o, side .. "LEFT", 0, 0)
        t:SetPoint(side .. "RIGHT", o, side .. "RIGHT", 0, 0)
        t:SetHeight(size)
    end
    t:SetColorTexture(1, 1, 1, 1)
    if t.SetGradient and _G.CreateColor then
        local solid, clear = _G.CreateColor(c[1], c[2], c[3], 1), _G.CreateColor(c[1], c[2], c[3], 0)
        -- HORIZONTAL: erste Farbe links; VERTICAL: erste Farbe unten.
        if side == "LEFT" then t:SetGradient("HORIZONTAL", solid, clear)
        elseif side == "RIGHT" then t:SetGradient("HORIZONTAL", clear, solid)
        elseif side == "TOP" then t:SetGradient("VERTICAL", clear, solid)
        else t:SetGradient("VERTICAL", solid, clear) end
    else
        t:SetColorTexture(c[1], c[2], c[3], 0.5)
    end
    own[t] = true
    return t
end

-- Ein weicher Rand ueber `area`, als Kind von `window`, auf Ebene `level`.
function W.SoftOverlay(window, area, level, size)
    local o = softOverlay[area]
    if not o then
        o = CreateFrame("Frame", nil, window)
        o:SetAllPoints(area)
        if o.EnableMouse then o:EnableMouse(false) end
        local c = WeintCodex.Colors.bgDark
        for _, side in ipairs({ "LEFT", "RIGHT", "TOP", "BOTTOM" }) do
            o[side] = OverlayEdge(o, side, c, size or W.SOFT_OVERLAY)
        end
        softOverlay[area] = o
    end
    local ok, strata = pcall(area.GetFrameStrata, area)
    if ok and type(strata) == "string" and o.SetFrameStrata then o:SetFrameStrata(strata) end
    if type(level) == "number" and o._level ~= level then
        o._level = level
        o:SetFrameLevel(level)
    end
    return o
end

local function LevelOf(fr)
    if type(fr) ~= "table" or not fr.GetFrameLevel then return nil end
    local ok, l = pcall(fr.GetFrameLevel, fr)
    l = ok and K.Plain(l) or nil
    return type(l) == "number" and l or nil
end

-- Ebene fuer den Rand der Karte: direkt unter dem niedrigsten Knopf auf
-- der Karte, wenn der ueber der Karte liegt; sonst 100 ueber der Karte.
function W.MapOverlayLevel(map)
    local base = LevelOf(map.ScrollContainer) or 1
    local low
    for _, fr in ipairs(type(map.overlayFrames) == "table" and map.overlayFrames or {}) do
        local l = LevelOf(fr)
        if l and (not low or l < low) then low = l end
    end
    local level = (low and low - 1 > base) and (low - 1) or math.min(base + 100, 9999)
    return level, base, low
end

-- Zweite Fassung (6.6.3.2, Beta-Test: "immer noch nicht nach aussen
-- weichgezeichnet"). Der Verlauf nach Fast-Schwarz lag richtig (rechts und
-- unten zu sehen), aber oben liegt ueber dem Fenster der helle Schein der
-- Klassenfarbe: dunkler Kartenrand neben hellem Kopf ist wieder eine
-- Kante - dieselbe Falle wie beim Modellbild (6.6.2.5). Jetzt wie dort:
-- die Kartenbilder SELBST laufen aus (media/ui/softmask), darunter
-- erscheint der Grund des Fensters samt Schein. Gemeint sind nur die
-- grossen Bilder (Kacheln, erkundete Gebiete, ab 128 x 128) in den
-- Ebenen der Karte; Marken sind kleiner und bleiben, wie sie sind. Die
-- Maske sitzt am Kartenausschnitt, nicht an den Kacheln - wer zieht oder
-- zoomt, schiebt die Karte unter ihr durch. Je Rahmen eine Maske (sie
-- gehoert dem Rahmen, dessen Bilder sie formt); neue Kacheln bekommen sie
-- beim naechsten Durchlauf. Ohne Masken im Client: der Verlauf von 6.6.3.1.
W.MAP_TILE_MIN = 128 * 128
local mapMask = { masks = setmetatable({}, { __mode = "k" }), masked = setmetatable({}, { __mode = "k" }), count = 0 }
W.mapMask = mapMask

local function TileArea(r)
    if r:GetObjectType() ~= "Texture" then return 0 end
    local w, h = K.Plain(r:GetWidth()), K.Plain(r:GetHeight())
    if type(w) ~= "number" or type(h) ~= "number" then return 0 end
    return w * h
end

local function MaskFor(frame, area)
    local m = mapMask.masks[frame]
    if m then return m end
    local ok, mask = pcall(frame.CreateMaskTexture, frame)
    if not ok or type(mask) ~= "table" then return nil end
    mask:SetTexture(W.SOFT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(area)
    own[mask] = true
    mapMask.masks[frame] = mask
    return mask
end

local function MaskTiles(frame, area)
    for _, r in ipairs(Regions(frame, "mapTiles")) do
        if not own[r] and not mapMask.masked[r] then
            local ok, a = pcall(TileArea, r)
            if ok and a >= W.MAP_TILE_MIN then
                local mask = MaskFor(frame, area)
                if mask and pcall(r.AddMaskTexture, r, mask) then
                    mapMask.masked[r] = true
                    mapMask.count = mapMask.count + 1
                end
            end
        end
    end
end

function W.SoftMap(map)
    local sc = map.ScrollContainer
    if type(sc) ~= "table" or not sc.GetFrameLevel then return nil end
    local canvas = sc.Child
    local canMask = type(canvas) == "table" and type(canvas.CreateMaskTexture) == "function"
    if canMask then
        -- Kacheln liegen in den Ebenen der Karte (Kinder des Inhalts) oder
        -- am Inhalt selbst.
        MaskTiles(canvas, sc)
        for _, layer in ipairs(Children(canvas, "mapLayers")) do
            if type(layer) == "table" and layer.GetRegions and not (layer.IsForbidden and layer:IsForbidden()) then
                MaskTiles(layer, sc)
            end
        end
        local o = softOverlay[sc]
        if o then o:Hide() end
        -- Was noch darunter liegt (sichtbar, nicht maskiert, nicht unser):
        -- laeuft die Karte ins Schwarze aus, steht es hier.
        local under = 0
        for _, r in ipairs(Regions(sc, "mapUnder")) do
            local ok, tex = pcall(IsTexture, r)
            if ok and tex and not own[r] and not mapMask.masked[r] and K.Bool(r:IsShown(), false)
               and K.Plain(r:GetAlpha()) ~= 0 then
                under = under + 1
            end
        end
        mapMask.report = string.format("   Weicher Rand (Karte): Maske an %d Bildern, darunter %d Bilder am Ausschnitt",
            mapMask.count, under)
        return mapMask
    end
    local level, base, low = W.MapOverlayLevel(map)
    local o = W.SoftOverlay(map, sc, level)
    o:Show()
    o._report = string.format("   Weicher Rand (Karte): Verlauf, Ebene %d, Karte %d, Knöpfe ab %s",
        level, base, low and tostring(low) or "–")
    mapMask.report = o._report
    return o
end

function W.SkinMap(f)
    if type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return nil end
    local d = done[f]
    if not d then
        d = {}
        done[f] = d
        HideOwnTextures(f)
        local border = f.BorderFrame
        if type(border) == "table" then
            HideDecorOf(border)
            HideOwnTextures(border)
            StyleTitle(border)
        end
        d.kachel = K.Kachel(f, { alpha = 0.94, shadow = 8 })
        own[d.kachel.bg], own[d.kachel.light] = true, true
        if d.kachel.shadow and d.kachel.shadow.tex then own[d.kachel.shadow.tex] = true end
        W.AddGlow(f, d)
    end
    SkinNavBar(f.NavBar)
    if Opt("windowArt") then W.SoftMap(f) end
    -- Innen: nur nach Namen, nie nach Flaeche (siehe oben). Der Knopf der
    -- Seitenleiste trug noch einen Eckschatten (6.6.3.1, /wcui fenster:
    -- "MapCornerShadow-Right ... SOLLTE WEG SEIN").
    local qm = f.QuestMapFrame or _G.QuestMapFrame
    -- 6.7.9.0: mit dem Stil des Fensters (Gold, S.CALM) - die Kategorien
    -- des Questlogs werden Abschnitte wie im Ruf statt mittig mit Lichthof.
    local sc = scoped[f]
    for _, part in ipairs({ f.BorderFrame, f.OverscrollBG, qm, _G.QuestScrollFrame, f.SidePanelToggle }) do
        if type(part) == "table" then HideByAtlas(part, 0, scoped[part] or sc) end
    end
    Grey(f, 0)
    if type(qm) == "table" then SkinPanelButtons(qm, 0) end
    return d
end

--------------------------------------------------
-- Seitenreiter und Innenflaechen (6.6.2.1)
--------------------------------------------------
-- Reiter am rechten Rand (Berufe: ein Reiter je Beruf; Gilde &
-- Communitys: Chat, Mitglieder, Gildeninfo). Im Berufefenster tragen sie
-- den Goldrahmen "common-sidetab" (gemessen) - wie die Reiter am
-- Charakterfenster: eine kleine Kachel, der gewaehlte mit Rand im Akzent.
-- Die Reiter der Communitys heissen im Quelltext des Spiels ChatTab,
-- RosterTab, GuildBenefitsTab, GuildInfoTab; ihr Bild ist .Background.
local SIDE_KEYS = { "ChatTab", "RosterTab", "GuildBenefitsTab", "GuildInfoTab" }
local sideDone = setmetatable({}, { __mode = "k" })
W.SideTabs = sideDone

local function SideTabAtlas(r)
    local ok, atlas = pcall(TextureAtlas, r)
    atlas = ok and K.Plain(atlas) or nil
    return type(atlas) == "string" and atlas:find("^common%-sidetab") and atlas or nil
end

local function IsSideTab(b)
    for _, r in ipairs(Regions(b, "isSide")) do
        if SideTabAtlas(r) then return true end
    end
    return false
end

-- GEWAEHLT? 6.6.2.1 nahm das erste Zeichen, das einer der Reiter trug -
-- im Berufefenster trugen es alle vier, und alle vier standen im Akzent
-- (Beta-Test). Seit 6.6.2.2: jedes Zeichen wird fuer die ganze Reihe
-- gelesen, und es zaehlt nur eines, das die Reihe TRENNT (nicht keiner,
-- nicht alle). Trennt keines, ist keiner markiert - lieber keine Auskunft
-- als eine falsche. /wcui fenster nennt die Zeichen je Reiter.
local function Shown(t)
    return type(t) == "table" and t.IsShown and K.Bool(t:IsShown(), false) or false
end

local function Brightness(t)
    if type(t) ~= "table" or not t.GetVertexColor then return nil end
    local ok, r, g, b = pcall(t.GetVertexColor, t)
    r, g, b = K.Plain(r), K.Plain(g), K.Plain(b)
    if not ok or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return nil end
    local desat = t.IsDesaturated and K.Bool(t:IsDesaturated(), false)
    return math.floor((r + g + b) * 100 + 0.5) - (desat and 1000 or 0)
end

function W.SideSignals(tab)
    local sig = {}
    if type(tab.GetChecked) == "function" then
        local ok, v = pcall(tab.GetChecked, tab)
        if ok then sig.checked = K.Bool(v, false) end
    end
    local sel = tab.SelectedTexture or tab.Selected
    if type(sel) == "table" and sel.IsShown then sig.selTex = Shown(sel) end
    if type(tab.IsEnabled) == "function" then
        local ok, v = pcall(tab.IsEnabled, tab)
        if ok and type(K.Plain(v)) ~= "nil" then sig.disabled = not K.Bool(v, true) end
    end
    for _, r in ipairs(Regions(tab, "sideSig")) do
        local a = SideTabAtlas(r)
        if a and a:lower():find("select", 1, true) then sig.selAtlas = Shown(r) or sig.selAtlas or false end
        if a == "common-sidetab" then sig.frameLight = Brightness(r) end
    end
    local icon = tab.Icon or tab.icon
    if type(icon) ~= "table" then icon = TabIcon(tab) end
    sig.iconLight = Brightness(icon)
    return sig
end

local FLAG_ORDER = { "checked", "selTex", "selAtlas", "disabled" }
local LIGHT_ORDER = { "frameLight", "iconLight" }

-- Welcher Reiter einer Reihe ist gewaehlt? Liefert ihn (oder nil) und das
-- Zeichen, das es entschieden hat.
function W.PickSelected(tabs, signals)
    for _, key in ipairs(FLAG_ORDER) do
        local yes, known = {}, 0
        for _, t in ipairs(tabs) do
            local v = signals[t][key]
            if type(v) == "boolean" then
                known = known + 1
                if v then yes[#yes + 1] = t end
            end
        end
        if known == #tabs and #yes == 1 then return yes[1], key end
    end
    -- Heller als alle anderen (Rahmen oder Bild), eindeutig.
    for _, key in ipairs(LIGHT_ORDER) do
        local best, bestV, second = nil, nil, nil
        local known = 0
        for _, t in ipairs(tabs) do
            local v = signals[t][key]
            if type(v) == "number" then
                known = known + 1
                if not bestV or v > bestV then second, best, bestV = bestV, t, v
                elseif not second or v > second then second = v end
            end
        end
        if known == #tabs and #tabs > 1 and bestV and second and bestV > second then return best, key end
    end
    return nil, nil
end

local function SkinSideTab(tab)
    if type(tab) ~= "table" or not tab.CreateTexture or (tab.IsForbidden and tab:IsForbidden()) then return nil end
    local d = sideDone[tab]
    if not d then
        for _, r in ipairs(Regions(tab, "sideSkin")) do
            if SideTabAtlas(r) then Hide(r) end
        end
        if type(tab.Background) == "table" then Hide(tab.Background) end
        d = { kachel = K.Kachel(tab, { shadow = 3 }) }
        own[d.kachel.bg], own[d.kachel.light] = true, true
        local hl = tab:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(tab)
        local h = WeintCodex.GameColors.hoverFill
        hl:SetColorTexture(h[1], h[2], h[3], h[4])
        own[hl] = true
        sideDone[tab] = d
    end
    return d
end

local function CollectSideTabs(f, depth, out)
    if depth > 6 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    if depth == 0 then
        for _, key in ipairs(SIDE_KEYS) do
            if type(f[key]) == "table" then out[#out + 1] = f[key] end
        end
    end
    for _, ch in ipairs(Children(f, "sideTabs", depth)) do
        if type(ch) == "table" then
            if sideDone[ch] or IsSideTab(ch) then out[#out + 1] = ch end
            CollectSideTabs(ch, depth + 1, out)
        end
    end
end

local function SkinSideTabs(f)
    -- Der gewaehlte Reiter traegt den Akzent SEINES Fensters (6.7.5.0): im
    -- Berufsfenster Gold (S.CALM), sonst die Klassenfarbe - ein Bereich,
    -- ein Akzent.
    local sc = scoped[f]
    local accent = S.Accent(sc and sc.accent)
    local found, seenTab = {}, {}
    CollectSideTabs(f, 0, found)
    -- Reihen: Reiter mit demselben Elternrahmen.
    local groups, order = {}, {}
    for _, tab in ipairs(found) do
        if not seenTab[tab] and SkinSideTab(tab) then
            seenTab[tab] = true
            local ok, p = pcall(tab.GetParent, tab)
            p = ok and p or tab
            if not groups[p] then groups[p] = {} order[#order + 1] = p end
            table.insert(groups[p], tab)
        end
    end
    for _, p in ipairs(order) do
        local tabs = groups[p]
        local signals = {}
        for _, t in ipairs(tabs) do signals[t] = W.SideSignals(t) end
        local pick, why = W.PickSelected(tabs, signals)
        for _, t in ipairs(tabs) do
            local d = sideDone[t]
            local on = (t == pick)
            d.signals, d.why = signals[t], on and why or nil
            if d.on ~= on or (on and d.accent ~= accent) then
                d.on, d.accent = on, on and accent or nil
                local c = on and accent or BLACK
                d.kachel.border:SetColor(c[1], c[2], c[3], 1)
            end
        end
    end
    return found
end
W.SkinSideTabs = SkinSideTabs

-- Fuer /wcui fenster: je Reiter seine Zeichen.
function W.SideTabReport(f)
    local out = {}
    local raw, found, seenTab = {}, {}, {}
    CollectSideTabs(f, 0, raw)
    for _, tab in ipairs(raw) do
        if not seenTab[tab] then seenTab[tab] = true found[#found + 1] = tab end
    end
    for i, tab in ipairs(found) do
        local d = sideDone[tab]
        local sig = (d and d.signals) or W.SideSignals(tab)
        local parts = {}
        for _, key in ipairs({ "checked", "selTex", "selAtlas", "disabled", "frameLight", "iconLight" }) do
            if type(sig[key]) ~= "nil" then parts[#parts + 1] = key .. "=" .. tostring(sig[key]) end
        end
        out[#out + 1] = string.format("   Reiter %d: %s%s", i, table.concat(parts, " "),
            (d and d.on) and (" · GEWÄHLT (" .. tostring(d.why) .. ")") or "")
        if i >= 8 then break end
    end
    return out
end

-- Innenflaechen tiefer im Fenster (InsetFrameTemplate: Bg + NineSlice),
-- etwa Liste, Chat und Mitglieder der Communitys: der Rahmen weg, eine
-- etwas hellere Flaeche darunter - wie die Innenflaechen oben am Fenster.
local insetDone = setmetatable({}, { __mode = "k" })
W.Insets = insetDone
local function SkinInset(inset)
    if type(inset) ~= "table" or insetDone[inset] or not inset.CreateTexture
       or (inset.IsForbidden and inset:IsForbidden()) then return end
    insetDone[inset] = true
    HideDecor(inset)
    local t = inset:CreateTexture(nil, "BACKGROUND", nil, -8)
    t:SetAllPoints(inset)
    local s1 = C.surface1
    t:SetColorTexture(s1[1], s1[2], s1[3], 0.45)
    own[t] = true
end

-- Bleibt, wie das Spiel es zeichnet (6.6.3.3, Beta-Test: "die
-- Mitgliederliste ist etwas verdunkelt, das kann gern wieder im
-- Normalzustand sein"): die Mitgliederliste der Communitys.
W.INSET_KEEP = { "MemberList" }
local insetKeep = setmetatable({}, { __mode = "k" })

-- "A.B.C" -> _G.A.B.C, oder nil.
-- Ohne gmatch (6.7.2.1): die Register und das PvP-Profil fragen ihre
-- Pfade in jedem Durchlauf, und gmatch legte dabei jedes Mal eine Closure
-- an. Teilstuecke sind Namen, die es schon gibt - :sub legt nichts neu an.
function W.Resolve(path)
    local t, i = _G, 1
    while i <= #path do
        local j = path:find(".", i, true)
        if type(t) ~= "table" then return nil end
        t = t[path:sub(i, j and j - 1 or -1)]
        if not j then break end
        i = j + 1
    end
    return type(t) == "table" and t or nil
end

-- Eine Flaeche, deren eigene Bilder nur Grund sind: weg, darunter eine
-- Innenflaeche. Einmal je Flaeche.
local ownBgDone = setmetatable({}, { __mode = "k" })
W.OwnBgDone = ownBgDone
function W.OwnBackground(f)
    if type(f) ~= "table" or ownBgDone[f] or not f.CreateTexture or (f.IsForbidden and f:IsForbidden()) then return end
    ownBgDone[f] = true
    HideOwnTextures(f)
    SkinInset(f)
end

local function SkinInsets(f, depth)
    if depth > 6 or type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) then return end
    if depth == 0 then
        for _, key in ipairs(W.INSET_KEEP) do
            if type(f[key]) == "table" then insetKeep[f[key]] = true end
        end
    end
    if insetKeep[f] then return end
    if depth > 0 then
        for _, key in ipairs({ "InsetFrame", "Inset" }) do
            if type(f[key]) == "table" and f[key].GetObjectType then SkinInset(f[key]) end
        end
    end
    for _, ch in ipairs(Children(f, "insets", depth)) do SkinInsets(ch, depth + 1) end
end
W.SkinInsets = function(f) SkinInsets(f, 0) end

-- Liste links an Gilde & Communitys (gemessen, 6.6.2.3): ihr Grund (Bild
-- 593918, zehnfach) und die Goldranken in den Ecken (FilligreeOverlay).
local listDone = setmetatable({}, { __mode = "k" })
function W.SkinCommunitiesList(f)
    local list = f.CommunitiesList or _G.CommunitiesFrameCommunitiesList
    if type(list) ~= "table" or listDone[list] or (list.IsForbidden and list:IsForbidden()) then return end
    listDone[list] = true
    HideOwnTextures(list)
    if type(list.FilligreeOverlay) == "table" then HideOwnTextures(list.FilligreeOverlay) end
end


-- Der Schein der Klasse oben (W.AddGlow) und die neue Sprache (6.7.7.0):
-- ein Fenster in Gold (S.CALM, Berufe) traegt ihn nie - er ist die
-- Klassenfarbe, und ein Bereich traegt einen Akzent. Ein gestalteter Teil
-- (W.HOSTED) kann ihn abschalten, solange er offen ist (GlowOff: das
-- Zauberbuch hat die ruhige Atmosphaere des Registers). Sonst bleibt er.
-- Versteckt statt durchsichtig und je Durchlauf gehalten - wie im
-- Charakterfenster (ui/character.lua), wo er wieder auftauchte.
function W.HoldGlow(f, n)
    local d = done[f]
    local glow = d and d.glow
    if not glow then return end
    local sc = scoped[f]
    local off = (sc and sc.accent == "frame") and true or false
    local hosted = W.HOSTED[n]
    if not off and hosted then
        for _, tab in ipairs(hosted) do
            if tab.GlowOff and tab.GlowOff(f) then off = true break end
        end
    end
    local shown = K.Bool(glow:IsShown(), false)
    if off and shown then glow:Hide()
    elseif not off and not shown and d.glowHeld then glow:Show() end
    d.glowHeld = off
end

function W.Inner()
    stats.runs = stats.runs + 1
    stats.last = _G.GetTime and K.Plain(_G.GetTime()) or nil
    -- Stile der Bereiche (ui/style.lua), bevor der erste Durchlauf eine
    -- Kopfzeile oder einen Balken anlegt.
    S.Register()
    for _, n in ipairs(W.WINDOWS) do
        local f = _G[n]
        if type(f) == "table" and done[f] and Open(f) then
            HideByAtlas(f, 0, scoped[f])
            SkinSlots(f)
            Grey(f, 0)
            SkinTabSystems(f, 0)
            SkinPanelButtons(f, 0)
            SkinSideTabs(f)
            -- Innenflaechen tiefer im Fenster nur dort, wo sie gemessen
            -- zu sehen waren - die schon gestalteten Fenster bleiben, wie sie sind.
            if n == "CommunitiesFrame" then W.SkinCommunitiesList(f) end
            if n == "CommunitiesFrame" or n == "ProfessionsFrame" or n == "LFGParentFrame" or n == "PVEFrame" then
                SkinInsets(f, 0)
            end
            if n == "CharacterFrame" then
                FitStats(f, 0)
                -- Das Charakterfenster als Ganzes: ui/character.lua.
                local CS = WeintCodex.UICharacter
                if CS then CS.Update(f, done[f]) end
                -- Gestaltete Reiter (W.TABS): Register (ui/register.lua: Ruf,
                -- Fertigkeiten) und PvP (ui/pvp.lua). Jeder prueft selbst,
                -- ob sein Reiter offen ist.
                for _, tab in ipairs(W.TABS) do tab.Update(f) end
            end
            local hosted = W.HOSTED[n]
            if hosted then
                for _, tab in ipairs(hosted) do tab.Update(f) end
            end
            W.HoldGlow(f, n)
            if W.WantsLarge(n) then
                SkinSpellItems(f, 0)
                LightenText(f, 0)
                W.HideLarge(f)
            elseif W.DIALOGS[n] then
                LightenText(f, 0, true)
                W.HideLarge(f)
            end
        end
    end
    SkinModeTabs()
    local map = _G[W.MAP]
    if type(map) == "table" and done[map] and Opt("mapSkin") and Open(map) then
        W.SkinMap(map)
        -- 6.7.9.0: auch die Karte hat gestaltete Teile (Questlog) und den
        -- Schein der Klasse (in Gold: aus).
        local hosted = W.HOSTED[W.MAP]
        if hosted then
            for _, tab in ipairs(hosted) do tab.Update(map) end
        end
        W.HoldGlow(map, W.MAP)
    end
end

function W.Status()
    local now = _G.GetTime and K.Plain(_G.GetTime()) or nil
    local ago = (type(now) == "number" and type(stats.last) == "number") and string.format("vor %d s", now - stats.last) or "nie"
    return string.format("Fenster-Stil %s · innen: %d Läufe (zuletzt %s), %d Bilder ausgeblendet, %d ohne Wirkung%s",
        Opt("windowSkin") and "an" or "aus", stats.runs, ago, stats.hidden, stats.stuck,
        stats.err and (" · Fehler: " .. tostring(stats.err)) or "")
end

function W.Apply()
    if not Opt("windowSkin") then return end
    for _, n in ipairs(W.WINDOWS) do
        local f = _G[n]
        -- Ein Teilfenster eines schon gestalteten Fensters bekommt keine
        -- zweite Kachel.
        local parent = type(f) == "table" and f.GetParent and f:GetParent()
        W.Skin(f, parent and done[parent] and true or false)
    end
    for _, n in ipairs(W.PANELS) do
        local f = _G[n]
        if type(f) == "table" and not done[f] then W.Skin(f, true) end
    end
    if type(_G[W.MAP]) == "table" and Opt("mapSkin") then W.SkinMap(_G[W.MAP]) end
    for _, n in ipairs(W.OWN_BG) do
        local f = _G[n]
        if type(f) == "table" and not done[f] then
            W.Skin(f, true)
            HideOwnTextures(f)
        end
    end
    for _, path in ipairs(W.OWN_BG_PATHS) do W.OwnBackground(W.Resolve(path)) end
    for _, n in ipairs(W.POPUPS) do W.SkinPopup(_G[n]) end
    W.Inner()
end

-- Die Fenster legt das Spiel beim Anmelden an; manche Teilfenster erst
-- beim ersten Oeffnen, das Zauberbuch erst beim ersten Druecken von P
-- (Blizzard_PlayerSpells laedt bei Bedarf). Deshalb: beim Anmelden, bei
-- jedem nachgeladenen Teil des Spiels und bei jedem Zeigen eines Fensters.
local hookedWin = {}
local function Run(fn)
    local ok, err = pcall(fn)
    if not ok then stats.err = err K.Report("fenster", err) end
end

-- Der Takt (6.6.2.6): bis dahin zweimal je Sekunde, je offenem Fenster
-- (zwei offene = vier Laeufe). Jetzt EIN Takt fuer alle: schnell kurz
-- nach dem Oeffnen und nach jedem Klick (Reiterwechsel, neue Zeilen),
-- danach nur noch alle zwei Sekunden - falls das Spiel ein Bild von sich
-- aus zurueckholt.
W.TICK_FAST, W.TICK_SLOW, W.FAST_FOR = 0.3, 2, 1.5
local tick = { last = -math.huge, fastUntil = 0 }
W.tick = tick

local function Now()
    local t = _G.GetTime and K.Plain(_G.GetTime())
    return type(t) == "number" and t or 0
end

function W.Wake()
    tick.fastUntil = Now() + W.FAST_FOR
end

function W.Tick()
    local now = Now()
    local gap = now < tick.fastUntil and W.TICK_FAST or W.TICK_SLOW
    if now - tick.last < gap then return false end
    tick.last = now
    Run(W.Inner)
    return true
end

local function HookWindow(f)
    if type(f) ~= "table" or hookedWin[f] or not f.HookScript or (f.IsForbidden and f:IsForbidden()) then return end
    hookedWin[f] = true
    f:HookScript("OnShow", function()
        Run(W.Apply)
        W.Wake()
    end)
    -- Ein eigener Kindrahmen, kein Skript am Fenster des Spiels: er
    -- laeuft nur, solange das Fenster sichtbar ist. Alle teilen W.Tick.
    local watch = CreateFrame("Frame", nil, f)
    -- So gross wie das Fenster und aus jeder Anordnung heraus: Fenster, die
    -- ihre Groesse aus ihren Kindern rechnen (Spielmenue), sollen ihn nicht
    -- mitzaehlen.
    watch:SetAllPoints(f)
    watch.ignoreInLayout = true
    watch:SetScript("OnUpdate", K.Measured("Fenster", function() W.Tick() end))
end

-- Ein Klick irgendwo: kurz schnell nachsehen. Laeuft nur etwas, solange
-- ein Fenster offen ist (die Taktgeber sind Kinder der Fenster).
local clicks = CreateFrame("Frame")
pcall(clicks.RegisterEvent, clicks, "GLOBAL_MOUSE_UP")
clicks:SetScript("OnEvent", function() W.Wake() end)

local hookedShow = {}
function W.HookAll()
    for _, n in ipairs(W.WINDOWS) do HookWindow(_G[n]) end
    if Opt("mapSkin") then HookWindow(_G[W.MAP]) end
    for _, n in ipairs(W.SHOW_HOOKS) do
        local f = _G[n]
        if type(f) == "table" and f.HookScript and not hookedShow[f] and not (f.IsForbidden and f:IsForbidden()) then
            hookedShow[f] = true
            f:HookScript("OnShow", function() Run(W.Inner) end)
        end
    end
    -- Neue Gespraechsseite im offenen Fenster (anderer NPC, Option gewaehlt).
    local g = _G.GossipFrame
    if type(g) == "table" and not hookedShow.gossip and _G.hooksecurefunc then
        for _, m in ipairs({ "Update", "Refresh" }) do
            if type(g[m]) == "function" then
                hookedShow.gossip = true
                _G.hooksecurefunc(g, m, function() Run(W.Inner) end)
            end
        end
    end
end

-- Ein Fenster des Spiels, das in keiner Liste steht, aber nach Zauberbuch
-- oder Talenten heisst: aufnehmen, gestalten, beobachten.
function W.Adopt(f)
    if type(f) ~= "table" or (f.IsForbidden and f:IsForbidden()) or not f.GetName then return false end
    local ok, name = pcall(f.GetName, f)
    if not ok or not W.WantsLarge(name) then return false end
    local known = false
    for _, n in ipairs(W.WINDOWS) do if n == name then known = true break end end
    if not known then W.WINDOWS[#W.WINDOWS + 1] = name end
    HookWindow(f)
    Run(W.Apply)
    return true
end

if _G.hooksecurefunc and type(_G.ShowUIPanel) == "function" then
    _G.hooksecurefunc("ShowUIPanel", function(f)
        if not K.UIEnabled() or not Opt("windowSkin") then return end
        W.Adopt(f)
    end)
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(_, event, name)
    if not K.UIEnabled() or not Opt("windowSkin") then return end
    if event == "ADDON_LOADED" and not (type(name) == "string" and name:find("^Blizzard_")) then return end
    -- Vor dem Anmelden gibt es nichts zu gestalten; PLAYER_LOGIN kommt noch.
    if event == "ADDON_LOADED" and not (_G.IsLoggedIn and K.Bool(_G.IsLoggedIn(), false)) then return end
    Run(W.Apply)
    W.HookAll()
end)
