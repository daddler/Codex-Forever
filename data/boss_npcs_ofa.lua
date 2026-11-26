--------------------------------------------------
-- WeintCodex :: NPC-Nummern der Bosse, Abgleich mit OneForAll (1.0.8.0)
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.
-- Herkunft (nur fuer Betreuer): OneForAll 6.2.13 (GPL-3.0, nur Daten; dort
-- aus QuestieDB Forever) und data/boss_npcs_forever.lua. Nur Nummern, die
-- data/boss_npcs.lua fehlen, nur bei gleichem englischem Namen im selben
-- Dungeon oder als Teil eines Kampfes. Art `community`.
-- Gleiche Form wie data/boss_npcs.lua; fuellt nur, was dort fehlt.
--------------------------------------------------

local B = WeintCodex and WeintCodex.BossNpcs
if not B then return end
for npc, e in pairs({
    [16059] = { "blackrock_depths", "theldren", "Theldren", "Theldren" },   -- OneForAll
    [246931] = { "city_of_dalaran", "mana_wraith", "Mana Wraith", "Mana Wraith" },   -- OneForAll
    [260808] = { "excavation_site", "highland_horror", "Highland Horror", "Highland Horror" },   -- OneForAll
    [250660] = { "ruins_of_lordaeron", "the_butcher", "The Butcher", "The Butcher" },   -- OneForAll
    [255699] = { "ruins_of_lordaeron", "lordaeron_captain", "Lordaeron Captain", "Lordaeron Captain" },   -- OneForAll
    [256035] = { "ruins_of_lordaeron", "viktor_the_vile", "Viktor the Vile", "Viktor the Vile" },   -- OneForAll
    [11032] = { "stratholme", "malor_the_zealous", "Malor the Zealous", "Malor the Zealous" },   -- OneForAll
    [11120] = { "stratholme", "crimson_hammersmith", "Crimson Hammersmith", "Crimson Hammersmith" },   -- OneForAll
    [16101] = { "stratholme", "jarien_and_sothos", "Jarien and Sothos", "Jarien and Sothos" },   -- OneForAll
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
    [258905] = { "drowned_city", "zulalai", "Zul'Alai" },   -- OneForAll
    [258924] = { "drowned_city", "vartaka", "Var'Taka" },   -- OneForAll
    [260042] = { "drowned_city", "captain_dreadrise", "Captain Dreadrise" },   -- OneForAll
    [260202] = { "drowned_city", "deathless_marrow", "Deathless Marrow" },   -- OneForAll
    [260243] = { "drowned_city", "minloth", "Min'loth the Serpent" },   -- OneForAll
    [263886] = { "drowned_city", "primeval_elemental", "Primeval Elemental" },   -- OneForAll
    [264177] = { "drowned_city", "gill", "Gill" },   -- OneForAll
}) do
    if B[npc] == nil and WeintCodex.BossNpcParts[npc] == nil then WeintCodex.BossNpcParts[npc] = e end
end
