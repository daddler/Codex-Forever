#!/usr/bin/env python3
"""Runde Bossbilder fuer die Dungeonkarte (1.0.8.23).

Aufruf (im Wurzelordner des Repos):

    python3 .github/scripts/make_boss_pins.py

Liest jedes Bossbild aus data/artwork.lua (eigenes Material, media/dungeons/
<Dungeon>/<Boss>.blp), schneidet das Quadrat um `focusX` aus, verkleinert es
auf PIN x PIN und schreibt es rund - Ecken durchsichtig, Rand geglaettet -
als media/dungeons/<Dungeon>/<Boss>_pin.tga (32 Bit, unkomprimiert).

Warum vorberechnet: im Spiel blieb der Punkt mit Maske (CreateMaskTexture)
schwarz (Bild aus dem Spiel, 1.0.8.23). Ein fertiges rundes Bild braucht
keine Maske - der Client zeichnet es wie jedes andere.
"""

import os
import re

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PIN = 64
SUPER = 4


def entries():
    text = open(os.path.join(ROOT, "data", "artwork.lua"), encoding="utf-8").read()
    for m in re.finditer(r'file = ART \.\. "([^"]+)",\s*\n\s*w = (\d+), h = (\d+), focusX = ([\d.]+)', text):
        rel = m.group(1)
        if rel.endswith("/header"):
            continue
        yield rel, int(m.group(2)), int(m.group(3)), float(m.group(4))


def main():
    big = PIN * SUPER
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, big - 1, big - 1], fill=255)
    mask = mask.resize((PIN, PIN), Image.LANCZOS)
    n = 0
    for rel, w, h, fx in entries():
        src = os.path.join(ROOT, "media", "dungeons", rel + ".blp")
        if not os.path.isfile(src):
            continue
        im = Image.open(src).convert("RGBA")
        W, H = im.size
        side = min(W, H)
        cx = max(side / 2, min(W - side / 2, fx * W))
        crop = im.crop((int(cx - side / 2), 0, int(cx - side / 2) + side, side))
        crop = crop.resize((PIN, PIN), Image.LANCZOS)
        crop.putalpha(mask)
        out = os.path.join(ROOT, "media", "dungeons", rel + "_pin.tga")
        crop.save(out, format="TGA", compression=None, orientation=1)  # oben links wie media/ui
        n += 1
    print("%d runde Bossbilder geschrieben" % n)


if __name__ == "__main__":
    main()
