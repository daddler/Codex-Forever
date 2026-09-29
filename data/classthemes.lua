--------------------------------------------------
-- WeintCodex :: Klassen-Themen des Charakterfensters (6.6.4.0)
--------------------------------------------------
-- Das Charakterfenster (ui/character.lua) ist fuer jede Klasse
-- DASSELBE Geruest: dunkle neutrale Basis, Szene hinter der Figur,
-- Klassenfarbe als Akzent, Werte auf einer dunklen Glasebene. Was je
-- Klasse anders ist, steht HIER und nur hier - das Layout liest es, es
-- kennt keine Klasse beim Namen.
--
-- EINE NEUE KLASSE HINZUFUEGEN (z. B. Magier):
--
--   1. Bild: das Original (2:3, etwa 1024x1536) in CLASS_JOBS von
--      .github/scripts/make_artwork.py eintragen und
--         python3 .github/scripts/make_artwork.py classes <ordner>
--      laufen lassen -> media/classes/mage.blp.
--   2. Bild eintragen: data/artwork.lua, WeintCodex.ClassArtworks.MAGE =
--      { file = "classes/mage", w = 1024, h = 1536, focusY = ..., dim = ... }
--      (data_test.lua prueft Datei und Masse).
--   3. Thema eintragen: unten MAGE = { scene = "MAGE", ... } - nur, was
--      vom DEFAULT abweicht. Ohne Eintrag gilt DEFAULT: Hintergrund des
--      Spiels, dasselbe Layout.
--   4. Im Spiel pruefen: /wcui fenster ueber dem Charakterfenster nennt
--      Thema, Szene, Licht und Ebenen.
--
-- DIE KLASSENFARBE steht hier NICHT, mit Absicht. Sie ist seit 6.6.3.1
-- der Akzent der ganzen Oberflaeche (WeintCodex.SetAccent, core/ui.lua;
-- die Farbe nennt das Spiel, RAID_CLASS_COLORS) - Priester weiss,
-- Jaeger gruen, Magier blau. Eine zweite Angabe hier waere eine zweite
-- Quelle derselben Farbe und im Charakterfenster eine andere als ueberall
-- sonst. Wer eine Klassenfarbe aendern will, aendert sie dort, fuer alle
-- Flaechen zugleich. Das Fenster nutzt sie nur als Akzent (Kopfzeile,
-- Linien, belegte und gewaehlte Plaetze, Maus) - nie als Flaechenfarbe.
--
-- WAS EIN THEMA SAGEN KANN (alle Werte 0..1, alle optional):
--
--   scene        Schluessel in WeintCodex.ClassArtworks, oder nil: dann
--                bleibt der Hintergrund des Spiels (die Buehne des Volks).
--   gameOverlay  Abdunklung des Spiels ueber der Szene (RaceBG-Overlay)
--                behalten? Zu einem eigenen Bild passt sie nicht - sie
--                machte das Priesterbild matt; dort uebernimmt `vignette`.
--   vignette     Randabdunklung der Szene (schwarz, nach innen weich).
--   calm         Beruhigung HINTER der Figur: ein weicher dunkler Hof,
--                der Details dort zuruecknimmt, damit die Szene die Figur
--                nicht ueberstrahlt. Kein Leuchten.
--   shadow       Schatten unter den Fuessen.
--   haze         Dunst am Boden, UEBER der Figur - zieht die Fuesse in
--                die Szene.
--   light        Licht der 3D-Szene: { ambient = {r,g,b}, diffuse = {r,g,b} }
--                in den Farben des Bildes. nil: das Licht des Spiels.
--   wash         Hauch der Lichtfarbe ueber Figur und Szene, additiv
--                ({r,g,b,a}) - gleicher Farbton fuer beide.
--   glass        Deckkraft der Glasebene unter den Werten.
--
-- Die Farben unter `light`/`wash` sind die DES BILDES (Kerzenlicht), nicht
-- der Palette - deshalb hier und nicht in core/ui.lua: ein anderes Bild
-- braucht anderes Licht. Gold hoechstens so: gedaempft, als Licht.
--------------------------------------------------

WeintCodex = WeintCodex or {}

WeintCodex.ClassThemes = {

    -- Jede Klasse ohne eigenen Eintrag - und die Grundlage aller anderen.
    DEFAULT = {
        scene       = nil,
        gameOverlay = true,
        vignette    = 0.25,
        calm        = 0,
        shadow      = 0.40,
        haze        = 0.25,
        light       = nil,
        wash        = nil,
        glass       = 0.80,
    },

    -- Referenz (6.6.4.0): Kathedrale mit Kerzen und Lichtkreuz.
    -- Licht warm, aber gedaempft und fast neutral - das Bild bringt das
    -- Gold schon mit; die Figur soll in ihm stehen, nicht golden werden.
    PRIEST = {
        scene       = "PRIEST",
        gameOverlay = false,
        vignette    = 0.60,
        calm        = 0.30,
        shadow      = 0.60,
        haze        = 0.40,
        light       = {
            ambient = { 0.58, 0.54, 0.48 },
            diffuse = { 0.95, 0.86, 0.70 },
        },
        wash        = { 1.00, 0.90, 0.75, 0.04 },
    },
}

-- Das Thema einer Klasse: ihr Eintrag ueber DEFAULT gelegt, dazu `art`
-- (das Bild aus data/artwork.lua oder nil). Einmal je Klasse gerechnet.
local merged = {}
function WeintCodex.ClassTheme(classToken)
    local key = type(classToken) == "string" and classToken or "DEFAULT"
    if merged[key] then return merged[key] end
    local out = {}
    for k, v in pairs(WeintCodex.ClassThemes.DEFAULT) do out[k] = v end
    local own = WeintCodex.ClassThemes[key]
    if type(own) == "table" and key ~= "DEFAULT" then
        for k, v in pairs(own) do out[k] = v end
    end
    out.class = key
    out.art = out.scene and WeintCodex.Art and WeintCodex.Art.Class and WeintCodex.Art.Class(out.scene) or nil
    merged[key] = out
    return out
end
