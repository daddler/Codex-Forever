--------------------------------------------------
-- WeintCodex :: Karte - Abgleich mit OneForAll (1.0.8.0)
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.
-- Herkunft (nur fuer Betreuer): Flugmeister aus QuestieDB Forever, Uebergaenge
-- aus Carbonite (beides ueber OneForAll 6.2.12, GPL-3.0 - nur Lagen).
-- Traegt beim Laden in WeintCodex.TownData und WeintCodex.MapMarksData ein,
-- nur was dort fehlt. Art `community`.
--------------------------------------------------

local TD, MD = WeintCodex and WeintCodex.TownData, WeintCodex and WeintCodex.MapMarksData
local FLIGHT = {   -- { Karte, x, y, Fraktion, Klasse }
    { 1450, 44.3, 45.9, "AH", "DRUID" },   -- Bunthen Plainswind
    { 1450, 44.2, 45.2, "AH", "DRUID" },   -- Silva Fil'naveth
    { 2482, 68.7, 46.8, "AH" },   -- Fayran Elthas
    { 2548, 59.6, 45.1, "H" },   -- Grakna
    { 2548, 60.6, 81.5, "A" },   -- Gretchen Mayberry
}
local CROSS = {    -- { Karte, x, y, Richtung, Zielkarte }
    { 1448, 0.650, 0.084, -0.345, 1450 },
    { 1433, 0.089, 0.719, 2.061, 1429 },
    { 1433, 0.071, 0.893, 2.312, 1431 },
    { 1433, 0.465, 0.086, 0.084, 1428 },
    { 1413, 0.639, 0.000, -0.271, 1454 },
    { 1450, 0.358, 0.722, 2.572, 1452 },
    { 1452, 0.280, 0.346, 0.960, 1450 },
}
if TD and TD.maps then
    for _, f in ipairs(FLIGHT) do
        TD.maps[f[1]] = TD.maps[f[1]] or {}
        table.insert(TD.maps[f[1]], { f[2], f[3], "flight", f[4], f[5] })
    end
end
if MD and MD.crossings then
    for _, c in ipairs(CROSS) do
        local l = MD.crossings[c[1]] or {}
        MD.crossings[c[1]] = l
        l[#l + 1], l[#l + 2], l[#l + 3], l[#l + 4] = c[2], c[3], c[4], c[5]
    end
end
