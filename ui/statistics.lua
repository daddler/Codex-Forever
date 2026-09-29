--------------------------------------------------
-- WeintCodex :: Oberflaeche - Statistiken (6.7.4.0)
--------------------------------------------------
-- Der Reiter "Statistiken" im Charakterfenster: eine lange Liste des
-- Spiels (Kategorie "Charakter", darin Gruppen wie "Vermoegen", Zeilen
-- mit Name und Wert). Das vierte Register (ui/register.lua) - und das
-- erste ohne Detailansicht (listOnly): dieselbe Liste wie im Ruf, sonst
-- nichts.
--
--   * Liste auf der angehobenen Flaeche, Vignette, neutrales Licht.
--   * Kategorien als Abschnitte (Band, Raute, Linie in der Klassenfarbe:
--     ein Reiter des Charakterfensters wie Ruf, Fertigkeiten, PvP).
--   * Eintraege mit Haarlinie, Hervorhebung des Spiels unter der Maus in
--     der Klassenfarbe getoent. Keine Auswahl - es gibt nichts zu waehlen.
--   * Werte ("--", Zahlen), Einrueckung und die Knoepfe zum Auf- und
--     Zuklappen der Gruppen bleiben, wie das Spiel sie zeigt.
--
-- GEMESSEN (6.7.2.1, /wcui fenster): StatisticsFrame, Zeilen unter
-- StatisticsFrame.ScrollBox.ScrollTarget mit .Content.BackgroundHighlight
-- ("charactercreate-customize-dropdown-linemouseover-*", wie im Ruf),
-- Gruppenzeilen mit .ToggleCollapseButton ("Campaign_HeaderIcon_Open"),
-- Bildlauf StatisticsFrame.ScrollBar (minimal-scrollbar-*). Kategorie
-- "Charakter" als Kopfzeile des Spiels (bis 6.7.3.0 mittig gestaltet,
-- weil das Fenster keinen Stil hatte).
--------------------------------------------------

WeintCodex = WeintCodex or {}

WeintCodex.UIStatistics = WeintCodex.UIRegister.New({
    label    = "Statistiken",
    key      = "stat",
    frames   = { "StatisticsFrame", "CharacterFrame.StatisticsFrame" },
    listOnly = true,
})
