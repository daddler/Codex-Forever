--------------------------------------------------
-- WeintCodex :: Oberflaeche - Kontakte (6.10.1.0)
--------------------------------------------------
-- Das Fenster "Kontakte" des Spiels (FriendsFrame, Taste O: Freunde,
-- Kuerzliche Verbuendete, Schlachtzug) in der ruhigen
-- Informationsoberflaeche. Kontakte gehoeren nicht zur Klasse: GOLD
-- (S.CALM), wie Post, Bank und Handel. Beta-Test 6.10.0.0: "das Fenster
-- Kontakte ist noch nicht bearbeitet" - Metallrahmen, Portraet, roter
-- Knopf, blauer Kasten mit der BattleTag.
--
-- Erstes Fenster, das von Anfang an aus Bausteinen besteht
-- (ui/calmparts.lua): hier steht nur, WAS gemessen wurde.
--
--   Huelle     Metallrahmen, Ecken, Streifen unter dem Titel weg, die roten
--              Knoepfe ("Freund hinzufuegen", "Nachricht senden") flach, die
--              Reiter oben ("Freunde", "Kuerzliche Verbuendete") ueber die
--              Reiterleiste des Spiels - alles im allgemeinen Durchlauf
--              (W.WINDOWS). Licht und Kante in Gold: ui/calm.lua.
--   Portraet   das Symbol mit den zwei Koepfen oben links (526421) weg, wie
--              an der Post - der Ring darum ist schon weg.
--   BattleTag  der blaue Kasten (FriendsFrameBattlenetFrame, 632259): eine
--              flache Leiste mit 1 px Rand. Name und Knopf daneben bleiben.
--   Status     das Feld mit dem farbigen Punkt (FriendsFrameStatusDropdown,
--              "common-dropdown-textholder"): flache Leiste.
--   Liste      die Innenflaeche (FriendsFrameInset) wie ueberall. Die Zeilen
--              behalten ihre Farbe (blau: BattleTag, gelb: Charakter, grau:
--              offline) und den Schein unter der Maus - beides sagt etwas.
--   Reiter     unten ("Kontakte", "Schlachtzug") flach, der gewaehlte in Gold.
--
-- GEMESSEN (6.10.0.0, /wcui fenster, Reiter "Freunde"): FriendsFrame
-- (374155, NineSlice "UI-Frame-Metal-*", "UI-Frame-PortraitMetal-*",
-- "_UI-Frame-TopTileStreaks", 526421), FriendsFrameInset (374154),
-- FriendsListFrame.ScrollBox (136809 Schein der Zeile, bleibt),
-- FriendsFrameAddFriendButton (130828/130826), FriendsFrameBattlenetFrame
-- (632259), FriendsTabHeader.TabSystem ("uiframe-tab-*",
-- "uiframe-activetab-*"), FriendsFrameStatusDropdown
-- ("common-dropdown-textholder").
-- UNGEMESSEN: "Kuerzliche Verbuendete", "Schlachtzug" und die
-- Ignorierliste - sie bekommen Huelle und Gold; was dort noch alt aussieht,
-- sagt /wcui fenster auf dem jeweiligen Reiter.
--
-- NEUES KONTAKTFENSTER (6.20.0.0): Blizzard hat die Kontakte neu gebaut -
-- SocialUIFrame mit Reitern rechts statt unten, Karten je Freund, Suche und
-- Filter. FriendsFrame bleibt hier stehen: was der Client nicht hat, faellt
-- heraus. Gemessen 07.10.2026 (/wcui fenster, Reiter "Freunde"):
--   Rahmen     NineSlice "UI-Frame-Metal-*", "UI-Frame-PortraitMetal-*",
--              SocialUIFrameBg, Portraet 526421, der rote Knopf "Neuen Freund
--              hinzufuegen" ("128-RedButton-*"), Seitenreiter
--              ("common-sidetab*") - allgemeiner Durchlauf (W.WINDOWS):
--              Kachel, Knopf flach, Reiter als Kachel, der gewaehlte in Gold.
--   Verlauf    oben und unten ("friends-frame-topTexBG"/"-bottomTexBG") weg.
--   BattleTag  das Band dahinter ("friends-frame-infoBG") weg, der blaue
--              Kasten (632259) eine Leiste ohne Rand an seiner Stelle; das
--              Feld des Status flach wie bisher.
--   Suche      das Suchfeld ("common-searchbar-a") flach. Der Filterknopf
--              bleibt: sein Pfeil ist Teil des Bildes.
--   Linien     ueber und unter der Liste ("perks-divider-short") weg.
--   Karten     je Freund ("friends-card-*") bleiben: grau heisst offline,
--              die Wahl und der Knopf zum Einladen sagen etwas.
-- UNGEMESSEN: "Kuerzliche Verbuendete", "Schlachtzug", "Anfragen".
--------------------------------------------------

WeintCodex = WeintCodex or {}

local CP = WeintCodex.UICalmParts

local FR = CP.New({
    label = "Kontakte", host = "FriendsFrame", depth = 4,
    files = {
        [526421] = "decor",  -- Symbol oben links (zwei Koepfe)
        [632259] = "field",  -- blauer Kasten mit der BattleTag
    },
    atlases = {
        { "^common%-dropdown%-textholder", "field" },  -- Feld des Status
    },
    -- Unten: Kontakte, (Wer), Schlachtzug, (Schnellbeitritt) - was der
    -- Client nicht hat, faellt heraus.
    tabs = { "FriendsFrameTab1", "FriendsFrameTab2", "FriendsFrameTab3", "FriendsFrameTab4" },
})
WeintCodex.UIFriends = FR

-- Das neue Kontaktfenster (6.20.0.0). Tiefe 3: bis zum Suchfeld
-- (FriendsList.FilterBar.SearchBar); die Karten darunter bleiben, wie sie
-- sind, und werden im Takt nicht abgelaufen.
FR.Social = CP.New({
    label = "Kontakte", host = "SocialUIFrame", depth = 3,
    files = {
        [526421] = "decor",  -- Symbol oben links (zwei Koepfe)
        [632259] = "strip",  -- blauer Kasten mit der BattleTag
    },
    atlases = {
        { "^common%-dropdown%-textholder", "field" },  -- Feld des Status
        { "^common%-searchbar%-a$", "field" },         -- Suchfeld
        { "^friends%-frame%-infoBG", "decor" },        -- Band hinter der BattleTag
        { "^friends%-frame%-topTexBG", "decor" },      -- Verlauf oben
        { "^friends%-frame%-bottomTexBG", "decor" },   -- Verlauf unten
        { "^perks%-divider%-short", "decor" },         -- Linien ueber/unter der Liste
    },
})
