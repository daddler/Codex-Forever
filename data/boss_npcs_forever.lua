--------------------------------------------------
-- WeintCodex :: NPC-Nummern der Bosse der neuen Forever-Dungeons (1.0.5.40)
--------------------------------------------------
-- Feedback: „Bosse sollen ja Orange haben und bei den neuen Inis
-- funktioniert das noch nicht“ (Namensplaketten). Die Plakette erkannte
-- Bosse nur am Client (Stufe „??“ oder Klassifizierung worldboss) - die
-- Bosse der neuen Dungeons meldet der Client offenbar nicht so.
--
-- HERKUNFT `community`: Bossnamen aus data/dungeons.lua, die Nummern per
-- exaktem englischem Namen aus der Forever-Datenbank von Questie (dieselbe
-- Quelle wie data/questdb.lua), je Name genau ein Treffer. Weggelassen:
-- The Drowned City (die Datenbank fuehrt dort nur Platzhalter „Staging
-- Area“), The Butcher, Alcaz-Insel und Shaper's Terrace (kein Treffer).
-- Gleiche Form wie data/boss_npcs.lua: [npc] = { Dungeon, Boss (englisch) }.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.ForeverBossNpcs = {
    [261306] = { "hall_of_thanes", "Faldrim Anvilmar" },
    [261316] = { "hall_of_thanes", "Magmatus" },
    [261311] = { "hall_of_thanes", "Plunder" },
    [261319] = { "hall_of_thanes", "Durgen Dirgehammer" },
    [250483] = { "ruins_of_lordaeron", "Witherfang" },
    [250631] = { "ruins_of_lordaeron", "The Abandoned" },
    [255699] = { "ruins_of_lordaeron", "Lordaeron Captain" },
    [256097] = { "ruins_of_lordaeron", "Bjork" },
    [250657] = { "ruins_of_lordaeron", "Rath'mael" },
    [256035] = { "ruins_of_lordaeron", "Viktor the Vile" },
    [260322] = { "excavation_site", "Saltspine" },
    [260325] = { "excavation_site", "Shadetooth" },
    [260326] = { "excavation_site", "Relic Guardian" },
    [260808] = { "excavation_site", "Highland Horror" },
    [247126] = { "city_of_dalaran", "Atrexis the Grave Knight" },
    [245999] = { "city_of_dalaran", "Arcane Anomaly" },
    [246003] = { "city_of_dalaran", "Fel Ancient" },
    [246017] = { "city_of_dalaran", "Unstable Sentinel" },
    [246008] = { "city_of_dalaran", "Mana Devourer" },
    [246016] = { "city_of_dalaran", "Arcanic Enigma" },
    [246931] = { "city_of_dalaran", "Mana Wraith" },
    [247032] = { "city_of_dalaran", "Lyn the Ignored" },
    [246020] = { "city_of_dalaran", "Shade of the Archmage" },
}
