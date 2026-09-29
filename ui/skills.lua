--------------------------------------------------
-- WeintCodex :: Oberflaeche - Fertigkeiten (6.7.1.0)
--------------------------------------------------
-- Der Reiter "Fertigkeiten" im Charakterfenster: links die Liste des
-- Spiels (Berufe, Sekundaere Fertigkeiten, Waffenfertigkeiten ... mit
-- Fortschrittsbalken), rechts die Detailansicht der gewaehlten
-- Fertigkeit. Ein Register (ui/register.lua) wie der Ruf - dasselbe
-- System, eigene Eigenheiten:
--
--   * Kein Codex-Zeichen. Ein thematisches Motiv (Werkzeug, Amboss) gibt
--     es unter den Grafiken nicht; ein neues wird nicht erzwungen.
--   * Die Linie steht UNTER dem Balken: Name und Fortschritt gehoeren
--     zusammen, darunter beginnt die Beschreibung.
--   * Was unter der Beschreibung folgt (weitere Zeilen, Knoepfe), bekommt
--     den abgesetzten Bereich - bewegt wird hier nichts.
--   * Die Karte endet unter dem Inhalt (compact).
--   * Fortschrittsbalken behalten Farbe und Text des Spiels (Blau ist die
--     Auskunft), nie die Klassenfarbe.
--
-- GEMESSEN (6.6.2.9, /wcui fenster): die Liste liegt unter
-- SkillsFrame.ScrollBox, Kopfzeilen mit "common-button-list-collapseExpand",
-- Balken mit "common-stat-bar-BG" - dieselben Vorlagen wie im Ruf.
-- UNGEMESSEN: Name des Fensters als globaler Name, Schluessel der Zeilen
-- und der Detailansicht. Deshalb mehrere Wege (Schluessel des Quelltexts
-- aelterer Fassungen, dann Suche) - /wcui fenster nennt, was gefunden
-- wurde ("Fertigkeiten, …").
--------------------------------------------------

WeintCodex = WeintCodex or {}

WeintCodex.UISkills = WeintCodex.UIRegister.New({
    label         = "Fertigkeiten",
    key           = "skill",
    frames        = { "SkillsFrame", "SkillFrame", "CharacterFrame.SkillsFrame", "CharacterFrame.SkillFrame" },
    detailKeys    = { "DetailFrame", "SkillDetailFrame", "Details", "Detail", "DetailScrollFrame" },
    detailGlobals = { "SkillDetailScrollFrame", "SkillDetailFrame" },
    -- Sonst: das Kind des Fensters mit dem laengsten Text (die Beschreibung).
    detailSearch  = true,
    titleKeys     = { "Title", "SkillName", "Name", "HeaderText" },
    titleGlobals  = { "SkillDetailHeaderText" },
    -- Sonst: die oberste Schriftzeile der Detailansicht (der Name).
    titleTop      = true,
    barKeys       = { "SkillBar", "StatusBar", "Bar", "ProgressBar" },
    detailBarKeys = { "StatusBar", "SkillBar", "Bar", "ProgressBar" },
    barLine       = "below",
    tail          = true,
    compact       = true,
})
