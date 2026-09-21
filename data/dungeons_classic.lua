--------------------------------------------------
-- WeintCodex :: Die klassischen Dungeons
--
-- WARUM DIESE DATEI ÜBERHAUPT EXISTIERT. Forever ersetzt die alten
-- Dungeons nicht, es stellt neun daneben. Die zwanzig klassischen
-- Instanzen bleiben im Kern des Spiels, Blizzard hat ihre Beute
-- überarbeitet, und die Legacy-Aufgaben führen weiter durch sie
-- hindurch. Wer auf Stufe 32 einen Dungeon sucht, bekommt von einer
-- Liste mit neun Einträgen die falsche Antwort - dort stehen für
-- diese Stufe zwei, im ganzen Spiel sind es sechs.
--
-- DIE HERKUNFT IST EINE ANDERE ALS BEI DEN FOREVER-DUNGEONS, UND DAS
-- IST DER GANZE HAKEN AN DIESER DATEI.
--
-- Dass es Darkmaster Gandling in der Scholomance gibt, ist seit
-- zwanzig Jahren nachprüfbar. Dass Forever ihn unverändert
-- übernimmt, ist es NICHT. Blizzard hat angekündigt, die Beute jedes
-- Bosses überarbeitet zu haben, und über die Kämpfe selbst nichts
-- gesagt. Jede Liste hier trägt deshalb `kind = "classic"`: die
-- Angabe stimmt für Classic, und für Forever ist sie eine begründete
-- Erwartung. Die Oberfläche schreibt genau das daneben.
--
-- DIE STUFENBEREICHE SIND DIE VON CLASSIC. Welche Stufen Forever für
-- die alten Dungeons vorsieht, hat Blizzard nicht veröffentlicht;
-- vereinzelte Berichte nennen leicht andere Werte (Uldaman 41-51
-- gegen 42-52). Ein zusammengesuchter Mischbestand wäre schlechter
-- als ein einheitlicher mit benannter Herkunft.
--
-- DEUTSCHE INSTANZNAMEN STEHEN HIER NICHT, und zwar aus demselben
-- Grund wie bei den Forever-Dungeons: die Zuordnung der Bossnotizen
-- des Bots läuft über den Namen. Ein Name, den dieses Addon anders
-- schreibt als der Client, ist ein Name, unter dem nichts ankommt.
-- Bei den GEBIETEN ist es umgekehrt - "Westfall" und "Eschental"
-- heissen seit zwanzig Jahren so.
--
-- SELTENE SPAWNS SIND NICHT VOLLSTÄNDIG GEFÜHRT. Eingetragen ist der
-- Hauptweg plus das, wonach ausdrücklich gefragt war: die Bosse, die
-- nur erscheinen, wenn die Gruppe etwas dafür tut. Wer eine
-- lückenlose Liste jedes seltenen Gegners erwartet, findet sie hier
-- nicht - und `raresListed = false` sagt es ihm, statt ihn es
-- herausfinden zu lassen.
--------------------------------------------------

local SRC = WeintCodex.Sources
local D   = WeintCodex.DungeonData

-- Kurzform: jede Liste dieser Datei stammt aus Classic.
local function Summon(text)
    return { text = text, source = SRC.CLASSIC }
end

WeintCodex_ClassicDungeons = {

    {
        id = "ragefire_chasm", name = "Ragefire Chasm",
        zone = "Orgrimmar", zoneDe = "Orgrimmar",
        size = 5, minLevel = 13, maxLevel = 18,
        theme = "Der Schlund unter Orgrimmar. Hordeseite; das Gegenstück zur "
             .. "Hall of Thanes der Allianz.",
        orderKnown = true, bossesComplete = true,
        bosses = {
            { id = "oggleflint",   name = "Oggleflint",              order = 1 },
            { id = "taragaman",    name = "Taragaman the Hungerer",  order = 2 },
            { id = "jergosh",      name = "Jergosh the Invoker",     order = 3 },
            { id = "bazzalan",     name = "Bazzalan",                order = 4 },
        },
    },

    {
        id = "the_deadmines", name = "The Deadmines",
        zone = "Westfall", zoneDe = "Westfall",
        size = 5, minLevel = 17, maxLevel = 26,
        theme = "Die Mine der Defias unter Moosbruch, mit der Werft am Ende.",
        orderKnown = true, bossesComplete = true,
        bosses = {
            { id = "rhahkzor",        name = "Rhahk'Zor",         order = 1 },
            { id = "miner_johnson",   name = "Miner Johnson",     optional = true,
              note = "Seltener Spawn im ersten Stollen." },
            { id = "sneeds_shredder", name = "Sneed's Shredder",  order = 2,
              note = "Nach dem Schredder steigt Sneed selbst aus." },
            { id = "gilnid",          name = "Gilnid",            order = 3 },
            { id = "mr_smite",        name = "Mr. Smite",         order = 4,
              note = "Wechselt zweimal die Waffe und betäubt dabei die Gruppe." },
            { id = "captain_greenskin", name = "Captain Greenskin", order = 5 },
            { id = "edwin_vancleef",  name = "Edwin VanCleef",    order = 6, last = true },
            { id = "cookie",          name = "Cookie",            order = 7 },
        },
    },

    {
        id = "wailing_caverns", name = "Wailing Caverns",
        zone = "The Barrens", zoneDe = "Brachland",
        size = 5, minLevel = 17, maxLevel = 24,
        theme = "Das Höhlensystem unter dem Brachland. Der Endkampf beginnt "
             .. "erst, wenn Naralex geweckt wird.",
        -- Die vier Fanglords lassen sich in fast beliebiger Folge
        -- legen; eine Nummerierung waere hier eine Behauptung.
        orderKnown = false, bossesComplete = true,
        bosses = {
            { id = "lady_anacondra", name = "Lady Anacondra" },
            { id = "lord_cobrahn",   name = "Lord Cobrahn" },
            { id = "kresh",          name = "Kresh", optional = true },
            { id = "lord_pythas",    name = "Lord Pythas" },
            { id = "skum",           name = "Skum", optional = true },
            { id = "lord_serpentis", name = "Lord Serpentis" },
            { id = "verdan",         name = "Verdan the Everliving", optional = true },
            { id = "deviate_faerie_dragon", name = "Deviate Faerie Dragon",
              optional = true, note = "Seltener Spawn." },
            {
                id = "mutanus", name = "Mutanus the Devourer", last = true,
                summon = Summon("Erscheint nicht von selbst. Nach den vier "
                    .. "Fanglords Naralex wecken und die Eskorte durch die "
                    .. "Höhlen zurückbegleiten - am Ende der Eskorte kommt "
                    .. "Mutanus aus dem Wasser."),
            },
        },
    },

    {
        id = "shadowfang_keep", name = "Shadowfang Keep",
        zone = "Silverpine Forest", zoneDe = "Silberwald",
        size = 5, minLevel = 22, maxLevel = 30,
        theme = "Die Burg über dem Silberwald, in der Arugal seine Wölfe "
             .. "hält.",
        orderKnown = true, bossesComplete = true,
        bosses = {
            { id = "rethilgore",      name = "Rethilgore",            order = 1 },
            { id = "razorclaw",       name = "Razorclaw the Butcher", optional = true },
            { id = "baron_silverlaine", name = "Baron Silverlaine",   order = 2 },
            { id = "commander_springvale", name = "Commander Springvale", order = 3 },
            { id = "odo",             name = "Odo the Blindwatcher",  order = 4 },
            { id = "deathsworn_captain", name = "Deathsworn Captain", optional = true,
              note = "Seltener Spawn." },
            { id = "fenrus",          name = "Fenrus the Devourer",   order = 5 },
            { id = "wolf_master_nandos", name = "Wolf Master Nandos", order = 6 },
            { id = "archmage_arugal", name = "Archmage Arugal",       order = 7, last = true },
        },
    },

    {
        id = "blackfathom_deeps", name = "Blackfathom Deeps",
        zone = "Ashenvale", zoneDe = "Eschental",
        size = 5, minLevel = 24, maxLevel = 32,
        theme = "Der überflutete Tempel an der Küste des Eschentals.",
        orderKnown = true, bossesComplete = true,
        bosses = {
            { id = "ghamoora",      name = "Ghamoo-ra",           order = 1 },
            { id = "lady_sarevess", name = "Lady Sarevess",       order = 2 },
            { id = "gelihast",      name = "Gelihast",            order = 3 },
            { id = "lorgus_jett",   name = "Lorgus Jett",         optional = true,
              note = "Seltener Spawn." },
            { id = "baron_aquanis", name = "Baron Aquanis",       optional = true },
            { id = "old_serrakis",  name = "Old Serra'kis",       order = 4 },
            { id = "twilight_lord_kelris", name = "Twilight Lord Kelris", order = 5 },
            { id = "akumai",        name = "Aku'mai",             order = 6, last = true },
        },
    },

    {
        id = "the_stockade", name = "The Stockade",
        zone = "Stormwind City", zoneDe = "Sturmwind",
        size = 5, minLevel = 24, maxLevel = 32,
        theme = "Das Gefängnis unter Sturmwind. Der kürzeste Dungeon im "
             .. "ganzen Spiel.",
        -- Rundbau ohne festen Weg.
        orderKnown = false, bossesComplete = true,
        bosses = {
            { id = "targorr",       name = "Targorr the Dread" },
            { id = "kam_deepfury",  name = "Kam Deepfury" },
            { id = "hamhock",       name = "Hamhock" },
            { id = "bazil_thredd",  name = "Bazil Thredd" },
            { id = "dextren_ward",  name = "Dextren Ward" },
            { id = "bruegal",       name = "Bruegal Ironknuckle", optional = true,
              note = "Seltener Spawn." },
        },
    },

    {
        id = "gnomeregan", name = "Gnomeregan",
        zone = "Dun Morogh", zoneDe = "Dun Morogh",
        size = 5, minLevel = 29, maxLevel = 38,
        theme = "Die verstrahlte Gnomenstadt. Lang, verwinkelt, mit einer "
             .. "Abkürzung über den Wartungsschacht.",
        orderKnown = true, bossesComplete = true,
        bosses = {
            { id = "grubbis",        name = "Grubbis",             order = 1 },
            { id = "viscous_fallout", name = "Viscous Fallout",    order = 2 },
            { id = "electrocutioner", name = "Electrocutioner 6000", order = 3 },
            { id = "crowd_pummeler", name = "Crowd Pummeler 9-60",  optional = true },
            { id = "dark_iron_ambassador", name = "Dark Iron Ambassador",
              optional = true, note = "Seltener Spawn." },
            { id = "thermaplugg",    name = "Mekgineer Thermaplugg", order = 4, last = true },
        },
    },

    {
        id = "razorfen_kraul", name = "Razorfen Kraul",
        zone = "The Barrens", zoneDe = "Brachland",
        size = 5, minLevel = 29, maxLevel = 38,
        theme = "Der Dornenbau der Quilboar im Süden des Brachlands.",
        orderKnown = false, bossesComplete = true,
        bosses = {
            { id = "roogug",          name = "Roogug" },
            { id = "aggem_thorncurse", name = "Aggem Thorncurse" },
            { id = "death_speaker_jargba", name = "Death Speaker Jargba" },
            { id = "overlord_ramtusk", name = "Overlord Ramtusk" },
            { id = "agathelos",       name = "Agathelos the Raging" },
            { id = "charlga_razorflank", name = "Charlga Razorflank", last = true },
        },
    },

    {
        id = "scarlet_monastery", name = "Scarlet Monastery",
        zone = "Tirisfal Glades", zoneDe = "Tirisfal-Wälder",
        size = 5, minLevel = 28, maxLevel = 45,
        theme = "Vier getrennte Flügel hinter einem Hof: Friedhof, "
             .. "Bibliothek, Waffenkammer, Kathedrale. Deshalb der breiteste "
             .. "Stufenbereich im Spiel.",
        -- Vier Fluegel sind keine Reihenfolge.
        orderKnown = false, bossesComplete = true,
        bosses = {
            { id = "interrogator_vishas", name = "Interrogator Vishas", wing = "Graveyard" },
            { id = "bloodmage_thalnos",   name = "Bloodmage Thalnos",   wing = "Graveyard" },
            { id = "ironspine",           name = "Ironspine",           wing = "Graveyard",
              optional = true, note = "Seltener Spawn." },
            { id = "azshir",              name = "Azshir the Sleepless", wing = "Graveyard",
              optional = true, note = "Seltener Spawn." },
            { id = "fallen_champion",     name = "Fallen Champion",     wing = "Graveyard",
              optional = true, note = "Seltener Spawn." },
            { id = "houndmaster_loksey",  name = "Houndmaster Loksey",  wing = "Library" },
            { id = "arcanist_doan",       name = "Arcanist Doan",       wing = "Library" },
            { id = "herod",               name = "Herod",               wing = "Armory" },
            { id = "high_inquisitor_fairbanks", name = "High Inquisitor Fairbanks",
              wing = "Cathedral", optional = true },
            { id = "mograine",            name = "Scarlet Commander Mograine", wing = "Cathedral" },
            { id = "whitemane",           name = "High Inquisitor Whitemane",  wing = "Cathedral",
              last = true, note = "Erweckt Mograine noch einmal." },
        },
    },

    {
        id = "razorfen_downs", name = "Razorfen Downs",
        zone = "The Barrens", zoneDe = "Brachland",
        size = 5, minLevel = 37, maxLevel = 46,
        theme = "Der obere Dornenbau, inzwischen von Untoten gehalten.",
        orderKnown = false, bossesComplete = true,
        bosses = {
            { id = "tutenkash",      name = "Tuten'kash" },
            { id = "mordresh",       name = "Mordresh Fire Eye" },
            { id = "glutton",        name = "Glutton" },
            { id = "plaguemaw",      name = "Plaguemaw the Rotting" },
            { id = "ragglesnout",    name = "Ragglesnout", optional = true,
              note = "Seltener Spawn." },
            { id = "amnennar",       name = "Amnennar the Coldbringer", last = true },
        },
    },

    {
        id = "uldaman", name = "Uldaman",
        zone = "Badlands", zoneDe = "Ödland",
        size = 5, minLevel = 41, maxLevel = 51,
        theme = "Das Titanengewölbe im Oedland. Der Zugang zur hinteren "
             .. "Hälfte geht über die Steinwächter.",
        orderKnown = true, bossesComplete = true,
        bosses = {
            { id = "revelosh",       name = "Revelosh",            order = 1 },
            { id = "the_lost_dwarves", name = "Baelog",            order = 2,
              note = "Steht zusammen mit Eric the Swift und Olaf." },
            { id = "ironaya",        name = "Ironaya",             order = 3 },
            { id = "ancient_stone_keeper", name = "Ancient Stone Keeper", order = 4 },
            { id = "galgann",        name = "Galgann Firehammer",  order = 5 },
            { id = "grimlok",        name = "Grimlok",             order = 6 },
            { id = "archaedas",      name = "Archaedas",           order = 7, last = true },
        },
    },

    {
        id = "zulfarrak", name = "Zul'Farrak",
        zone = "Tanaris", zoneDe = "Tanaris",
        size = 5, minLevel = 44, maxLevel = 54,
        theme = "Die Trollstadt in Tanaris, mit der Pyramidenschlacht in der "
             .. "Mitte.",
        orderKnown = true, bossesComplete = true,
        bosses = {
            { id = "antusul",        name = "Antu'sul",            order = 1 },
            { id = "theka",          name = "Theka the Martyr",    order = 2 },
            { id = "zumrah",         name = "Witch Doctor Zum'rah", order = 3 },
            { id = "sergeant_bly",   name = "Sergeant Bly",        order = 4,
              note = "Die Pyramidenschlacht: erst die Wellen, dann wendet sich "
                  .. "Bly gegen die Gruppe." },
            { id = "nekrum",         name = "Nekrum Gutchewer",    order = 5 },
            { id = "sezzziz",        name = "Shadowpriest Sezz'ziz", order = 6 },
            { id = "ukorz",          name = "Chief Ukorz Sandscalp", order = 7, last = true,
              note = "Mit seinem Leibwächter Ruuzlu." },
            {
                id = "gahzrilla", name = "Gahz'rilla", optional = true,
                summon = Summon("Nur mit dem Schlägel von Zul'Farrak. Den "
                    .. "Sockel am Wasserbecken damit benutzen - ohne den "
                    .. "Schlägel erscheint Gahz'rilla nicht."),
            },
        },
    },

    {
        id = "maraudon", name = "Maraudon",
        zone = "Desolace", zoneDe = "Desolace",
        size = 5, minLevel = 46, maxLevel = 55,
        theme = "Drei Zugänge: der orange und der violette Flügel führen "
             .. "beide in den inneren Teil.",
        orderKnown = false, bossesComplete = true,
        bosses = {
            { id = "noxxion",        name = "Noxxion" },
            { id = "razorlash",      name = "Razorlash" },
            { id = "lord_vyletongue", name = "Lord Vyletongue" },
            { id = "meshlok",        name = "Meshlok the Harvester", optional = true,
              note = "Seltener Spawn." },
            { id = "tinkerer_gizlock", name = "Tinkerer Gizlock" },
            { id = "celebras",       name = "Celebras the Cursed",
              note = "Danach öffnet Celebras den Rückweg." },
            { id = "landslide",      name = "Landslide" },
            { id = "rotgrip",        name = "Rotgrip" },
            { id = "princess_theradras", name = "Princess Theradras", last = true },
        },
    },

    {
        id = "sunken_temple", name = "Temple of Atal'Hakkar",
        zone = "Swamp of Sorrows", zoneDe = "Sumpf des Elends",
        size = 5, minLevel = 50, maxLevel = 60,
        theme = "Der versunkene Tempel im Sumpf des Elends. Zwei Ebenen; "
             .. "unten die Drachkin, oben die Trolle.",
        -- ZWEI BESCHWOERBARE BOSSE IN EINER INSTANZ - nirgends sonst
        -- in Classic gibt es das.
        orderKnown = false, bossesComplete = true,
        bosses = {
            {
                id = "atalalarion", name = "Atal'alarion", optional = true,
                summon = Summon("Die sechs Statuen im Hauptraum in der "
                    .. "richtigen Reihenfolge benutzen - der Reihe nach, wie "
                    .. "die grünen Flammen aufleuchten. Danach öffnet sich "
                    .. "die Grube, und Atal'alarion steigt heraus."),
            },
            { id = "jammalan",       name = "Jammal'an the Prophet" },
            { id = "ogom",           name = "Ogom the Wretched" },
            { id = "dreamscythe",    name = "Dreamscythe" },
            { id = "weaver",         name = "Weaver" },
            { id = "morphaz",        name = "Morphaz" },
            { id = "hazzas",         name = "Hazzas" },
            { id = "eranikus",       name = "Shade of Eranikus", last = true },
            {
                id = "avatar_of_hakkar", name = "Avatar of Hakkar", optional = true,
                summon = Summon("Im Sanktum des gefallenen Gottes den Schrein "
                    .. "des Seelenschinders benutzen - oder das Ei von Hakkar "
                    .. "beziehungsweise Yeh'kinyas Schriftrolle. Erst die sechs "
                    .. "Trollpriester an den Becken legen."),
            },
        },
    },

    {
        id = "blackrock_depths", name = "Blackrock Depths",
        zone = "Blackrock Mountain", zoneDe = "Der Schwarzfels",
        size = 5, minLevel = 52, maxLevel = 60,
        theme = "Die größte Instanz des Spiels: eigene Stadt, eigenes "
             .. "Wirtshaus, eigenes Gefängnis. Kein Dungeon, den man am "
             .. "Stück läuft.",
        -- ETWA FUENFUNDZWANZIG KAEMPFE OHNE FESTEN WEG. Welche man
        -- laeuft, entscheidet die Gruppe; eine Nummerierung waere hier
        -- schlicht falsch.
        orderKnown = false, bossesComplete = true,
        bosses = {
            { id = "lord_roccor",      name = "Lord Roccor", wing = "Detention Block" },
            { id = "high_interrogator_gerstahn", name = "High Interrogator Gerstahn", wing = "Detention Block" },
            { id = "houndmaster_grebmar", name = "Houndmaster Grebmar", wing = "Detention Block" },
            { id = "ring_of_law",      name = "Ring of Law", wing = "Detention Block",
              note = "Arenaereignis: drei Wellen, dann einer von mehreren "
                  .. "Gegnern (Gorosh the Dervish, Anub'shiah, Hedrum the "
                  .. "Creeper, Ok'thor the Breaker, Eviscerator, Grizzle)." },
            { id = "theldren",         name = "Theldren", wing = "Detention Block", optional = true,
              note = "Alternative Arenagegner." },
            { id = "pyromancer_loregrain", name = "Pyromancer Loregrain", wing = "Detention Block" },
            { id = "golem_lord_argelmach", name = "Golem Lord Argelmach", wing = "Detention Block",
              note = "In der Manufaktur." },
            { id = "hurley_blackbreath", name = "Hurley Blackbreath", wing = "Shadowforge City",
              note = "Kommt aus der Brauerei, wenn ein Fass angestochen wird." },
            { id = "phalanx",          name = "Phalanx", wing = "Shadowforge City" },
            { id = "ribbly_screwspigot", name = "Ribbly Screwspigot", wing = "Shadowforge City", optional = true },
            { id = "plugger_spazzring", name = "Plugger Spazzring", wing = "Shadowforge City" },
            { id = "lord_incendius",   name = "Lord Incendius", wing = "Shadowforge City" },
            { id = "warder_stilgiss",  name = "Warder Stilgiss", wing = "Shadowforge City",
              note = "Zusammen mit Verek." },
            { id = "watchman_doomgrip", name = "Watchman Doomgrip", wing = "Shadowforge City", optional = true,
              note = "Erscheint beim Oeffnen des Tresors." },
            { id = "fineous_darkvire", name = "Fineous Darkvire", wing = "Shadowforge City" },
            { id = "baelgar",          name = "Bael'gar", wing = "Shadowforge City" },
            { id = "general_angerforge", name = "General Angerforge", wing = "Shadowforge City" },
            { id = "ambassador_flamelash", name = "Ambassador Flamelash", wing = "Imperial Seat",
              note = "Allein in der Kammer der Verzauberung." },
            { id = "panzor",           name = "Panzor the Invincible", wing = "Imperial Seat", optional = true,
              note = "Seltener Spawn." },
            { id = "the_seven",        name = "The Seven", wing = "Imperial Seat" },
            { id = "magmus",           name = "Magmus", wing = "Imperial Seat" },
            { id = "dagran_thaurissan", name = "Emperor Dagran Thaurissan", wing = "Imperial Seat", last = true,
              note = "Mit Prinzessin Moira Bronzebart - sie darf nicht sterben, "
                  .. "wenn die Gruppe die Quest abschließen will." },
        },
    },

    {
        id = "lower_blackrock_spire", name = "Lower Blackrock Spire",
        zone = "Blackrock Mountain", zoneDe = "Der Schwarzfels",
        size = 5, minLevel = 55, maxLevel = 60,
        theme = "Die untere Hälfte der Schwarzfelsspitze, gehalten von Orcs "
             .. "und ihren Wolfsreitern.",
        orderKnown = true, bossesComplete = true,
        bosses = {
            { id = "highlord_omokk",   name = "Highlord Omokk",        order = 1 },
            { id = "shadow_hunter_voshgajin", name = "Shadow Hunter Vosh'gajin", order = 2 },
            { id = "war_master_voone", name = "War Master Voone",      order = 3 },
            {
                id = "urok_doomhowl", name = "Urok Doomhowl", optional = true,
                summon = Summon("Omokks Kopf (fällt von Highlord Omokk) "
                    .. "zusammen mit dem Grobgezimmerten Spieß aus dem ersten "
                    .. "Raum auf den Tributhaufen legen. Urok kommt nicht "
                    .. "sofort - erst laufen mehrere Wellen Oger an."),
            },
            { id = "mother_smolderweb", name = "Mother Smolderweb",    order = 4 },
            { id = "quartermaster_zigris", name = "Quartermaster Zigris", order = 5 },
            { id = "halycon",          name = "Halycon",               order = 6 },
            { id = "gizrul",           name = "Gizrul the Slavener",   order = 7 },
            { id = "overlord_wyrmthalak", name = "Overlord Wyrmthalak", order = 8, last = true },
        },
    },

    {
        id = "upper_blackrock_spire", name = "Upper Blackrock Spire",
        zone = "Blackrock Mountain", zoneDe = "Der Schwarzfels",
        -- ZEHNERGRUPPE, und das ist keine Nachlaessigkeit: UBRS ist in
        -- Classic der eine Dungeon, der keiner ist.
        size = 10, minLevel = 58, maxLevel = 60,
        theme = "Die Spitze des Schwarzfels. In Classic eine Zehnergruppe - "
             .. "der einzige Dungeon, der keine Fünfergruppe ist.",
        orderKnown = true, bossesComplete = true,
        bosses = {
            { id = "pyroguard_emberseer", name = "Pyroguard Emberseer", order = 1 },
            { id = "solakar_flamewreath", name = "Solakar Flamewreath", order = 2 },
            { id = "goraluk_anvilcrack",  name = "Goraluk Anvilcrack",  order = 3 },
            { id = "jed_runewatcher",     name = "Jed Runewatcher",     optional = true,
              note = "Seltener Spawn." },
            { id = "warchief_rend_blackhand", name = "Warchief Rend Blackhand", order = 4,
              note = "Erst die Arenawellen, dann Rend auf Gyth." },
            { id = "the_beast",           name = "The Beast",           order = 5 },
            {
                id = "lord_valthalak", name = "Lord Valthalak", optional = true,
                summon = Summon("Mit dem Kohlenbecken des Winkens im Raum der "
                    .. "Bestie beschwören. Das Becken kommt aus der Questreihe "
                    .. "um Valthalaks Amulett."),
            },
            { id = "general_drakkisath",  name = "General Drakkisath",  order = 6, last = true },
        },
    },

    {
        id = "dire_maul", name = "Dire Maul",
        zone = "Feralas", zoneDe = "Feralas",
        size = 5, minLevel = 55, maxLevel = 60,
        theme = "Drei getrennte Flügel. Nur der Ostflügel ist ohne "
             .. "Schlüssel offen; der Sichelschlüssel dafür fällt von "
             .. "Pusillin im Osten.",
        orderKnown = false, bossesComplete = true,
        bosses = {
            { id = "pusillin",         name = "Pusillin",         wing = "East",
              note = "Läuft weg und lässt sich jagen. Trägt den "
                  .. "Sichelschlüssel." },
            { id = "zevrim_thornhoof", name = "Zevrim Thornhoof", wing = "East" },
            { id = "hydrospawn",       name = "Hydrospawn",       wing = "East" },
            { id = "lethtendris",      name = "Lethtendris",      wing = "East" },
            { id = "alzzin",           name = "Alzzin the Wildshaper", wing = "East" },
            { id = "isalien",          name = "Isalien",          wing = "East",
              optional = true, note = "Nur über eine Questreihe." },
            { id = "tendris_warpwood", name = "Tendris Warpwood", wing = "West" },
            { id = "illyanna_ravenoak", name = "Illyanna Ravenoak", wing = "West" },
            { id = "magister_kalendris", name = "Magister Kalendris", wing = "West" },
            { id = "tsuzee",           name = "Tsu'zee",          wing = "West",
              optional = true, note = "Seltener Spawn." },
            { id = "immolthar",        name = "Immol'thar",       wing = "West" },
            { id = "prince_tortheldrin", name = "Prince Tortheldrin", wing = "West" },
            {
                id = "lord_helnurath", name = "Lord Hel'nurath", wing = "West",
                optional = true,
                summon = Summon("Nur für Hexenmeister und nur nach Immol'thar: "
                    .. "im Raum der Beschwörung das Ritual der Questreihe um "
                    .. "das Teufelsross ausführen."),
            },
            { id = "guard_moldar",     name = "Guard Mol'dar",    wing = "North" },
            { id = "stomper_kreeg",    name = "Stomper Kreeg",    wing = "North" },
            { id = "guard_fengus",     name = "Guard Fengus",     wing = "North" },
            { id = "guard_slipkik",    name = "Guard Slip'kik",   wing = "North" },
            { id = "captain_kromcrush", name = "Captain Kromcrush", wing = "North" },
            { id = "king_gordok",      name = "King Gordok",      wing = "North", last = true,
              note = "Tributlauf: wer die Wachen VOR King Gordok stehen lässt, "
                  .. "bekommt am Ende mehr." },
        },
    },

    {
        id = "stratholme", name = "Stratholme",
        zone = "Eastern Plaguelands", zoneDe = "Östliche Pestländer",
        size = 5, minLevel = 58, maxLevel = 60,
        theme = "Zwei Hälften mit getrennten Eingängen: die Scharlachrote "
             .. "Seite und die Untotenseite des Barons.",
        orderKnown = false, bossesComplete = true,
        bosses = {
            { id = "fras_siabi",       name = "Fras Siabi",       wing = "Scarlet",
              optional = true },
            { id = "hearthsinger_forresten", name = "Hearthsinger Forresten",
              wing = "Scarlet", optional = true, note = "Seltener Spawn." },
            { id = "the_unforgiven",   name = "The Unforgiven",   wing = "Scarlet" },
            { id = "timmy_the_cruel",  name = "Timmy the Cruel",  wing = "Scarlet" },
            { id = "malor_the_zealous", name = "Malor the Zealous", wing = "Scarlet" },
            { id = "crimson_hammersmith", name = "Crimson Hammersmith",
              wing = "Scarlet", optional = true },
            { id = "cannon_master_willey", name = "Cannon Master Willey", wing = "Scarlet" },
            { id = "archivist_galford", name = "Archivist Galford", wing = "Scarlet" },
            { id = "balnazzar",        name = "Grand Crusader Dathrohan", wing = "Scarlet",
              last = true, note = "Verwandelt sich unterwegs in Balnazzar." },
            {
                id = "postmaster_malown", name = "Postmaster Malown", wing = "Scarlet",
                optional = true,
                summon = Summon("Die drei Postkästen in der Stadt in der "
                    .. "richtigen Folge leeren; nach dem letzten erscheint der "
                    .. "Postmeister."),
            },
            {
                id = "jarien_and_sothos", name = "Jarien and Sothos", wing = "Scarlet",
                optional = true,
                summon = Summon("Ueber die Questreihe der Scharlachroten Seite: "
                    .. "das Ysida-Ereignis auslösen, dann erscheinen beide "
                    .. "zusammen."),
            },
            { id = "skul",             name = "Skul",             wing = "Undead",
              optional = true, note = "Seltener Spawn." },
            { id = "stonespine",       name = "Stonespine",       wing = "Undead",
              optional = true, note = "Seltener Spawn." },
            { id = "baroness_anastari", name = "Baroness Anastari", wing = "Undead" },
            { id = "nerubenkan",       name = "Nerub'enkan",      wing = "Undead" },
            { id = "maleki_the_pallid", name = "Maleki the Pallid", wing = "Undead" },
            { id = "magistrate_barthilas", name = "Magistrate Barthilas", wing = "Undead" },
            { id = "ramstein",         name = "Ramstein the Gorger", wing = "Undead" },
            { id = "baron_rivendare",  name = "Baron Rivendare",  wing = "Undead", last = true,
              note = "Der Zeitlauf für Ysida beginnt mit Ramstein." },
        },
    },

    {
        id = "scholomance", name = "Scholomance",
        zone = "Western Plaguelands", zoneDe = "Westliche Pestländer",
        size = 5, minLevel = 58, maxLevel = 60,
        theme = "Die Nekromantenschule unter Caer Darrow. Gandling erscheint "
             .. "erst, wenn die sechs Kammern leer sind.",
        orderKnown = false, bossesComplete = true,
        bosses = {
            { id = "blood_steward",    name = "Blood Steward of Kirtonos" },
            {
                id = "kirtonos", name = "Kirtonos the Herald", optional = true,
                summon = Summon("Das Blut der Unschuldigen (fällt von Jandice "
                    .. "Barov) am Kohlenbecken im Beschwörungsraum benutzen. "
                    .. "Ohne das Blut steht dort niemand."),
            },
            { id = "jandice_barov",    name = "Jandice Barov", optional = true,
              note = "Verschwindet und stellt Trugbilder auf." },
            { id = "rattlegore",       name = "Rattlegore",
              note = "Trägt den Schlüssel zum Betrachtungsraum." },
            { id = "marduk_blackpool", name = "Marduk Blackpool" },
            { id = "vectus",           name = "Vectus" },
            { id = "ras_frostwhisper", name = "Ras Frostwhisper" },
            { id = "instructor_malicia", name = "Instructor Malicia" },
            { id = "theolen_krastinov", name = "Doctor Theolen Krastinov" },
            { id = "lorekeeper_polkelt", name = "Lorekeeper Polkelt" },
            { id = "the_ravenian",     name = "The Ravenian" },
            { id = "lord_alexei_barov", name = "Lord Alexei Barov" },
            { id = "lady_illucia_barov", name = "Lady Illucia Barov" },
            { id = "darkmaster_gandling", name = "Darkmaster Gandling", last = true,
              note = "Erscheint im Gewölbe, sobald die sechs Kammerbosse "
                  .. "liegen." },
        },
    },

}

--------------------------------------------------
-- Herkunft: eine fuer alle
--------------------------------------------------
-- Jede Liste dieser Datei stammt aus Classic, und keine ist fuer
-- Forever bestaetigt. Statt zwanzigmal dasselbe Feld zu schreiben,
-- wird es hier einmal gesetzt - wer eine Liste ergaenzt, kann es
-- nicht vergessen.

for _, dungeon in ipairs(WeintCodex_ClassicDungeons) do
    dungeon.legacy      = true
    dungeon.release     = "Classic"
    dungeon.journalId   = nil
    dungeon.mapArt      = nil
    dungeon.raresListed = false
    dungeon.bossSource  = dungeon.bossSource or SRC.CLASSIC
    dungeon.bossCount   = dungeon.bossCount or #dungeon.bosses
end

--------------------------------------------------
-- Zugriff
--------------------------------------------------
-- Die klassischen Dungeons haengen sich an dieselben Funktionen wie
-- die von Forever (data/dungeons.lua). Das ist Absicht: die Seite,
-- der Prueflauf und die Suche sollen nicht zwei Sorten Dungeon
-- kennen muessen, sondern einen Bestand mit einem Herkunftsfeld.
--------------------------------------------------

function D.AllClassic()
    return WeintCodex_ClassicDungeons
end

-- Alle Dungeons des Spiels, Forever und Classic zusammen. Die
-- Reihenfolge ist die nach Mindeststufe - das ist die Frage, mit der
-- man auf eine Dungeonliste schaut.
local combined = nil

function D.AllInstances()
    if combined then return combined end
    combined = {}
    for _, dungeon in ipairs(WeintCodex_Dungeons) do combined[#combined + 1] = dungeon end
    for _, dungeon in ipairs(WeintCodex_ClassicDungeons) do combined[#combined + 1] = dungeon end
    table.sort(combined, function(a, b)
        if a.minLevel ~= b.minLevel then return a.minLevel < b.minLevel end
        if a.maxLevel ~= b.maxLevel then return a.maxLevel < b.maxLevel end
        return a.name < b.name
    end)
    return combined
end

-- Get() muss beide Bestaende finden, sonst landet ein Suchtreffer auf
-- einen klassischen Dungeon ins Leere.
local ForeverGet = D.Get

function D.Get(dungeonId)
    local found = ForeverGet(dungeonId)
    if found then return found end
    for _, dungeon in ipairs(WeintCodex_ClassicDungeons) do
        if dungeon.id == dungeonId then return dungeon end
    end
    return nil
end

function D.IsLegacy(dungeon)
    return type(dungeon) == "table" and dungeon.legacy == true
end

-- ALLE BESCHWOERBAREN ZUSATZBOSSE DES SPIELS, an einer Stelle.
-- Danach war ausdruecklich gefragt, und verstreut ueber neunundzwanzig
-- Dungeons waere die Antwort keine.
function D.AllSummonable()
    local found = {}
    for _, dungeon in ipairs(D.AllInstances()) do
        for _, boss in ipairs(dungeon.bosses or {}) do
            if type(boss.summon) == "table" then
                found[#found + 1] = { dungeon = dungeon, boss = boss }
            end
        end
    end
    return found
end

--------------------------------------------------
-- Staffelung: Stufenabschnitte und Fluegel
--------------------------------------------------
-- BEIDE GIBT ES AUS DEMSELBEN GRUND, UND ER IST EIN GEMESSENER.
--
-- Die Listenspalte hat beim kleinsten zulaessigen Fenster 716 px.
-- Neunundzwanzig Instanzen mit Stufenzeile sind 1334 px. Die
-- zweiundzwanzig Kaempfe von Blackrock Depths sind allein 660 px.
-- Beides zusammen anzuzeigen ist nicht eng, sondern unmoeglich - und
-- eine Unternavigation, die still ueberlaeuft, ist genau der Zustand,
-- den 5.1.0.0 abgeschafft hat (siehe docs/architecture/overview.md,
-- Abschnitt "Nichts muss scrollen").
--
-- Deshalb zwei Staffelungen, und keine davon versteckt etwas:
--
--   STUFENABSCHNITTE fassen die Instanzen. Immer genau einer ist
--   offen. Das ist ausserdem die Frage, mit der man auf eine
--   Dungeonliste schaut - "was passt zu Stufe 32?" und nicht "wie
--   heissen alle neunundzwanzig?".
--
--   FLUEGEL fassen die Kaempfe grosser Instanzen. Sie sind KEINE
--   Erfindung dieses Addons: Scarlet Monastery, Dire Maul und
--   Stratholme haben im Spiel getrennte Eingaenge, und Blackrock
--   Depths ist in Abschnitte geteilt, die jede Gruppe einzeln laeuft.
--   Eine Instanz ohne Fluegel zeigt ihre Kaempfe am Stueck.
--------------------------------------------------

-- Die Grenzen. Sie stehen als Zahlen da und nicht als Rechnung,
-- damit sich die Gruppierung nicht lautlos verschiebt, wenn ein
-- Dungeon dazukommt.
local BRACKET_BOUNDS = { 13, 23, 30, 45, 56 }

local bracketCache = nil

function D.Brackets()
    if bracketCache then return bracketCache end

    local buckets = {}
    for index = 1, #BRACKET_BOUNDS do
        buckets[index] = { dungeons = {} }
    end

    for _, dungeon in ipairs(D.AllInstances()) do
        local slot = 1
        for index, bound in ipairs(BRACKET_BOUNDS) do
            if dungeon.minLevel >= bound then slot = index end
        end
        local bucket = buckets[slot]
        bucket.dungeons[#bucket.dungeons + 1] = dungeon
    end

    -- Die Beschriftung kommt aus dem Bestand und nicht aus den
    -- Grenzen: steht in einem Abschnitt nichts zwischen 30 und 35,
    -- soll da auch nicht "ab 30" stehen.
    bracketCache = {}
    for _, bucket in ipairs(buckets) do
        if #bucket.dungeons > 0 then
            local lo, hi = nil, nil
            for _, dungeon in ipairs(bucket.dungeons) do
                if lo == nil or dungeon.minLevel < lo then lo = dungeon.minLevel end
                if hi == nil or dungeon.minLevel > hi then hi = dungeon.minLevel end
            end
            bucket.min   = lo
            bucket.max    = hi
            bucket.label = "Ab Stufe " .. lo .. " – " .. hi
            bracketCache[#bracketCache + 1] = bucket
        end
    end

    return bracketCache
end

-- In welchem Abschnitt steckt dieser Dungeon? Gebraucht, damit die
-- Seite beim Wiederbetreten den richtigen aufklappt.
function D.BracketIndexOf(dungeonId)
    for index, bucket in ipairs(D.Brackets()) do
        for _, dungeon in ipairs(bucket.dungeons) do
            if dungeon.id == dungeonId then return index end
        end
    end
    return 1
end

-- Die Fluegel einer Instanz, in der Reihenfolge ihres ersten
-- Auftretens in der Bossliste. `nil`, wenn die Instanz keine hat -
-- und nil heisst hier "am Stueck", nicht "unbekannt".
function D.Wings(dungeon)
    if type(dungeon) ~= "table" then return nil end
    local order, seen = {}, {}
    for _, boss in ipairs(dungeon.bosses or {}) do
        if boss.wing and not seen[boss.wing] then
            seen[boss.wing] = true
            order[#order + 1] = boss.wing
        end
    end
    if #order == 0 then return nil end
    return order
end

-- Die Kaempfe eines Fluegels. Ohne Fluegelangabe alle - so kann die
-- Seite immer dieselbe Funktion rufen.
function D.BossesInWing(dungeon, wing)
    local found = {}
    for _, boss in ipairs((type(dungeon) == "table" and dungeon.bosses) or {}) do
        if wing == nil or boss.wing == wing then found[#found + 1] = boss end
    end
    return found
end
