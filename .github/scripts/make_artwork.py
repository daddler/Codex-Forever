"""
Aus einem Original-Artwork die Addon-Fassung machen: zuschneiden,
skalieren, als BLP2/DXT1 mit Mipmaps ablegen.

    python3 .github/scripts/make_artwork.py ~/Bilder/hall_of_thanes

Der Ordner enthält die Originale unter den Namen, die unten in JOBS
stehen; geschrieben wird nach media/dungeons/<dungeon>/.

**Warum es das gibt.** Was in media/ liegt, sind siebenundvierzig Binärdateien,
und aus einer Binärdatei geht nicht hervor, welcher Ausschnitt eines
Originals sie ist. Ohne dieses Skript wäre "das Motiv sitzt zwei
Pixel zu hoch" eine Aufgabe, die jemand von vorn löst. Die
Ausschnitte stehen zusätzlich als Kommentar in `data/artwork.lua`,
damit sie auch ohne das Skript lesbar sind.

**Warum BLP2/DXT1 und nicht PNG.** WoW lädt PNG nicht. Bleiben BLP und
TGA: ein unkomprimiertes TGA wäre in dieser Grösse 768 KB je Bild
(8,2 MB für siebenundvierzig), BLP2/DXT1 ist 171 KB je Bild bei
einer mittleren Abweichung von rund 2 von 255 Helligkeitsstufen. DXT1
und nicht DXT5, weil die Bilder undurchsichtig sind - DXT5 kostete das
Doppelte und brächte nur einen Alphakanal, den keines von ihnen hat.
Dieselbe Kodierung wie media/logo.blp, und dieselbe Mipmap-Kette
(hinunter bis zur Breite 4).

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
]

TARGET_W, TARGET_H = 1024, 256


def dxt1_blocks(image, workdir):
    """Eine Stufe als rohe DXT1-Bloecke. ImageMagick komprimiert, der
    128 Byte grosse DDS-Kopf faellt weg - was bleibt, ist exakt das,
    was BLP2 an dieser Stelle erwartet."""
    png = os.path.join(workdir, "level.png")
    dds = os.path.join(workdir, "level.dds")
    image.save(png)
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


def mip_chain(image):
    """Die Kette, die media/logo.blp auch hat: halbieren, bis die
    Breite 4 erreicht ist."""
    levels = [image]
    width, height = image.size
    while width > 4:
        width, height = max(1, width // 2), max(1, height // 2)
        levels.append(image.resize((width, height), Image.LANCZOS))
    return levels


def write_blp(path, levels, width, height):
    """BLP2, Typ 1, Kodierung 2 (DXT), ohne Alpha, mit Mipmaps.
    Kopf: 148 Byte, danach die Stufen hintereinander."""
    offsets, sizes = [0] * 16, [0] * 16
    cursor, blob = 148, b""
    for index, data in enumerate(levels[:16]):
        offsets[index], sizes[index] = cursor, len(data)
        cursor += len(data)
        blob += data

    header = struct.pack("<4sIBBBBII", b"BLP2", 1, 2, 0, 0, 1, width, height)
    header += struct.pack("<16I", *offsets) + struct.pack("<16I", *sizes)
    assert len(header) == 148

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(header + blob)


def main():
    if len(sys.argv) != 2:
        print(__doc__.strip())
        return 2

    source_dir = os.path.expanduser(sys.argv[1])
    for target, filename, (x, y, crop_w, crop_h) in JOBS:
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
        if abs(crop_w / crop_h - TARGET_W / TARGET_H) > 0.01:
            print("Ausschnitt von " + filename + " ist nicht 4:1")
            return 1

        scaled = original.crop((x, y, x + crop_w, y + crop_h)) \
                         .resize((TARGET_W, TARGET_H), Image.LANCZOS)

        with tempfile.TemporaryDirectory() as workdir:
            levels = [dxt1_blocks(level, workdir) for level in mip_chain(scaled)]

        path = os.path.join(REPO, "media", target + ".blp")
        write_blp(path, levels, TARGET_W, TARGET_H)
        print("%-46s %7d B  (%s, %dx%d)"
              % (target + ".blp", os.path.getsize(path), filename, crop_w, crop_h))

    return 0


if __name__ == "__main__":
    sys.exit(main())
