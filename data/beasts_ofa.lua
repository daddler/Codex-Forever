--------------------------------------------------
-- WeintCodex :: Wildtierkunde - Abgleich mit OneForAll (1.0.8.0)
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.
-- Herkunft (nur fuer Betreuer): OneForAll 6.2.13 (GPL-3.0, nur Daten) -
-- Familien nach wow-petopia.com/forever (07.11.2026), Lagen QuestieDB Forever.
-- Traegt beim Laden in WeintCodex.BeastData ein: neue Tiere (b, s) und
-- die Familie, wo die neuere Quelle anders sagt. Art `community`.
--------------------------------------------------

local B = WeintCodex and WeintCodex.BeastData
if not B then return end
local add = {
        [4724] = "15	Sandstrider	30-31			35	",
        [250488] = "14	Tarantula	16-17	en		52	",
        [250619] = "14	Broodwidow	16	en		52	",
        [256040] = "14	Deep Widow	15-16	en		52	",
        [260157] = "6	Elder Snow Leopard	9-10	n		14	",
        [266851] = "14	Ukorsbane	8	en		30	",
        [269075] = "6	Snow Leopard Prowler	6	n		14	",
        [270693] = "8	Daggerfang	15	n		15	",
        [271336] = "12	Carnage	30	en		23	",
}
local spots = {
        [260157] = "14:760566",
        [266851] = "30:517558",
        [269075] = "14:274629",
        [270693] = "15:616439",
        [271336] = "23:698301",
}
local family = {
        [253282] = 3,   -- Bird of Prey statt Raptor
        [253283] = 3,   -- Bird of Prey statt Raptor
        [254589] = 9,   -- Fox statt Wolf
}
for id, v in pairs(add) do if not B.b[id] then B.b[id] = v end end
for id, v in pairs(spots) do if not B.s[id] then B.s[id] = v end end
for id, f in pairs(family) do
    local v = B.b[id]
    if v then B.b[id] = v:gsub("^%d+", tostring(f), 1) end
end
B.OFA = { added = add, family = family }
