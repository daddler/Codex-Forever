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
-- [Instanz] = { { dungeon, boss, Ebene, x, y }, ... }  (x, y: 0..1)
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.DungeonPins = {
    [33] = {
        { "shadowfang_keep", "baron_silverlaine", 2, 0.3044, 0.7740 },   -- Karte 311
        { "shadowfang_keep", "commander_springvale", 1, 0.2804, 0.5973 },   -- Karte 310
    },
    [36] = {
        { "the_deadmines", "rhahkzor", 1, 0.3653, 0.6123 },   -- Karte 291
        { "the_deadmines", "sneeds_shredder", 1, 0.5020, 0.8683 },   -- Karte 291
        { "the_deadmines", "gilnid", 2, 0.1248, 0.7590 },   -- Karte 292
        { "the_deadmines", "mr_smite", 2, 0.5518, 0.2536 },   -- Karte 292
        { "the_deadmines", "captain_greenskin", 2, 0.6076, 0.3748 },   -- Karte 292
        { "the_deadmines", "edwin_vancleef", 2, 0.6076, 0.4489 },   -- Karte 292
        { "the_deadmines", "cookie", 2, 0.6763, 0.4017 },   -- Karte 292
    },
    [43] = {
        { "wailing_caverns", "lady_anacondra", 1, 0.3060, 0.4303 },   -- Karte 279
        { "wailing_caverns", "lord_cobrahn", 1, 0.1667, 0.5676 },   -- Karte 279
        { "wailing_caverns", "kresh", 1, 0.3852, 0.3607 },   -- Karte 279
        { "wailing_caverns", "lord_pythas", 1, 0.1913, 0.3955 },   -- Karte 279
        { "wailing_caverns", "skum", 1, 0.6230, 0.7439 },   -- Karte 279
        { "wailing_caverns", "lord_serpentis", 1, 0.6161, 0.5389 },   -- Karte 279
        { "wailing_caverns", "verdan", 1, 0.5546, 0.4652 },   -- Karte 279
        { "wailing_caverns", "mutanus", 1, 0.3456, 0.1373 },   -- Karte 279
    },
    [47] = {
        { "razorfen_kraul", "roogug", 1, 0.8723, 0.4108 },   -- Karte 301
        { "razorfen_kraul", "aggem_thorncurse", 1, 0.8019, 0.5164 },   -- Karte 301
        { "razorfen_kraul", "death_speaker_jargba", 1, 0.8730, 0.4221 },   -- Karte 301
        { "razorfen_kraul", "overlord_ramtusk", 1, 0.5710, 0.3053 },   -- Karte 301
        { "razorfen_kraul", "agathelos", 1, 0.0806, 0.6885 },   -- Karte 301
        { "razorfen_kraul", "charlga_razorflank", 1, 0.2172, 0.3135 },   -- Karte 301
    },
    [48] = {
        { "blackfathom_deeps", "ghamoora", 1, 0.3333, 0.6069 },   -- Karte 221
        { "blackfathom_deeps", "lady_sarevess", 1, 0.1119, 0.3896 },   -- Karte 221
        { "blackfathom_deeps", "gelihast", 1, 0.5433, 0.5642 },   -- Karte 221
        { "blackfathom_deeps", "old_serrakis", 3, 0.5866, 0.3090 },   -- Karte 223
        { "blackfathom_deeps", "twilight_lord_kelris", 2, 0.5239, 0.8082 },   -- Karte 222
        { "blackfathom_deeps", "akumai", 2, 0.8552, 0.8642 },   -- Karte 222
    },
    [70] = {
        { "uldaman", "revelosh", 1, 0.5342, 0.7254 },   -- Karte 230
        { "uldaman", "the_lost_dwarves", 1, 0.5847, 0.9201 },   -- Karte 230
        { "uldaman", "ironaya", 1, 0.3730, 0.7398 },   -- Karte 230
        { "uldaman", "ancient_stone_keeper", 1, 0.4754, 0.4406 },   -- Karte 230
        { "uldaman", "galgann", 1, 0.2678, 0.3279 },   -- Karte 230
        { "uldaman", "grimlok", 1, 0.2199, 0.2561 },   -- Karte 230
        { "uldaman", "archaedas", 2, 0.5533, 0.5041 },   -- Karte 231
    },
    [90] = {
        { "gnomeregan", "grubbis", 1, 0.7787, 0.6701 },   -- Karte 226
        { "gnomeregan", "viscous_fallout", 2, 0.7596, 0.4652 },   -- Karte 227
        { "gnomeregan", "electrocutioner", 2, 0.2432, 0.6844 },   -- Karte 227
        { "gnomeregan", "crowd_pummeler", 3, 0.4317, 0.8832 },   -- Karte 228
        { "gnomeregan", "thermaplugg", 4, 0.3115, 0.3033 },   -- Karte 229
    },
    [109] = {
        { "sunken_temple", "jammalan", 1, 0.7609, 0.4590 },   -- Karte 220
        { "sunken_temple", "eranikus", 1, 0.6708, 0.8770 },   -- Karte 220
        { "sunken_temple", "avatar_of_hakkar", 1, 0.2432, 0.4590 },   -- Karte 220
    },
    [129] = {
        { "razorfen_downs", "tutenkash", 1, 0.5943, 0.3402 },   -- Karte 300
        { "razorfen_downs", "mordresh", 1, 0.8607, 0.4672 },   -- Karte 300
        { "razorfen_downs", "glutton", 1, 0.3429, 0.6680 },   -- Karte 300
        { "razorfen_downs", "amnennar", 1, 0.4454, 0.6045 },   -- Karte 300
    },
    [209] = {
        { "zulfarrak", "antusul", 1, 0.6462, 0.2766 },   -- Karte 219
        { "zulfarrak", "theka", 1, 0.5314, 0.2623 },   -- Karte 219
        { "zulfarrak", "zumrah", 1, 0.4426, 0.1762 },   -- Karte 219
        { "zulfarrak", "nekrum", 1, 0.2964, 0.1742 },   -- Karte 219
        { "zulfarrak", "sezzziz", 1, 0.2964, 0.1742 },   -- Karte 219
        { "zulfarrak", "ukorz", 1, 0.4221, 0.3299 },   -- Karte 219
        { "zulfarrak", "gahzrilla", 1, 0.2809, 0.3828 },   -- Karte 219
    },
    [229] = {
        { "lower_blackrock_spire", "highlord_omokk", 3, 0.3866, 0.5902 },   -- Karte 252
        { "lower_blackrock_spire", "shadow_hunter_voshgajin", 2, 0.5533, 0.6926 },   -- Karte 251
        { "lower_blackrock_spire", "war_master_voone", 1, 0.5246, 0.5451 },   -- Karte 250
        { "lower_blackrock_spire", "urok_doomhowl", 4, 0.4549, 0.5574 },   -- Karte 253
        { "lower_blackrock_spire", "mother_smolderweb", 2, 0.6207, 0.7414 },   -- Karte 251
        { "lower_blackrock_spire", "quartermaster_zigris", 5, 0.5396, 0.8443 },   -- Karte 254
        { "lower_blackrock_spire", "halycon", 5, 0.3798, 0.8402 },   -- Karte 254
        { "lower_blackrock_spire", "gizrul", 5, 0.3948, 0.7930 },   -- Karte 254
        { "lower_blackrock_spire", "overlord_wyrmthalak", 6, 0.5751, 0.6004 },   -- Karte 255
        { "upper_blackrock_spire", "pyroguard_emberseer", 6, 0.3033, 0.2664 },   -- Karte 255
        { "upper_blackrock_spire", "solakar_flamewreath", 6, 0.3661, 0.3811 },   -- Karte 255
    },
    [230] = {
        { "blackrock_depths", "lord_roccor", 1, 0.5560, 0.6701 },   -- Karte 242
        { "blackrock_depths", "high_interrogator_gerstahn", 1, 0.4740, 0.9221 },   -- Karte 242
        { "blackrock_depths", "houndmaster_grebmar", 1, 0.5350, 0.5735 },   -- Karte 242
        { "blackrock_depths", "ring_of_law", 1, 0.4978, 0.6458 },   -- Karte 242
        { "blackrock_depths", "theldren", 1, 0.4978, 0.6458 },   -- Karte 242
        { "blackrock_depths", "pyromancer_loregrain", 2, 0.5492, 0.9488 },   -- Karte 243
        { "blackrock_depths", "golem_lord_argelmach", 2, 0.3648, 0.6516 },   -- Karte 243
        { "blackrock_depths", "hurley_blackbreath", 2, 0.5057, 0.7048 },   -- Karte 243
        { "blackrock_depths", "phalanx", 2, 0.4582, 0.5647 },   -- Karte 243
        { "blackrock_depths", "ribbly_screwspigot", 2, 0.5255, 0.6254 },   -- Karte 243
        { "blackrock_depths", "plugger_spazzring", 2, 0.4772, 0.6571 },   -- Karte 243
        { "blackrock_depths", "lord_incendius", 1, 0.5642, 0.3115 },   -- Karte 242
        { "blackrock_depths", "warder_stilgiss", 2, 0.6025, 0.6598 },   -- Karte 243
        { "blackrock_depths", "fineous_darkvire", 1, 0.6352, 0.2111 },   -- Karte 242
        { "blackrock_depths", "baelgar", 1, 0.2514, 0.5348 },   -- Karte 242
        { "blackrock_depths", "general_angerforge", 2, 0.3634, 0.8238 },   -- Karte 243
        { "blackrock_depths", "ambassador_flamelash", 2, 0.5383, 0.4857 },   -- Karte 243
        { "blackrock_depths", "the_seven", 2, 0.5383, 0.2480 },   -- Karte 243
        { "blackrock_depths", "magmus", 2, 0.7964, 0.1189 },   -- Karte 243
        { "blackrock_depths", "dagran_thaurissan", 2, 0.9098, 0.1189 },   -- Karte 243
    },
    [289] = {
        { "scholomance", "jandice_barov", 2, 0.5997, 0.1831 },   -- Karte 477
        { "scholomance", "rattlegore", 2, 0.4844, 0.2618 },   -- Karte 477
        { "scholomance", "darkmaster_gandling", 4, 0.5011, 0.3262 },   -- Karte 479
    },
    [329] = {
        { "stratholme", "hearthsinger_forresten", 1, 0.6052, 0.3135 },   -- Karte 317
        { "stratholme", "the_unforgiven", 1, 0.7350, 0.2049 },   -- Karte 317
        { "stratholme", "timmy_the_cruel", 1, 0.5000, 0.1783 },   -- Karte 317
        { "stratholme", "malor_the_zealous", 1, 0.2993, 0.4119 },   -- Karte 317
        { "stratholme", "cannon_master_willey", 1, 0.0478, 0.5061 },   -- Karte 317
        { "stratholme", "archivist_galford", 1, 0.2773, 0.7541 },   -- Karte 317
        { "stratholme", "balnazzar", 1, 0.2049, 0.8217 },   -- Karte 317
        { "stratholme", "postmaster_malown", 1, 0.5581, 0.6841 },   -- Karte 317
        { "stratholme", "baroness_anastari", 2, 0.7459, 0.4693 },   -- Karte 318
        { "stratholme", "nerubenkan", 2, 0.5724, 0.4611 },   -- Karte 318
        { "stratholme", "maleki_the_pallid", 2, 0.6749, 0.2275 },   -- Karte 318
        { "stratholme", "magistrate_barthilas", 2, 0.5669, 0.1619 },   -- Karte 318
        { "stratholme", "ramstein", 2, 0.4563, 0.1988 },   -- Karte 318
        { "stratholme", "baron_rivendare", 2, 0.3866, 0.2008 },   -- Karte 318
    },
    [349] = {
        { "maraudon", "noxxion", 1, 0.3620, 0.0984 },   -- Karte 280
        { "maraudon", "razorlash", 1, 0.1667, 0.3443 },   -- Karte 280
        { "maraudon", "lord_vyletongue", 1, 0.3784, 0.7049 },   -- Karte 280
        { "maraudon", "tinkerer_gizlock", 1, 0.5096, 0.5307 },   -- Karte 280
        { "maraudon", "celebras", 2, 0.2459, 0.1434 },   -- Karte 281
        { "maraudon", "landslide", 2, 0.4085, 0.4877 },   -- Karte 281
        { "maraudon", "rotgrip", 2, 0.4139, 0.8176 },   -- Karte 281
        { "maraudon", "princess_theradras", 2, 0.2582, 0.7889 },   -- Karte 281
    },
    [429] = {
        { "dire_maul", "zevrim_thornhoof", 6, 0.5751, 0.7439 },   -- Karte 240
        { "dire_maul", "hydrospawn", 6, 0.5369, 0.7152 },   -- Karte 240
        { "dire_maul", "lethtendris", 5, 0.4385, 0.4816 },   -- Karte 239
        { "dire_maul", "alzzin", 6, 0.5669, 0.2889 },   -- Karte 240
        { "dire_maul", "tendris_warpwood", 2, 0.3361, 0.5369 },   -- Karte 236
        { "dire_maul", "illyanna_ravenoak", 2, 0.2036, 0.7766 },   -- Karte 236
        { "dire_maul", "magister_kalendris", 3, 0.3388, 0.4508 },   -- Karte 237
        { "dire_maul", "immolthar", 4, 0.3497, 0.5758 },   -- Karte 238
        { "dire_maul", "prince_tortheldrin", 4, 0.6230, 0.2316 },   -- Karte 238
        { "dire_maul", "guard_moldar", 1, 0.6954, 0.7602 },   -- Karte 235
        { "dire_maul", "stomper_kreeg", 1, 0.6120, 0.6926 },   -- Karte 235
        { "dire_maul", "guard_fengus", 1, 0.4945, 0.7807 },   -- Karte 235
        { "dire_maul", "guard_slipkik", 1, 0.2664, 0.5717 },   -- Karte 235
        { "dire_maul", "captain_kromcrush", 1, 0.3183, 0.5061 },   -- Karte 235
        { "dire_maul", "king_gordok", 1, 0.3195, 0.2295 },   -- Karte 235
    },
}
