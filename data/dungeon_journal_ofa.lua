--------------------------------------------------
-- WeintCodex :: Dungeon-Journal, Abgleich mit OneForAll (1.0.8.0)
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_oneforall.lua - nicht von Hand aendern.
-- Herkunft (nur fuer Betreuer): OneForAll 6.2.12 (GPL-3.0, nur Daten) -
-- Dropchancen von Wowhead Forever (Bosse mit 100+ Kills, Stand 08.-13.11.2026),
-- Classic-Chancen von foreverchanges.pro; Quests aus QuestieDB Forever.
--   OFA_DROP[Dungeon][Gegenstand] = { Chance %, in Forever gemessen }
--     gemessen: gilt vor dem Bestand; sonst nur, wo der Bestand keine Zahl hat.
--   OFA_QUESTS[Dungeon]  Quests, die dem Dungeon fehlten (keine Texte).
-- Art `community`.
--------------------------------------------------

local J = WeintCodex.DungeonJournal

J.OFA_DROP = {
    alcaz_island_prison = { [276732] = { 32, true }, [276733] = { 33, true }, [276734] = { 33, true }, [276735] = { 33, true }, [276736] = { 30, true }, [276737] = { 33, true }, [276738] = { 27, true }, [276739] = { 42, true }, [276740] = { 31, true }, [276741] = { 32, true }, [276742] = { 30, true }, [276743] = { 38, true }, [276744] = { 33, true }, [276745] = { 34, true }, [276746] = { 34, true } },
    blackfathom_deeps = { [1155] = { 35, true }, [1470] = { 6, true }, [6901] = { 32, true }, [6902] = { 32, true }, [6903] = { 32, true }, [6904] = { 32, true }, [6905] = { 33, true }, [6906] = { 33, true }, [6907] = { 34, true }, [6908] = { 31, true }, [6909] = { 37, true }, [6910] = { 31, true }, [6911] = { 31, true }, [16782] = { 93, false }, [273839] = { 34, true }, [273840] = { 34, true }, [273841] = { 35, true }, [273842] = { 30, true }, [273843] = { 32, true }, [273846] = { 33, true } },
    blackmaw_hold = { [280056] = { 35, true }, [280057] = { 31, true }, [280058] = { 29, true }, [280059] = { 36, true }, [280060] = { 34, true }, [280061] = { 27, true }, [280062] = { 32, true }, [280063] = { 32, true }, [280064] = { 36, true }, [280065] = { 35, true }, [280066] = { 35, true }, [280067] = { 27, true }, [280068] = { 43, true }, [280069] = { 24, true }, [280070] = { 32, true }, [280071] = { 37, true }, [280072] = { 28, true }, [280073] = { 33, true }, [280074] = { 35, true }, [280075] = { 29, true }, [280076] = { 32, true } },
    blackrock_depths = { [11702] = { 19, true }, [11703] = { 19, true }, [11722] = { 23, true }, [11735] = { 8, false }, [11744] = { 26, true }, [11745] = { 23, true }, [11755] = { 33, true }, [11926] = { 27, false }, [11929] = { 50, false }, [12791] = { 41, true }, [12793] = { 29, true }, [18043] = { 20, false }, [18044] = { 24, false }, [22242] = { 34, true }, [22270] = { 18, true }, [22275] = { 23, false }, [276877] = { 30, true }, [276879] = { 24, true }, [276884] = { 33, true } },
    city_of_dalaran = { [273032] = { 35, true }, [273034] = { 33, true }, [273035] = { 32, true }, [273037] = { 28, true }, [273038] = { 36, true }, [273041] = { 33, true }, [273042] = { 35, true }, [273043] = { 30, true }, [273044] = { 33, true }, [273045] = { 37, true }, [273046] = { 36, true }, [273048] = { 30, true }, [273049] = { 32, true }, [273051] = { 33, true }, [273052] = { 32, true }, [273053] = { 30, true }, [273055] = { 35, true }, [273099] = { 10, true } },
    dire_maul = { [18450] = { 13, false }, [18451] = { 12, false }, [18458] = { 10, false }, [18459] = { 13, false }, [18460] = { 12, false }, [18462] = { 13, false }, [18463] = { 11, false }, [18464] = { 13, false }, [18475] = { 16, false }, [18477] = { 15, false }, [18479] = { 14, false }, [18528] = { 18, false }, [18530] = { 13, false }, [18533] = { 10, false } },
    drowned_city = { [286650] = { 45, true }, [286651] = { 55, true }, [286658] = { 49, true }, [286662] = { 51, true } },
    excavation_site = { [270180] = { 73, true }, [273022] = { 36, true }, [273023] = { 31, true }, [273024] = { 33, true }, [273025] = { 32, true }, [273026] = { 35, true }, [273027] = { 33, true }, [273029] = { 34, true }, [273030] = { 32, true } },
    gnomeregan = { [9445] = { 32, true }, [9450] = { 33, true }, [274042] = { 33, true }, [274043] = { 34, true }, [274068] = { 34, true } },
    hall_of_thanes = { [270227] = { 34, true }, [270229] = { 33, true }, [270230] = { 31, true }, [270231] = { 33, true }, [270256] = { 36, true }, [270260] = { 34, true }, [270261] = { 31, true }, [271095] = { 36, true }, [271096] = { 32, true }, [271098] = { 32, true }, [274286] = { 63, true } },
    kroldok_stronghold = { [274995] = { 35, true }, [274996] = { 29, true }, [274997] = { 36, true }, [274998] = { 32, true }, [274999] = { 33, true }, [275000] = { 33, true }, [275001] = { 40, true }, [275002] = { 33, true }, [275003] = { 27, true }, [275004] = { 36, true }, [275005] = { 27, true }, [275006] = { 30, true }, [275007] = { 22, true }, [275008] = { 24, true }, [275009] = { 20, true }, [275010] = { 29, true }, [286428] = { 33, true }, [286429] = { 34, true }, [286430] = { 33, true } },
    maraudon = { [17752] = { 26, true }, [17754] = { 26, true }, [17755] = { 24, true }, [275864] = { 23, true } },
    ragefire_chasm = { [272996] = { 32, true }, [272998] = { 34, true }, [272999] = { 31, true }, [273003] = { 34, true }, [273005] = { 34, true }, [273007] = { 31, true } },
    razorfen_downs = { [10760] = { 34, true }, [10761] = { 29, true }, [10762] = { 26, true }, [10763] = { 24, true }, [10764] = { 25, true }, [10765] = { 22, true }, [10766] = { 31, true }, [10772] = { 33, true }, [10774] = { 33, true }, [274380] = { 36, true }, [274381] = { 24, true }, [274385] = { 34, true } },
    razorfen_kraul = { [2816] = { 35, true }, [6681] = { 33, true }, [6682] = { 34, true }, [6685] = { 31, true }, [6686] = { 31, true }, [6687] = { 35, true }, [6688] = { 54, true }, [6689] = { 46, true }, [6690] = { 31, true }, [6691] = { 37, true }, [6692] = { 34, true }, [6693] = { 34, true }, [6694] = { 32, true }, [6695] = { 27, false }, [6696] = { 33, false }, [6697] = { 33, false }, [274149] = { 28, true }, [274152] = { 36, true }, [274155] = { 31, true }, [274158] = { 32, true }, [274159] = { 34, true }, [274160] = { 32, true }, [274161] = { 35, true } },
    ruins_of_lordaeron = { [271201] = { 31, true }, [271202] = { 34, true }, [271203] = { 35, true }, [271204] = { 34, true }, [271205] = { 33, true }, [271206] = { 34, true }, [271207] = { 33, true }, [271208] = { 33, true }, [271210] = { 32, true }, [271211] = { 33, true }, [271213] = { 34, true }, [271214] = { 32, true }, [271216] = { 35, true }, [271217] = { 35, true }, [271218] = { 34, true } },
    scarlet_monastery = { [3456] = { 21, true }, [7682] = { 34, true }, [7683] = { 32, true }, [7684] = { 34, true }, [7685] = { 32, true }, [7708] = { 34, true }, [7710] = { 29, true }, [7711] = { 33, true }, [7712] = { 32, true }, [7713] = { 31, true }, [7714] = { 32, true }, [7717] = { 26, true }, [7718] = { 24, true }, [7719] = { 24, true }, [7731] = { 35, true }, [7756] = { 26, true }, [10329] = { 2, false }, [10330] = { 14, false }, [10331] = { 2, false }, [10333] = { 2, false }, [23169] = { 100, true }, [274290] = { 34, true }, [274291] = { 34, true }, [274292] = { 24, true }, [274293] = { 30, true }, [274294] = { 30, true }, [274295] = { 26, true } },
    scholomance = { [22303] = { 18, true }, [22326] = { 14, true }, [22332] = { 17, true }, [22333] = { 37, true } },
    shadowfang_keep = { [932] = { 19, false }, [3191] = { 34, true }, [3230] = { 33, true }, [3748] = { 36, true }, [5254] = { 33, true }, [5943] = { 3, false }, [6314] = { 34, true }, [6318] = { 32, true }, [6319] = { 33, true }, [6320] = { 32, true }, [6321] = { 33, true }, [6323] = { 34, true }, [6340] = { 34, true }, [273456] = { 33, true }, [273457] = { 34, true }, [273637] = { 33, true }, [273643] = { 33, true }, [273645] = { 35, true }, [273646] = { 33, true }, [273647] = { 30, true } },
    shapers_terrace = { [280012] = { 31, true }, [280013] = { 29, true }, [280014] = { 40, true }, [280015] = { 34, true }, [280016] = { 32, true }, [280017] = { 34, true }, [280018] = { 24, true }, [280019] = { 31, true }, [280020] = { 40, true }, [280021] = { 34, true }, [280022] = { 37, true }, [280023] = { 38, true }, [280024] = { 28, true }, [280025] = { 34, true }, [280026] = { 48, true }, [280027] = { 52, true }, [280028] = { 58, true }, [280029] = { 40, true }, [280031] = { 49, true }, [280032] = { 51, true }, [280045] = { 28, true } },
    stratholme = { [12103] = { 16, false }, [13348] = { 16, false }, [13353] = { 2, false }, [13358] = { 14, false }, [13359] = { 15, false }, [13360] = { 15, false }, [13369] = { 16, false }, [16725] = { 14, false }, [18717] = { 14, false }, [18718] = { 12, false }, [18720] = { 12, false }, [23125] = { 100, true }, [276397] = { 4, true }, [276398] = { 3, true }, [276399] = { 3, true } },
    sunken_temple = { [10783] = { 5, false }, [10784] = { 3, false }, [10785] = { 6, false }, [10786] = { 8, false }, [10787] = { 7, false }, [10788] = { 10, false } },
    the_deadmines = { [872] = { 34, true }, [1156] = { 33, true }, [1929] = { 6, false }, [1934] = { 6, false }, [1936] = { 6, false }, [1937] = { 34, true }, [1951] = { 6, false }, [2169] = { 34, true }, [2874] = { 56, false }, [5187] = { 33, true }, [5192] = { 26, true }, [5194] = { 32, true }, [5195] = { 34, true }, [5196] = { 25, true }, [5197] = { 34, true }, [5198] = { 33, true }, [5199] = { 33, true }, [7230] = { 25, true }, [10400] = { 3, false }, [10401] = { 3, false }, [10402] = { 3, false }, [273289] = { 33, true }, [273293] = { 33, true }, [273297] = { 33, true }, [273298] = { 33, true }, [284715] = { 24, true }, [285292] = { 32, true } },
    the_stockade = { [2280] = { 36, true }, [273804] = { 31, true }, [273805] = { 34, true }, [273806] = { 35, true }, [273807] = { 34, true }, [273808] = { 30, true }, [273809] = { 37, true }, [273810] = { 29, true }, [273811] = { 34, true }, [273817] = { 36, true }, [273819] = { 32, true }, [273820] = { 32, true }, [273824] = { 24, true }, [273825] = { 25, true }, [273827] = { 29, true }, [273829] = { 22, true } },
    uldaman = { [9407] = { 29, true }, [9408] = { 30, true }, [9409] = { 30, true }, [9410] = { 33, true }, [9411] = { 33, true }, [9413] = { 16, true }, [9418] = { 17, true }, [11118] = { 50, true }, [274431] = { 34, true }, [274432] = { 17, true }, [274484] = { 12, true } },
    wailing_caverns = { [5404] = { 33, true }, [6446] = { 11, true }, [6447] = { 44, true }, [6448] = { 32, true }, [6449] = { 34, true }, [6472] = { 34, true }, [6473] = { 33, true }, [10412] = { 33, true }, [10413] = { 2, false }, [10441] = { 68, false }, [13245] = { 45, true }, [273084] = { 11, true }, [273088] = { 34, true }, [273089] = { 33, true }, [273137] = { 34, true } },
    zulfarrak = { [9467] = { 33, true }, [9469] = { 36, true }, [12469] = { 57, true }, [12470] = { 46, true }, [12471] = { 43, true }, [18082] = { 36, true }, [18083] = { 34, true }, [274642] = { 30, true }, [274646] = { 34, true }, [274647] = { 31, true }, [274648] = { 34, true }, [274654] = { 57, true }, [274655] = { 43, true }, [274657] = { 31, true }, [274658] = { 54, true } },
}

J.OFA_QUESTS = {
    blackmaw_hold = {
        { id = 99187, name = "The Reliquary of Tyr", level = 58, requires = 50, faction = "horde", classes = { "PALADIN" } },
    },
    city_of_dalaran = {
        { id = 92432, name = "An Alarming Request", level = 33, requires = 30, faction = "alliance" },
        { id = 92459, name = "Friend of the Kirin Tor", level = 33, requires = 24, faction = "alliance" },
    },
    dire_maul = {
        { id = 96076, name = "In Demand - Ancient Elven Curiosities", level = 60, requires = 60, faction = "both" },
        { id = 7581, name = "The Prison's Bindings", level = 60, requires = 60, faction = "both", classes = { "WARLOCK" } },
        { id = 7631, name = "Dreadsteed of Xoroth", level = 60, requires = 60, faction = "both", classes = { "WARLOCK" } },
    },
    drowned_city = {
        { id = 96078, name = "A Tale Spun Around the Fire", level = 40, requires = 30, faction = "horde" },
        { id = 95798, name = "The Web of Magic", level = 40, requires = 30, faction = "alliance" },
        { id = 95799, name = "Findings for the Explorer's League", level = 40, requires = 30, faction = "alliance" },
    },
    gnomeregan = {
        { id = 80325, name = "The Mad King", level = 40, requires = 40, faction = "horde" },
    },
    kroldok_stronghold = {
        { id = 94998, name = "Curios of Curiosity", level = 42, requires = 38, faction = "alliance" },
    },
    lower_blackrock_spire = {
        { id = 5306, name = "Snakestone of the Shadow Huntress", level = 60, requires = 50, faction = "both" },
    },
    razorfen_kraul = {
        { id = 79360, name = "Elemental Aid", level = 33, requires = 30, faction = "horde", classes = { "SHAMAN" } },
        { id = 96264, name = "Elemental Aid", level = 33, requires = 30, faction = "alliance", classes = { "SHAMAN" } },
    },
    ruins_of_lordaeron = {
        { id = 97291, name = "Unending Torment", level = 21, requires = 15, faction = "horde" },
    },
    scarlet_monastery = {
        { id = 79946, name = "A Brother In Need", level = 40, requires = 35, faction = "alliance", classes = { "PALADIN" } },
        { id = 78676, name = "The Eye of Bhossca", level = 35, requires = 25, faction = "both", classes = { "ROGUE" } },
        { id = 6141, name = "Brother Anton", level = 39, requires = 34, faction = "alliance" },
    },
    scholomance = {
        { id = 7629, name = "Imp Delivery", level = 60, requires = 60, faction = "both", classes = { "WARLOCK" } },
        { id = 7647, name = "Judgment and Redemption", level = 60, requires = 60, faction = "alliance", classes = { "PALADIN" } },
        { id = 8258, name = "The Darkreaver Menace", level = 60, requires = 60, faction = "horde", classes = { "SHAMAN" } },
    },
    shadowfang_keep = {
        { id = 1654, name = "The Test of Righteousness", level = 22, requires = 20, faction = "alliance", classes = { "PALADIN" } },
        { id = 78261, name = "The Horn of Xelthos", level = 23, requires = 1, faction = "both", classes = { "ROGUE" } },
    },
    stratholme = {
        { id = 5305, name = "Sweet Serenity", level = 60, requires = 50, faction = "both" },
        { id = 5307, name = "Corruption", level = 60, requires = 50, faction = "both" },
        { id = 5281, name = "The Restless Souls", level = 60, requires = 55, faction = "both" },
        { id = 84330, name = "A Wee Bit O' Necromancy", level = 59, requires = 54, faction = "alliance", classes = { "PALADIN" } },
    },
    sunken_temple = {
        { id = 9053, name = "A Better Ingredient", level = 52, requires = 50, faction = "both", classes = { "DRUID" } },
        { id = 8232, name = "The Green Drake", level = 52, requires = 50, faction = "both", classes = { "HUNTER" } },
        { id = 8253, name = "Destroy Morphaz", level = 52, requires = 50, faction = "both", classes = { "MAGE" } },
        { id = 8257, name = "Blood of Morphaz", level = 52, requires = 50, faction = "both", classes = { "PRIEST" } },
        { id = 8236, name = "The Azure Key", level = 52, requires = 50, faction = "both", classes = { "ROGUE" } },
        { id = 8422, name = "Trolls of a Feather", level = 52, requires = 50, faction = "both", classes = { "WARLOCK" } },
        { id = 8425, name = "Voodoo Feathers", level = 52, requires = 50, faction = "both", classes = { "WARRIOR" } },
        { id = 8413, name = "Da Voodoo", level = 52, requires = 50, faction = "horde", classes = { "SHAMAN" } },
        { id = 8415, name = "Chillwind Point", level = 52, requires = 50, faction = "alliance", classes = { "PALADIN" } },
        { id = 8417, name = "A Troubled Spirit", level = 50, requires = 50, faction = "both", classes = { "WARRIOR" } },
        { id = 8418, name = "Forging the Mightstone", level = 52, requires = 50, faction = "alliance", classes = { "PALADIN" } },
    },
    wailing_caverns = {
        { id = 3369, name = "In Nightmares", level = 25, requires = 15, faction = "horde" },
        { id = 3370, name = "In Nightmares", level = 25, requires = 15, faction = "alliance" },
    },
    zulfarrak = {
        { id = 2769, name = "The Brassbolts Brothers", level = 46, requires = 40, faction = "alliance" },
        { id = 80411, name = "The Talisman of Kazdor", level = 50, requires = 45, faction = "both", classes = { "ROGUE" } },
    },
}

J.MergeOneForAll()
