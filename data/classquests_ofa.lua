--------------------------------------------------
-- WeintCodex :: Klassenquests - Abgleich mit OneForAll (1.0.8.0)
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.
-- Herkunft (nur fuer Betreuer): OneForAll 6.2.13 (GPL-3.0, nur Daten),
-- dort aus QuestieDB Forever (18.11.2026). Nur Quests, die dem Bestand
-- fehlen; Geber unter eigenem, negativem Schluessel. Art `community`.
--------------------------------------------------

local Q = WeintCodex and WeintCodex.ClassQuestData
if not Q then return end
-- Geber ohne bekannte NPC-Nummer: eigener, negativer Schluessel (CQ.Npc).
Q.OFA_NPCS = Q.OFA_NPCS or {}
local ADD = {
    PRIEST = {
        { id = 5678, name = "Arcane Feedback", lv = 20, rl = 20, ra = 1, giver = 11401, pre = {  }, ofa = true },
    },
    SHAMAN = {
        { id = 79358, name = "Storm, Earth, and Fire", lv = 30, rl = 30, ra = 4294967373, giver = -79358, pre = { 96264 }, ofa = true },
        { id = 79360, name = "Elemental Aid", lv = 30, rl = 30, ra = 8589934770, giver = -79360, pre = { 1531, 1532, 96136 }, ofa = true },
        { id = 79361, name = "Storm, Earth, and Fire", lv = 30, rl = 30, ra = 8589934770, giver = 5905, pre = { 79364 }, ofa = true },
        { id = 79364, name = "Eyes on the Sky", lv = 30, rl = 30, ra = 8589934770, giver = -79364, pre = { 79360 }, ofa = true },
        { id = 79366, name = "Heed My Call", lv = 30, rl = 30, ra = 8589934770, giver = -79366, pre = { 79361 }, ofa = true },
        { id = 79442, name = "The Tempest's Weapons", lv = 30, rl = 30, ra = 8589934770, giver = -79442, pre = { 79366, 96135 }, ofa = true },
        { id = 92466, name = "Call of Earth", lv = 3, rl = 3, ra = 8589934770, giver = -92466, pre = {  }, ofa = true },
        { id = 92467, name = "Call of Earth", lv = 3, rl = 3, ra = 8589934770, giver = -92467, pre = { 1516, 1519, 92466 }, ofa = true },
        { id = 92468, name = "Call of Earth", lv = 3, rl = 3, ra = 8589934770, giver = -92468, pre = { 92467 }, ofa = true },
        { id = 94373, name = "Call of Earth", lv = 4, rl = 4, ra = 4, giver = -94373, pre = {  }, ofa = true },
        { id = 94374, name = "Call of Earth", lv = 4, rl = 4, ra = 4294967373, giver = -94374, pre = { 94373 }, ofa = true },
        { id = 94375, name = "Call of Earth", lv = 4, rl = 4, ra = 4294967373, giver = -94375, pre = { 94374 }, ofa = true },
        { id = 94449, name = "Call of Fire", lv = 10, rl = 10, ra = 4, giver = -94449, pre = {  }, ofa = true },
        { id = 94465, name = "Call of Fire", lv = 10, rl = 10, ra = 4294967373, giver = -94465, pre = {  }, ofa = true },
        { id = 94466, name = "Call of Fire", lv = 10, rl = 10, ra = 4294967373, giver = -94466, pre = { 94465 }, ofa = true },
        { id = 94467, name = "Call of Fire", lv = 10, rl = 10, ra = 4294967373, giver = -94467, pre = { 94466 }, ofa = true },
        { id = 94468, name = "Call of Fire", lv = 10, rl = 10, ra = 4, giver = -94468, pre = { 94467 }, ofa = true },
        { id = 94494, name = "Call of Water", lv = 20, rl = 20, ra = 4294967373, giver = -94494, pre = {  }, ofa = true },
        { id = 94495, name = "Call of Water", lv = 20, rl = 20, ra = 4294967373, giver = -94495, pre = { 94494 }, ofa = true },
        { id = 94497, name = "Call of Water", lv = 20, rl = 20, ra = 4294967373, giver = -94497, pre = { 94495 }, ofa = true },
        { id = 94499, name = "Call of Water", lv = 20, rl = 20, ra = 4294967373, giver = -94499, pre = { 94497 }, ofa = true },
        { id = 94500, name = "Call of Water", lv = 20, rl = 20, ra = 4294967373, giver = -94500, pre = { 94499 }, ofa = true },
        { id = 94501, name = "Call of Water", lv = 20, rl = 20, ra = 4294967373, giver = -94501, pre = { 94500 }, ofa = true },
        { id = 94502, name = "Call of Water", lv = 20, rl = 20, ra = 4294967373, giver = -94502, pre = { 94501 }, ofa = true },
        { id = 94503, name = "Call of Water", lv = 20, rl = 20, ra = 4, giver = -94503, pre = { 94502 }, ofa = true },
        { id = 94505, name = "Call of Water", lv = 20, rl = 20, ra = 4, giver = -94505, pre = { 94503 }, ofa = true },
        { id = 94789, name = "Call of Air", lv = 30, rl = 30, ra = 4294967373, giver = -94789, pre = {  }, ofa = true },
        { id = 96016, name = "The Tempest's Weapons", lv = 30, rl = 30, ra = 4294967373, giver = -96016, pre = { 79366, 96135 }, ofa = true },
        { id = 96135, name = "Heed My Call", lv = 30, rl = 30, ra = 4294967373, giver = -96135, pre = { 79358 }, ofa = true },
        { id = 96136, name = "Call of Air", lv = 30, rl = 30, ra = 8589934592, giver = -96136, pre = {  }, ofa = true },
        { id = 96243, name = "Call of Earth", lv = 4, rl = 4, ra = 68, giver = -96243, pre = {  }, ofa = true },
        { id = 96264, name = "Elemental Aid", lv = 30, rl = 30, ra = 4294967373, giver = -96264, pre = { 94789 }, ofa = true },
        { id = 97243, name = "Call of Fire", lv = 10, rl = 10, ra = 8589934592, giver = -97243, pre = { 98517 }, ofa = true },
        { id = 97244, name = "Call of Fire", lv = 10, rl = 10, ra = 8589934770, giver = -97244, pre = { 97243 }, ofa = true },
        { id = 97245, name = "Call of Fire", lv = 10, rl = 10, ra = 8589934770, giver = -97245, pre = { 97244 }, ofa = true },
        { id = 97257, name = "Call of Fire", lv = 10, rl = 10, ra = 8589934770, giver = -97257, pre = { 97245 }, ofa = true },
        { id = 98517, name = "Call of Fire", lv = 10, rl = 10, ra = 8589934592, giver = 3344, pre = {  }, ofa = true },
    },
}
Q.OFA_NPCS[-79358] = { "Veyric Thunderhame", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-79360] = { "Rau Cliffrunner", 1441, 46.1, 51.7, "H" }
Q.OFA_NPCS[-79364] = { "Rau Cliffrunner", 1441, 46.1, 51.7, "H" }
Q.OFA_NPCS[-79366] = { "Rau Cliffrunner", 1441, 46.1, 51.7, "H" }
Q.OFA_NPCS[-79442] = { "Rau Cliffrunner", 1441, 46.1, 51.7, "H" }
Q.OFA_NPCS[-92466] = { "Windshaper Boro", 2521, 42.8, 23.6, "H" }
Q.OFA_NPCS[-92467] = { "Windshaper Boro", 2521, 42.8, 23.6, "H" }
Q.OFA_NPCS[-92468] = { "Minor Manifestation of Earth", 2521, 49.7, 23.8, "H" }
Q.OFA_NPCS[-94373] = { "Teo Hammerstorm", 1426, 28.8, 66.2, "A" }
Q.OFA_NPCS[-94374] = { "Teo Hammerstorm", 1426, 28.8, 66.2, "A" }
Q.OFA_NPCS[-94375] = { "Minor Manifestation of Earth", 1426, 24.8, 61.9, "A" }
Q.OFA_NPCS[-94449] = { "Eldrun Stormbreaker", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-94465] = { "Bruegs Kindleborn", 1426, 87.9, 44.8, "A" }
Q.OFA_NPCS[-94466] = { "Braldir Ashmantle", 1432, 32.2, 66, "A" }
Q.OFA_NPCS[-94467] = { "Braldir Ashmantle", 1432, 32.2, 66, "A" }
Q.OFA_NPCS[-94468] = { "Brazier of the Dormant Flame", 1432, 31.8, 64.5, "A" }
Q.OFA_NPCS[-94494] = { "Eldrun Stormbreaker", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-94495] = { "Norric Lochthane", 1432, 41.8, 19.1, "A" }
Q.OFA_NPCS[-94497] = { "Hervdana Saegrund", 1437, 65.8, 76.5, "A" }
Q.OFA_NPCS[-94499] = { "Hervdana Saegrund", 1437, 65.8, 76.5, "A" }
Q.OFA_NPCS[-94500] = { "Hervdana Saegrund", 1437, 65.8, 76.5, "A" }
Q.OFA_NPCS[-94501] = { "Hervdana Saegrund", 1437, 65.8, 76.5, "A" }
Q.OFA_NPCS[-94502] = { "Norric Lochthane", 1432, 41.8, 19.1, "A" }
Q.OFA_NPCS[-94503] = { "Forgotten Shrine", 1436, 45.6, 59.9, "A" }
Q.OFA_NPCS[-94505] = { "Minor Manifestation of Water", 1421, 38.7, 44.6, "A" }
Q.OFA_NPCS[-94789] = { "Eldrun Stormbreaker", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-96016] = { "Veyric Thunderhame", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-96135] = { "Veyric Thunderhame", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-96136] = { "Alaana Stormwalker", 1412, 33.4, 22.6, "AH" }
Q.OFA_NPCS[-96243] = { "Eldrun Stormbreaker", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-96264] = { "Veyric Thunderhame", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-97243] = { "Sessaria Skystride", 2521, 58.3, 78.5, "AH" }
Q.OFA_NPCS[-97244] = { "Olariaan Swiftburn", 2521, 51.2, 86.2, "H" }
Q.OFA_NPCS[-97245] = { "Olariaan Swiftburn", 2521, 51.2, 86.2, "H" }
Q.OFA_NPCS[-97257] = { "Olariaan Swiftburn", 2521, 51.2, 86.2, "H" }
local mt = getmetatable(Q.CLASSES)
local build = mt and mt.__index
if type(build) == "function" then
    mt.__index = function(t, class)
        local list = build(t, class)
        if type(list) == "table" and ADD[class] then
            for _, q in ipairs(ADD[class]) do list[#list + 1] = q end
            ADD[class] = nil
        end
        return list
    end
end
Q.OFA_ADDED = 38
