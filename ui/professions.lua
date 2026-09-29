--------------------------------------------------
-- WeintCodex :: Oberflaeche - Berufe (6.7.5.0)
--------------------------------------------------
-- Das Berufsfenster (ProfessionsFrame) in derselben ruhigen
-- Informationsoberflaeche wie Ruf, Fertigkeiten, Abzeichen und
-- Statistiken - aber in GOLD (S.CALM): Berufe gehoeren nicht zur Klasse.
-- Das ist der Fall, fuer den das Gold (GameColors.frameAccent) seit 6.7.0.0
-- bereitliegt; ein Bereich, ein Akzent.
--
-- Die Rezeptseite (CraftingPage) ist ein Register (ui/register.lua), das
-- erste ausserhalb des Charakterfensters (cfg.host):
--   links   die Rezeptliste des Spiels: Kategorien als Abschnitte (Band,
--           Raute, Linie in Gold), Rezepte mit Haarlinie, Hervorhebung des
--           Spiels (Hover und gewaehlt) in Gold getoent, Auswahl-Strich.
--   rechts  das Rezept (SchematicForm) als Karte: Name groesser in SEINER
--           Farbe (Qualitaet), Beschreibung, darunter abgesetzt, was folgt
--           (Reagenzien, Werkzeug, ...); die Karte endet unter dem Inhalt.
--           Nichts davon wird bewegt - Knoepfe (Reagenzien) sperren das
--           Ruecken ohnehin.
--   Grund   Hintergrund der Seite, der Rezeptliste und das grosse Bild
--           hinter dem Rezept sind weg (ui/windows.lua, W.HIDE_ATLAS) - die
--           Flaechen des Registers liegen an ihrer Stelle.
-- Unveraendert: Rangbalken oben (Rahmen, animierte Fuellung, Text),
-- Symbol des Ergebnisses mit Qualitaetsrahmen, Plaetze der Reagenzien,
-- Filter, Knoepfe (Herstellen, Alle), Suchfeld, Seitenreiter.
--
-- GEMESSEN (6.7.4.0, /wcui fenster auf der Seite der Kochkunst):
--   ProfessionsFrame.CraftingPage                 Profession-Background-Template2
--   .CraftingPage.RecipeList                      Professions-background-summarylist
--   .RecipeList.ScrollBox.ScrollTarget.<Zeile>    Professions_Recipe_Hover/_Active
--   .RecipeList.ScrollBar                         minimal-scrollbar-*
--   .CraftingPage.SchematicForm                   Profession-background-card-Cooking
--   .SchematicForm.OutputIcon, .Reagents.<..>.Button, .CraftingPage.RankBar
--   Kategorien der Liste: Kopfzeilen des Spiels ("Alltaegliche Mahlzeiten").
-- UNGEMESSEN: Schluessel des Rezeptnamens (OutputText wie im Quelltext des
-- Spiels, sonst die oberste Zeile) und der Zeilen (Label).
--
-- Die UEBERSICHT (erster Seitenreiter, Karten je Beruf) bleibt, wie sie seit
-- 6.6.2.1 ist (Hintergrund weg, Bilder der Karten gedaempft) - bekommt aber
-- denselben Stil (Gold). Ihr Aufbau ist nicht gemessen.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local S = WeintCodex.UIStyle

-- Das ganze Fenster in Gold: Kopfzeilen und Balken auch der Uebersicht.
S.SCOPES.ProfessionsFrame = S.CALM

WeintCodex.UIProfessions = WeintCodex.UIRegister.New({
    label          = "Berufe",
    key            = "prof",
    host           = "ProfessionsFrame",
    style          = S.CALM,
    frames         = { "ProfessionsFrame.CraftingPage" },
    listKeys       = { "RecipeList.ScrollBox", "ScrollBox" },
    scrollBarKeys  = { "RecipeList.ScrollBar", "ScrollBar" },
    highlightAtlas = "^Professions_Recipe_",
    detailKeys     = { "SchematicForm" },
    titleKeys      = { "OutputText", "RecipeName", "Title", "Name" },
    titleTop       = true,
    -- Der Rezeptname kann die Qualitaet tragen: seine Farbe bleibt.
    titleColor     = false,
    barKeys        = { "StatusBar", "Bar" },
    detailBarKeys  = { "StatusBar", "Bar" },
    barLine        = "below",
    tail           = true,
    compact        = true,
})
