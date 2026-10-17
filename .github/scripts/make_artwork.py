"""
Aus einem Original-Artwork die Addon-Fassung machen: zuschneiden,
skalieren, als BLP2/DXT1 ohne Mipmaps ablegen.

    python3 .github/scripts/make_artwork.py ~/Bilder/dungeons
    python3 .github/scripts/make_artwork.py classes ~/Bilder/klassen

Der Ordner enthält die Originale unter den Namen, die unten in JOBS
(bzw. CLASS_JOBS) stehen; geschrieben wird nach media/dungeons/<dungeon>/
bzw. media/classes/.

**Klassenbilder (6.6.3.5)** stehen hinter dem Modell im
Charakterfenster. Sie werden NICHT zugeschnitten: das Modellfeld misst
im Spiel rund 397x464, die Originale sind 2:3 - welcher Streifen zu
sehen ist, rechnet `WeintCodex.CoverCoords` aus `focusY` im Spiel
(data/artwork.lua). Gespeichert wird das ganze Bild auf 1024x512 (seit 6.29.7.0; vorher 1024x1024)
(Zweierpotenz), also senkrecht gestaucht; data/artwork.lua nennt die
Masse des ORIGINALS, damit der Ausschnitt unverzerrt bleibt. 256 KB je
Klasse, geladen wird nur die eigene.

**Warum es das gibt.** Was in media/ liegt, sind siebenundvierzig Binärdateien,
und aus einer Binärdatei geht nicht hervor, welcher Ausschnitt eines
Originals sie ist. Ohne dieses Skript wäre "das Motiv sitzt zwei
Pixel zu hoch" eine Aufgabe, die jemand von vorn löst. Die
Ausschnitte stehen zusätzlich als Kommentar in `data/artwork.lua`,
damit sie auch ohne das Skript lesbar sind.

**Warum BLP2/DXT1 und nicht PNG.** WoW lädt PNG nicht. Bleiben BLP und
TGA: ein unkomprimiertes TGA wäre in dieser Grösse 768 KB je Bild
(8,2 MB für siebenundvierzig), BLP2/DXT1 ist rund 128 KB je Bild bei
einer mittleren Abweichung von rund 2 von 255 Helligkeitsstufen. DXT1
und nicht DXT5, weil die Bilder undurchsichtig sind - DXT5 kostete das
Doppelte und brächte nur einen Alphakanal, den keines von ihnen hat.

**Warum ohne Mipmaps.** Jedes Bild steht in einer UI-Kachel fester
Grösse (keine Kamera, keine Distanz) - Mipmaps waren hier nie mehr als
eine vorgerechnete Kette kleinerer Kopien, die nie ein Frame anfordert.
Das sparte, ueber alle Bilder, rund 2 MB im ZIP. Gespeichert wird nur
noch Stufe 0, `hasMips` bleibt 0.

**Warum die Ausschnitte 4:1 sind.** Die Kästen, in denen die Bilder
stehen, sind breit und flach: eine Bosskarte ist im grossen Fenster
rund 425x80 px (5,3:1), im kleinen 232x66 (3,5:1), die Kopfkarte
zwischen 3,5:1 und 8:1. 4:1 liegt dazwischen, also beschneidet
`WeintCodex.CoverCoords` im Spiel nur noch wenig - gespeichert werden
kaum Pixel, die nie jemand sieht. Das Motiv steht RECHTS der Mitte,
weil links Nummer und Name stehen.

**Was das Skript NICHT tut:** die Originale anfassen. Es liest sie und
schreibt woanders hin.

Gebraucht werden Pillow und ImageMagick (`magick`).
"""

import os
import shutil
import struct
import subprocess
import sys
import tempfile

from PIL import Image

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# Ziel, Quelldatei, Ausschnitt (x, y, breite, hoehe) im Original.
# Der Ausschnitt ist 4:1 und von Hand gesetzt; die Zielgroesse ist
# immer 1024x256 (Zweierpotenz, sonst laedt der Client die Textur
# nicht).
JOBS = [
    ("dungeons/hall_of_thanes/header",             "hall_of_thanes/header.png",             (  0,  69, 1983, 496)),
    ("dungeons/hall_of_thanes/faldrim_anvilmar",   "hall_of_thanes/faldrim_anvilmar.png",   (  0,   8, 1300, 325)),
    ("dungeons/hall_of_thanes/magmatus",           "hall_of_thanes/magmatus.png",           (  0, 110, 1300, 325)),
    ("dungeons/hall_of_thanes/plunder",            "hall_of_thanes/plunder.png",            (100,  40, 1300, 325)),
    ("dungeons/hall_of_thanes/durgen_dirgehammer", "hall_of_thanes/durgen_dirgehammer.png", (100,  25, 1400, 350)),
    ("dungeons/ragefire_chasm/header",             "ragefire_chasm/header.png",             (  0,  69, 1983, 496)),
    ("dungeons/ragefire_chasm/oggleflint",         "ragefire_chasm/oggleflint.png",         (200,  80, 1300, 325)),
    ("dungeons/ragefire_chasm/taragaman",          "ragefire_chasm/taragaman.png",          (200,  40, 1300, 325)),
    ("dungeons/ragefire_chasm/jergosh",            "ragefire_chasm/jergosh.png",            (200,   0, 1300, 325)),
    ("dungeons/ragefire_chasm/bazzalan",           "ragefire_chasm/bazzalan.png",           (200,   0, 1300, 325)),
    ("dungeons/ruins_of_lordaeron/header",             "ruins_of_lordaeron/header.png",             (  0,  69, 1983, 496)),
    ("dungeons/ruins_of_lordaeron/witherfang",         "ruins_of_lordaeron/witherfang.png",         (200,  90, 1300, 325)),
    ("dungeons/ruins_of_lordaeron/the_abandoned",      "ruins_of_lordaeron/the_abandoned.png",      (200,  80, 1300, 325)),
    ("dungeons/ruins_of_lordaeron/the_butcher",        "ruins_of_lordaeron/the_butcher.png",        (200,  70, 1300, 325)),
    ("dungeons/ruins_of_lordaeron/lordaeron_captain",  "ruins_of_lordaeron/lordaeron_captain.png",  (200,  60, 1300, 325)),
    ("dungeons/ruins_of_lordaeron/bjork",              "ruins_of_lordaeron/bjork.png",              (200,  60, 1300, 325)),
    ("dungeons/ruins_of_lordaeron/rathmael",           "ruins_of_lordaeron/rathmael.png",           (200,  70, 1300, 325)),
    ("dungeons/ruins_of_lordaeron/viktor_the_vile",    "ruins_of_lordaeron/viktor_the_vile.png",    (200,  70, 1300, 325)),
    ("dungeons/wailing_caverns/header",                "wailing_caverns/header.png",                (  0, 240, 1672, 418)),
    ("dungeons/wailing_caverns/lady_anacondra",        "wailing_caverns/lady_anacondra.png",        (200,   0, 1300, 325)),
    ("dungeons/wailing_caverns/lord_cobrahn",          "wailing_caverns/lord_cobrahn.png",          (200,   0, 1300, 325)),
    ("dungeons/wailing_caverns/kresh",                 "wailing_caverns/kresh.png",                 (200,  80, 1300, 325)),
    ("dungeons/wailing_caverns/lord_pythas",           "wailing_caverns/lord_pythas.png",           (200,   0, 1300, 325)),
    ("dungeons/wailing_caverns/skum",                  "wailing_caverns/skum.png",                  (200,  70, 1300, 325)),
    ("dungeons/wailing_caverns/lord_serpentis",        "wailing_caverns/lord_serpentis.png",        (200,   0, 1300, 325)),
    ("dungeons/wailing_caverns/verdan",                "wailing_caverns/verdan.png",                (200,  70, 1300, 325)),
    ("dungeons/wailing_caverns/deviate_faerie_dragon","wailing_caverns/deviate_faerie_dragon.png",(200,  80, 1300, 325)),
    ("dungeons/wailing_caverns/mutanus",               "wailing_caverns/mutanus.png",               (  0, 250, 1672, 418)),
    ("dungeons/the_deadmines/header",                   "the_deadmines/header.png",                   (  0,  69, 1983, 496)),
    ("dungeons/the_deadmines/rhahkzor",                 "the_deadmines/rhahkzor.png",                 (200,  40, 1300, 325)),
    ("dungeons/the_deadmines/miner_johnson",            "the_deadmines/miner_johnson.png",            (200,  50, 1300, 325)),
    ("dungeons/the_deadmines/sneeds_shredder",          "the_deadmines/sneeds_shredder.png",          (200,  40, 1300, 325)),
    ("dungeons/the_deadmines/gilnid",                   "the_deadmines/gilnid.png",                   (200,  40, 1300, 325)),
    ("dungeons/the_deadmines/mr_smite",                 "the_deadmines/mr_smite.png",                 (200,  20, 1300, 325)),
    ("dungeons/the_deadmines/captain_greenskin",        "the_deadmines/captain_greenskin.png",        (200,  40, 1300, 325)),
    ("dungeons/the_deadmines/edwin_vancleef",           "the_deadmines/edwin_vancleef.png",           (200,  20, 1300, 325)),
    ("dungeons/the_deadmines/cookie",                   "the_deadmines/cookie.png",                   (  0, 250, 1672, 418)),
    ("dungeons/shadowfang_keep/header",                 "shadowfang_keep/header.png",                 (  0,  69, 1983, 496)),
    ("dungeons/shadowfang_keep/rethilgore",              "shadowfang_keep/rethilgore.png",              (  0,   0, 1672, 418)),
    ("dungeons/shadowfang_keep/razorclaw",               "shadowfang_keep/razorclaw.png",               (  0,   0, 1672, 418)),
    ("dungeons/shadowfang_keep/baron_silverlaine",       "shadowfang_keep/baron_silverlaine.png",       (  0,   0, 1672, 418)),
    ("dungeons/shadowfang_keep/commander_springvale",    "shadowfang_keep/commander_springvale.png",    (  0,   0, 1672, 418)),
    ("dungeons/shadowfang_keep/odo",                      "shadowfang_keep/odo.png",                      (  0,   0, 1672, 418)),
    ("dungeons/shadowfang_keep/deathsworn_captain",      "shadowfang_keep/deathsworn_captain.png",      (  0,   0, 1672, 418)),
    ("dungeons/shadowfang_keep/fenrus",                  "shadowfang_keep/fenrus.png",                  (  0,   0, 1672, 418)),
    ("dungeons/shadowfang_keep/wolf_master_nandos",       "shadowfang_keep/wolf_master_nandos.png",       (  0,   0, 1672, 418)),
    ("dungeons/shadowfang_keep/archmage_arugal",          "shadowfang_keep/archmage_arugal.png",          (  0,   0, 1672, 418)),
    # Excavation Site (6.29.3.0): Banner ganz oben. Bossbilder nur noch
    # 512x128 (32 statt 128 KB) - eine Bosskarte ist hoechstens rund
    # 425x80 px gross, mehr Pixel sieht dort niemand.
    ("dungeons/excavation_site/header",          "excavation_site/banner.png",         (  0,   0, 1983, 496)),
    ("dungeons/excavation_site/saltspine",       "excavation_site/saltspine.png",      (  0, 150, 1983, 496), (512, 128)),
    ("dungeons/excavation_site/shadetooth",      "excavation_site/shadetooth.png",     (  0,  20, 1983, 496), (512, 128)),
    ("dungeons/excavation_site/relic_guardian",  "excavation_site/relic_guardian.png", (  0,  30, 1983, 496), (512, 128)),
    # 6.29.4.0: fuenf weitere Dungeons, gleiches Schema.
    ("dungeons/blackfathom_deeps/header", "blackfathom_deeps/banner.png", (0, 0, 1983, 496)),
    ("dungeons/blackfathom_deeps/ghamoora", "blackfathom_deeps/ghamoo-ra.png", (0, 90, 1983, 496), (512, 128)),
    ("dungeons/blackfathom_deeps/lady_sarevess", "blackfathom_deeps/lady_sarevess.png", (0, 20, 1983, 496), (512, 128)),
    ("dungeons/blackfathom_deeps/gelihast", "blackfathom_deeps/gelihast.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackfathom_deeps/lorgus_jett", "blackfathom_deeps/lorgus_jett.png", (0, 20, 1983, 496), (512, 128)),
    ("dungeons/blackfathom_deeps/baron_aquanis", "blackfathom_deeps/baron_aquanis.png", (0, 40, 1983, 496), (512, 128)),
    ("dungeons/blackfathom_deeps/old_serrakis", "blackfathom_deeps/old_serra_kis.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackfathom_deeps/twilight_lord_kelris", "blackfathom_deeps/twilight_lord_kelris.png", (0, 20, 1983, 496), (512, 128)),
    ("dungeons/blackfathom_deeps/akumai", "blackfathom_deeps/aku_mai.png", (0, 40, 1983, 496), (512, 128)),
    ("dungeons/the_stockade/header", "stockade/banner.png", (0, 0, 1983, 496)),
    ("dungeons/the_stockade/targorr", "stockade/targorr_the_dread.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/the_stockade/kam_deepfury", "stockade/kam_deepfury.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/the_stockade/hamhock", "stockade/hamhock.png", (0, 50, 1983, 496), (512, 128)),
    ("dungeons/the_stockade/bazil_thredd", "stockade/bazil_thredd.png", (0, 40, 1983, 496), (512, 128)),
    ("dungeons/the_stockade/dextren_ward", "stockade/dextren_ward.png", (0, 40, 1983, 496), (512, 128)),
    ("dungeons/the_stockade/bruegal", "stockade/bruegal_ironknuckle.png", (0, 40, 1983, 496), (512, 128)),
    ("dungeons/city_of_dalaran/header", "city_of_dalaran/banner.png", (0, 0, 1983, 496)),
    ("dungeons/city_of_dalaran/atrexis", "city_of_dalaran/atrexis_the_grave_knight.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/city_of_dalaran/arcane_anomaly", "city_of_dalaran/arcane_anomaly.png", (0, 100, 1983, 496), (512, 128)),
    ("dungeons/city_of_dalaran/fel_ancient", "city_of_dalaran/fel_ancient.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/city_of_dalaran/unstable_sentinel", "city_of_dalaran/unstable_sentinel.png", (0, 80, 1983, 496), (512, 128)),
    ("dungeons/city_of_dalaran/mana_devourer", "city_of_dalaran/mana_devourer.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/city_of_dalaran/arcanic_enigma", "city_of_dalaran/arcanic_enigma.png", (0, 100, 1983, 496), (512, 128)),
    ("dungeons/city_of_dalaran/lyn_the_ignored", "city_of_dalaran/lyn_the_ignored.png", (0, 10, 1983, 496), (512, 128)),
    ("dungeons/city_of_dalaran/shade_of_the_archmage", "city_of_dalaran/shade_of_the_archmage.png", (0, 10, 1983, 496), (512, 128)),
    ("dungeons/scarlet_monastery/header", "scarlet_monastery/banner.png", (0, 0, 1983, 496)),
    ("dungeons/scarlet_monastery/interrogator_vishas", "scarlet_monastery/interrogator_vishas.png", (0, 10, 1983, 496), (512, 128)),
    ("dungeons/scarlet_monastery/bloodmage_thalnos", "scarlet_monastery/bloodmage_thalnos.png", (0, 20, 1983, 496), (512, 128)),
    ("dungeons/scarlet_monastery/ironspine", "scarlet_monastery/ironspine.png", (0, 0, 1983, 496), (512, 128)),
    ("dungeons/scarlet_monastery/azshir", "scarlet_monastery/azshir_the_sleepless.png", (0, 30, 1983, 496), (512, 128)),
    ("dungeons/scarlet_monastery/fallen_champion", "scarlet_monastery/the_fallen_champion.png", (0, 10, 1983, 496), (512, 128)),
    ("dungeons/gnomeregan/header", "gnomeregan/banner.png", (0, 0, 1983, 496)),
    ("dungeons/gnomeregan/grubbis", "gnomeregan/grubbis.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/gnomeregan/viscous_fallout", "gnomeregan/viscous_fallout.png", (0, 120, 1983, 496), (512, 128)),
    ("dungeons/gnomeregan/electrocutioner", "gnomeregan/electrocutioner_6000.png", (0, 80, 1983, 496), (512, 128)),
    ("dungeons/gnomeregan/crowd_pummeler", "gnomeregan/crowd_pummeler_9-60.png", (0, 40, 1983, 496), (512, 128)),
    ("dungeons/gnomeregan/dark_iron_ambassador", "gnomeregan/dark_iron_ambassador.png", (0, 10, 1983, 496), (512, 128)),
    ("dungeons/gnomeregan/thermaplugg", "gnomeregan/mekgineer_thermaplugg.png", (0, 60, 1983, 496), (512, 128)),
    # 6.29.5.0: Razorfen Kraul.
    ("dungeons/razorfen_kraul/header", "razorfen_kraul/banner.png", (0, 0, 1983, 496)),
    ("dungeons/razorfen_kraul/roogug", "razorfen_kraul/roogug.png", (0, 20, 1983, 496), (512, 128)),
    ("dungeons/razorfen_kraul/aggem_thorncurse", "razorfen_kraul/aggem_thorncurse.png", (0, 20, 1983, 496), (512, 128)),
    ("dungeons/razorfen_kraul/death_speaker_jargba", "razorfen_kraul/death_speaker_jargba.png", (0, 20, 1983, 496), (512, 128)),
    ("dungeons/razorfen_kraul/overlord_ramtusk", "razorfen_kraul/overlord_ramtusk.png", (0, 30, 1983, 496), (512, 128)),
    ("dungeons/razorfen_kraul/agathelos", "razorfen_kraul/agathelos_the_raging.png", (0, 40, 1983, 496), (512, 128)),
    ("dungeons/razorfen_kraul/charlga_razorflank", "razorfen_kraul/charlga_razorflank.png", (0, 10, 1983, 496), (512, 128)),
    # 6.33.0.0: Razorfen Downs und Drowned City (nur Zul'Alai ist ein Boss im Bestand).
    ("dungeons/razorfen_downs/header", "razorfen_down/banner.png", (0, 100, 1983, 496)),
    ("dungeons/razorfen_downs/tutenkash", "razorfen_down/tuten-kash.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/razorfen_downs/mordresh", "razorfen_down/mordresh_fire_eye.png", (0, 40, 1983, 496), (512, 128)),
    ("dungeons/razorfen_downs/glutton", "razorfen_down/glutton.png", (0, 40, 1983, 496), (512, 128)),
    ("dungeons/razorfen_downs/plaguemaw", "razorfen_down/plaguemaw_the_rotting.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/razorfen_downs/ragglesnout", "razorfen_down/ragglesnout.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/razorfen_downs/amnennar", "razorfen_down/amnennar_the_coldbringer.png", (0, 30, 1983, 496), (512, 128)),
    ("dungeons/drowned_city/header", "the_drowned_city/banner.png", (0, 60, 1983, 496)),
    ("dungeons/drowned_city/zulalai", "the_drowned_city/zul-alai.png", (0, 40, 1983, 496), (512, 128)),
    # 6.50.2.0: Untere Schwarzfelsspitze. Alle Originale hochkant (1514x1039,
    # Banner 1672x941) - Ausschnitt 4:1 je Bild dort, wo der Kopf steht.
    ("dungeons/lower_blackrock_spire/header", "lower_blackrock_spire/banner.png", (0, 250, 1672, 418)),
    ("dungeons/lower_blackrock_spire/highlord_omokk", "lower_blackrock_spire/highlord_omokk.png", (0, 0, 1513, 378), (512, 128)),
    ("dungeons/lower_blackrock_spire/shadow_hunter_voshgajin", "lower_blackrock_spire/shadow_hunter_vosh-gajin.png", (0, 50, 1514, 378), (512, 128)),
    ("dungeons/lower_blackrock_spire/war_master_voone", "lower_blackrock_spire/war_master_voone.png", (0, 0, 1514, 378), (512, 128)),
    ("dungeons/lower_blackrock_spire/urok_doomhowl", "lower_blackrock_spire/urok_doomhowl.png", (0, 0, 1514, 378), (512, 128)),
    ("dungeons/lower_blackrock_spire/mother_smolderweb", "lower_blackrock_spire/mother_smolderweb.png", (0, 200, 1514, 378), (512, 128)),
    ("dungeons/lower_blackrock_spire/quartermaster_zigris", "lower_blackrock_spire/quartermaster_zigris.png", (0, 50, 1514, 378), (512, 128)),
    ("dungeons/lower_blackrock_spire/halycon", "lower_blackrock_spire/halycon.png", (0, 300, 1514, 378), (512, 128)),
    ("dungeons/lower_blackrock_spire/gizrul", "lower_blackrock_spire/gizrul_the_slavener.png", (0, 150, 1514, 378), (512, 128)),
    ("dungeons/lower_blackrock_spire/overlord_wyrmthalak", "lower_blackrock_spire/overlord_wyrmthalak.png", (0, 0, 1514, 378), (512, 128)),
    # 6.58.0.0: Scholomance. Bosse 1514x1039, Banner 2172x724 - Ausschnitt 4:1
    # je Bild am Kopf.
    ("dungeons/scholomance/header", "scholomance/banner.png", (0, 90, 2172, 543)),
    ("dungeons/scholomance/blood_steward", "scholomance/blood_steward.png", (0, 0, 1514, 378), (512, 128)),
    ("dungeons/scholomance/kirtonos", "scholomance/kirtonos.png", (0, 0, 1514, 378), (512, 128)),
    ("dungeons/scholomance/jandice_barov", "scholomance/jandice_barov.png", (0, 20, 1514, 378), (512, 128)),
    ("dungeons/scholomance/rattlegore", "scholomance/rattlegore.png", (0, 60, 1514, 378), (512, 128)),
    ("dungeons/scholomance/marduk_blackpool", "scholomance/marduk_blackpool.png", (0, 40, 1514, 378), (512, 128)),
    ("dungeons/scholomance/vectus", "scholomance/vectus.png", (0, 60, 1514, 378), (512, 128)),
    ("dungeons/scholomance/ras_frostwhisper", "scholomance/ras_frostwhisper.png", (0, 20, 1514, 378), (512, 128)),
    ("dungeons/scholomance/instructor_malicia", "scholomance/instructor_malicia.png", (0, 0, 1514, 378), (512, 128)),
    ("dungeons/scholomance/theolen_krastinov", "scholomance/theolen_krastinov.png", (0, 60, 1514, 378), (512, 128)),
    ("dungeons/scholomance/lorekeeper_polkelt", "scholomance/lorekeeper_polkelt.png", (0, 50, 1514, 378), (512, 128)),
    ("dungeons/scholomance/the_ravenian", "scholomance/the_ravenian.png", (0, 150, 1514, 378), (512, 128)),
    ("dungeons/scholomance/lord_alexei_barov", "scholomance/lord_alexei_barov.png", (0, 80, 1514, 378), (512, 128)),
    ("dungeons/scholomance/lady_illucia_barov", "scholomance/lady_illucia_barov.png", (0, 20, 1514, 378), (512, 128)),
    ("dungeons/scholomance/darkmaster_gandling", "scholomance/darkmaster_gandling.png", (0, 30, 1514, 378), (512, 128)),
    # 6.60.0.0: Stratholme. Bosse 1514x1039 (Ramstein 1983x793), Banner
    # 1514x1039 - Ausschnitt 4:1 je Bild am Kopf.
    ("dungeons/stratholme/header", "stratholme/banner.png", (0, 260, 1514, 378)),
    ("dungeons/stratholme/fras_siabi", "stratholme/fras_siabi.png", (0, 100, 1514, 378), (512, 128)),
    ("dungeons/stratholme/hearthsinger_forresten", "stratholme/hearthsinger_forresten.png", (0, 50, 1514, 378), (512, 128)),
    ("dungeons/stratholme/the_unforgiven", "stratholme/the_unforgiven.png", (0, 60, 1514, 378), (512, 128)),
    ("dungeons/stratholme/timmy_the_cruel", "stratholme/timmy_the_cruel.png", (0, 100, 1514, 378), (512, 128)),
    ("dungeons/stratholme/malor_the_zealous", "stratholme/malor_the_zealous.png", (0, 70, 1514, 378), (512, 128)),
    ("dungeons/stratholme/crimson_hammersmith", "stratholme/crimson_hammersmith.png", (0, 60, 1514, 378), (512, 128)),
    ("dungeons/stratholme/cannon_master_willey", "stratholme/cannon_master_willey.png", (0, 100, 1514, 378), (512, 128)),
    ("dungeons/stratholme/archivist_galford", "stratholme/archivist_galford.png", (0, 0, 1514, 378), (512, 128)),
    ("dungeons/stratholme/balnazzar", "stratholme/balnazzar.png", (0, 0, 1514, 378), (512, 128)),
    ("dungeons/stratholme/postmaster_malown", "stratholme/postmaster_malown.png", (0, 30, 1514, 378), (512, 128)),
    ("dungeons/stratholme/jarien_and_sothos", "stratholme/jarien_and_sothos.png", (0, 100, 1514, 378), (512, 128)),
    ("dungeons/stratholme/skul", "stratholme/skul.png", (0, 30, 1514, 378), (512, 128)),
    ("dungeons/stratholme/stonespine", "stratholme/stonespine.png", (0, 200, 1514, 378), (512, 128)),
    ("dungeons/stratholme/baroness_anastari", "stratholme/baroness_anastari.png", (0, 60, 1514, 378), (512, 128)),
    ("dungeons/stratholme/nerubenkan", "stratholme/nerubenkan.png", (0, 200, 1514, 378), (512, 128)),
    ("dungeons/stratholme/maleki_the_pallid", "stratholme/maleki_the_pallid.png", (0, 60, 1514, 378), (512, 128)),
    ("dungeons/stratholme/magistrate_barthilas", "stratholme/magistrate_barthilas.png", (0, 60, 1514, 378), (512, 128)),
    ("dungeons/stratholme/ramstein", "stratholme/ramstein.png", (0, 100, 1983, 495), (512, 128)),
    ("dungeons/stratholme/baron_rivendare", "stratholme/baron_rivendare.png", (0, 60, 1514, 378), (512, 128)),
    # 6.50.1.0: Duesterbruch (drei Fluegel, ein Kopfbild). Banner 2172x724, die
    # drei grossen Oger 1515x1038 bzw. 1672x941 - Ausschnitt von oben, 4:1.
    ("dungeons/dire_maul/header", "dire_maul/banner.png", (0, 90, 2172, 543)),
    ("dungeons/dire_maul/pusillin", "dire_maul/pusillin.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/zevrim_thornhoof", "dire_maul/zevrim_thornhoof.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/hydrospawn", "dire_maul/hydrospawn.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/lethtendris", "dire_maul/lethtendris.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/alzzin", "dire_maul/alzzin_the_wildshaper.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/isalien", "dire_maul/isalien.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/tendris_warpwood", "dire_maul/tendris_warpwood.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/illyanna_ravenoak", "dire_maul/illyanna_ravenoak.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/magister_kalendris", "dire_maul/magister_kalendris.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/tsuzee", "dire_maul/tsu-zee.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/immolthar", "dire_maul/immol-thar.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/prince_tortheldrin", "dire_maul/prince_tortheldrin.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/lord_helnurath", "dire_maul/lord_hel-nurath.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/guard_moldar", "dire_maul/guard_mol-dar.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/stomper_kreeg", "dire_maul/stomper_kreeg.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/dire_maul/guard_fengus", "dire_maul/guard_fengus.png", (0, 0, 1672, 418), (512, 128)),
    ("dungeons/dire_maul/guard_slipkik", "dire_maul/guard_slip-kik.png", (0, 0, 1515, 379), (512, 128)),
    ("dungeons/dire_maul/captain_kromcrush", "dire_maul/captain_kromcrush.png", (0, 0, 1515, 379), (512, 128)),
    ("dungeons/dire_maul/king_gordok", "dire_maul/king_gordok.png", (0, 0, 1515, 379), (512, 128)),
    # 6.49.1.0: Blackrocktiefen (drei Fluegel, ein Kopfbild).
    ("dungeons/blackrock_depths/header", "blackrock_depths/banner.png", (0, 80, 1983, 496)),
    ("dungeons/blackrock_depths/lord_roccor", "blackrock_depths/lord_roccor.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/high_interrogator_gerstahn", "blackrock_depths/high_interrogator_gerstahn.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/houndmaster_grebmar", "blackrock_depths/houndmaster_grebmar.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/ring_of_law", "blackrock_depths/ring_of_law.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/theldren", "blackrock_depths/theldren.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/pyromancer_loregrain", "blackrock_depths/pyromancer_loregrain.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/golem_lord_argelmach", "blackrock_depths/golem_lord_argelmach.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/hurley_blackbreath", "blackrock_depths/hurley_blackbreath.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/phalanx", "blackrock_depths/phalanx.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/ribbly_screwspigot", "blackrock_depths/ribbly_screwspigot.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/plugger_spazzring", "blackrock_depths/plugger_spazzring.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/lord_incendius", "blackrock_depths/lord_incendius.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/warder_stilgiss", "blackrock_depths/warder_stilgiss.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/watchman_doomgrip", "blackrock_depths/watchman_doomgrip.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/fineous_darkvire", "blackrock_depths/fineous_darkvire.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/baelgar", "blackrock_depths/bael-gar.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/general_angerforge", "blackrock_depths/general_angerforge.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/ambassador_flamelash", "blackrock_depths/ambassador_flamelash.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/panzor", "blackrock_depths/panzor_the_invincible.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/the_seven", "blackrock_depths/the_seven.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/magmus", "blackrock_depths/magmus.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/blackrock_depths/dagran_thaurissan", "blackrock_depths/emperor_dagran_thaurissan.png", (0, 60, 1983, 496), (512, 128)),
    # 6.49.0.0: Uldaman, Zul'Farrak, Maraudon, Tempel von Atal'Hakkar.
    ("dungeons/uldaman/header", "uldaman/banner.png", (0, 80, 1983, 496)),
    ("dungeons/uldaman/revelosh", "uldaman/revelosh.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/uldaman/the_lost_dwarves", "uldaman/baelog.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/uldaman/ironaya", "uldaman/ironaya.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/uldaman/ancient_stone_keeper", "uldaman/ancient_stone_keeper.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/uldaman/galgann", "uldaman/galgann_firehammer.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/uldaman/grimlok", "uldaman/grimlok.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/uldaman/archaedas", "uldaman/archaedas.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/zulfarrak/header", "zul_farrak/banner.png", (0, 80, 1983, 496)),
    ("dungeons/zulfarrak/antusul", "zul_farrak/antu-sul.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/zulfarrak/theka", "zul_farrak/theka_the_martyr.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/zulfarrak/zumrah", "zul_farrak/witch_doctor_zum-rah.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/zulfarrak/sergeant_bly", "zul_farrak/sergeant_bly.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/zulfarrak/nekrum", "zul_farrak/nekrum_gutchewer.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/zulfarrak/sezzziz", "zul_farrak/shadowpriest_sezz-ziz.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/zulfarrak/ukorz", "zul_farrak/chief_ukorz_sandscalp.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/zulfarrak/gahzrilla", "zul_farrak/gahz-rilla.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/maraudon/header", "maraudon/banner.png", (0, 80, 1983, 496)),
    ("dungeons/maraudon/noxxion", "maraudon/noxxion.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/maraudon/razorlash", "maraudon/razorlash.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/maraudon/lord_vyletongue", "maraudon/lord_vyletongue.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/maraudon/meshlok", "maraudon/meshlock_the_harvester.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/maraudon/tinkerer_gizlock", "maraudon/tinkerer_gizlock.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/maraudon/celebras", "maraudon/celebras_the_cursed.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/maraudon/landslide", "maraudon/landslide.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/maraudon/rotgrip", "maraudon/rotgrip.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/maraudon/princess_theradras", "maraudon/princess_theradras.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/sunken_temple/header", "atal_hakkar/banner.png", (0, 80, 1983, 496)),
    ("dungeons/sunken_temple/atalalarion", "atal_hakkar/atal-alarion.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/sunken_temple/jammalan", "atal_hakkar/jammal-an_the_prophet.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/sunken_temple/ogom", "atal_hakkar/ogom_the_wretched.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/sunken_temple/dreamscythe", "atal_hakkar/dreamscythe.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/sunken_temple/weaver", "atal_hakkar/weaver.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/sunken_temple/morphaz", "atal_hakkar/morphaz.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/sunken_temple/hazzas", "atal_hakkar/hazzas.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/sunken_temple/eranikus", "atal_hakkar/shade_of_eranikus.png", (0, 60, 1983, 496), (512, 128)),
    ("dungeons/sunken_temple/avatar_of_hakkar", "atal_hakkar/avatar_of_hakkar.png", (0, 60, 1983, 496), (512, 128)),
]

TARGET_W, TARGET_H = 1024, 256

# Ziel, Quelldatei. Ganzes Bild, Ziel 1024x512 (siehe oben).
CLASS_JOBS = [
    ("classes/priest", "priest.webp"),
    ("classes/hunter", "hunter.webp"),   # Querformat 1496x1051, 6.6.4.4
    # 6.6.4.5, alle Querformat 1496x1051:
    ("classes/warrior", "warrior.png"),
    ("classes/druid", "druid.png"),
    ("classes/mage", "mage.png"),
    ("classes/rogue", "rogue.png"),
    ("classes/warlock", "warlock.png"),
    ("classes/paladin", "paladin.png"),
    ("classes/shaman", "shaman.png"),
]
CLASS_W, CLASS_H = 1024, 512   # 6.29.7.0, vorher 1024x1024


def dxt1_blocks(image, workdir):
    """Eine Stufe als rohe DXT1-Bloecke. ImageMagick komprimiert, der
    128 Byte grosse DDS-Kopf faellt weg - was bleibt, ist exakt das,
    was BLP2 an dieser Stelle erwartet."""
    png = os.path.join(workdir, "level.png")
    dds = os.path.join(workdir, "level.dds")
    image.save(png)
    if shutil.which("magick") is None:
        # Ohne ImageMagick: Pillow (ab 11) schreibt DXT1 selbst - gleicher
        # 128-Byte-Kopf, gleiche Bloecke.
        image.save(dds, pixel_format="DXT1")
        with open(dds, "rb") as handle:
            return handle.read()[128:]
    subprocess.run(
        ["magick", png,
         "-define", "dds:compression=dxt1",
         "-define", "dds:mipmaps=0",
         "-define", "dds:cluster-fit=true",
         dds],
        check=True,
    )
    with open(dds, "rb") as handle:
        return handle.read()[128:]


def write_blp(path, level0, width, height):
    """BLP2, Typ 1, Kodierung 2 (DXT), ohne Alpha, ohne Mipmaps - nur
    Stufe 0. Kopf: 148 Byte, danach die eine Stufe."""
    offsets, sizes = [0] * 16, [0] * 16
    offsets[0], sizes[0] = 148, len(level0)

    header = struct.pack("<4sIBBBBII", b"BLP2", 1, 2, 0, 0, 0, width, height)
    header += struct.pack("<16I", *offsets) + struct.pack("<16I", *sizes)
    assert len(header) == 148

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(header + level0)


def classes(source_dir):
    for target, filename in CLASS_JOBS:
        source = os.path.join(source_dir, filename)
        if not os.path.exists(source):
            # Einzeln erneuern koennen: wer nur ein neues Bild hat, legt
            # nur das in den Ordner - die anderen Dateien bleiben.
            print("uebersprungen (kein Original): " + filename)
            continue
        original = Image.open(source).convert("RGB")
        scaled = original.resize((CLASS_W, CLASS_H), Image.LANCZOS)
        with tempfile.TemporaryDirectory() as workdir:
            level0 = dxt1_blocks(scaled, workdir)
        path = os.path.join(REPO, "media", target + ".blp")
        write_blp(path, level0, CLASS_W, CLASS_H)
        print("%-46s %7d B  (%s, %dx%d)"
              % (target + ".blp", os.path.getsize(path), filename, *original.size))
    return 0


def shrink():
    """6.29.7.0: vorhandene BLPs verkleinern, ohne die Originale.

    Bossbilder 1024x256 -> 512x128 (eine Bosskarte ist hoechstens rund
    425x80 px), Klassenbilder 1024x1024 -> 1024x512 (das Modellfeld ist
    rund 397x464 px hoch; die Breite bleibt, weil dort nur ein Streifen
    des Querformats zu sehen ist). Gelesen wird die DXT1-Fassung selbst
    (Pillow liest BLP2); das Verkleinern mittelt je zwei Pixel und glaettet
    dabei auch die Bloecke der alten Kompression. Koepfe (header.blp)
    bleiben 1024x256 - die Kopfkarte ist im breiten Fenster groesser.
    Laeuft mehrfach ohne Schaden: was schon klein ist, bleibt liegen.
    """
    jobs = []
    for root, _, files in os.walk(os.path.join(REPO, "media", "dungeons")):
        for name in files:
            if name.endswith(".blp") and name != "header.blp":
                jobs.append((os.path.join(root, name), (1024, 256), (512, 128)))
    for name in os.listdir(os.path.join(REPO, "media", "classes")):
        if name.endswith(".blp"):
            jobs.append((os.path.join(REPO, "media", "classes", name), (1024, 1024), (1024, 512)))
    for path, big, small in sorted(jobs):
        image = Image.open(path).convert("RGB")
        if image.size != big:
            continue
        scaled = image.resize(small, Image.LANCZOS)
        with tempfile.TemporaryDirectory() as workdir:
            level0 = dxt1_blocks(scaled, workdir)
        write_blp(path, level0, small[0], small[1])
        print("%-60s %7d B" % (os.path.relpath(path, REPO), os.path.getsize(path)))
    return 0


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "shrink":
        return shrink()
    if len(sys.argv) == 3 and sys.argv[1] == "classes":
        return classes(os.path.expanduser(sys.argv[2]))
    if len(sys.argv) != 2:
        print(__doc__.strip())
        return 2

    source_dir = os.path.expanduser(sys.argv[1])
    only = os.environ.get("ONLY")
    for job in JOBS:
        target, filename, (x, y, crop_w, crop_h) = job[:3]
        TW, TH = job[3] if len(job) > 3 else (TARGET_W, TARGET_H)
        # 6.29.7.0: jedes Bossbild 512x128, nur Koepfe 1024x256.
        if not target.endswith("/header") and len(job) == 3:
            TW, TH = 512, 128
        if only and only not in target:
            continue
        source = os.path.join(source_dir, filename)
        if not os.path.exists(source):
            print("fehlt: " + source)
            return 1

        original = Image.open(source).convert("RGB")
        if x + crop_w > original.size[0] or y + crop_h > original.size[1]:
            print("Ausschnitt liegt ausserhalb von " + filename)
            return 1
        # Kein Verzerren: der Ausschnitt hat schon das Seitenverhaeltnis
        # des Ziels, skaliert wird nur noch gleichmaessig.
        if abs(crop_w / crop_h - TW / TH) > 0.01:
            print("Ausschnitt von " + filename + " ist nicht 4:1")
            return 1

        scaled = original.crop((x, y, x + crop_w, y + crop_h)) \
                         .resize((TW, TH), Image.LANCZOS)

        with tempfile.TemporaryDirectory() as workdir:
            level0 = dxt1_blocks(scaled, workdir)

        path = os.path.join(REPO, "media", target + ".blp")
        write_blp(path, level0, TW, TH)
        print("%-46s %7d B  (%s, %dx%d)"
              % (target + ".blp", os.path.getsize(path), filename, crop_w, crop_h))

    return 0


if __name__ == "__main__":
    sys.exit(main())
