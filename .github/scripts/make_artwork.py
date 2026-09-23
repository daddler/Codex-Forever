"""
Aus einem Original-Artwork die Addon-Fassung machen: zuschneiden,
skalieren, als BLP2/DXT1 mit Mipmaps ablegen.

    python3 .github/scripts/make_artwork.py ~/Bilder/hall_of_thanes

Der Ordner enthält die Originale unter den Namen, die unten in JOBS
stehen; geschrieben wird nach media/dungeons/<dungeon>/.

**Warum es das gibt.** Was in media/ liegt, sind fünf Binärdateien,
und aus einer Binärdatei geht nicht hervor, welcher Ausschnitt eines
Originals sie ist. Ohne dieses Skript wäre "das Motiv sitzt zwei
Pixel zu hoch" eine Aufgabe, die jemand von vorn löst. Die
Ausschnitte stehen zusätzlich als Kommentar in `data/artwork.lua`,
damit sie auch ohne das Skript lesbar sind.

**Warum BLP2/DXT1 und nicht PNG.** WoW lädt PNG nicht. Bleiben BLP und
TGA: ein unkomprimiertes TGA wäre in dieser Grösse 768 KB je Bild
(3,8 MB für fünf), BLP2/DXT1 ist 171 KB je Bild (860 KB für fünf) bei
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
    ("dungeons/hall_of_thanes/header",             "header.png",             (  0,  69, 1983, 496)),
    ("dungeons/hall_of_thanes/faldrim_anvilmar",   "faldrim_anvilmar.png",   (  0,   8, 1300, 325)),
    ("dungeons/hall_of_thanes/magmatus",           "magmatus.png",           (  0, 110, 1300, 325)),
    ("dungeons/hall_of_thanes/plunder",            "plunder.png",            (100,  40, 1300, 325)),
    ("dungeons/hall_of_thanes/durgen_dirgehammer", "durgen_dirgehammer.png", (100,  25, 1400, 350)),
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
