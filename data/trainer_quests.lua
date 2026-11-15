--------------------------------------------------
-- WeintCodex :: Zauber, die man ueber Quests lernt
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_naowh_training.py aus Naowh Forever
-- 1.2.33 (Training, Daten aus dem Client-Build 1.60.1.70888) - nicht
-- von Hand aendern. Herkunft `community`: kein Lehrer lehrt sie, eine
-- Quest belohnt sie. Nur Zauber, die data/trainer.lua nicht fuehrt.
-- { Stufe, Zaubernummer, Rassen (ClassicRace) oder nil }
--------------------------------------------------

local T = WeintCodex.TrainerData
T.QUEST_SPELLS = {
    DRUID = {
        { 10, 5487 },
        { 10, 6795 },
        { 10, 6807 },
        { 10, 18960 },
        { 14, 8946 },
        { 16, 1066 },
        { 20, 768 },
        { 20, 1079 },
        { 20, 1082 },
        { 20, 5215 },
    },
    HUNTER = {
        { 10, 883 },
        { 10, 982 },
        { 10, 1515 },
        { 10, 2641 },
        { 10, 6991 },
    },
    MAGE = {
        { 60, 10140 },
        { 60, 28272 },
    },
    PALADIN = {
        { 12, 7328 },
    },
    PRIEST = {
        { 10, 2652, { 5 } },
        { 10, 9035, { 8 } },
        { 10, 10797, { 4 } },
        { 10, 13908, { 3 } },
        { 10, 1277370, { 1 } },
        { 10, 1277455, { 7 } },
        { 20, 2651, { 4 } },
        { 20, 13896, { 1 } },
        { 20, 18137, { 8 } },
        { 20, 1277324, { 5 } },
        { 20, 1277331, { 3 } },
        { 20, 1277462, { 7 } },
    },
    ROGUE = {
        { 20, 2842 },
    },
    SHAMAN = {
        { 4, 8071 },
        { 10, 3599 },
        { 20, 5394 },
    },
    WARLOCK = {
        { 10, 697 },
        { 20, 712 },
        { 20, 713 },
        { 30, 691 },
        { 50, 1122 },
        { 60, 18540 },
    },
    WARRIOR = {
        { 10, 71 },
        { 10, 355 },
        { 10, 7386 },
        { 30, 2458 },
        { 30, 20252 },
    },
}
