--------------------------------------------------
-- WeintCodex :: Oberflaeche - Ruf (6.7.0.0)
--------------------------------------------------
-- Das erste Fenster der Designsprache (ui/style.lua), der Reiter "Ruf" im
-- Charakterfenster (ReputationFrame) und seine Detailansicht rechts.
-- Seit 6.7.1.0 ein Register (ui/register.lua): Liste, Zeilen, Balken,
-- Auswahl, Karte und Bericht sind derselbe Baustein wie bei den
-- Fertigkeiten (ui/skills.lua). Hier steht nur, was am Ruf anders ist.
--
-- Geschichte (Einzelheiten in docs/systems/ui.md):
--   6.7.0.0  Stil-Schicht, erster Ruf (noch Gold).
--   6.7.0.1  Klassenfarbe (gehoert zum Charakter), Flaechen statt
--            schwarzer Kaesten; gemessen: Balken sind keine Statusbalken,
--            Fuellung "common-stat-bar-white"; Hervorhebung des Spiels
--            Content.BackgroundHighlight.
--   6.7.0.2  Fraktionsregister und Codex-Tafel, Astrolab-Zeichen.
--   6.7.0.3  Detailansicht als kompakte Karte, Haekchen ruecken unter die
--            Beschreibung.
--   6.7.2.1  Dieselbe Gliederung wie die Fertigkeiten: Name, Stufe und
--            Balken bilden den Kopf der Karte, die Linie steht UNTER dem
--            Balken; die Karte endet immer unter dem Inhalt (compact), auch
--            wenn die Haekchen nicht ruecken duerfen.
--
-- GEMESSEN (/wcui fenster): Zeilen unter
-- ReputationFrame.ScrollBox.ScrollTarget mit .Content; Balken
-- Content.ReputationBar; Detailansicht ReputationFrame.ReputationDetailFrame
-- im Fenster, Titel .Title, Haekchen AtWarCheckbox usw.
--------------------------------------------------

WeintCodex = WeintCodex or {}

WeintCodex.UIReputation = WeintCodex.UIRegister.New({
    label         = "Ruf",
    key           = "rep",
    frames        = { "ReputationFrame" },
    detailKeys    = { "ReputationDetailFrame" },
    detailGlobals = { "ReputationDetailFrame" },
    titleKeys     = { "Title", "FactionName", "Name" },
    titleGlobals  = { "ReputationDetailFactionName" },
    barKeys       = { "ReputationBar", "StatusBar", "Bar" },
    detailBarKeys = { "ReputationBar", "Bar", "StatusBar" },
    -- Das Zeichen des Codex: das Register der Welt.
    sigil         = true,
    -- Wie bei den Fertigkeiten: Name, Stufe und Fortschritt gehoeren
    -- zusammen, unter dem Balken beginnt die Beschreibung.
    barLine       = "below",
    compact       = true,
})
