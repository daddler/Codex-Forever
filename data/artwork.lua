--------------------------------------------------
-- WeintCodex :: Artwork
--
-- EIN BILD IST HIER KEINE AUSKUNFT.
--
-- Diese Datei ist die einzige Stelle, an der das Addon einen
-- Bildpfad kennt, und sie steht unter denselben zwei Regeln wie
-- jede andere Bestandsdatei - nur beantworten sie hier etwas
-- anderes.
--
--   KEIN PFAD OHNE DATEI. Ein Texturpfad, hinter dem nichts liegt,
--   zeichnet im Spiel ein gruenes Rechteck, und ein gruenes Rechteck
--   sieht aus wie ein Bild. Was hier steht, liegt in media/ -
--   .github/tests/data_test.lua prueft jede Zeile dieser Tabelle
--   gegen den Ordner. Deshalb steht hier kein Pfad in den
--   Spielclient: welche Texturen Forever vergibt, weiss niemand in
--   diesem Projekt, und geraten wird nicht.
--
--   KEIN BILD, DAS ETWAS BEHAUPTET. Was in media/dungeons liegt,
--   ist eigenes Material und KEINE Abbildung des Spiels: so sieht
--   der Boss im Client nicht aus, so sieht die Instanz im Client
--   nicht aus, und keine Zeile dieser Tabelle sagt etwas darueber.
--   Ein Bild ist hier Atmosphaere und nichts sonst. Alles, was die
--   Seite BEHAUPTET - wie viele Bosse, in welcher Reihenfolge, wo
--   einer steht -, steht weiter in data/dungeons.lua und traegt dort
--   seine Herkunft (data/sources.lua). Ein bebilderter Dungeon ist
--   deshalb kein besser belegter: die Hall of Thanes bleibt
--   `community`, mit Bild wie ohne.
--
-- WARUM DAS NICHT IM WIDERSPRUCH ZU "KEINE BILDER" STEHT. Bis
-- 5.2.0.6 stand in modules/dungeonpages.lua, dass dieses Addon keine
-- Bilder liefern kann, und die zwei Gruende dort gelten unveraendert:
-- Blizzards Kartenmaterial ist nicht veroeffentlicht, und es gehoert
-- uns nicht. Beides betrifft BLIZZARDS Material. Eigenes Material
-- faellt unter keinen der beiden Gruende - es behauptet nur nichts,
-- und genau deshalb steht hier, dass es nichts behauptet.
--
-- WIE EIN EINTRAG AUSSIEHT:
--
--   file    Pfad unterhalb von media/, ohne Endung (WoW sucht sich
--           .blp/.tga selbst). Schraegstriche; core/ui.lua macht
--           daraus Backslashes.
--   w, h    Die Masse der Datei. Sie stehen hier und werden nicht
--           gemessen: der Prueflauf hat keinen Client, der eine
--           Textur vermessen koennte, und der Ausschnitt muss in
--           Spiel und Lauf derselbe sein (WeintCodex.CoverCoords).
--   focusX  Wo das Motiv liegt, 0..1. Wird nur gebraucht, wenn der
--   focusY  Kasten SCHMALER ist als das Bild - dann entscheidet der
--           Fokus, welcher Teil stehen bleibt. Fehlt er, ist es die
--           Mitte.
--
-- WIE DIE DATEIEN GEMACHT SIND (damit sie sich nachbauen lassen):
-- aus den Originalen 1983x793 bzw. 1672x941, mit einem von Hand
-- gesetzten 4:1-Ausschnitt (das Motiv RECHTS der Mitte, weil links
-- Nummer und Name stehen), auf 1024x256 skaliert und als BLP2/DXT1
-- OHNE Mipmaps abgelegt - rund 128 KB je Bild statt 2,3 MB. Ohne
-- Mipmaps, weil jedes Bild in einer UI-Kachel fester Groesse steht
-- und nie aus der Distanz gesehen wird; die Kette bis Breite 4 kostete
-- pro Bild rund 43 KB, die kein Frame je anfordert. Der Ausschnitt
-- steht je Datei darunter.
--
-- HALL OF THANES, RAGEFIRE CHASM, RUINS OF LORDAERON, WAILING CAVERNS,
-- THE DEADMINES UND SHADOWFANG KEEP SIND DIE ERSTEN SECHS BEBILDERTEN
-- DUNGEONS. Eine Seite ohne Eintrag sieht aus wie vor 5.2.0.7 (siehe WeintCodex.Artwork, Punkt 1)
-- - es braucht dafuer keine Zeile hier und keine Fallunterscheidung dort.
--
-- Material gibt es fuer diese fünf; die anderen Dungeons bleiben
-- ohne Artwork, bis eigenes Material vorliegt.
--------------------------------------------------

WeintCodex = WeintCodex or {}

local ART = "dungeons/"

WeintCodex.Artworks = {

    hall_of_thanes = {

        -- Der Thronsaal, Blick zum Sitz der Thane. Schnitt aus
        -- header.png (1983x793): x 0, y 69, 1983x496.
        --
        -- Der Fokus liegt RECHTS und nicht in der Mitte: wird die
        -- Kopfkarte schmal, soll der Thron stehen bleiben und nicht
        -- der Treppenaufgang - und die linke Haelfte ist die dunkle,
        -- auf der Kennzeichnung, Name und Themensatz stehen.
        header = {
            file = ART .. "hall_of_thanes/header",
            w = 1024, h = 256, focusX = 0.58,
        },

        bosses = {
            -- Schnitt aus faldrim_anvilmar.png (1672x941):
            -- x 0, y 8, 1300x325.
            faldrim_anvilmar = {
                file = ART .. "hall_of_thanes/faldrim_anvilmar",
                w = 1024, h = 256, focusX = 0.58,
            },
            -- Schnitt aus magmatus.png: x 0, y 110, 1300x325.
            magmatus = {
                file = ART .. "hall_of_thanes/magmatus",
                w = 1024, h = 256, focusX = 0.56,
            },
            -- Schnitt aus plunder.png: x 100, y 40, 1300x325.
            plunder = {
                file = ART .. "hall_of_thanes/plunder",
                w = 1024, h = 256, focusX = 0.66,
            },
            -- Schnitt aus durgen_dirgehammer.png: x 100, y 25, 1400x350.
            durgen_dirgehammer = {
                file = ART .. "hall_of_thanes/durgen_dirgehammer",
                w = 1024, h = 256, focusX = 0.60,
            },
        },
    },

    ragefire_chasm = {
        header = {
            file = ART .. "ragefire_chasm/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            oggleflint = {
                file = ART .. "ragefire_chasm/oggleflint",
                w = 1024, h = 256, focusX = 0.60,
            },
            taragaman = {
                file = ART .. "ragefire_chasm/taragaman",
                w = 1024, h = 256, focusX = 0.62,
            },
            jergosh = {
                file = ART .. "ragefire_chasm/jergosh",
                w = 1024, h = 256, focusX = 0.60,
            },
            bazzalan = {
                file = ART .. "ragefire_chasm/bazzalan",
                w = 1024, h = 256, focusX = 0.58,
            },
        },
    },

    ruins_of_lordaeron = {
        header = {
            file = ART .. "ruins_of_lordaeron/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            witherfang = {
                file = ART .. "ruins_of_lordaeron/witherfang",
                w = 1024, h = 256, focusX = 0.60,
            },
            the_abandoned = {
                file = ART .. "ruins_of_lordaeron/the_abandoned",
                w = 1024, h = 256, focusX = 0.60,
            },
            the_butcher = {
                file = ART .. "ruins_of_lordaeron/the_butcher",
                w = 1024, h = 256, focusX = 0.58,
            },
            lordaeron_captain = {
                file = ART .. "ruins_of_lordaeron/lordaeron_captain",
                w = 1024, h = 256, focusX = 0.60,
            },
            bjork = {
                file = ART .. "ruins_of_lordaeron/bjork",
                w = 1024, h = 256, focusX = 0.60,
            },
            rathmael = {
                file = ART .. "ruins_of_lordaeron/rathmael",
                w = 1024, h = 256, focusX = 0.60,
            },
            viktor_the_vile = {
                file = ART .. "ruins_of_lordaeron/viktor_the_vile",
                w = 1024, h = 256, focusX = 0.58,
            },
        },
    },

    the_deadmines = {
        -- Schnitte aus den gelieferten Originalen; alle 4:1 auf 1024x256.
        header = {
            file = ART .. "the_deadmines/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            rhahkzor = {
                file = ART .. "the_deadmines/rhahkzor",
                w = 1024, h = 256, focusX = 0.58,
            },
            miner_johnson = {
                file = ART .. "the_deadmines/miner_johnson",
                w = 1024, h = 256, focusX = 0.60,
            },
            sneeds_shredder = {
                file = ART .. "the_deadmines/sneeds_shredder",
                w = 1024, h = 256, focusX = 0.60,
            },
            gilnid = {
                file = ART .. "the_deadmines/gilnid",
                w = 1024, h = 256, focusX = 0.60,
            },
            mr_smite = {
                file = ART .. "the_deadmines/mr_smite",
                w = 1024, h = 256, focusX = 0.60,
            },
            captain_greenskin = {
                file = ART .. "the_deadmines/captain_greenskin",
                w = 1024, h = 256, focusX = 0.58,
            },
            edwin_vancleef = {
                file = ART .. "the_deadmines/edwin_vancleef",
                w = 1024, h = 256, focusX = 0.62,
            },
            cookie = {
                file = ART .. "the_deadmines/cookie",
                w = 1024, h = 256, focusX = 0.58,
            },
        },
    },

    shadowfang_keep = {
        -- Header aus header(4).png (1983x793): x 0, y 69, 1983x496.
        -- Bossbilder: x 0, y 0, 1672x418.
        header = {
            file = ART .. "shadowfang_keep/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            rethilgore = {
                file = ART .. "shadowfang_keep/rethilgore",
                w = 1024, h = 256, focusX = 0.60,
            },
            razorclaw = {
                file = ART .. "shadowfang_keep/razorclaw",
                w = 1024, h = 256, focusX = 0.60,
            },
            baron_silverlaine = {
                file = ART .. "shadowfang_keep/baron_silverlaine",
                w = 1024, h = 256, focusX = 0.62,
            },
            commander_springvale = {
                file = ART .. "shadowfang_keep/commander_springvale",
                w = 1024, h = 256, focusX = 0.60,
            },
            odo = {
                file = ART .. "shadowfang_keep/odo",
                w = 1024, h = 256, focusX = 0.60,
            },
            deathsworn_captain = {
                file = ART .. "shadowfang_keep/deathsworn_captain",
                w = 1024, h = 256, focusX = 0.60,
            },
            fenrus = {
                file = ART .. "shadowfang_keep/fenrus",
                w = 1024, h = 256, focusX = 0.60,
            },
            wolf_master_nandos = {
                file = ART .. "shadowfang_keep/wolf_master_nandos",
                w = 1024, h = 256, focusX = 0.60,
            },
            archmage_arugal = {
                file = ART .. "shadowfang_keep/archmage_arugal",
                w = 1024, h = 256, focusX = 0.60,
            },
        },
    },

    excavation_site = {
        -- Alle Originale 1983x793. Banner: x 0, y 0, 1983x496 (ganz oben).
        -- Bossbilder 512x128 (Karten sind hoechstens ~425x80):
        -- saltspine y 150, shadetooth y 20, relic_guardian y 30.
        header = {
            file = ART .. "excavation_site/header",
            w = 1024, h = 256, focusX = 0.60,
        },
        bosses = {
            saltspine = {
                file = ART .. "excavation_site/saltspine",
                w = 512, h = 128, focusX = 0.65,
            },
            shadetooth = {
                file = ART .. "excavation_site/shadetooth",
                w = 512, h = 128, focusX = 0.62,
            },
            relic_guardian = {
                file = ART .. "excavation_site/relic_guardian",
                w = 512, h = 128, focusX = 0.58,
            },
        },
    },

    blackfathom_deeps = {
        -- Originale 1983x793, Banner y 0, Bosse 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "blackfathom_deeps/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            ghamoora = {
                file = ART .. "blackfathom_deeps/ghamoora",
                w = 512, h = 128, focusX = 0.55,
            },
            lady_sarevess = {
                file = ART .. "blackfathom_deeps/lady_sarevess",
                w = 512, h = 128, focusX = 0.55,
            },
            gelihast = {
                file = ART .. "blackfathom_deeps/gelihast",
                w = 512, h = 128, focusX = 0.55,
            },
            lorgus_jett = {
                file = ART .. "blackfathom_deeps/lorgus_jett",
                w = 512, h = 128, focusX = 0.55,
            },
            baron_aquanis = {
                file = ART .. "blackfathom_deeps/baron_aquanis",
                w = 512, h = 128, focusX = 0.55,
            },
            old_serrakis = {
                file = ART .. "blackfathom_deeps/old_serrakis",
                w = 512, h = 128, focusX = 0.55,
            },
            twilight_lord_kelris = {
                file = ART .. "blackfathom_deeps/twilight_lord_kelris",
                w = 512, h = 128, focusX = 0.55,
            },
            akumai = {
                file = ART .. "blackfathom_deeps/akumai",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    the_stockade = {
        -- Originale 1983x793, Banner y 0, Bosse 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "the_stockade/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            targorr = {
                file = ART .. "the_stockade/targorr",
                w = 512, h = 128, focusX = 0.55,
            },
            kam_deepfury = {
                file = ART .. "the_stockade/kam_deepfury",
                w = 512, h = 128, focusX = 0.55,
            },
            hamhock = {
                file = ART .. "the_stockade/hamhock",
                w = 512, h = 128, focusX = 0.55,
            },
            bazil_thredd = {
                file = ART .. "the_stockade/bazil_thredd",
                w = 512, h = 128, focusX = 0.55,
            },
            dextren_ward = {
                file = ART .. "the_stockade/dextren_ward",
                w = 512, h = 128, focusX = 0.55,
            },
            bruegal = {
                file = ART .. "the_stockade/bruegal",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    city_of_dalaran = {
        -- Originale 1983x793, Banner y 0, Bosse 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "city_of_dalaran/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            atrexis = {
                file = ART .. "city_of_dalaran/atrexis",
                w = 512, h = 128, focusX = 0.55,
            },
            arcane_anomaly = {
                file = ART .. "city_of_dalaran/arcane_anomaly",
                w = 512, h = 128, focusX = 0.55,
            },
            fel_ancient = {
                file = ART .. "city_of_dalaran/fel_ancient",
                w = 512, h = 128, focusX = 0.55,
            },
            unstable_sentinel = {
                file = ART .. "city_of_dalaran/unstable_sentinel",
                w = 512, h = 128, focusX = 0.55,
            },
            mana_devourer = {
                file = ART .. "city_of_dalaran/mana_devourer",
                w = 512, h = 128, focusX = 0.55,
            },
            arcanic_enigma = {
                file = ART .. "city_of_dalaran/arcanic_enigma",
                w = 512, h = 128, focusX = 0.55,
            },
            lyn_the_ignored = {
                file = ART .. "city_of_dalaran/lyn_the_ignored",
                w = 512, h = 128, focusX = 0.55,
            },
            shade_of_the_archmage = {
                file = ART .. "city_of_dalaran/shade_of_the_archmage",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    scarlet_monastery = {
        -- Originale 1983x793, Banner y 0, Bosse 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "scarlet_monastery/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            interrogator_vishas = {
                file = ART .. "scarlet_monastery/interrogator_vishas",
                w = 512, h = 128, focusX = 0.55,
            },
            bloodmage_thalnos = {
                file = ART .. "scarlet_monastery/bloodmage_thalnos",
                w = 512, h = 128, focusX = 0.55,
            },
            ironspine = {
                file = ART .. "scarlet_monastery/ironspine",
                w = 512, h = 128, focusX = 0.55,
            },
            azshir = {
                file = ART .. "scarlet_monastery/azshir",
                w = 512, h = 128, focusX = 0.55,
            },
            fallen_champion = {
                file = ART .. "scarlet_monastery/fallen_champion",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    gnomeregan = {
        -- Originale 1983x793, Banner y 0, Bosse 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "gnomeregan/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            grubbis = {
                file = ART .. "gnomeregan/grubbis",
                w = 512, h = 128, focusX = 0.55,
            },
            viscous_fallout = {
                file = ART .. "gnomeregan/viscous_fallout",
                w = 512, h = 128, focusX = 0.55,
            },
            electrocutioner = {
                file = ART .. "gnomeregan/electrocutioner",
                w = 512, h = 128, focusX = 0.55,
            },
            crowd_pummeler = {
                file = ART .. "gnomeregan/crowd_pummeler",
                w = 512, h = 128, focusX = 0.55,
            },
            dark_iron_ambassador = {
                file = ART .. "gnomeregan/dark_iron_ambassador",
                w = 512, h = 128, focusX = 0.55,
            },
            thermaplugg = {
                file = ART .. "gnomeregan/thermaplugg",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    razorfen_kraul = {
        -- Originale 1983x793, Banner y 0, Bosse 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "razorfen_kraul/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            roogug = {
                file = ART .. "razorfen_kraul/roogug",
                w = 512, h = 128, focusX = 0.55,
            },
            aggem_thorncurse = {
                file = ART .. "razorfen_kraul/aggem_thorncurse",
                w = 512, h = 128, focusX = 0.55,
            },
            death_speaker_jargba = {
                file = ART .. "razorfen_kraul/death_speaker_jargba",
                w = 512, h = 128, focusX = 0.55,
            },
            overlord_ramtusk = {
                file = ART .. "razorfen_kraul/overlord_ramtusk",
                w = 512, h = 128, focusX = 0.55,
            },
            agathelos = {
                file = ART .. "razorfen_kraul/agathelos",
                w = 512, h = 128, focusX = 0.55,
            },
            charlga_razorflank = {
                file = ART .. "razorfen_kraul/charlga_razorflank",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    wailing_caverns = {
        -- Schnitt aus header(2).png (1672x941): x 0, y 240, 1672x418.
        header = {
            file = ART .. "wailing_caverns/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            lady_anacondra = {
                file = ART .. "wailing_caverns/lady_anacondra",
                w = 1024, h = 256, focusX = 0.60,
            },
            lord_cobrahn = {
                file = ART .. "wailing_caverns/lord_cobrahn",
                w = 1024, h = 256, focusX = 0.60,
            },
            kresh = {
                file = ART .. "wailing_caverns/kresh",
                w = 1024, h = 256, focusX = 0.58,
            },
            lord_pythas = {
                file = ART .. "wailing_caverns/lord_pythas",
                w = 1024, h = 256, focusX = 0.60,
            },
            skum = {
                file = ART .. "wailing_caverns/skum",
                w = 1024, h = 256, focusX = 0.60,
            },
            lord_serpentis = {
                file = ART .. "wailing_caverns/lord_serpentis",
                w = 1024, h = 256, focusX = 0.60,
            },
            verdan = {
                file = ART .. "wailing_caverns/verdan",
                w = 1024, h = 256, focusX = 0.60,
            },
            deviate_faerie_dragon = {
                file = ART .. "wailing_caverns/deviate_faerie_dragon",
                w = 1024, h = 256, focusX = 0.62,
            },
            mutanus = {
                file = ART .. "wailing_caverns/mutanus",
                w = 1024, h = 256, focusX = 0.58,
            },
        },
    },
}

--------------------------------------------------
-- Klassen (6.6.3.5)
--------------------------------------------------
-- Ein Bild je Klasse hinter dem Modell im Charakterfenster (Beta-Test:
-- "atmosphaerischer als das, was ich bisher habe"). Eigenes Material wie
-- die Dungeonbilder, und dieselbe Regel: eine Klasse ohne Eintrag sieht
-- aus wie vorher (Hintergrund des Spiels, weich auslaufend).
--
-- w, h sind die Masse des ORIGINALS (2:3). Die Datei selbst ist
-- 1024x1024, also senkrecht gestaucht (Zweierpotenz); weil
-- CoverCoords mit den Massen hier rechnet, steht das Bild im Spiel
-- wieder unverzerrt. Zu sehen ist bei einem Modellfeld von 397x464
-- ein Streifen von 78 % der Hoehe; focusY legt ihn fest.
-- dim: Helligkeit, damit das Modell vor dem Bild steht.
--
-- Hier stehen nur die BILDER (Datei, Masse, Ausschnitt). Welche Klasse
-- welches Bild nutzt, mit welchem Licht und welcher Atmosphaere, steht in
-- data/classthemes.lua (6.6.4.0).

WeintCodex.ClassArtworks = {

    -- Kathedrale, Lichtkreuz ueber dem Altar, Kerzen, Bodenkreis.
    -- priest.webp (1024x1536), ganz.
    PRIEST = {
        file = "classes/priest",
        w = 1024, h = 1536, focusY = 0.55, dim = 0.9,
    },

    -- Jaegerlager im Wald: Tor mit Geweihschaedeln und Hirschbanner,
    -- zwei Woelfe, Wasserfall, Fackeln, nasser Steinboden (6.6.4.4).
    -- hunter.webp (1496x1051), ganz. QUERFORMAT: das Modellfeld (hochkant,
    -- 397x464) zeigt davon rund 60 % der Breite, die volle Hoehe;
    -- focusX 0.44 = das Tor mit Banner hinter der Figur, beide Woelfe im Bild.
    HUNTER = {
        file = "classes/hunter",
        w = 1496, h = 1051, focusX = 0.44, dim = 0.85,
    },

    -- 6.6.4.5: sieben weitere, alle Querformat 1496x1051, ganz. Wie beim
    -- Jaeger zeigt das hochkante Modellfeld rund 60 % der Breite; focusX
    -- legt das Motiv der Mitte hinter die Figur.

    -- Waffenkammer/Thronsaal: Schild auf dem Thron, rote Banner,
    -- Kronleuchter, Aexte, Esse. focusX 0.54 = der Thron.
    WARRIOR = {
        file = "classes/warrior",
        w = 1496, h = 1051, focusX = 0.54, dim = 0.85,
    },
    -- Hain: Geweihtor, zwei Hirsche, Runensteine, Wasserfaelle, Sonne.
    -- focusX 0.56 = das Geweihtor ueber der Treppe.
    DRUID = {
        file = "classes/druid",
        w = 1496, h = 1051, focusX = 0.56, dim = 0.85,
    },
    -- Arkane Halle: Armillarsphaere, Lichtsaeule, schwebende Tuerme,
    -- blaue Flammen, Buecher. focusX 0.55 = Sphaere und Lichtsaeule.
    MAGE = {
        file = "classes/mage",
        w = 1496, h = 1051, focusX = 0.55, dim = 0.85,
    },
    -- Nacht, Diebesversteck: Treppe zu Kapuzenstatuen, schwarze Banner,
    -- Laternen, Truhen, Dolche. focusX 0.55 = Treppe und Tor.
    ROGUE = {
        file = "classes/rogue",
        w = 1496, h = 1051, focusX = 0.55, dim = 0.9,
    },
    -- Violette Bibliothek: gruenes Portal am Ende der Treppe, violette
    -- Flammen, Kapuzenfiguren, Gargoyle. focusX 0.60 = das Portal.
    WARLOCK = {
        file = "classes/warlock",
        w = 1496, h = 1051, focusX = 0.60, dim = 0.85,
    },
    -- Lichthalle: Altar mit Lichtkreuz vor hohem Fenster, zwei
    -- Ritterstatuen, blaue Banner mit Goldstern. focusX 0.60 = der Altar.
    -- Das hellste Bild - dim 0.82.
    PALADIN = {
        file = "classes/paladin",
        w = 1496, h = 1051, focusX = 0.60, dim = 0.82,
    },
    -- Steinkreis: Tor mit Runen, Blitz und Sturmwirbel, Totems,
    -- Wasserfaelle. focusX 0.59 = das Tor ueber der Treppe.
    SHAMAN = {
        file = "classes/shaman",
        w = 1496, h = 1051, focusX = 0.59, dim = 0.85,
    },
}

--------------------------------------------------
-- Zugriff
--------------------------------------------------
-- Zwei Funktionen, und beide geben nil zurueck, wo es nichts gibt.
-- Das ist der ganze Rueckfall: eine Seite fragt, bekommt nil und
-- zeichnet sich wie immer.

WeintCodex.Art = {}

function WeintCodex.Art.Dungeon(dungeonId)
    if not dungeonId then return nil end
    local entry = WeintCodex.Artworks[dungeonId]
    return entry and entry.header or nil
end

function WeintCodex.Art.Boss(dungeonId, bossId)
    if not dungeonId or not bossId then return nil end
    local entry = WeintCodex.Artworks[dungeonId]
    if not entry or not entry.bosses then return nil end
    return entry.bosses[bossId]
end

function WeintCodex.Art.Class(classToken)
    if type(classToken) ~= "string" then return nil end
    return WeintCodex.ClassArtworks[classToken]
end
