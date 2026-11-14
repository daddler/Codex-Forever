--------------------------------------------------
-- WeintCodex :: Karten der neuen Forever-Dungeons (1.0.5.38)
--------------------------------------------------
-- Der Forever-Client hat fuer die neuen Dungeons KEINE Karte (UiMap/
-- UiMapArt des Builds 1.60.1.70862 gelesen ueber wago.tools: keine
-- Dungeonkarte, keine Kacheln). Diese Karten sind eigene Zeichnungen von
--
--   Santiago Reyes - „Atlas de Azeroth: Forever“
--   https://asguevara433.wixsite.com/srmaps/post/proyecto-atlas-de-azeroth-forever
--
-- „Los mapas son míos, y son reinterpretaciones, mas no arte oficial de
-- World of Warcraft.“ Erlaubnis fuer Addons auf derselben Seite („TODOS
-- ustedes tienen autorización para utilizar los mapas“), Bedingungen:
-- nichts damit verkaufen, Wasserzeichen und Nennung NIE veraendern, den
-- Zeichner nennen. WeintCodex zeigt die Bilder unveraendert und nennt ihn
-- unter jeder Karte (`credit`).
--
-- Nur veroeffentlichte Karten - er bittet, Unveroeffentlichtes nicht zu
-- teilen. Stand 09.11.2026: Dalaran (zwei Ebenen), Ruinen von Lordaeron,
-- Hall of Thanes, Ausgrabungsstaette. Seit 1.0.6.9 (Stand 14.11.2026, seine
-- neue Seite https://sreyesmaps.com/post/proyecto-atlas-de-azeroth-forever,
-- „9 / 11“, jede Karte mit eigener Seite und „Descargar“): Drowned City
-- (2 Ebenen), Krol'dok, Alcaz (2), Blackmaw Hold (6), Shaper's Terrace (2) -
-- jeweils die aktuelle Fassung, 3000x2000 auf 1024x683 verkleinert, sonst
-- unveraendert. Die beiden Schlachtzuege fehlen dort noch.
--
-- Bilder: media/dungeonmaps/<name>_a.blp (Zeilen 0-511) und _b.blp
-- (512-767), DXT1, gebaut mit .github/scripts/make_dungeonmaps.py aus den
-- 1024x1024-Bildern. `h` = Hoehe der Karte in Bildpunkten (Breite 1024).
-- Schluessel: Instanz-ID aus GetInstanceInfo (Map.db2 des Clients).
--------------------------------------------------

local D = WeintCodex.DungeonMapData
if not D then return end

local PATH = "Interface\\AddOns\\WeintCodex\\media\\dungeonmaps\\"
local CREDIT = "Karte: Santiago Reyes – Atlas de Azeroth: Forever"

local function Floor(name, h, label)
    return { files = { PATH .. name .. "_a", PATH .. name .. "_b" }, h = h, name = label, credit = CREDIT }
end

D.FOREVER_SOURCE = { kind = "community", label = "Zeichnung von Santiago Reyes, keine Karte des Spiels" }

D.MAPS[2959] = { name = "City of Dalaran", drawn = true, floors = {
    Floor("2959", 684, "City of Dalaran (1)"),
    Floor("2959_2", 689, "City of Dalaran (2)"),
} }
D.MAPS[2998] = { name = "Excavation Site: Wetlands", drawn = true, floors = { Floor("2998", 684) } }
D.MAPS[2999] = { name = "Ruins of Lordaeron", drawn = true, floors = { Floor("2999", 684) } }
D.MAPS[3065] = { name = "The Hall of Thanes", drawn = true, floors = { Floor("3065", 684) } }

-- 1.0.6.9: Schluessel wie oben (Instanz-ID); Ebenen in der Reihenfolge
-- seiner Seite.
local function Floors(key, n, label)
    local out = {}
    for i = 1, n do
        out[i] = Floor(i == 1 and key or (key .. "_" .. i), 683, n > 1 and (label .. " (" .. i .. ")") or nil)
    end
    return out
end
D.MAPS[2970] = { name = "The Drowned City", drawn = true, floors = Floors("2970", 2, "The Drowned City") }
D.MAPS[3039] = { name = "Krol'dok Stronghold", drawn = true, floors = Floors("3039", 1) }
D.MAPS[2994] = { name = "Alcaz Island Prison", drawn = true, floors = Floors("2994", 2, "Alcaz Island Prison") }
D.MAPS[2974] = { name = "Blackmaw Hold", drawn = true, floors = Floors("2974", 6, "Blackmaw Hold") }
D.MAPS[3001] = { name = "Shaper's Terrace", drawn = true, floors = Floors("3001", 2, "Shaper's Terrace") }
