--------------------------------------------------
-- WeintCodex :: Bosse auf den Dungeonkarten
--------------------------------------------------
-- ERZEUGT von .github/scripts/import_mappins.py - nicht von Hand
-- aendern; neu erzeugen.
--
-- HERKUNFT `classic`: die Tabellen JournalEncounter, UiMapXMapArt und
-- UiMapArtTile des Spiels (Classic- und aktuelle Fassung, gelesen ueber
-- wago.tools). Ein Punkt steht nur, wo die Kartengrafik des Bosses aus
-- denselben Bilddateien besteht wie die Ebene in data/dungeonmaps.lua.
-- Dass Forever die Bosse an denselben Stellen stehen hat, ist eine
-- begruendete Erwartung, nicht gemessen.
--
-- 1.0.8.21: dazu Naowh Forever, nur die Lage (`community`, Feld 6 =
-- "n"); Spieltabelle = "s". Widersprechen sich beide, steht kein Punkt:
--   blackrock_depths/ring_of_law, dire_maul/lethtendris, lower_blackrock_spire/mother_smolderweb, maraudon/tinkerer_gizlock, razorfen_kraul/agathelos, razorfen_kraul/charlga_razorflank, razorfen_kraul/roogug, shadowfang_keep/baron_silverlaine, shadowfang_keep/commander_springvale, the_deadmines/mr_smite
--
-- [Instanz] = { { dungeon, boss, Ebene, x, y, Quelle }, ... }  (x, y: 0..1)
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.DungeonPins = {
    [33] = {
        { "shadowfang_keep", "rethilgore", 1, 0.6660, 0.7170, "n" },
        { "shadowfang_keep", "razorclaw", 2, 0.3020, 0.7630, "n" },
        { "shadowfang_keep", "odo", 7, 0.7140, 0.7000, "n" },
        { "shadowfang_keep", "deathsworn_captain", 7, 0.4281, 0.8250, "n" },
        { "shadowfang_keep", "fenrus", 4, 0.5430, 0.5310, "n" },
        { "shadowfang_keep", "wolf_master_nandos", 6, 0.5600, 0.6209, "n" },
        { "shadowfang_keep", "archmage_arugal", 6, 0.6809, 0.3281, "n" },
    },
    [34] = {
        { "the_stockade", "targorr", 1, 0.5000, 0.4950, "n" },
        { "the_stockade", "kam_deepfury", 1, 0.6900, 0.3000, "n" },
        { "the_stockade", "hamhock", 1, 0.7830, 0.4570, "n" },
        { "the_stockade", "bazil_thredd", 1, 0.8550, 0.5170, "n" },
        { "the_stockade", "dextren_ward", 1, 0.2170, 0.2631, "n" },
        { "the_stockade", "bruegal", 1, 0.5000, 0.1901, "n" },
    },
    [36] = {
        { "the_deadmines", "rhahkzor", 1, 0.3653, 0.6123, "s" },   -- Karte 291
        { "the_deadmines", "miner_johnson", 1, 0.5290, 0.5030, "n" },
        { "the_deadmines", "sneeds_shredder", 1, 0.5020, 0.8683, "s" },   -- Karte 291
        { "the_deadmines", "gilnid", 2, 0.1248, 0.7590, "s" },   -- Karte 292
        { "the_deadmines", "captain_greenskin", 2, 0.6076, 0.3748, "s" },   -- Karte 292
        { "the_deadmines", "edwin_vancleef", 2, 0.6076, 0.4489, "s" },   -- Karte 292
        { "the_deadmines", "cookie", 2, 0.6763, 0.4017, "s" },   -- Karte 292
    },
    [43] = {
        { "wailing_caverns", "lady_anacondra", 1, 0.3060, 0.4303, "s" },   -- Karte 279
        { "wailing_caverns", "lord_cobrahn", 1, 0.1667, 0.5676, "s" },   -- Karte 279
        { "wailing_caverns", "kresh", 1, 0.3852, 0.3607, "s" },   -- Karte 279
        { "wailing_caverns", "lord_pythas", 1, 0.1913, 0.3955, "s" },   -- Karte 279
        { "wailing_caverns", "skum", 1, 0.6230, 0.7439, "s" },   -- Karte 279
        { "wailing_caverns", "lord_serpentis", 1, 0.6161, 0.5389, "s" },   -- Karte 279
        { "wailing_caverns", "verdan", 1, 0.5546, 0.4652, "s" },   -- Karte 279
        { "wailing_caverns", "mutanus", 1, 0.3456, 0.1373, "s" },   -- Karte 279
    },
    [47] = {
        { "razorfen_kraul", "aggem_thorncurse", 1, 0.8019, 0.5164, "s" },   -- Karte 301
        { "razorfen_kraul", "death_speaker_jargba", 1, 0.8730, 0.4221, "s" },   -- Karte 301
        { "razorfen_kraul", "overlord_ramtusk", 1, 0.5710, 0.3053, "s" },   -- Karte 301
    },
    [48] = {
        { "blackfathom_deeps", "ghamoora", 1, 0.3333, 0.6069, "s" },   -- Karte 221
        { "blackfathom_deeps", "lady_sarevess", 1, 0.1119, 0.3896, "s" },   -- Karte 221
        { "blackfathom_deeps", "gelihast", 1, 0.5433, 0.5642, "s" },   -- Karte 221
        { "blackfathom_deeps", "lorgus_jett", 2, 0.3250, 0.7000, "n" },
        { "blackfathom_deeps", "baron_aquanis", 2, 0.4200, 0.7200, "n" },
        { "blackfathom_deeps", "old_serrakis", 3, 0.5866, 0.3090, "s" },   -- Karte 223
        { "blackfathom_deeps", "twilight_lord_kelris", 2, 0.5239, 0.8082, "s" },   -- Karte 222
        { "blackfathom_deeps", "akumai", 2, 0.8552, 0.8642, "s" },   -- Karte 222
    },
    [70] = {
        { "uldaman", "revelosh", 1, 0.5342, 0.7254, "s" },   -- Karte 230
        { "uldaman", "the_lost_dwarves", 1, 0.5847, 0.9201, "s" },   -- Karte 230
        { "uldaman", "ironaya", 1, 0.3730, 0.7398, "s" },   -- Karte 230
        { "uldaman", "ancient_stone_keeper", 1, 0.4754, 0.4406, "s" },   -- Karte 230
        { "uldaman", "galgann", 1, 0.2678, 0.3279, "s" },   -- Karte 230
        { "uldaman", "grimlok", 1, 0.2199, 0.2561, "s" },   -- Karte 230
        { "uldaman", "archaedas", 2, 0.5533, 0.5041, "s" },   -- Karte 231
    },
    [90] = {
        { "gnomeregan", "grubbis", 1, 0.7787, 0.6701, "s" },   -- Karte 226
        { "gnomeregan", "viscous_fallout", 2, 0.7596, 0.4652, "s" },   -- Karte 227
        { "gnomeregan", "electrocutioner", 2, 0.2432, 0.6844, "s" },   -- Karte 227
        { "gnomeregan", "crowd_pummeler", 3, 0.4317, 0.8832, "s" },   -- Karte 228
        { "gnomeregan", "thermaplugg", 4, 0.3115, 0.3033, "s" },   -- Karte 229
    },
    [109] = {
        { "sunken_temple", "atalalarion", 1, 0.4990, 0.4550, "n" },
        { "sunken_temple", "jammalan", 1, 0.7609, 0.4590, "s" },   -- Karte 220
        { "sunken_temple", "ogom", 1, 0.7870, 0.4540, "n" },
        { "sunken_temple", "dreamscythe", 1, 0.4720, 0.4190, "n" },
        { "sunken_temple", "weaver", 1, 0.5260, 0.4190, "n" },
        { "sunken_temple", "morphaz", 1, 0.4730, 0.8699, "n" },
        { "sunken_temple", "hazzas", 1, 0.5220, 0.8699, "n" },
        { "sunken_temple", "eranikus", 1, 0.6708, 0.8770, "s" },   -- Karte 220
        { "sunken_temple", "avatar_of_hakkar", 1, 0.2432, 0.4590, "s" },   -- Karte 220
    },
    [129] = {
        { "razorfen_downs", "tutenkash", 1, 0.5943, 0.3402, "s" },   -- Karte 300
        { "razorfen_downs", "mordresh", 1, 0.8607, 0.4672, "s" },   -- Karte 300
        { "razorfen_downs", "glutton", 1, 0.3429, 0.6680, "s" },   -- Karte 300
        { "razorfen_downs", "plaguemaw", 1, 0.4610, 0.2300, "n" },
        { "razorfen_downs", "ragglesnout", 1, 0.4600, 0.5080, "n" },
        { "razorfen_downs", "amnennar", 1, 0.4454, 0.6045, "s" },   -- Karte 300
    },
    [189] = {
        { "scarlet_monastery", "interrogator_vishas", 1, 0.7210, 0.5970, "n" },
        { "scarlet_monastery", "bloodmage_thalnos", 1, 0.2440, 0.5630, "n" },
        { "scarlet_monastery", "ironspine", 1, 0.4330, 0.6800, "n" },
        { "scarlet_monastery", "azshir", 1, 0.2580, 0.6690, "n" },
        { "scarlet_monastery", "fallen_champion", 1, 0.2760, 0.5590, "n" },
        { "scarlet_monastery", "houndmaster_loksey", 2, 0.2920, 0.8400, "n" },
        { "scarlet_monastery", "arcanist_doan", 2, 0.8340, 0.7410, "n" },
        { "scarlet_monastery", "herod", 3, 0.7850, 0.1060, "n" },
        { "scarlet_monastery", "high_inquisitor_fairbanks", 4, 0.5540, 0.2491, "n" },
        { "scarlet_monastery", "mograine", 4, 0.4890, 0.2731, "n" },
        { "scarlet_monastery", "whitemane", 4, 0.4900, 0.1661, "n" },
    },
    [209] = {
        { "zulfarrak", "antusul", 1, 0.6462, 0.2766, "s" },   -- Karte 219
        { "zulfarrak", "theka", 1, 0.5314, 0.2623, "s" },   -- Karte 219
        { "zulfarrak", "zumrah", 1, 0.4426, 0.1762, "s" },   -- Karte 219
        { "zulfarrak", "sergeant_bly", 1, 0.2300, 0.1540, "n" },
        { "zulfarrak", "nekrum", 1, 0.2964, 0.1742, "s" },   -- Karte 219
        { "zulfarrak", "sezzziz", 1, 0.2964, 0.1742, "s" },   -- Karte 219
        { "zulfarrak", "ukorz", 1, 0.4221, 0.3299, "s" },   -- Karte 219
        { "zulfarrak", "gahzrilla", 1, 0.2809, 0.3828, "s" },   -- Karte 219
    },
    [229] = {
        { "lower_blackrock_spire", "highlord_omokk", 3, 0.3866, 0.5902, "s" },   -- Karte 252
        { "lower_blackrock_spire", "shadow_hunter_voshgajin", 2, 0.5533, 0.6926, "s" },   -- Karte 251
        { "lower_blackrock_spire", "war_master_voone", 1, 0.5246, 0.5451, "s" },   -- Karte 250
        { "lower_blackrock_spire", "urok_doomhowl", 4, 0.4549, 0.5574, "s" },   -- Karte 253
        { "lower_blackrock_spire", "quartermaster_zigris", 5, 0.5396, 0.8443, "s" },   -- Karte 254
        { "lower_blackrock_spire", "halycon", 5, 0.3798, 0.8402, "s" },   -- Karte 254
        { "lower_blackrock_spire", "gizrul", 5, 0.3948, 0.7930, "s" },   -- Karte 254
        { "lower_blackrock_spire", "overlord_wyrmthalak", 6, 0.5751, 0.6004, "s" },   -- Karte 255
        { "upper_blackrock_spire", "pyroguard_emberseer", 6, 0.3033, 0.2664, "s" },   -- Karte 255
        { "upper_blackrock_spire", "solakar_flamewreath", 6, 0.3661, 0.3811, "s" },   -- Karte 255
        { "upper_blackrock_spire", "goraluk_anvilcrack", 7, 0.2930, 0.2760, "n" },
        { "upper_blackrock_spire", "jed_runewatcher", 7, 0.5740, 0.4659, "n" },
        { "upper_blackrock_spire", "warchief_rend_blackhand", 7, 0.4910, 0.2470, "n" },
        { "upper_blackrock_spire", "the_beast", 7, 0.6450, 0.3120, "n" },
        { "upper_blackrock_spire", "general_drakkisath", 7, 0.3380, 0.4680, "n" },
    },
    [230] = {
        { "blackrock_depths", "lord_roccor", 1, 0.5560, 0.6701, "s" },   -- Karte 242
        { "blackrock_depths", "high_interrogator_gerstahn", 1, 0.4740, 0.9221, "s" },   -- Karte 242
        { "blackrock_depths", "houndmaster_grebmar", 1, 0.5350, 0.5735, "s" },   -- Karte 242
        { "blackrock_depths", "theldren", 1, 0.4978, 0.6458, "s" },   -- Karte 242
        { "blackrock_depths", "pyromancer_loregrain", 2, 0.5492, 0.9488, "s" },   -- Karte 243
        { "blackrock_depths", "golem_lord_argelmach", 2, 0.3648, 0.6516, "s" },   -- Karte 243
        { "blackrock_depths", "hurley_blackbreath", 2, 0.5057, 0.7048, "s" },   -- Karte 243
        { "blackrock_depths", "phalanx", 2, 0.4582, 0.5647, "s" },   -- Karte 243
        { "blackrock_depths", "ribbly_screwspigot", 2, 0.5255, 0.6254, "s" },   -- Karte 243
        { "blackrock_depths", "plugger_spazzring", 2, 0.4772, 0.6571, "s" },   -- Karte 243
        { "blackrock_depths", "lord_incendius", 1, 0.5642, 0.3115, "s" },   -- Karte 242
        { "blackrock_depths", "warder_stilgiss", 2, 0.6025, 0.6598, "s" },   -- Karte 243
        { "blackrock_depths", "fineous_darkvire", 1, 0.6352, 0.2111, "s" },   -- Karte 242
        { "blackrock_depths", "baelgar", 1, 0.2514, 0.5348, "s" },   -- Karte 242
        { "blackrock_depths", "general_angerforge", 2, 0.3634, 0.8238, "s" },   -- Karte 243
        { "blackrock_depths", "ambassador_flamelash", 2, 0.5383, 0.4857, "s" },   -- Karte 243
        { "blackrock_depths", "panzor", 2, 0.4889, 0.3510, "n" },
        { "blackrock_depths", "the_seven", 2, 0.5383, 0.2480, "s" },   -- Karte 243
        { "blackrock_depths", "magmus", 2, 0.7964, 0.1189, "s" },   -- Karte 243
        { "blackrock_depths", "dagran_thaurissan", 2, 0.9098, 0.1189, "s" },   -- Karte 243
    },
    [289] = {
        { "scholomance", "jandice_barov", 2, 0.5997, 0.1831, "s" },   -- Karte 477
        { "scholomance", "rattlegore", 2, 0.4844, 0.2618, "s" },   -- Karte 477
        { "scholomance", "darkmaster_gandling", 4, 0.5011, 0.3262, "s" },   -- Karte 479
    },
    [329] = {
        { "stratholme", "hearthsinger_forresten", 1, 0.6052, 0.3135, "s" },   -- Karte 317
        { "stratholme", "the_unforgiven", 1, 0.7350, 0.2049, "s" },   -- Karte 317
        { "stratholme", "timmy_the_cruel", 1, 0.5000, 0.1783, "s" },   -- Karte 317
        { "stratholme", "malor_the_zealous", 1, 0.2993, 0.4119, "s" },   -- Karte 317
        { "stratholme", "cannon_master_willey", 1, 0.0478, 0.5061, "s" },   -- Karte 317
        { "stratholme", "archivist_galford", 1, 0.2773, 0.7541, "s" },   -- Karte 317
        { "stratholme", "balnazzar", 1, 0.2049, 0.8217, "s" },   -- Karte 317
        { "stratholme", "postmaster_malown", 1, 0.5581, 0.6841, "s" },   -- Karte 317
        { "stratholme", "skul", 1, 0.5740, 0.6520, "n" },
        { "stratholme", "stonespine", 2, 0.6490, 0.4890, "n" },
        { "stratholme", "baroness_anastari", 2, 0.7459, 0.4693, "s" },   -- Karte 318
        { "stratholme", "nerubenkan", 2, 0.5724, 0.4611, "s" },   -- Karte 318
        { "stratholme", "maleki_the_pallid", 2, 0.6749, 0.2275, "s" },   -- Karte 318
        { "stratholme", "magistrate_barthilas", 2, 0.5669, 0.1619, "s" },   -- Karte 318
        { "stratholme", "ramstein", 2, 0.4563, 0.1988, "s" },   -- Karte 318
        { "stratholme", "baron_rivendare", 2, 0.3866, 0.2008, "s" },   -- Karte 318
    },
    [349] = {
        { "maraudon", "noxxion", 1, 0.3620, 0.0984, "s" },   -- Karte 280
        { "maraudon", "razorlash", 1, 0.1667, 0.3443, "s" },   -- Karte 280
        { "maraudon", "lord_vyletongue", 1, 0.3784, 0.7049, "s" },   -- Karte 280
        { "maraudon", "meshlok", 1, 0.2430, 0.7080, "n" },
        { "maraudon", "celebras", 2, 0.2459, 0.1434, "s" },   -- Karte 281
        { "maraudon", "landslide", 2, 0.4085, 0.4877, "s" },   -- Karte 281
        { "maraudon", "rotgrip", 2, 0.4139, 0.8176, "s" },   -- Karte 281
        { "maraudon", "princess_theradras", 2, 0.2582, 0.7889, "s" },   -- Karte 281
    },
    [389] = {
        { "ragefire_chasm", "oggleflint", 1, 0.6940, 0.6460, "n" },
        { "ragefire_chasm", "taragaman", 1, 0.4070, 0.5760, "n" },
        { "ragefire_chasm", "jergosh", 1, 0.3420, 0.8160, "n" },
        { "ragefire_chasm", "bazzalan", 1, 0.4190, 0.8640, "n" },
    },
    [429] = {
        { "dire_maul", "pusillin", 5, 0.4370, 0.4720, "n" },
        { "dire_maul", "zevrim_thornhoof", 6, 0.5751, 0.7439, "s" },   -- Karte 240
        { "dire_maul", "hydrospawn", 6, 0.5369, 0.7152, "s" },   -- Karte 240
        { "dire_maul", "alzzin", 6, 0.5669, 0.2889, "s" },   -- Karte 240
        { "dire_maul", "tendris_warpwood", 2, 0.3361, 0.5369, "s" },   -- Karte 236
        { "dire_maul", "illyanna_ravenoak", 2, 0.2036, 0.7766, "s" },   -- Karte 236
        { "dire_maul", "magister_kalendris", 3, 0.3388, 0.4508, "s" },   -- Karte 237
        { "dire_maul", "tsuzee", 3, 0.3290, 0.1300, "n" },
        { "dire_maul", "immolthar", 4, 0.3497, 0.5758, "s" },   -- Karte 238
        { "dire_maul", "prince_tortheldrin", 4, 0.6230, 0.2316, "s" },   -- Karte 238
        { "dire_maul", "lord_helnurath", 4, 0.3060, 0.6519, "n" },
        { "dire_maul", "guard_moldar", 1, 0.6954, 0.7602, "s" },   -- Karte 235
        { "dire_maul", "stomper_kreeg", 1, 0.6120, 0.6926, "s" },   -- Karte 235
        { "dire_maul", "guard_fengus", 1, 0.4945, 0.7807, "s" },   -- Karte 235
        { "dire_maul", "guard_slipkik", 1, 0.2664, 0.5717, "s" },   -- Karte 235
        { "dire_maul", "captain_kromcrush", 1, 0.3183, 0.5061, "s" },   -- Karte 235
        { "dire_maul", "king_gordok", 1, 0.3195, 0.2295, "s" },   -- Karte 235
    },
    [2959] = {
        { "city_of_dalaran", "atrexis", 2, 0.5457, 0.5098, "n" },
        { "city_of_dalaran", "arcane_anomaly", 1, 0.5182, 0.8594, "n" },
        { "city_of_dalaran", "fel_ancient", 1, 0.5162, 0.5813, "n" },
        { "city_of_dalaran", "unstable_sentinel", 1, 0.5943, 0.4312, "n" },
        { "city_of_dalaran", "mana_devourer", 1, 0.3608, 0.8334, "n" },
        { "city_of_dalaran", "arcanic_enigma", 1, 0.4881, 0.7764, "n" },
        { "city_of_dalaran", "lyn_the_ignored", 2, 0.7026, 0.1742, "n" },
        { "city_of_dalaran", "shade_of_the_archmage", 1, 0.5011, 0.2481, "n" },
    },
    [2970] = {
        { "drowned_city", "zulalai", 1, 0.6970, 0.5720, "n" },
        { "drowned_city", "vartaka", 1, 0.5140, 0.6890, "n" },
        { "drowned_city", "captain_dreadrise", 1, 0.5460, 0.3440, "n" },
        { "drowned_city", "deathless_marrow", 1, 0.3490, 0.5360, "n" },
        { "drowned_city", "minloth", 1, 0.1961, 0.5390, "n" },
        { "drowned_city", "primeval_elemental", 1, 0.6180, 0.6720, "n" },
    },
    [2994] = {
        { "alcaz_island_prison", "overseer_wrex", 1, 0.6420, 0.3380, "n" },
        { "alcaz_island_prison", "tidemistress_cazass", 1, 0.3550, 0.7140, "n" },
        { "alcaz_island_prison", "katerina_the_cleaner", 2, 0.3900, 0.7150, "n" },
        { "alcaz_island_prison", "the_questioner", 1, 0.2470, 0.1730, "n" },
        { "alcaz_island_prison", "blazeroar", 2, 0.6610, 0.7140, "n" },
    },
    [2998] = {
        { "excavation_site", "saltspine", 1, 0.5000, 0.3929, "n" },
        { "excavation_site", "shadetooth", 1, 0.3395, 0.4689, "n" },
        { "excavation_site", "relic_guardian", 1, 0.3405, 0.6590, "n" },
        { "excavation_site", "highland_horror", 1, 0.0797, 0.3729, "n" },
    },
    [2999] = {
        { "ruins_of_lordaeron", "witherfang", 1, 0.7069, 0.3682, "n" },
        { "ruins_of_lordaeron", "the_abandoned", 1, 0.4030, 0.5209, "n" },
        { "ruins_of_lordaeron", "the_butcher", 1, 0.5870, 0.6914, "n" },
        { "ruins_of_lordaeron", "lordaeron_captain", 1, 0.3490, 0.3772, "n" },
        { "ruins_of_lordaeron", "bjork", 1, 0.4070, 0.4241, "n" },
        { "ruins_of_lordaeron", "rathmael", 1, 0.4770, 0.6246, "n" },
        { "ruins_of_lordaeron", "viktor_the_vile", 1, 0.3820, 0.6645, "n" },
    },
    [3001] = {
        { "shapers_terrace", "nanaya", 1, 0.7580, 0.6210, "n" },
        { "shapers_terrace", "snowtalon", 1, 0.1220, 0.1130, "n" },
        { "shapers_terrace", "cinder", 1, 0.1310, 0.6600, "n" },
        { "shapers_terrace", "bolt", 1, 0.4000, 0.6740, "n" },
    },
    [3039] = {
        { "kroldok_stronghold", "slavecrusher_grox", 1, 0.3310, 0.7029, "n" },
        { "kroldok_stronghold", "twilight_commander_zarmok", 1, 0.3920, 0.7340, "n" },
        { "kroldok_stronghold", "war_handler_ashka", 1, 0.6210, 0.5270, "n" },
        { "kroldok_stronghold", "nargurk", 1, 0.4110, 0.5790, "n" },
        { "kroldok_stronghold", "overlord_mugg", 1, 0.6880, 0.2420, "n" },
        { "kroldok_stronghold", "bossman_toof", 1, 0.6170, 0.4320, "n" },
    },
    [3065] = {
        { "hall_of_thanes", "faldrim_anvilmar", 1, 0.5050, 0.6675, "n" },
        { "hall_of_thanes", "magmatus", 1, 0.7170, 0.4929, "n" },
        { "hall_of_thanes", "plunder", 1, 0.5080, 0.5109, "n" },
        { "hall_of_thanes", "durgen_dirgehammer", 1, 0.5070, 0.1687, "n" },
    },
}
