--------------------------------------------------
-- WeintCodex :: Klassenquests - Abgleich mit OneForAll (1.0.8.0)
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.
-- Herkunft (nur fuer Betreuer): OneForAll 6.2.12 (GPL-3.0, nur Daten),
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
        { id = 79358, name = "Storm, Earth, and Fire", lv = 30, rl = 30, ra = 77, giver = -79358, pre = { 96264 }, ofa = true },
        { id = 79360, name = "Elemental Aid", lv = 30, rl = 30, ra = 178, giver = -79360, pre = { 1531, 1532, 96136 }, ofa = true },
        { id = 79361, name = "Storm, Earth, and Fire", lv = 30, rl = 30, ra = 178, giver = 5905, pre = { 79364 }, ofa = true },
        { id = 79364, name = "Eyes on the Sky", lv = 30, rl = 30, ra = 178, giver = -79364, pre = { 79360 }, ofa = true },
        { id = 79366, name = "Heed My Call", lv = 30, rl = 30, ra = 178, giver = -79366, pre = { 79361 }, ofa = true },
        { id = 79442, name = "The Tempest's Weapons", lv = 30, rl = 30, ra = 162, giver = -79442, pre = { 79366, 96135 }, ofa = true },
        { id = 94789, name = "Call of Air", lv = 30, rl = 30, ra = 77, giver = -94789, pre = {  }, ofa = true },
        { id = 96016, name = "The Tempest's Weapons", lv = 30, rl = 30, ra = 77, giver = -96016, pre = { 79366, 96135 }, ofa = true },
        { id = 96135, name = "Heed My Call", lv = 30, rl = 30, ra = 77, giver = -96135, pre = { 79358 }, ofa = true },
        { id = 96136, name = "Call of Air", lv = 30, rl = 30, giver = -96136, pre = {  }, ofa = true },
        { id = 96264, name = "Elemental Aid", lv = 30, rl = 30, ra = 77, giver = -96264, pre = { 94789 }, ofa = true },
    },
}
Q.OFA_NPCS[-79358] = { "Veyric Thunderhame", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-79360] = { "Rau Cliffrunner", 1441, 46.1, 51.7, "H" }
Q.OFA_NPCS[-79364] = { "Rau Cliffrunner", 1441, 46.1, 51.7, "H" }
Q.OFA_NPCS[-79366] = { "Rau Cliffrunner", 1441, 46.1, 51.7, "H" }
Q.OFA_NPCS[-79442] = { "Rau Cliffrunner", 1441, 46.1, 51.7, "H" }
Q.OFA_NPCS[-94789] = { "Eldrun Stormbreaker", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-96016] = { "Veyric Thunderhame", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-96135] = { "Veyric Thunderhame", 1455, 47.1, 13.8, "A" }
Q.OFA_NPCS[-96136] = { "Alaana Stormwalker", 1412, 33.4, 22.6, "AH" }
Q.OFA_NPCS[-96264] = { "Veyric Thunderhame", 1455, 47.1, 13.8, "A" }
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
Q.OFA_ADDED = 12
