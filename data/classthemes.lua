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
-- DIE VIER GROESSEN JE KLASSE und wo sie stehen:
--
--   Hintergrund   `scene` hier -> Bild in WeintCodex.ClassArtworks
--                 (data/artwork.lua: Datei, Masse, Ausschnitt, Helligkeit)
--   Klassenfarbe  NICHT hier - aus dem Spiel, als Akzent der ganzen
--                 Oberflaeche (siehe oben)
--   Lichtfarbe    `light` (Umgebung/Hauptlicht der 3D-Szene) und `wash`
--   Atmosphaere   `gameOverlay`, `vignette`, `calm`, `shadow`, `haze`, `glass`
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
        glass       = 0.62,   -- 6.6.4.1: leichter, die Szene scheint durch
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

    -- Zweite Klasse (6.6.4.4): Jaegerlager im Wald, Sonne durch die Baeume,
    -- Fackeln. Dieselben Werte fuer Tiefe wie beim Priester - das Geruest
    -- bleibt gleich, nur das Licht folgt dem Bild: Umgebung ein Hauch
    -- gruen (Laub), Hauptlicht warmes Sonnenlicht, der Hauch darueber
    -- kaum sichtbar gruenlich. Gruen als LICHT, nicht als Flaeche - der
    -- Akzent (Linien, Plaetze, Kopfzeile) ist die Klassenfarbe des Spiels.
    HUNTER = {
        scene       = "HUNTER",
        gameOverlay = false,
        vignette    = 0.60,
        calm        = 0.30,
        shadow      = 0.60,
        haze        = 0.40,
        light       = {
            ambient = { 0.52, 0.57, 0.48 },
            diffuse = { 0.96, 0.90, 0.74 },
        },
        wash        = { 0.80, 0.95, 0.70, 0.035 },
    },

    -- 6.6.4.5: die uebrigen sieben Klassen. Tiefe wie Priester und Jaeger (das
    -- Geruest), nur das Licht folgt jeweils dem Bild - gedaempfte
    -- Umgebung, Hauptlicht in der Farbe der staerksten Lichtquelle, ein
    -- Hauch darueber unter 4 %.

    -- Waffenkammer: Esse und Kerzen, warmes Rot-Orange.
    WARRIOR = {
        scene = "WARRIOR", gameOverlay = false,
        vignette = 0.60, calm = 0.30, shadow = 0.60, haze = 0.40,
        light = { ambient = { 0.58, 0.50, 0.44 }, diffuse = { 1.00, 0.82, 0.62 } },
        wash  = { 1.00, 0.75, 0.55, 0.035 },
    },
    -- Hain: Sonne durch Laub wie beim Jaeger, etwas goldener.
    DRUID = {
        scene = "DRUID", gameOverlay = false,
        vignette = 0.60, calm = 0.30, shadow = 0.60, haze = 0.40,
        light = { ambient = { 0.53, 0.57, 0.47 }, diffuse = { 0.97, 0.90, 0.72 } },
        wash  = { 0.85, 0.95, 0.70, 0.035 },
    },
    -- Arkane Halle: kuehles Blau der Lichtsaeule, Kerzen nur am Rand.
    MAGE = {
        scene = "MAGE", gameOverlay = false,
        vignette = 0.60, calm = 0.30, shadow = 0.60, haze = 0.40,
        light = { ambient = { 0.50, 0.52, 0.62 }, diffuse = { 0.85, 0.87, 1.00 } },
        wash  = { 0.70, 0.78, 1.00, 0.035 },
    },
    -- Nacht, Laternen: dunkle Umgebung, warmes Laternenlicht - die
    -- dunkelste Szene, der Hauch am schwaechsten.
    ROGUE = {
        scene = "ROGUE", gameOverlay = false,
        vignette = 0.60, calm = 0.25, shadow = 0.60, haze = 0.40,
        light = { ambient = { 0.48, 0.46, 0.46 }, diffuse = { 0.95, 0.80, 0.62 } },
        wash  = { 1.00, 0.80, 0.60, 0.03 },
    },
    -- Violette Flammen und gruenes Portal: Umgebung violett, Hauptlicht
    -- blass violett (das Gruen bleibt im Bild, auf der Figur waere es krank).
    WARLOCK = {
        scene = "WARLOCK", gameOverlay = false,
        vignette = 0.60, calm = 0.30, shadow = 0.60, haze = 0.40,
        light = { ambient = { 0.52, 0.48, 0.58 }, diffuse = { 0.90, 0.82, 0.98 } },
        wash  = { 0.75, 0.60, 0.95, 0.035 },
    },
    -- Lichthalle: goldenes Licht wie beim Priester, etwas heller; der
    -- Hof hinter der Figur etwas staerker, das Bild ist das hellste.
    PALADIN = {
        scene = "PALADIN", gameOverlay = false,
        vignette = 0.60, calm = 0.34, shadow = 0.60, haze = 0.40,
        light = { ambient = { 0.58, 0.54, 0.48 }, diffuse = { 0.98, 0.88, 0.70 } },
        wash  = { 1.00, 0.90, 0.72, 0.035 },
    },
    -- Sturm: kuehles Blau des Blitzes, die Kerzen nur am Rand.
    SHAMAN = {
        scene = "SHAMAN", gameOverlay = false,
        vignette = 0.60, calm = 0.30, shadow = 0.60, haze = 0.40,
        light = { ambient = { 0.48, 0.52, 0.60 }, diffuse = { 0.82, 0.88, 1.00 } },
        wash  = { 0.65, 0.78, 1.00, 0.035 },
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
