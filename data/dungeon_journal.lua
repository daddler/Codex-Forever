--------------------------------------------------
-- WeintCodex :: Dungeon-Journal - Beute und Quests
--------------------------------------------------
-- Seit 6.5.0.0: je Boss die Beute, je Dungeon die Quests, fuer die
-- sieben Dungeons, zu denen Beta-Berichte vorliegen (Hall of Thanes,
-- Ragefire Chasm, Wailing Caverns, Ruins of Lordaeron, The Deadmines,
-- Shadowfang Keep, Blackfathom Deeps).
--
-- HERKUNFT: `community`, wie die Bosslisten der Forever-Dungeons.
-- Zusammengetragen aus oeffentlichen Beta-Berichten (wowforevertalents,
-- foreverchanges, Wowhead Forever, Stand 22.-25.09.2026) - NICHT aus dem
-- Client gelesen. Die Beute mischt beobachtete Forever-Gegenstaende mit
-- aus Classic uebernommenen Zuordnungen; welche welche ist, sagen die
-- Berichte nicht je Gegenstand. Deshalb steht keine Dropchance da und
-- kein Wert eines Gegenstands: den nennt der Client selbst (Tooltip).
--
-- NAMEN: englisch, wie die Boss- und Dungeonnamen dieses Addons. Im
-- Spiel zeigt die Seite den Namen, den der Client liefert (Gegenstand:
-- C_Item/GetItemInfo, Quest: C_QuestLog.GetTitleForQuestID), sobald er
-- ihn kennt - der englische ist nur der Rueckfall. Die Texte (Geber,
-- Ziel, Hinweise) sind Deutsch; Orte mit belegtem deutschem Namen
-- stehen deutsch, Unterorte und NPC englisch.
--
-- ERFAHRUNG (`xp`) ist ein BEOBACHTETER Beta-Wert, keine Angabe des
-- Clients. Blizzard stimmt sie waehrend der Beta nach; fragt der Client
-- die Belohnung selbst heraus, gilt seine Zahl.
--
-- Beute:  { itemID, Name, Platz, Qualitaet, from = Gegner (optional) }
--   `from` steht, wo der Gegner des Berichts kein eigener Boss dieses
--   Addons ist (Sneed springt aus Sneed's Shredder, derselbe Kampf).
-- others: Beute von Gegnern ohne eigenen Boss hier (Fel Steed, Arugal's
--   Voidwalker in Shadowfang Keep).
-- Quest:  id, name, level, requires, faction (both/alliance/horde),
--   class (optional), giver, objective, turnin, xp, money (Kupfer),
--   reputation { {Fraktion, Wert} }, choice, rewards { {id, Name, Q} },
--   startItem { id, Name }, followRewards { {id, Name} }, note.
--
-- Kein Gegenstand, keine Quest ohne Nummer: `data_test.lua` prueft,
-- dass jede Beute an einem Boss haengt, den es in data/dungeons*.lua
-- gibt, und dass jede Nummer eine ganze Zahl ist.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.DungeonJournal = {}

local J = WeintCodex.DungeonJournal

J.SOURCE = {
    kind  = "community",
    date  = "25.09.2026",
    label = "Beta-Berichte der Community (Beute und Quests)",
}

J.DATA = {
    hall_of_thanes = {
        loot = {
            faldrim_anvilmar = {
                { 270227, "Ephemeral Choker", "Hals", 3 },
                { 271096, "Aetherwisp Bracers", "Handgelenke, Stoff", 3 },
                { 271097, "Spiritwraith Drape", "Rücken, Stoff", 3 },
            },
            magmatus = {
                { 270230, "Kindlegem Girdle", "Taille, Schwere Rüstung", 3 },
                { 270231, "Flamefist Grips", "Hände, Leder", 3 },
                { 271095, "Fang of Magmatus", "Waffenhand, Dolch", 3 },
            },
            plunder = {
                { 270228, "Golemheart Stave", "Zweihändig, Stab", 3 },
                { 271098, "Golemguard Chest", "Brust, Schwere Rüstung", 3 },
                { 270229, "Treads of the Protector Golem", "Füße, Schwere Rüstung", 3 },
            },
            durgen_dirgehammer = {
                { 270256, "Durgen's Crescent Axe", "Waffenhand, Axt", 3 },
                { 270260, "Direhammer Leggings", "Beine, Leder", 3 },
                { 270261, "Robes of the Disgraced Thane", "Brust, Stoff", 3 },
                { 274286, "Durgen Dirgehammer's Head", "Questgegenstand", 1 },
            },
        },
        quests = {
            {
                id = 96395, name = "An Ancient Grudge", level = 15, requires = 10, faction = "both",
                giver = "Ghostly Attendant, in der Hall of Thanes nach dem ersten Raum",
                objective = "Den Geist von Faldrim Anvilmar zur Ruhe betten.",
                turnin = "Ghostly Attendant, im Dungeon",
                xp = 3570,
                choice = true,
                rewards = { { 279899, "Catacomb Cloak", 3 }, { 279900, "Deepgrave Trousers", 3 } },
            },
            {
                id = 96403, name = "Important Heirlooms", level = 15, requires = 10, faction = "both",
                giver = "Thom Filch, an der Brücke / am Eingang zum Gewölbe in Eisenschmiede",
                objective = "8 Zwergische Erbstücke aus der Hall of Thanes sammeln.",
                turnin = "Thom Filch, am Eingang des Dungeons",
                xp = 4590,
                money = 700,
                reputation = { { "Gadgetzan", 100 } },
                choice = true,
                rewards = { { 279898, "Dwarven Tome", 3 }, { 280096, "Tomb Robber's Gloves", 3 } },
            },
            {
                id = 96394, name = "The Restless Dead", level = 15, requires = 10, faction = "alliance",
                giver = "Afadra Dunwall, Eisenschmiede",
                objective = "15 Enraged Apparitions und 10 Tormented Souls töten, danach Anvilmars Geist zur Ruhe betten.",
                turnin = "Afadra Dunwall, Eisenschmiede",
                xp = 3570,
                money = 700,
                reputation = { { "Eisenschmiede", 100 } },
                choice = true,
                rewards = { { 279897, "Dusty Belt", 3 }, { 280095, "Cryptwalker Bracers", 3 } },
            },
            {
                id = 96393, name = "Old Ironforge Incursion", level = 16, requires = 9, faction = "alliance",
                giver = "Earthseer Farsen, Dun Morogh (nach „Underground Map“)",
                objective = "In die Hall of Thanes gehen und den Kopf von Durgen Dirgehammer holen.",
                turnin = "König Magni Bronzebart, Eisenschmiede",
                xp = 4930,
                money = 800,
                reputation = { { "Eisenschmiede", 100 }, { "Gnomeregangnome", 100 } },
                choice = true,
                rewards = { { 279894, "Calibrated Blunderbuss", 3 }, { 279895, "Ironforge Greathammer", 3 }, { 279896, "Deepblaze", 3 } },
                startItem = { 274268, "Dark Iron Map" },
                note = "Die Reihe beginnt mit der Dark Iron Map, Beute von Dark Iron Spies bei Ironband's Compound in Dun Morogh (um 76; 61).",
            },
            {
                id = 98423, name = "The Treaty of Understanding", level = 16, requires = 9, faction = "alliance",
                giver = "Steintafel in einem Gewölbe der Reliquary of Kings (Raum von Durgen Dirgehammer)",
                objective = "Den Vertrag der Verständigung zu Magni Bronzebart in Eisenschmiede bringen.",
                turnin = "König Magni Bronzebart, Eisenschmiede",
                xp = 3900,
                money = 1600,
                reputation = { { "Eisenschmiede", 100 }, { "Gnomeregangnome", 100 } },
                note = "Die Tafel liegt in einem der Gewölbe im Raum des letzten Bosses. Gewölbe öffnen und die Tafel benutzen, bevor ihr den Dungeon verlasst.",
            },
        },
    },
    ragefire_chasm = {
        loot = {
            oggleflint = {
                { 272999, "Barbaric Crossbow", "Distanz, Armbrust", 3 },
                { 272996, "Trogg Scepter", "Waffenhand, Streitkolben", 3 },
                { 272998, "Bone Knuckles", "Waffenhand, Faustwaffe", 3 },
            },
            taragaman = {
                { 14149, "Subterranean Cape", "Rücken, Stoff", 3 },
                { 14148, "Crystalline Cuffs", "Handgelenke, Stoff", 3 },
                { 14145, "Cursed Felblade", "Waffenhand, Schwert", 3 },
            },
            jergosh = {
                { 14150, "Robe of Evocation", "Brust, Stoff", 3 },
                { 14147, "Cavedweller Bracers", "Handgelenke, Schwere Rüstung", 3 },
                { 14151, "Chanting Blade", "Einhändig, Dolch", 3 },
            },
            bazzalan = {
                { 273003, "Searing Dagger", "Waffenhand, Dolch", 3 },
                { 273007, "Chasm Walkers", "Füße, Leder", 3 },
                { 273005, "Satyrskin Cloak", "Rücken, Stoff", 3 },
            },
        },
        quests = {
            {
                id = 5723, name = "Testing an Enemy's Strength", level = 15, requires = 9, faction = "horde",
                giver = "Rahauro, Anhöhe der Ältesten, Donnerfels",
                objective = "Je 8 Ragefire Troggs und Ragefire Shamans in Ragefire Chasm töten.",
                turnin = "Rahauro, Anhöhe der Ältesten, Donnerfels",
                xp = 3202,
                money = 700,
                reputation = { { "Donnerfels", 100 } },
            },
            {
                id = 5722, name = "Searching for the Lost Satchel", level = 16, requires = 9, faction = "horde",
                giver = "Rahauro, Anhöhe der Ältesten, Donnerfels",
                objective = "Die Leiche von Maur Grimtotem in Ragefire Chasm finden und durchsuchen.",
                turnin = "An der Leiche von Maur Grimtotem",
                xp = 880,
                note = "Von der ersten großen Dreierkreuzung den rechten Gang nehmen, bergauf bis kurz vor die Sackgasse, dann links in den kleinen Seitenraum.",
            },
            {
                id = 5724, name = "Returning the Lost Satchel", level = 16, requires = 9, faction = "horde",
                giver = "Grimtotem-Tasche von der Leiche Maur Grimtotems in Ragefire Chasm",
                objective = "Die Grimtotem-Tasche zu Rahauro nach Donnerfels bringen.",
                turnin = "Rahauro, Anhöhe der Ältesten, Donnerfels",
                xp = 4422,
                reputation = { { "Donnerfels", 150 } },
                choice = true,
                rewards = { { 15452, "Featherbead Bracers", 3 }, { 15453, "Savannah Bracers", 3 }, { 270003, "Garrison Cuffs", 3 } },
            },
            {
                id = 5728, name = "Hidden Enemies", level = 16, requires = 9, faction = "horde",
                giver = "Thrall, Tal der Weisheit, Orgrimmar",
                objective = "Bazzalan und Jergosh the Invoker in Ragefire Chasm töten.",
                turnin = "Thrall, Tal der Weisheit, Orgrimmar",
                xp = 3507,
                money = 800,
                reputation = { { "Orgrimmar", 100 } },
                followRewards = { { 15443, "Kris of Orgrimmar" }, { 15445, "Hammer of Orgrimmar" }, { 15424, "Axe of Orgrimmar" }, { 15444, "Staff of Orgrimmar" } },
                note = "Setzt die früheren Schritte von „Hidden Enemies“ in Orgrimmar voraus. Der nächste Schritt bietet später:",
            },
            {
                id = 5761, name = "Slaying the Beast", level = 16, requires = 9, faction = "horde",
                giver = "Neeru Fireblade, Kluft der Schatten, Orgrimmar",
                objective = "Taragaman the Hungerer töten und sein Herz bergen.",
                turnin = "Neeru Fireblade, Kluft der Schatten, Orgrimmar",
                xp = 3507,
                money = 800,
            },
            {
                id = 5725, name = "The Power to Destroy...", level = 16, requires = 9, faction = "horde",
                giver = "Varimathras, Königsviertel, Unterstadt",
                objective = "Zauber der Schatten und Beschwörungen aus dem Nether in Ragefire Chasm sammeln.",
                turnin = "Varimathras, Königsviertel, Unterstadt",
                xp = 4422,
                reputation = { { "Unterstadt", 150 } },
                choice = true,
                rewards = { { 15449, "Ghastly Trousers", 3 }, { 15450, "Dredgemire Leggings", 3 }, { 15451, "Gargoyle Leggings", 3 } },
            },
        },
    },
    wailing_caverns = {
        loot = {
            lord_cobrahn = {
                { 6460, "Cobrahn's Grasp", "Taille, Schwere Rüstung", 3 },
                { 10410, "Leggings of the Fang", "Beine, Leder", 3 },
                { 6465, "Robe of the Moccasin", "Brust, Stoff", 3 },
            },
            lady_anacondra = {
                { 10412, "Belt of the Fang", "Taille, Leder", 3 },
                { 5404, "Serpent's Shoulders", "Schulter, Leder", 3 },
                { 6446, "Snakeskin Bag", "Tasche", 2 },
                { 273088, "Snake Eye Kaleidoscope", "Hals", 3 },
            },
            kresh = {
                { 13245, "Kresh's Back", "Schildhand, Schild", 3 },
                { 6447, "Worn Turtle Shell Shield", "Schildhand, Schild", 3 },
                { 273084, "Cloak of Hermitic Bliss", "Rücken, Stoff", 3 },
            },
            lord_pythas = {
                { 6472, "Stinging Viper", "Einhändig, Streitkolben", 3 },
                { 6473, "Armor of the Fang", "Brust, Leder", 3 },
                { 273089, "Slither Cord", "Taille, Stoff", 3 },
            },
            skum = {
                { 6449, "Glowing Lizardscale Cloak", "Rücken, Stoff", 3 },
                { 6448, "Tail Spike", "Einhändig, Dolch", 3 },
                { 273137, "Skum's Bucket", "In Schildhand geführt", 3 },
            },
            lord_serpentis = {
                { 6469, "Venomstrike", "Distanz, Bogen", 3 },
                { 5970, "Serpent Gloves", "Hände, Stoff", 2 },
                { 10411, "Footpads of the Fang", "Füße, Leder", 3 },
                { 6459, "Savage Trodders", "Füße, Schwere Rüstung", 3 },
            },
            verdan = {
                { 6630, "Seedcloud Buckler", "Schildhand, Schild", 3 },
                { 6631, "Living Root", "Zweihändig, Stab", 3 },
                { 6629, "Sporid Cape", "Rücken, Stoff", 2 },
            },
            mutanus = {
                { 6461, "Slime-encrusted Pads", "Schulter, Stoff", 3 },
                { 6627, "Mutant Scale Breastplate", "Brust, Schwere Rüstung", 3 },
                { 6463, "Deep Fathom Ring", "Finger", 3 },
                { 10441, "Glowing Shard", "Questgegenstand", 1 },
            },
            deviate_faerie_dragon = {
                { 5243, "Firebelcher", "Distanz, Zauberstab", 3 },
                { 6632, "Feyscale Cloak", "Rücken, Stoff", 3 },
            },
        },
        quests = {
            {
                id = 1486, name = "Deviate Hides", level = 17, requires = 13, faction = "both",
                giver = "Nalpak, über dem Eingang von Wailing Caverns, Brachland",
                objective = "20 Deviathäute zu Nalpak bringen.",
                turnin = "Nalpak, über dem Eingang von Wailing Caverns, Brachland",
                xp = 4640,
                money = 1800,
                choice = true,
                rewards = { { 6480, "Slick Deviate Leggings", 2 }, { 918, "Deviate Hide Pack", 1 } },
            },
            {
                id = 1491, name = "Smart Drinks", level = 18, requires = 13, faction = "both",
                giver = "Mebok Mizzyrix, Ratschet, Brachland",
                objective = "6 Wehklagensessenzen zu Mebok Mizzyrix bringen.",
                turnin = "Mebok Mizzyrix, Ratschet, Brachland",
                xp = 3915,
                money = 1000,
            },
            {
                id = 959, name = "Trouble at the Docks", level = 18, requires = 14, faction = "both",
                giver = "Crane Operator Bigglefuzz, Ratschet, Brachland",
                objective = "Den 99 Jahre alten Portwein von Mad Magglish in Wailing Caverns holen.",
                turnin = "Crane Operator Bigglefuzz, Ratschet, Brachland",
                xp = 3915,
                money = 1000,
            },
            {
                id = 1487, name = "Deviate Eradication", level = 21, requires = 15, faction = "both",
                giver = "Ebru, über dem Eingang von Wailing Caverns, Brachland",
                objective = "Je 7 Deviate Ravagers, Deviate Vipers, Deviate Shamblers und Deviate Dreadfangs töten.",
                turnin = "Ebru, über dem Eingang von Wailing Caverns, Brachland",
                xp = 5945,
                money = 2500,
                choice = true,
                rewards = { { 6476, "Pattern: Deviate Scale Belt", 2 }, { 8071, "Sizzle Stick", 2 }, { 6481, "Dagmire Gauntlets", 2 } },
            },
            {
                id = 6981, name = "The Glowing Shard", level = 26, requires = 15, faction = "both",
                giver = "Gegenstand: Glowing Shard, Beute von Mutanus the Devourer",
                objective = "In Ratschet jemanden finden, der die Scherbe deuten kann, und sie wie angewiesen abgeben.",
                turnin = "Den Anweisungen der Quest ab Ratschet folgen",
                xp = 7685,
                startItem = { 10441, "Glowing Shard" },
                followRewards = { { 10657, "Talbar Mantle" }, { 10658, "Quagmire Galoshes" } },
                note = "Die Quest selbst hat keine Gegenstandsbelohnung. Die Folgequest „In Nightmares“ bietet später:",
            },
            {
                id = 914, name = "Leaders of the Fang", level = 22, requires = 10, faction = "horde",
                giver = "Nara Wildmane, Donnerfels",
                objective = "Die Edelsteine von Cobrahn, Anacondra, Pythas und Serpentis zu Nara Wildmane bringen.",
                turnin = "Nara Wildmane, Donnerfels",
                xp = 6380,
                reputation = { { "Donnerfels", 150 } },
                choice = true,
                rewards = { { 6505, "Crescent Staff", 3 }, { 6504, "Wingblade", 3 }, { 270018, "Hammerbone", 3 } },
                note = "Setzt die Oasen-Reihe im Brachland voraus: The Barrens Oases, The Forgotten Pools, The Stagnant Oasis und Altered Beings, dann Hamuul Runetotem und Nara Wildmane.",
            },
            {
                id = 962, name = "Serpentbloom", level = 18, requires = 14, faction = "horde",
                giver = "Apothecary Zamah, Teiche der Visionen, Donnerfels",
                objective = "10 Schlangenflaum aus den Höhlen des Wehklagens sammeln.",
                turnin = "Apothecary Zamah, Donnerfels",
                xp = 4930,
                money = 1000,
                choice = true,
                rewards = { { 10919, "Apothecary Gloves", 2 }, { 270008, "Heat Resistant Mitts", 2 }, { 270009, "Safety Boots", 2 } },
            },
        },
    },
    ruins_of_lordaeron = {
        loot = {
            the_butcher = {
                { 271204, "Meathook Slicer", "Einhändig, Dolch", 3 },
                { 271205, "Abomination Bones", "Brust, Schwere Rüstung", 3 },
                { 271206, "Leftover Abomination Skin", "Brust, Stoff", 3 },
            },
            witherfang = {
                { 271201, "Atrophic Girdle", "Taille, Schwere Rüstung", 3 },
                { 271202, "Witherbite Bracers", "Handgelenke, Leder", 3 },
                { 271203, "Segmented Spider Leg", "Zweihändig, Stab", 3 },
            },
            the_abandoned = {
                { 271207, "Wispcloth Leggings", "Beine, Stoff", 3 },
                { 271208, "Grip of Fear", "Hände, Schwere Rüstung", 3 },
                { 271216, "Scepter of the Abandoned", "Waffenhand, Streitkolben", 3 },
            },
            bjork = {
                { 271209, "Bonerust Leggings", "Beine, Schwere Rüstung", 3 },
                { 271210, "Tuskwrap Belt", "Taille, Stoff", 3 },
                { 271217, "Corpse Chopper", "Zweihändig, Axt", 3 },
            },
            rathmael = {
                { 271213, "Mirror of Rath'mael", "Schildhand, Schild", 3 },
                { 271214, "Frostbane Treads", "Füße, Stoff", 3 },
                { 271215, "Coldspire Staff", "Zweihändig, Stab", 3 },
            },
            viktor_the_vile = {
                { 271211, "Vilewalkers", "Füße, Schwere Rüstung", 3 },
                { 271212, "Bloodied Chestwraps", "Brust, Leder", 3 },
                { 271218, "Vileblood Scimitar", "Einhändig, Schwert", 3 },
            },
            lordaeron_captain = {
                { 6641, "Haunting Blade", "Zweihändig, Schwert", 3 },
                { 6642, "Phantom Armor", "Brust, Schwere Rüstung", 3 },
            },
        },
        quests = {
            {
                id = 95250, name = "Abominable Creatures", level = 21, requires = 16, faction = "alliance",
                giver = "Captain Truman, gleich hinter dem Eingang der Ruins of Lordaeron (links)",
                objective = "Den Kopf des Barons aus den Ruins of Lordaeron holen.",
                turnin = "Captain Truman, gleich hinter dem Eingang",
                xp = 6188,
                choice = true,
                rewards = { { 279864, "Monstrous Cleaver", 3 }, { 279865, "Grave Shroud", 3 }, { 279867, "Slain Baron's Signet", 3 } },
            },
            {
                id = 97288, name = "Unending Torment", level = 21, requires = 16, faction = "horde",
                giver = "Gegenstand: Abominable Head, in den Ruins of Lordaeron",
                objective = "Den Kopf in die Unterstadt bringen.",
                turnin = "Meisterapotheker Faranell, Unterstadt",
                xp = 5300,
                choice = true,
                rewards = { { 279864, "Monstrous Cleaver", 3 }, { 279865, "Grave Shroud", 3 }, { 279867, "Slain Baron's Signet", 3 } },
                startItem = { 280438, "Abominable Head" },
                note = "Die Belohnung zur Auswahl gibt es beim folgenden Schritt in der Unterstadt.",
            },
            {
                id = 92401, name = "A Frightened Request", level = 22, requires = 15, faction = "horde",
                giver = "Tabitha Heartweaver, Das Grabmal, Silberwald",
                objective = "Dem Verschwinden von Edward Heartweaver in den Ruins of Lordaeron nachgehen.",
                turnin = "Tabitha Heartweaver, Das Grabmal, Silberwald",
                xp = 7040,
                reputation = { { "Unterstadt", 150 } },
                choice = true,
                rewards = { { 251485, "Edwards' Knife", 3 }, { 251486, "Tabitha's Cuffs", 3 } },
            },
            {
                id = 95195, name = "Bloodied Insignia", level = 22, requires = 16, faction = "alliance",
                giver = "Gegenstand: Bloodied Insignia, in den Ruins of Lordaeron",
                objective = "10 blutbefleckte Abzeichen sammeln.",
                turnin = "General Marcus Jonathan, Sturmwind",
                xp = 9750,
                money = 4500,
                choice = true,
                rewards = { { 279868, "Duty Bound Leggings", 3 }, { 279869, "Remembrance Armor", 3 } },
                startItem = { 268535, "Bloodied Insignia" },
            },
            {
                id = 95189, name = "Crest of Lordaeron", level = 22, requires = 16, faction = "alliance",
                giver = "Gegenstand: Crest of Lordaeron, in den Ruins of Lordaeron",
                objective = "Das Wappen von Lordaeron nach Sturmwind bringen.",
                turnin = "Lady Dena Kennedy, Sturmwind",
                xp = 9750,
                choice = false,
                rewards = { { 280567, "Small Sack of Gems", 1 } },
                startItem = { 268579, "Crest of Lordaeron" },
                note = "Das Wappen erscheint an einer von mehreren Stellen im Dungeon; berichtet sind obere Turmböden, Seiten- und Gruftkammern nahe The Baron und die Gegend um Bjork.",
            },
            {
                id = 95204, name = "Crest of Lordaeron", level = 22, requires = 16, faction = "horde",
                giver = "Gegenstand: Crest of Lordaeron, in den Ruins of Lordaeron",
                objective = "Das Wappen von Lordaeron in die Unterstadt bringen.",
                turnin = "Oran Snakewrithe, Unterstadt",
                xp = 8320,
                choice = false,
                rewards = { { 280567, "Small Sack of Gems", 1 } },
                startItem = { 268579, "Crest of Lordaeron" },
                note = "Das Wappen erscheint an einer von mehreren Stellen im Dungeon; berichtet sind obere Turmböden, Seiten- und Gruftkammern nahe The Baron und die Gegend um Bjork.",
            },
            {
                id = 92421, name = "Light's Justice", level = 22, requires = 15, faction = "horde",
                giver = "Morbin Lightbane, Unterstadt",
                objective = "25 unversehrte Gliedmaßen in den Ruins of Lordaeron sammeln.",
                turnin = "Morbin Lightbane, Unterstadt",
                xp = 7040,
                money = 4500,
                reputation = { { "Unterstadt", 150 } },
                choice = true,
                rewards = { { 279874, "The Stitcher", 3 }, { 279875, "Spare Part Bindings", 3 } },
            },
            {
                id = 92415, name = "Remember That I Love You", level = 22, requires = 15, faction = "alliance",
                giver = "Gegenstand: Blood-Stained Letter, Friedhof in den Ruins of Lordaeron",
                objective = "Den blutbefleckten Brief zu Waisenmatrone Nightingale bringen.",
                turnin = "Waisenmatrone Nightingale, Sturmwind",
                xp = 9750,
                choice = false,
                rewards = { { 279870, "Tarnished Locket", 3 } },
                startItem = { 251522, "Blood-Stained Letter" },
            },
            {
                id = 95216, name = "The New Plague", level = 22, requires = 16, faction = "horde",
                giver = "Theodore Griffs, Unterstadt",
                objective = "Den hochgiftigen Stamm von Witherfang holen.",
                turnin = "Theodore Griffs, Unterstadt",
                xp = 8320,
                choice = true,
                rewards = { { 279876, "Plaguefang", 3 }, { 279877, "Blight Gloves", 3 } },
            },
            {
                id = 92422, name = "The Wrath of Rath'mael", level = 22, requires = 15, faction = "horde",
                giver = "Deathguard Kristof, Brill, Tirisfal (65,2; 60,2)",
                objective = "Rath'mael in den Ruins of Lordaeron töten.",
                turnin = "Deathguard Kristof, Brill",
                reputation = { { "Unterstadt", 150 } },
                choice = true,
                rewards = { { 251533, "Forsaken Greataxe", 3 }, { 251534, "Gnarled Necromancer's Staff", 3 } },
            },
        },
    },
    the_deadmines = {
        loot = {
            rhahkzor = {
                { 872, "Rockslicer", "Zweihändig, Axt", 3 },
                { 5187, "Rhahk'Zor's Hammer", "Zweihändig, Streitkolben", 3 },
                { 273289, "Ogre Loincloth", "Beine, Stoff", 3 },
            },
            miner_johnson = {
                { 5443, "Gold-plated Buckler", "Schildhand, Schild", 3 },
                { 5444, "Miner's Cape", "Rücken, Stoff", 3 },
            },
            sneeds_shredder = {
                { 1937, "Buzz Saw", "Einhändig, Schwert", 3 },
                { 2169, "Buzzer Blade", "Waffenhand, Dolch", 3 },
                { 285292, "Dull Sawblade", "Wurfwaffe", 3 },
                { 5194, "Taskmaster Axe", "Zweihändig, Axt", 3, from = "Sneed" },
                { 5195, "Gold-flecked Gloves", "Hände, Stoff", 3, from = "Sneed" },
                { 273293, "Bandsaw Wristbands", "Handgelenke, Schwere Rüstung", 3, from = "Sneed" },
                { 273092, "Blueprint: Repair Bot", "Ingenieurskunst (Bauplan)", 2, from = "Sneed" },
            },
            gilnid = {
                { 1156, "Lavishly Jeweled Ring", "Finger", 3 },
                { 5199, "Smelting Pants", "Beine, Leder", 3 },
                { 273297, "Goblin Hammer", "Waffenhand, Streitkolben", 3 },
            },
            mr_smite = {
                { 7230, "Smite's Mighty Hammer", "Zweihändig, Streitkolben", 3 },
                { 5192, "Thief's Blade", "Einhändig, Schwert", 3 },
                { 5196, "Smite's Reaver", "Einhändig, Axt", 3 },
                { 284715, "First Mate Band", "Finger", 3 },
            },
            captain_greenskin = {
                { 5201, "Emberstone Staff", "Zweihändig, Stab", 3 },
                { 10403, "Blackened Defias Belt", "Taille, Leder", 3 },
                { 5200, "Impaling Harpoon", "Zweihändig, Stangenwaffe", 3 },
            },
            edwin_vancleef = {
                { 5193, "Cape of the Brotherhood", "Rücken, Stoff", 3 },
                { 5202, "Corsair's Overshirt", "Brust, Stoff", 3 },
                { 10399, "Blackened Defias Armor", "Brust, Leder", 3 },
                { 5191, "Cruel Barb", "Einhändig, Schwert", 3 },
                { 2874, "An Unsent Letter", "Questgegenstand", 1 },
            },
            cookie = {
                { 5198, "Cookie's Stirring Rod", "Distanz, Zauberstab", 3 },
                { 5197, "Cookie's Tenderizer", "Einhändig, Streitkolben", 3 },
                { 273298, "Lookie's Spyglass", "Schmuck", 3 },
            },
        },
        quests = {
            {
                id = 214, name = "Red Silk Bandanas", level = 17, requires = 14, faction = "alliance",
                giver = "Scout Riell, Turm der Späherkuppe, Westfall",
                objective = "10 rote Seidenbandanas von den Defias in The Deadmines sammeln.",
                turnin = "Scout Riell, Turm der Späherkuppe, Westfall",
                xp = 4688,
                reputation = { { "Sturmwind", 100 } },
                choice = true,
                rewards = { { 2074, "Solid Shortblade", 2 }, { 2089, "Scrimshaw Dagger", 2 }, { 6094, "Piercing Axe", 2 }, { 270005, "Monastic Hammer", 2 } },
                note = "Setzt den Begleitschritt der Reihe „The Defias Brotherhood“ voraus.",
            },
            {
                id = 168, name = "Collecting Memories", level = 18, requires = 14, faction = "alliance",
                giver = "Wilder Thistlenettle, Zwergendistrikt, Sturmwind",
                objective = "4 Karten der Bergarbeitergewerkschaft von untoten Bergarbeitern in den Stollen vor der Instanz sammeln.",
                turnin = "Wilder Thistlenettle, Sturmwind",
                xp = 1350,
                reputation = { { "Eisenschmiede", 100 } },
                choice = true,
                rewards = { { 2037, "Tunneler's Boots", 2 }, { 2036, "Dusty Mining Gloves", 2 }, { 270007, "Worn Miner's Waistcord", 2 } },
                note = "Der Seitenstollen mit den Untoten liegt vor dem Portal der Instanz.",
            },
            {
                id = 92753, name = "Destruction in Deadmines", level = 18, requires = 9, faction = "alliance",
                giver = "Gegenstand: Extra-Destructive Explosives benutzen",
                objective = "Den Sprengstoff neben der Schmiede in The Deadmines anbringen.",
                turnin = "Alba Fairmoon, Hügel hinter Mondbruch nahe dem Ausgang von The Deadmines",
                xp = 4050,
                reputation = { { "Sturmwind", 50 } },
                note = "Wie man den Sprengstoff bekommt, ist nicht bestätigt.",
            },
            {
                id = 167, name = "Oh Brother...", level = 20, requires = 15, faction = "alliance",
                giver = "Wilder Thistlenettle, Zwergendistrikt, Sturmwind",
                objective = "Thistlenettles Abzeichen von Foreman Thistlenettle im untoten Seitenstollen holen.",
                turnin = "Wilder Thistlenettle, Sturmwind",
                xp = 1550,
                reputation = { { "Eisenschmiede", 100 } },
                choice = true,
                rewards = { { 1893, "Miner's Revenge", 2 }, { 270012, "Miner's Workgloves", 2 }, { 270013, "Miner's Workboots", 2 } },
                note = "Der Vorarbeiter steht in den Stollen vor dem Portal der Instanz.",
            },
            {
                id = 2040, name = "Underground Assault", level = 20, requires = 15, faction = "alliance",
                giver = "Shoni the Shilent, Zwergendistrikt, Sturmwind",
                objective = "Den Gnoam-Sprecklesprocket aus Sneed's Shredder bergen.",
                turnin = "Shoni the Shilent, Sturmwind",
                xp = 5813,
                reputation = { { "Sturmwind", 100 }, { "Gnomeregangnome", 100 } },
                choice = true,
                rewards = { { 7606, "Polar Gauntlets", 2 }, { 7607, "Sable Wand", 2 }, { 270015, "Bravo's Armbands", 2 }, { 270016, "Dreamer's Leggings", 2 } },
                note = "Folgt auf „Speak with Shoni“.",
            },
            {
                id = 166, name = "The Defias Brotherhood", level = 22, requires = 14, faction = "alliance",
                giver = "Gryan Stoutmantle, Turm der Späherkuppe, Westfall (56,4; 47,5)",
                objective = "Edwin VanCleef besiegen und seinen Kopf holen.",
                turnin = "Gryan Stoutmantle, Späherkuppe, Westfall",
                xp = 9750,
                reputation = { { "Sturmwind", 200 } },
                choice = true,
                rewards = { { 6087, "Chausses of Westfall", 3 }, { 2041, "Tunic of Westfall", 3 }, { 2042, "Staff of Westfall", 3 } },
                note = "Letzter Schritt der Reihe „The Defias Brotherhood“ im Dungeon; die früheren Schritte zuerst erledigen.",
            },
            {
                id = 373, name = "The Unsent Letter", level = 22, requires = 16, faction = "alliance",
                giver = "Gegenstand: An Unsent Letter, Beute von Edwin VanCleef",
                objective = "Den Brief zum Stadtarchitekten nach Sturmwind bringen.",
                turnin = "Baros Alexston, Rathaus, Kathedralenplatz, Sturmwind",
                xp = 870,
                money = 700,
                reputation = { { "Sturmwind", 50 } },
                startItem = { 2874, "An Unsent Letter" },
                note = "Beginnt eine Folgereihe, die mit Bazil Thredd weitergeht.",
            },
        },
    },
    shadowfang_keep = {
        loot = {
            rethilgore = {
                { 5254, "Rugged Spaulders", "Schulter, Leder", 2 },
                { 273457, "Sorcerer Collar", "Hals", 3 },
                { 273456, "Cell Keeper's Claws", "Waffenhand, Faustwaffe", 3 },
            },
            razorclaw = {
                { 1292, "Butcher's Cleaver", "Einhändig, Axt", 3 },
                { 6226, "Bloody Apron", "Brust, Stoff", 3 },
                { 6633, "Butcher's Slicer", "Einhändig, Schwert", 3 },
            },
            baron_silverlaine = {
                { 6321, "Silverlaine's Family Seal", "Finger", 3 },
                { 6323, "Baron's Scepter", "Waffenhand, Streitkolben", 3 },
                { 273637, "Blade of Silverlaine", "Waffenhand, Schwert", 3 },
            },
            commander_springvale = {
                { 6320, "Commander's Crest", "Schildhand, Schild", 3 },
                { 3191, "Arced War Axe", "Zweihändig, Axt", 3 },
                { 273643, "Worgenbane Talisman", "Schmuck", 3 },
            },
            odo = {
                { 6318, "Odo's Ley Staff", "Zweihändig, Stab", 3 },
                { 6319, "Girdle of the Blindwatcher", "Taille, Leder", 3 },
                { 273645, "Blindwatcher's Sight", "Kopf", 3 },
            },
            deathsworn_captain = {
                { 6642, "Phantom Armor", "Brust, Schwere Rüstung", 3 },
                { 6641, "Haunting Blade", "Zweihändig, Schwert", 3 },
            },
            fenrus = {
                { 6340, "Fenrus' Hide", "Rücken, Stoff", 3 },
                { 3230, "Black Wolf Bracers", "Handgelenke, Leder", 3 },
                { 273646, "Half-Eaten Boots", "Füße, Schwere Rüstung", 3 },
            },
            wolf_master_nandos = {
                { 3748, "Feline Mantle", "Schulter, Stoff", 3 },
                { 6314, "Wolfmaster Cape", "Rücken, Stoff", 3 },
            },
            archmage_arugal = {
                { 6324, "Robes of Arugal", "Brust, Stoff", 3 },
                { 6392, "Belt of Arugal", "Taille, Stoff", 3 },
                { 6220, "Meteor Shard", "Einhändig, Dolch", 3 },
            },
        },
        others = {
            { name = "Fel Steed / Shadow Charger", items = {
                { 6341, "Eerie Stable Lantern", "In Schildhand geführt", 3 },
                { 932, "Fel Steed Saddlebags", "Tasche", 2 },
            } },
            { name = "Arugal's Voidwalker", items = {
                { 5943, "Rift Bracers", "Handgelenke, Schwere Rüstung", 3 },
            } },
        },
        quests = {
            {
                id = 1098, name = "Deathstalkers in Shadowfang", level = 25, requires = 18, faction = "horde",
                giver = "High Executor Hadrec, Das Grabmal, Silberwald",
                objective = "Deathstalker Adamant und Deathstalker Vincent in Shadowfang Keep finden.",
                turnin = "Deathstalker Vincent, in Shadowfang Keep",
                xp = 8700,
                money = 1800,
                reputation = { { "Unterstadt", 100 } },
                choice = true,
                rewards = { { 3324, "Ghostly Mantle", 3 }, { 270023, "Tanned Shoulderpads", 3 }, { 270024, "Bronzed Shoulderguards", 3 } },
            },
            {
                id = 1740, name = "The Orb of Soran'ruk", level = 25, requires = 20, faction = "both",
                class = "WARLOCK",
                giver = "Doan Karhan, Brachland",
                objective = "3 Soran'ruk-Bruchstücke und 1 großes Soran'ruk-Bruchstück zu Doan Karhan bringen.",
                turnin = "Doan Karhan, Brachland",
                xp = 2550,
                choice = true,
                rewards = { { 6898, "Orb of Soran'ruk", 3 }, { 15109, "Staff of Soran'ruk", 3 } },
                note = "Klassenquest für Hexenmeister. Die Bruchstücke gibt es in Shadowfang Keep und in Blackfathom Deeps.",
            },
            {
                id = 1013, name = "The Book of Ur", level = 26, requires = 16, faction = "horde",
                giver = "Keeper Bel'dugur, Apothekarium, Unterstadt",
                objective = "Das Buch von Ur aus Shadowfang Keep zu Keeper Bel'dugur bringen.",
                turnin = "Keeper Bel'dugur, Apothekarium, Unterstadt",
                xp = 9135,
                reputation = { { "Unterstadt", 100 } },
                choice = true,
                rewards = { { 6335, "Grizzled Boots", 3 }, { 4534, "Steel-clasped Bracers", 3 }, { 270030, "Tattered Mittens", 3 } },
            },
            {
                id = 1014, name = "Arugal Must Die", level = 27, requires = 18, faction = "horde",
                giver = "Dalar Dawnweaver, Das Grabmal, Silberwald",
                objective = "Archmage Arugal töten und seinen Kopf zu Dalar Dawnweaver bringen.",
                turnin = "Dalar Dawnweaver, Das Grabmal, Silberwald",
                xp = 14355,
                reputation = { { "Unterstadt", 200 } },
                choice = false,
                rewards = { { 6414, "Seal of Sylvanas", 3 } },
                note = "Laut den Questdaten von Forever gibt es zusätzlich den Zauber Arkane Intelligenz.",
            },
        },
    },
    blackfathom_deeps = {
        loot = {
            ghamoora = {
                { 6907, "Tortoise Armor", "Brust, Schwere Rüstung", 3 },
                { 6908, "Ghamoo-ra's Bind", "Taille, Stoff", 3 },
                { 273839, "Spiked Shell Band", "Finger", 3 },
            },
            lady_sarevess = {
                { 888, "Naga Battle Gloves", "Hände, Leder", 3 },
                { 3078, "Naga Heartpiercer", "Distanz, Bogen", 2 },
                { 11121, "Darkwater Talwar", "Waffenhand, Schwert", 2 },
                { 252798, "Pattern: Brawler's Leather Hood", "Lederverarbeitung (Muster)", 3 },
            },
            gelihast = {
                { 6906, "Algae Fists", "Hände, Schwere Rüstung", 3 },
                { 6905, "Reef Axe", "Zweihändig, Axt", 3 },
                { 1470, "Murloc Skin Bag", "Tasche", 1 },
            },
            lorgus_jett = {
                { 273843, "Fallenroot Longbow", "Distanz, Bogen", 3 },
            },
            baron_aquanis = {
                { 16782, "Strange Water Globe", "Questgegenstand", 1 },
            },
            old_serrakis = {
                { 6901, "Glowing Thresher Cape", "Rücken, Stoff", 3 },
                { 6904, "Bite of Serra'kis", "Einhändig, Dolch", 3 },
                { 6902, "Bands of Serra'kis", "Handgelenke, Leder", 3 },
            },
            twilight_lord_kelris = {
                { 1155, "Rod of the Sleepwalker", "Zweihändig, Stab", 3 },
                { 6903, "Gaze Dreamer Pants", "Beine, Stoff", 3 },
                { 273846, "Twilight Lord Girdle", "Taille, Schwere Rüstung", 3 },
            },
            akumai = {
                { 6911, "Moss Cinch", "Taille, Leder", 3 },
                { 6910, "Leech Pants", "Beine, Stoff", 3 },
                { 6909, "Strike of the Hydra", "Zweihändig, Schwert", 3 },
            },
        },
        quests = {
            {
                id = 971, name = "Knowledge in the Deeps", level = 23, requires = 10, faction = "alliance",
                giver = "Gerrig Bonegrip, Forlorn Cavern, Eisenschmiede (50,8; 5,6)",
                objective = "Das Lorgalis-Manuskript aus Blackfathom Deeps bergen.",
                turnin = "Gerrig Bonegrip, Forlorn Cavern, Eisenschmiede",
                xp = 10313,
                reputation = { { "Eisenschmiede", 50 } },
                choice = false,
                rewards = { { 6743, "Sustaining Ring", 2 } },
                startItem = { 5359, "Lorgalis Manuscript" },
                note = "Das Manuskript liegt in einer Narbigen Eisentruhe unter Wasser im Becken von Ask'ar, in der nördlichen Nische direkt hinter dem Raum der Schildkröte Ghamoo-ra.",
            },
            {
                id = 1275, name = "Researching the Corruption", level = 24, requires = 18, faction = "alliance",
                giver = "Gershala Nightwhisper, Auberdine, Dunkelküste (38,3; 43,1)",
                objective = "8 verderbte Hirnstämme von Kreaturen in Blackfathom Deeps sammeln.",
                turnin = "Gershala Nightwhisper, Auberdine, Dunkelküste",
                xp = 2400,
                money = 3500,
                reputation = { { "Darnassus", 150 } },
                choice = true,
                rewards = { { 7003, "Beetle Clasps", 2 }, { 7004, "Prelacy Cape", 2 }, { 270021, "Staghide Armguards", 3 } },
                note = "Folgt auf „The Corruption Abroad“.",
            },
            {
                id = 1198, name = "In Search of Thaelrid", level = 24, requires = 18, faction = "alliance",
                giver = "Dawnwatcher Shaedlass, Terrasse der Handwerker, Darnassus",
                objective = "Argent Guard Thaelrid in Blackfathom Deeps finden.",
                turnin = "Argent Guard Thaelrid, in Blackfathom Deeps",
                xp = 2400,
                reputation = { { "Argentumdämmerung", 150 }, { "Darnassus", 150 } },
            },
            {
                id = 1199, name = "Twilight Falls", level = 25, requires = 20, faction = "alliance",
                giver = "Argent Guard Manados, Terrasse der Handwerker, Darnassus (55; 24)",
                objective = "10 Zwielichtanhänger von Mitgliedern des Schattenhammers in Blackfathom Deeps sammeln.",
                turnin = "Argent Guard Manados, Terrasse der Handwerker, Darnassus",
                xp = 9563,
                reputation = { { "Argentumdämmerung", 150 }, { "Darnassus", 150 } },
                choice = false,
                rewards = { { 6998, "Nimbus Boots", 2 }, { 7000, "Heartwood Girdle", 2 }, { 270025, "Silvered Gauntlets", 3 } },
            },
            {
                id = 1200, name = "Blackfathom Villainy", level = 27, requires = 18, faction = "alliance",
                giver = "Argent Guard Thaelrid, in Blackfathom Deeps",
                objective = "Twilight Lord Kelris besiegen und seinen Kopf bergen.",
                turnin = "Dawnwatcher Selgorm, Darnassus",
                xp = 12375,
                money = 6500,
                reputation = { { "Argentumdämmerung", 200 }, { "Darnassus", 200 } },
                choice = true,
                rewards = { { 7001, "Gravestone Scepter", 3 }, { 7002, "Arctic Buckler", 3 }, { 270031, "Dark Ritual Leggings", 3 }, { 270032, "Cultist's Armguards", 3 } },
            },
            {
                id = 6564, name = "Allegiance to the Old Gods", level = 22, requires = 17, faction = "horde",
                giver = "Die Feuchte Notiz benutzen, Beute von Blackfathom Tide Priestesses",
                objective = "Die Feuchte Notiz zu Je'neu Sancrea im Eschental bringen.",
                turnin = "Je'neu Sancrea, Zoram'gar-Außenposten, Eschental",
                money = 1100,
                reputation = { { "Dunkelspeertrolle", 150 } },
                startItem = { 16790, "Damp Note" },
                note = "Vorstufe zu „Allegiance to the Old Gods“ (Lorgus Jett).",
            },
            {
                id = 6562, name = "Trouble in the Deeps", level = 22, requires = 17, faction = "horde",
                giver = "Tsunaman, Steinkrallengebirge",
                objective = "Mit Je'neu Sancrea im Eschental sprechen.",
                turnin = "Je'neu Sancrea, Zoram'gar-Außenposten, Eschental",
                xp = 440,
                reputation = { { "Dunkelspeertrolle", 25 }, { "Irdener Ring", 100 } },
                note = "Einleitung zu „The Essence of Aku'Mai“.",
            },
            {
                id = 6563, name = "The Essence of Aku'Mai", level = 22, requires = 17, faction = "horde",
                giver = "Je'neu Sancrea, Zoram'gar-Außenposten, Eschental (12; 34)",
                objective = "20 Saphire von Aku'Mai in Blackfathom Deeps sammeln.",
                turnin = "Je'neu Sancrea, Zoram'gar-Außenposten, Eschental",
                xp = 1750,
                money = 1400,
                reputation = { { "Dunkelspeertrolle", 100 }, { "Irdener Ring", 150 } },
                note = "Folgt auf „Trouble in the Deeps“.",
            },
            {
                id = 6565, name = "Allegiance to the Old Gods", level = 26, requires = 17, faction = "horde",
                giver = "Je'neu Sancrea, Zoram'gar-Außenposten, Eschental (12; 34)",
                objective = "Lorgus Jett in Blackfathom Deeps besiegen.",
                turnin = "Je'neu Sancrea, Zoram'gar-Außenposten, Eschental",
                xp = 2650,
                money = 4000,
                reputation = { { "Dunkelspeertrolle", 150 }, { "Irdener Ring", 150 } },
                choice = true,
                rewards = { { 17694, "Band of the Fist", 3 }, { 17695, "Chestnut Mantle", 3 } },
                note = "Folgt auf die Stufe mit der Feuchten Notiz.",
            },
            {
                id = 6561, name = "Blackfathom Villainy", level = 27, requires = 18, faction = "horde",
                giver = "Argent Guard Thaelrid, in Blackfathom Deeps",
                objective = "Twilight Lord Kelris besiegen und seinen Kopf bergen.",
                turnin = "Bashana Runetotem, Donnerfels",
                xp = 12375,
                money = 6500,
                reputation = { { "Argentumdämmerung", 200 }, { "Donnerfels", 200 } },
                choice = true,
                rewards = { { 7001, "Gravestone Scepter", 3 }, { 7002, "Arctic Buckler", 3 }, { 270031, "Dark Ritual Leggings", 3 }, { 270032, "Cultist's Armguards", 3 } },
            },
            {
                id = 6921, name = "Amongst the Ruins", level = 27, requires = 21, faction = "horde",
                giver = "Je'neu Sancrea, Zoram'gar-Außenposten, Eschental (12; 34)",
                objective = "Den Tiefenkern vom Tiefenstein in Blackfathom Deeps bergen.",
                turnin = "Je'neu Sancrea, Zoram'gar-Außenposten, Eschental",
                xp = 10313,
                money = 4500,
                note = "Am Tiefenstein lässt sich auch Baron Aquanis beschwören (optional).",
            },
        },
    },
}

--------------------------------------------------
-- Orte auf der Weltkarte (seit 6.5.1.0)
--------------------------------------------------
-- Wo eine Quest beginnt, als Punkt auf der Weltkarte: Karte (UiMapID)
-- und Lage 0..1 auf ihr. HERKUNFT wie oben (`community`): dieselben
-- Beta-Berichte. Die Kartennummern sind die von Classic (Westfalen 1436,
-- Sturmwind 1453 ...), nicht die des heutigen Spiels (52, 84) - so
-- berichtet, und die Berichte stammen von einem Addon, das im Beta-Client
-- mit genau diesen Nummern lief. Die Lagen sind die bekannten aus Classic;
-- ob Forever jeden Geber an denselben Fleck stellt, ist nicht geprueft.
-- Deshalb sagt die Marke auf der Karte "unbestaetigt".
--
-- `who` ist, wer (oder was) an dem Punkt steht. `item = true`: die Quest
-- beginnt mit einem Gegenstand, der Punkt ist sein Fundort.
-- Nicht jede Quest hat einen Punkt: Geber im Dungeon, Quests aus Beute
-- und Geber, deren Lage nicht berichtet ist, bleiben ohne. The Glowing
-- Shard (6981) bleibt bewusst ohne: der Bericht nennt Falla Sagewind in
-- Donnerfels - die ist nicht der Geber, die Quest beginnt mit Beute.

J.PLACES = {
    -- Hall of Thanes
    [96393] = { map = 1426, x = 0.7620, y = 0.6080, who = "Dark Iron Spies", item = true },
    -- Ruins of Lordaeron
    [92401] = { map = 1421, x = 0.4450, y = 0.4300, who = "Tabitha Heartweaver" },
    [92421] = { map = 1458, x = 0.5790, y = 0.8950, who = "Morbin Lightbane" },
    [95216] = { map = 1458, x = 0.4650, y = 0.7160, who = "Theodore Griffs" },
    [92422] = { map = 1420, x = 0.6520, y = 0.6020, who = "Deathguard Kristof" },
    -- The Deadmines
    [214]   = { map = 1436, x = 0.5667, y = 0.4735, who = "Scout Riell" },
    [168]   = { map = 1453, x = 0.6680, y = 0.4380, who = "Wilder Thistlenettle" },
    [167]   = { map = 1453, x = 0.6680, y = 0.4380, who = "Wilder Thistlenettle" },
    [2040]  = { map = 1453, x = 0.6300, y = 0.3400, who = "Shoni the Shilent" },
    [166]   = { map = 1436, x = 0.5640, y = 0.4750, who = "Gryan Stoutmantle" },
    -- Ragefire Chasm
    [5723]  = { map = 1456, x = 0.7040, y = 0.3220, who = "Rahauro" },
    [5722]  = { map = 1456, x = 0.7040, y = 0.3220, who = "Rahauro" },
    [5728]  = { map = 1454, x = 0.3200, y = 0.3780, who = "Thrall" },
    [5761]  = { map = 1454, x = 0.4960, y = 0.5060, who = "Neeru Fireblade" },
    [5725]  = { map = 1458, x = 0.5620, y = 0.9260, who = "Varimathras" },
    -- Blackfathom Deeps
    [971]   = { map = 1455, x = 0.5083, y = 0.0561, who = "Gerrig Bonegrip" },
    [1275]  = { map = 1439, x = 0.3830, y = 0.4310, who = "Gershala Nightwhisper" },
    [1198]  = { map = 1457, x = 0.5500, y = 0.2400, who = "Dawnwatcher Shaedlass" },
    [1199]  = { map = 1457, x = 0.5500, y = 0.2400, who = "Argent Guard Manados" },
    [6563]  = { map = 1440, x = 0.1200, y = 0.3400, who = "Je'neu Sancrea" },
    [6562]  = { map = 1442, x = 0.4720, y = 0.6420, who = "Tsunaman" },
    [6565]  = { map = 1440, x = 0.1200, y = 0.3400, who = "Je'neu Sancrea" },
    [6921]  = { map = 1440, x = 0.1200, y = 0.3400, who = "Je'neu Sancrea" },
    -- Wailing Caverns
    [1486]  = { map = 1413, x = 0.4660, y = 0.3630, who = "Nalpak" },
    [1487]  = { map = 1413, x = 0.4660, y = 0.3570, who = "Ebru" },
    [962]   = { map = 1456, x = 0.2300, y = 0.2100, who = "Apothecary Zamah" },
    [1491]  = { map = 1413, x = 0.6280, y = 0.3670, who = "Mebok Mizzyrix" },
    [959]   = { map = 1413, x = 0.6390, y = 0.3830, who = "Crane Operator Bigglefuzz" },
    [914]   = { map = 1456, x = 0.7530, y = 0.3130, who = "Nara Wildmane" },
    -- Shadowfang Keep
    [1098]  = { map = 1421, x = 0.4340, y = 0.4090, who = "High Executor Hadrec" },
    [1740]  = { map = 1413, x = 0.4930, y = 0.5720, who = "Doan Karhan" },
    [1013]  = { map = 1458, x = 0.5370, y = 0.5450, who = "Keeper Bel'dugur" },
    [1014]  = { map = 1421, x = 0.4420, y = 0.3980, who = "Dalar Dawnweaver" },
}

-- Ort einer Quest auf der Weltkarte, oder nil.
function J.Place(questId)
    return J.PLACES[questId]
end

-- Beute eines Bosses (Liste, leer wenn keine berichtet ist).
function J.Loot(dungeonId, bossId)
    local d = J.DATA[dungeonId]
    return d and d.loot and d.loot[bossId] or {}
end

-- Beute von Gegnern ohne eigenen Boss.
function J.Others(dungeonId)
    local d = J.DATA[dungeonId]
    return d and d.others or {}
end

-- Quests eines Dungeons; `faction` ("alliance"/"horde") filtert, nil
-- liefert alle.
function J.Quests(dungeonId, faction)
    local d = J.DATA[dungeonId]
    local out = {}
    for _, q in ipairs(d and d.quests or {}) do
        if not faction or q.faction == "both" or q.faction == faction then
            out[#out + 1] = q
        end
    end
    return out
end

function J.Has(dungeonId)
    return J.DATA[dungeonId] ~= nil
end
