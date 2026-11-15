--------------------------------------------------
-- WeintCodex :: Debuffs - alle Nummern je Zauber auf Forever
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_naowh_debuffs.lua aus Naowh Forever 1.2.33
-- (Raid Debuffs, aus dem Client-Build 1.60.1.70790) - nicht von Hand aendern.
-- [Grundzauber] = { Nummern aller Raenge und Fassungen }
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.DebuffIDs = {
    [7386] = { 7386, 7405, 8380, 11596, 11597, 11971, 13444, 15502, 15572, 16145, 21081, 24317, 25051, 27991, 365663 }, -- Sunder Armor
    [1160] = { 1160, 6190, 11554, 11555, 11556, 13730, 16244, 19778, 23511, 27579 }, -- Demoralizing Shout
    [6343] = { 6343, 8198, 8204, 8205, 11580, 11581, 13532, 413589, 461810, 461826, 461827, 461828, 461829, 461830 }, -- Thunder Clap
    [8647] = { 8647, 8649, 8650, 11197, 11198 }, -- Expose Armor
    [770] = { 770, 778, 6950, 9749, 9907, 13424, 13752, 16498, 20656, 21670, 1288561, 1289452 }, -- Faerie Fire
    [99] = { 99, 1735, 9490, 9747, 9898, 10968, 15727, 15971, 20753, 27551 }, -- Demoralizing Roar
    [704] = { 704, 7658, 7659, 11717, 16231, 1225841 }, -- Curse of Recklessness
    [402792] = { 402792, 440892, 1311676, 1311677, 1311680 }, -- Curse of the Elements
    [402791] = { 402791 }, -- Curse of Shadow
    [17794] = { 17794 }, -- Shadow Vulnerability
    [1130] = { 1130, 14323, 14324, 14325, 1213268 }, -- Hunter's Mark
    [20186] = { 20186, 20354, 20355, 25757 }, -- Judgement of Wisdom
    [20185] = { 20185, 20344, 20345, 20346, 25752, 28775 }, -- Judgement of Light
    [20188] = { 20188, 20300, 20301, 20302, 20303, 21183, 25942, 456496 }, -- Judgement of the Crusader
    [15257] = { 15257, 15258 }, -- Shadow Weaving
    [11180] = { 11180, 12579 }, -- Winter's Chill
    [22959] = { 22959 }, -- Fire Vulnerability
}
