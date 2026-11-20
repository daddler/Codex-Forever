--------------------------------------------------
-- WeintCodex :: NPC-Nummern der Bosse, Abgleich mit OneForAll (1.0.8.0)
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.
-- Herkunft (nur fuer Betreuer): OneForAll 6.2.12 (GPL-3.0, nur Daten; dort
-- aus QuestieDB Forever) und data/boss_npcs_forever.lua. Nur Nummern, die
-- data/boss_npcs.lua fehlen, nur bei gleichem englischem Namen im selben
-- Dungeon oder als Teil eines Kampfes. Art `community`.
-- Gleiche Form wie data/boss_npcs.lua; fuellt nur, was dort fehlt.
--------------------------------------------------

local B = WeintCodex and WeintCodex.BossNpcs
if not B then return end
for npc, e in pairs({
    [246931] = { "city_of_dalaran", "mana_wraith", "Mana Wraith", "Mana Wraith" },   -- OneForAll
    [260808] = { "excavation_site", "highland_horror", "Highland Horror", "Highland Horror" },   -- OneForAll
    [250660] = { "ruins_of_lordaeron", "the_butcher", "The Butcher", "The Butcher" },   -- OneForAll
    [255699] = { "ruins_of_lordaeron", "lordaeron_captain", "Lordaeron Captain", "Lordaeron Captain" },   -- boss_npcs_forever
    [256035] = { "ruins_of_lordaeron", "viktor_the_vile", "Viktor the Vile", "Viktor the Vile" },   -- OneForAll
    [11032] = { "stratholme", "malor_the_zealous", "Malor the Zealous", "Malor the Zealous" },   -- OneForAll
    [11120] = { "stratholme", "crimson_hammersmith", "Crimson Hammersmith", "Crimson Hammersmith" },   -- OneForAll
}) do
    if B[npc] == nil then B[npc] = e end
end

-- Weitere Gegner desselben Kampfes: [npc] = { Dungeon, Boss, englischer Name }.
-- Gelesen von ui/bossmod.lua (Kampf erkennen, Zauber zaehlen) und
-- ui/nameplates.lua (Bossfarbe).
WeintCodex.BossNpcParts = WeintCodex.BossNpcParts or {}
for npc, e in pairs({
    [642] = { "the_deadmines", "sneeds_shredder", "Sneed's Shredder" },   -- OneForAll
    [9035] = { "blackrock_depths", "the_seven", "Anger'rel" },   -- OneForAll
    [9039] = { "blackrock_depths", "the_seven", "Doom'rel" },   -- OneForAll
    [10813] = { "stratholme", "balnazzar", "Balnazzar" },   -- OneForAll
}) do
    if B[npc] == nil and WeintCodex.BossNpcParts[npc] == nil then WeintCodex.BossNpcParts[npc] = e end
end
