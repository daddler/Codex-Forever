--------------------------------------------------
-- WeintCodex :: Oberflaeche - Abzeichen (6.7.3.0)
--------------------------------------------------
-- Der Reiter "Abzeichen" im Charakterfenster (Waehrungen): links die
-- Liste des Spiels, rechts die Detailansicht der gewaehlten Waehrung. Das
-- dritte Register (ui/register.lua) nach Ruf und Fertigkeiten - dieselbe
-- ruhige Informationsoberflaeche, keine Kopie:
--
--   * Liste auf der angehobenen Flaeche, Gruppen als Abschnitte (Band,
--     Raute, Linie), Eintraege mit Haarlinie, Auswahl mit Strich - wie im
--     Ruf. Symbol, Name und Anzahl bleiben, wie das Spiel sie zeigt.
--   * Rechts die Karte: Name als Titel, Linie, Beschreibung; was folgt
--     (Haekchen wie "Inaktiv"/"Im Rucksack anzeigen" oder weitere Zeilen)
--     im abgesetzten Bereich; die Karte endet unter dem Inhalt.
--   * Kein Codex-Zeichen (wie bei den Fertigkeiten): kein Motiv, keins
--     erzwungen.
--
-- GEMESSEN (6.7.2.1, /wcui fenster, Liste LEER - Stufe 19 ohne
-- Waehrungen): das Fenster heisst TokenFrame, die Bildlaufleiste
-- TokenFrame.ScrollBar (minimal-scrollbar-*), rechts steht nur der Hinweis
-- "Waehlt eine Waehrung, um ihre Details anzuzeigen." - dafuer der
-- Leerzustand im Register.
-- UNGEMESSEN: Schluessel der Liste, der Zeilen und der Detailansicht. Die
-- Kopfzeilen sind wahrscheinlich dieselbe Vorlage wie im Ruf
-- (common-button-list-collapseExpand, 6.6.2.9 vermutet). Deshalb mehrere
-- Wege, dann Suche - /wcui fenster nennt, was gefunden wurde
-- ("Abzeichen, …").
--------------------------------------------------

WeintCodex = WeintCodex or {}

WeintCodex.UICurrency = WeintCodex.UIRegister.New({
    label         = "Abzeichen",
    key           = "token",
    frames        = { "TokenFrame", "CharacterFrame.TokenFrame" },
    listKeys      = { "ScrollBox", "Container", "ScrollFrame" },
    detailKeys    = { "DetailFrame", "TokenDetailFrame", "CurrencyDetailFrame", "Details", "Detail" },
    detailGlobals = { "TokenFrameDetailFrame", "TokenDetailFrame", "CurrencyDetailFrame" },
    -- Sonst: das Kind des Fensters mit dem laengsten Text (die Beschreibung
    -- - oder im Leerzustand der Hinweis).
    detailSearch  = true,
    titleKeys     = { "Title", "Name", "CurrencyName", "TokenName" },
    titleGlobals  = { "TokenFrameDetailName" },
    titleTop      = true,
    barKeys       = { "StatusBar", "Bar", "ProgressBar" },
    detailBarKeys = { "StatusBar", "Bar", "ProgressBar" },
    barLine       = "below",
    tail          = true,
    compact       = true,
})
