--------------------------------------------------
-- WeintCodex :: Oberflaeche - Addon-Liste in Gold (6.136.0.0)
--------------------------------------------------
-- Das Fenster "Addon-Liste" des Spiels (AddonList), Beta-Test: "Das
-- Fenster muss auch noch bearbeitet werden mit dem Design".
--
-- GEMESSEN (6.134.0.1, /wcui fenster AddonList): Metallrahmen (NineSlice
-- "UI-Frame-Metal-*", "_UI-Frame-TopTileStreaks"), AddonListBg (374155),
-- Innenflaeche AddonListInset (374154), vier rote Knoepfe ("128-RedButton-*":
-- Alle aktivieren/deaktivieren, OK, Abbrechen), Suchfeld
-- ("common-search-border-*") - Rahmen, Knoepfe und Innenflaeche nimmt der
-- allgemeine Durchlauf (W.WINDOWS) und ui/calm.lua.
-- Was nur dieses Fenster hat:
--   Suche      Rand des Suchfelds weg, das Feld eine flache Leiste.
-- Unveraendert: Haken, Pfeile der Gruppen, Auswahl des Charakters,
-- Leistungsanzeige, Bildlaufleiste - und jedes Skript (Addons an- und
-- ausschalten bleibt allein beim Spiel).
--------------------------------------------------

WeintCodex = WeintCodex or {}

local CP = WeintCodex.UICalmParts

WeintCodex.UIAddonList = CP.New({
    label = "Addons", host = "AddonList", depth = 4,
    atlases = {
        { "^common%-search%-border%-", "field" },
    },
})
