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
                w = 512, h = 128, focusX = 0.58,
            },
            -- Schnitt aus magmatus.png: x 0, y 110, 1300x325.
            magmatus = {
                file = ART .. "hall_of_thanes/magmatus",
                w = 512, h = 128, focusX = 0.56,
            },
            -- Schnitt aus plunder.png: x 100, y 40, 1300x325.
            plunder = {
                file = ART .. "hall_of_thanes/plunder",
                w = 512, h = 128, focusX = 0.66,
            },
            -- Schnitt aus durgen_dirgehammer.png: x 100, y 25, 1400x350.
            durgen_dirgehammer = {
                file = ART .. "hall_of_thanes/durgen_dirgehammer",
                w = 512, h = 128, focusX = 0.60,
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
                w = 512, h = 128, focusX = 0.60,
            },
            taragaman = {
                file = ART .. "ragefire_chasm/taragaman",
                w = 512, h = 128, focusX = 0.62,
            },
            jergosh = {
                file = ART .. "ragefire_chasm/jergosh",
                w = 512, h = 128, focusX = 0.60,
            },
            bazzalan = {
                file = ART .. "ragefire_chasm/bazzalan",
                w = 512, h = 128, focusX = 0.58,
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
                w = 512, h = 128, focusX = 0.60,
            },
            the_abandoned = {
                file = ART .. "ruins_of_lordaeron/the_abandoned",
                w = 512, h = 128, focusX = 0.60,
            },
            the_butcher = {
                file = ART .. "ruins_of_lordaeron/the_butcher",
                w = 512, h = 128, focusX = 0.58,
            },
            lordaeron_captain = {
                file = ART .. "ruins_of_lordaeron/lordaeron_captain",
                w = 512, h = 128, focusX = 0.60,
            },
            bjork = {
                file = ART .. "ruins_of_lordaeron/bjork",
                w = 512, h = 128, focusX = 0.60,
            },
            rathmael = {
                file = ART .. "ruins_of_lordaeron/rathmael",
                w = 512, h = 128, focusX = 0.60,
            },
            viktor_the_vile = {
                file = ART .. "ruins_of_lordaeron/viktor_the_vile",
                w = 512, h = 128, focusX = 0.58,
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
                w = 512, h = 128, focusX = 0.58,
            },
            miner_johnson = {
                file = ART .. "the_deadmines/miner_johnson",
                w = 512, h = 128, focusX = 0.60,
            },
            sneeds_shredder = {
                file = ART .. "the_deadmines/sneeds_shredder",
                w = 512, h = 128, focusX = 0.60,
            },
            gilnid = {
                file = ART .. "the_deadmines/gilnid",
                w = 512, h = 128, focusX = 0.60,
            },
            mr_smite = {
                file = ART .. "the_deadmines/mr_smite",
                w = 512, h = 128, focusX = 0.60,
            },
            captain_greenskin = {
                file = ART .. "the_deadmines/captain_greenskin",
                w = 512, h = 128, focusX = 0.58,
            },
            edwin_vancleef = {
                file = ART .. "the_deadmines/edwin_vancleef",
                w = 512, h = 128, focusX = 0.62,
            },
            cookie = {
                file = ART .. "the_deadmines/cookie",
                w = 512, h = 128, focusX = 0.58,
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
                w = 512, h = 128, focusX = 0.60,
            },
            razorclaw = {
                file = ART .. "shadowfang_keep/razorclaw",
                w = 512, h = 128, focusX = 0.60,
            },
            baron_silverlaine = {
                file = ART .. "shadowfang_keep/baron_silverlaine",
                w = 512, h = 128, focusX = 0.62,
            },
            commander_springvale = {
                file = ART .. "shadowfang_keep/commander_springvale",
                w = 512, h = 128, focusX = 0.60,
            },
            odo = {
                file = ART .. "shadowfang_keep/odo",
                w = 512, h = 128, focusX = 0.60,
            },
            deathsworn_captain = {
                file = ART .. "shadowfang_keep/deathsworn_captain",
                w = 512, h = 128, focusX = 0.60,
            },
            fenrus = {
                file = ART .. "shadowfang_keep/fenrus",
                w = 512, h = 128, focusX = 0.60,
            },
            wolf_master_nandos = {
                file = ART .. "shadowfang_keep/wolf_master_nandos",
                w = 512, h = 128, focusX = 0.60,
            },
            archmage_arugal = {
                file = ART .. "shadowfang_keep/archmage_arugal",
                w = 512, h = 128, focusX = 0.60,
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

    razorfen_downs = {
        -- Originale 1983x793, Banner y 100, Bosse 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "razorfen_downs/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            tutenkash = {
                file = ART .. "razorfen_downs/tutenkash",
                w = 512, h = 128, focusX = 0.55,
            },
            mordresh = {
                file = ART .. "razorfen_downs/mordresh",
                w = 512, h = 128, focusX = 0.55,
            },
            glutton = {
                file = ART .. "razorfen_downs/glutton",
                w = 512, h = 128, focusX = 0.55,
            },
            plaguemaw = {
                file = ART .. "razorfen_downs/plaguemaw",
                w = 512, h = 128, focusX = 0.55,
            },
            ragglesnout = {
                file = ART .. "razorfen_downs/ragglesnout",
                w = 512, h = 128, focusX = 0.55,
            },
            amnennar = {
                file = ART .. "razorfen_downs/amnennar",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    uldaman = {
        -- Originale 1983x793, Banner y 80, Bosse y 60, 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "uldaman/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            revelosh = {
                file = ART .. "uldaman/revelosh",
                w = 512, h = 128, focusX = 0.55,
            },
            the_lost_dwarves = {
                file = ART .. "uldaman/the_lost_dwarves",
                w = 512, h = 128, focusX = 0.55,
            },
            ironaya = {
                file = ART .. "uldaman/ironaya",
                w = 512, h = 128, focusX = 0.55,
            },
            ancient_stone_keeper = {
                file = ART .. "uldaman/ancient_stone_keeper",
                w = 512, h = 128, focusX = 0.55,
            },
            galgann = {
                file = ART .. "uldaman/galgann",
                w = 512, h = 128, focusX = 0.55,
            },
            grimlok = {
                file = ART .. "uldaman/grimlok",
                w = 512, h = 128, focusX = 0.55,
            },
            archaedas = {
                file = ART .. "uldaman/archaedas",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    zulfarrak = {
        -- Originale 1983x793, Banner y 80, Bosse y 60, 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "zulfarrak/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            antusul = {
                file = ART .. "zulfarrak/antusul",
                w = 512, h = 128, focusX = 0.55,
            },
            theka = {
                file = ART .. "zulfarrak/theka",
                w = 512, h = 128, focusX = 0.55,
            },
            zumrah = {
                file = ART .. "zulfarrak/zumrah",
                w = 512, h = 128, focusX = 0.55,
            },
            sergeant_bly = {
                file = ART .. "zulfarrak/sergeant_bly",
                w = 512, h = 128, focusX = 0.55,
            },
            nekrum = {
                file = ART .. "zulfarrak/nekrum",
                w = 512, h = 128, focusX = 0.55,
            },
            sezzziz = {
                file = ART .. "zulfarrak/sezzziz",
                w = 512, h = 128, focusX = 0.55,
            },
            ukorz = {
                file = ART .. "zulfarrak/ukorz",
                w = 512, h = 128, focusX = 0.55,
            },
            gahzrilla = {
                file = ART .. "zulfarrak/gahzrilla",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    maraudon = {
        -- Originale 1983x793, Banner y 80, Bosse y 60, 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "maraudon/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            noxxion = {
                file = ART .. "maraudon/noxxion",
                w = 512, h = 128, focusX = 0.55,
            },
            razorlash = {
                file = ART .. "maraudon/razorlash",
                w = 512, h = 128, focusX = 0.55,
            },
            lord_vyletongue = {
                file = ART .. "maraudon/lord_vyletongue",
                w = 512, h = 128, focusX = 0.55,
            },
            meshlok = {
                file = ART .. "maraudon/meshlok",
                w = 512, h = 128, focusX = 0.55,
            },
            tinkerer_gizlock = {
                file = ART .. "maraudon/tinkerer_gizlock",
                w = 512, h = 128, focusX = 0.55,
            },
            celebras = {
                file = ART .. "maraudon/celebras",
                w = 512, h = 128, focusX = 0.55,
            },
            landslide = {
                file = ART .. "maraudon/landslide",
                w = 512, h = 128, focusX = 0.55,
            },
            rotgrip = {
                file = ART .. "maraudon/rotgrip",
                w = 512, h = 128, focusX = 0.55,
            },
            princess_theradras = {
                file = ART .. "maraudon/princess_theradras",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    sunken_temple = {
        -- Originale 1983x793, Banner y 80, Bosse y 60, 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "sunken_temple/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            atalalarion = {
                file = ART .. "sunken_temple/atalalarion",
                w = 512, h = 128, focusX = 0.55,
            },
            jammalan = {
                file = ART .. "sunken_temple/jammalan",
                w = 512, h = 128, focusX = 0.55,
            },
            ogom = {
                file = ART .. "sunken_temple/ogom",
                w = 512, h = 128, focusX = 0.55,
            },
            dreamscythe = {
                file = ART .. "sunken_temple/dreamscythe",
                w = 512, h = 128, focusX = 0.55,
            },
            weaver = {
                file = ART .. "sunken_temple/weaver",
                w = 512, h = 128, focusX = 0.55,
            },
            morphaz = {
                file = ART .. "sunken_temple/morphaz",
                w = 512, h = 128, focusX = 0.55,
            },
            hazzas = {
                file = ART .. "sunken_temple/hazzas",
                w = 512, h = 128, focusX = 0.55,
            },
            eranikus = {
                file = ART .. "sunken_temple/eranikus",
                w = 512, h = 128, focusX = 0.55,
            },
            avatar_of_hakkar = {
                file = ART .. "sunken_temple/avatar_of_hakkar",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    blackrock_depths = {
        -- Originale 1983x793, Banner y 80, Bosse y 60, 512x128 (siehe make_artwork.py).
        header = {
            file = ART .. "blackrock_depths/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            lord_roccor = {
                file = ART .. "blackrock_depths/lord_roccor",
                w = 512, h = 128, focusX = 0.55,
            },
            high_interrogator_gerstahn = {
                file = ART .. "blackrock_depths/high_interrogator_gerstahn",
                w = 512, h = 128, focusX = 0.55,
            },
            houndmaster_grebmar = {
                file = ART .. "blackrock_depths/houndmaster_grebmar",
                w = 512, h = 128, focusX = 0.55,
            },
            ring_of_law = {
                file = ART .. "blackrock_depths/ring_of_law",
                w = 512, h = 128, focusX = 0.55,
            },
            theldren = {
                file = ART .. "blackrock_depths/theldren",
                w = 512, h = 128, focusX = 0.55,
            },
            pyromancer_loregrain = {
                file = ART .. "blackrock_depths/pyromancer_loregrain",
                w = 512, h = 128, focusX = 0.55,
            },
            golem_lord_argelmach = {
                file = ART .. "blackrock_depths/golem_lord_argelmach",
                w = 512, h = 128, focusX = 0.55,
            },
            hurley_blackbreath = {
                file = ART .. "blackrock_depths/hurley_blackbreath",
                w = 512, h = 128, focusX = 0.55,
            },
            phalanx = {
                file = ART .. "blackrock_depths/phalanx",
                w = 512, h = 128, focusX = 0.55,
            },
            ribbly_screwspigot = {
                file = ART .. "blackrock_depths/ribbly_screwspigot",
                w = 512, h = 128, focusX = 0.55,
            },
            plugger_spazzring = {
                file = ART .. "blackrock_depths/plugger_spazzring",
                w = 512, h = 128, focusX = 0.55,
            },
            lord_incendius = {
                file = ART .. "blackrock_depths/lord_incendius",
                w = 512, h = 128, focusX = 0.55,
            },
            warder_stilgiss = {
                file = ART .. "blackrock_depths/warder_stilgiss",
                w = 512, h = 128, focusX = 0.55,
            },
            watchman_doomgrip = {
                file = ART .. "blackrock_depths/watchman_doomgrip",
                w = 512, h = 128, focusX = 0.55,
            },
            fineous_darkvire = {
                file = ART .. "blackrock_depths/fineous_darkvire",
                w = 512, h = 128, focusX = 0.55,
            },
            baelgar = {
                file = ART .. "blackrock_depths/baelgar",
                w = 512, h = 128, focusX = 0.55,
            },
            general_angerforge = {
                file = ART .. "blackrock_depths/general_angerforge",
                w = 512, h = 128, focusX = 0.55,
            },
            ambassador_flamelash = {
                file = ART .. "blackrock_depths/ambassador_flamelash",
                w = 512, h = 128, focusX = 0.55,
            },
            panzor = {
                file = ART .. "blackrock_depths/panzor",
                w = 512, h = 128, focusX = 0.55,
            },
            the_seven = {
                file = ART .. "blackrock_depths/the_seven",
                w = 512, h = 128, focusX = 0.55,
            },
            magmus = {
                file = ART .. "blackrock_depths/magmus",
                w = 512, h = 128, focusX = 0.55,
            },
            dagran_thaurissan = {
                file = ART .. "blackrock_depths/dagran_thaurissan",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    dire_maul = {
        -- Originale meist 1983x793 (Bosse y 60); Banner und die Oger im Norden
        -- haben eigene Masse und Ausschnitte (siehe make_artwork.py).
        header = {
            file = ART .. "dire_maul/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            pusillin = {
                file = ART .. "dire_maul/pusillin",
                w = 512, h = 128, focusX = 0.55,
            },
            zevrim_thornhoof = {
                file = ART .. "dire_maul/zevrim_thornhoof",
                w = 512, h = 128, focusX = 0.55,
            },
            hydrospawn = {
                file = ART .. "dire_maul/hydrospawn",
                w = 512, h = 128, focusX = 0.55,
            },
            lethtendris = {
                file = ART .. "dire_maul/lethtendris",
                w = 512, h = 128, focusX = 0.55,
            },
            alzzin = {
                file = ART .. "dire_maul/alzzin",
                w = 512, h = 128, focusX = 0.55,
            },
            isalien = {
                file = ART .. "dire_maul/isalien",
                w = 512, h = 128, focusX = 0.55,
            },
            tendris_warpwood = {
                file = ART .. "dire_maul/tendris_warpwood",
                w = 512, h = 128, focusX = 0.55,
            },
            illyanna_ravenoak = {
                file = ART .. "dire_maul/illyanna_ravenoak",
                w = 512, h = 128, focusX = 0.55,
            },
            magister_kalendris = {
                file = ART .. "dire_maul/magister_kalendris",
                w = 512, h = 128, focusX = 0.55,
            },
            tsuzee = {
                file = ART .. "dire_maul/tsuzee",
                w = 512, h = 128, focusX = 0.55,
            },
            immolthar = {
                file = ART .. "dire_maul/immolthar",
                w = 512, h = 128, focusX = 0.55,
            },
            prince_tortheldrin = {
                file = ART .. "dire_maul/prince_tortheldrin",
                w = 512, h = 128, focusX = 0.55,
            },
            lord_helnurath = {
                file = ART .. "dire_maul/lord_helnurath",
                w = 512, h = 128, focusX = 0.55,
            },
            guard_moldar = {
                file = ART .. "dire_maul/guard_moldar",
                w = 512, h = 128, focusX = 0.55,
            },
            stomper_kreeg = {
                file = ART .. "dire_maul/stomper_kreeg",
                w = 512, h = 128, focusX = 0.55,
            },
            guard_fengus = {
                file = ART .. "dire_maul/guard_fengus",
                w = 512, h = 128, focusX = 0.55,
            },
            guard_slipkik = {
                file = ART .. "dire_maul/guard_slipkik",
                w = 512, h = 128, focusX = 0.55,
            },
            captain_kromcrush = {
                file = ART .. "dire_maul/captain_kromcrush",
                w = 512, h = 128, focusX = 0.55,
            },
            king_gordok = {
                file = ART .. "dire_maul/king_gordok",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    lower_blackrock_spire = {
        -- Originale hochkant, Ausschnitt je Bild (siehe make_artwork.py).
        header = {
            file = ART .. "lower_blackrock_spire/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            highlord_omokk = {
                file = ART .. "lower_blackrock_spire/highlord_omokk",
                w = 512, h = 128, focusX = 0.55,
            },
            shadow_hunter_voshgajin = {
                file = ART .. "lower_blackrock_spire/shadow_hunter_voshgajin",
                w = 512, h = 128, focusX = 0.55,
            },
            war_master_voone = {
                file = ART .. "lower_blackrock_spire/war_master_voone",
                w = 512, h = 128, focusX = 0.55,
            },
            urok_doomhowl = {
                file = ART .. "lower_blackrock_spire/urok_doomhowl",
                w = 512, h = 128, focusX = 0.55,
            },
            mother_smolderweb = {
                file = ART .. "lower_blackrock_spire/mother_smolderweb",
                w = 512, h = 128, focusX = 0.55,
            },
            quartermaster_zigris = {
                file = ART .. "lower_blackrock_spire/quartermaster_zigris",
                w = 512, h = 128, focusX = 0.55,
            },
            halycon = {
                file = ART .. "lower_blackrock_spire/halycon",
                w = 512, h = 128, focusX = 0.55,
            },
            gizrul = {
                file = ART .. "lower_blackrock_spire/gizrul",
                w = 512, h = 128, focusX = 0.55,
            },
            overlord_wyrmthalak = {
                file = ART .. "lower_blackrock_spire/overlord_wyrmthalak",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },
    upper_blackrock_spire = {
        -- Originale 1448x1086 u. a., Ausschnitt je Bild (siehe make_artwork.py).
        header = {
            file = ART .. "upper_blackrock_spire/header",
            w = 1024, h = 256, focusX = 0.6,
        },
        bosses = {
            pyroguard_emberseer = {
                file = ART .. "upper_blackrock_spire/pyroguard_emberseer",
                w = 512, h = 128, focusX = 0.5,
            },
            solakar_flamewreath = {
                file = ART .. "upper_blackrock_spire/solakar_flamewreath",
                w = 512, h = 128, focusX = 0.45,
            },
            goraluk_anvilcrack = {
                file = ART .. "upper_blackrock_spire/goraluk_anvilcrack",
                w = 512, h = 128, focusX = 0.45,
            },
            jed_runewatcher = {
                file = ART .. "upper_blackrock_spire/jed_runewatcher",
                w = 512, h = 128, focusX = 0.55,
            },
            warchief_rend_blackhand = {
                file = ART .. "upper_blackrock_spire/warchief_rend_blackhand",
                w = 512, h = 128, focusX = 0.55,
            },
            the_beast = {
                file = ART .. "upper_blackrock_spire/the_beast",
                w = 512, h = 128, focusX = 0.55,
            },
            lord_valthalak = {
                file = ART .. "upper_blackrock_spire/lord_valthalak",
                w = 512, h = 128, focusX = 0.4,
            },
            general_drakkisath = {
                file = ART .. "upper_blackrock_spire/general_drakkisath",
                w = 512, h = 128, focusX = 0.6,
            },
        },
    },
    stratholme = {
        -- Originale 1514x1039, Ausschnitt je Bild (siehe make_artwork.py).
        header = {
            file = ART .. "stratholme/header",
            w = 1024, h = 256, focusX = 0.5,
        },
        bosses = {
            fras_siabi = {
                file = ART .. "stratholme/fras_siabi",
                w = 512, h = 128, focusX = 0.55,
            },
            hearthsinger_forresten = {
                file = ART .. "stratholme/hearthsinger_forresten",
                w = 512, h = 128, focusX = 0.55,
            },
            the_unforgiven = {
                file = ART .. "stratholme/the_unforgiven",
                w = 512, h = 128, focusX = 0.55,
            },
            timmy_the_cruel = {
                file = ART .. "stratholme/timmy_the_cruel",
                w = 512, h = 128, focusX = 0.55,
            },
            malor_the_zealous = {
                file = ART .. "stratholme/malor_the_zealous",
                w = 512, h = 128, focusX = 0.55,
            },
            crimson_hammersmith = {
                file = ART .. "stratholme/crimson_hammersmith",
                w = 512, h = 128, focusX = 0.55,
            },
            cannon_master_willey = {
                file = ART .. "stratholme/cannon_master_willey",
                w = 512, h = 128, focusX = 0.55,
            },
            archivist_galford = {
                file = ART .. "stratholme/archivist_galford",
                w = 512, h = 128, focusX = 0.55,
            },
            balnazzar = {
                file = ART .. "stratholme/balnazzar",
                w = 512, h = 128, focusX = 0.55,
            },
            postmaster_malown = {
                file = ART .. "stratholme/postmaster_malown",
                w = 512, h = 128, focusX = 0.55,
            },
            jarien_and_sothos = {
                file = ART .. "stratholme/jarien_and_sothos",
                w = 512, h = 128, focusX = 0.55,
            },
            skul = {
                file = ART .. "stratholme/skul",
                w = 512, h = 128, focusX = 0.55,
            },
            stonespine = {
                file = ART .. "stratholme/stonespine",
                w = 512, h = 128, focusX = 0.55,
            },
            baroness_anastari = {
                file = ART .. "stratholme/baroness_anastari",
                w = 512, h = 128, focusX = 0.55,
            },
            nerubenkan = {
                file = ART .. "stratholme/nerubenkan",
                w = 512, h = 128, focusX = 0.55,
            },
            maleki_the_pallid = {
                file = ART .. "stratholme/maleki_the_pallid",
                w = 512, h = 128, focusX = 0.55,
            },
            magistrate_barthilas = {
                file = ART .. "stratholme/magistrate_barthilas",
                w = 512, h = 128, focusX = 0.55,
            },
            ramstein = {
                file = ART .. "stratholme/ramstein",
                w = 512, h = 128, focusX = 0.55,
            },
            baron_rivendare = {
                file = ART .. "stratholme/baron_rivendare",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },
    scholomance = {
        -- Originale 1514x1039, Ausschnitt je Bild (siehe make_artwork.py).
        header = {
            file = ART .. "scholomance/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            blood_steward = {
                file = ART .. "scholomance/blood_steward",
                w = 512, h = 128, focusX = 0.55,
            },
            kirtonos = {
                file = ART .. "scholomance/kirtonos",
                w = 512, h = 128, focusX = 0.55,
            },
            jandice_barov = {
                file = ART .. "scholomance/jandice_barov",
                w = 512, h = 128, focusX = 0.55,
            },
            rattlegore = {
                file = ART .. "scholomance/rattlegore",
                w = 512, h = 128, focusX = 0.55,
            },
            marduk_blackpool = {
                file = ART .. "scholomance/marduk_blackpool",
                w = 512, h = 128, focusX = 0.55,
            },
            vectus = {
                file = ART .. "scholomance/vectus",
                w = 512, h = 128, focusX = 0.55,
            },
            ras_frostwhisper = {
                file = ART .. "scholomance/ras_frostwhisper",
                w = 512, h = 128, focusX = 0.55,
            },
            instructor_malicia = {
                file = ART .. "scholomance/instructor_malicia",
                w = 512, h = 128, focusX = 0.55,
            },
            theolen_krastinov = {
                file = ART .. "scholomance/theolen_krastinov",
                w = 512, h = 128, focusX = 0.55,
            },
            lorekeeper_polkelt = {
                file = ART .. "scholomance/lorekeeper_polkelt",
                w = 512, h = 128, focusX = 0.55,
            },
            the_ravenian = {
                file = ART .. "scholomance/the_ravenian",
                w = 512, h = 128, focusX = 0.55,
            },
            lord_alexei_barov = {
                file = ART .. "scholomance/lord_alexei_barov",
                w = 512, h = 128, focusX = 0.55,
            },
            lady_illucia_barov = {
                file = ART .. "scholomance/lady_illucia_barov",
                w = 512, h = 128, focusX = 0.55,
            },
            darkmaster_gandling = {
                file = ART .. "scholomance/darkmaster_gandling",
                w = 512, h = 128, focusX = 0.55,
            },
        },
    },

    drowned_city = {
        -- Originale 1983x793, Banner y 60. Bilder liegen fuer sieben Gestalten
        -- vor, im Bestand steht aber nur Zul'Alai (data/dungeons.lua) - die
        -- anderen bekommen erst ein Bild, wenn sie eine Herkunft haben.
        header = {
            file = ART .. "drowned_city/header",
            w = 1024, h = 256, focusX = 0.58,
        },
        bosses = {
            zulalai = {
                file = ART .. "drowned_city/zulalai",
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
                w = 512, h = 128, focusX = 0.60,
            },
            lord_cobrahn = {
                file = ART .. "wailing_caverns/lord_cobrahn",
                w = 512, h = 128, focusX = 0.60,
            },
            kresh = {
                file = ART .. "wailing_caverns/kresh",
                w = 512, h = 128, focusX = 0.58,
            },
            lord_pythas = {
                file = ART .. "wailing_caverns/lord_pythas",
                w = 512, h = 128, focusX = 0.60,
            },
            skum = {
                file = ART .. "wailing_caverns/skum",
                w = 512, h = 128, focusX = 0.60,
            },
            lord_serpentis = {
                file = ART .. "wailing_caverns/lord_serpentis",
                w = 512, h = 128, focusX = 0.60,
            },
            verdan = {
                file = ART .. "wailing_caverns/verdan",
                w = 512, h = 128, focusX = 0.60,
            },
            deviate_faerie_dragon = {
                file = ART .. "wailing_caverns/deviate_faerie_dragon",
                w = 512, h = 128, focusX = 0.62,
            },
            mutanus = {
                file = ART .. "wailing_caverns/mutanus",
                w = 512, h = 128, focusX = 0.58,
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
-- 1024x512 (seit 6.29.7.0), also senkrecht gestaucht (Zweierpotenz); weil
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
