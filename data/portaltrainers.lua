--------------------------------------------------
-- WeintCodex :: Portallehrer der Magier (1.0.5.36)
--------------------------------------------------
-- Wunsch des Spielers: „wie beim Jäger eine Rubrik Teleport und Portale,
-- wo man das lernen kann, inkl. Pfeil“. WELCHE Zauber das sind, Stufe und
-- Kosten, steht im Lehrerbestand (data/trainer.lua: die Magierzauber mit
-- `faction`). WER sie lehrt und WO, steht hier.
--
-- HERKUNFT: `community`. NPC-Nummer, Untertitel „Portal Trainer“, Fraktion
-- und Lage aus der Forever-Datenbank von Questie (dieselbe Quelle wie
-- data/questdb.lua, Spawns über areaIdToUiMapId auf UiMapIDs gerechnet).
-- Dass jeder Portallehrer alle Teleports/Portale seiner Fraktion lehrt,
-- ist die Regel aus Classic, nicht im Forever-Client geprüft.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.TrainerData = WeintCodex.TrainerData or {}

WeintCodex.TrainerData.PORTAL_TRAINERS = {
    { npc = 2485, name = "Larimaine Purdue",  faction = "Alliance", map = 1453, x = 50.39, y = 85.99 }, -- Sturmwind
    { npc = 2489, name = "Milstaff Stormeye", faction = "Alliance", map = 1455, x = 25.5,  y = 7.07 },  -- Eisenschmiede
    { npc = 4165, name = "Elissa Dumas",      faction = "Alliance", map = 1457, x = 40.6,  y = 82.13 }, -- Darnassus
    { npc = 5958, name = "Thuul",             faction = "Horde",    map = 1454, x = 38.68, y = 85.41 }, -- Orgrimmar
    { npc = 2492, name = "Lexington Mortaim", faction = "Horde",    map = 1458, x = 84.19, y = 15.58 }, -- Unterstadt
    { npc = 5957, name = "Birgitte Cranston", faction = "Horde",    map = 1456, x = 22.5,  y = 16.91 }, -- Donnerfels
}
