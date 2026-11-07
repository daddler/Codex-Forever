"""
Weisser Ring mit weichem Rand fuer den Mauszeiger und den Spielerpfeil
(ui/cursor.lua, 1.0.5.12). Kein Spielmaterial - gezeichnet.

    python3 .github/scripts/make_ring.py

Schreibt media/ui/ring.tga (128x128, RGBA, weiss; die Farbe setzt das Spiel
mit SetVertexColor).
"""

import math
import os

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "media", "ui", "ring.tga")

SIZE, SS = 128, 4
OUTER, INNER = 0.47, 0.37   # Anteil der Kantenlaenge (Radius)


def main():
    big = SIZE * SS
    img = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    px = img.load()
    c = (big - 1) / 2
    for y in range(SIZE):
        for x in range(SIZE):
            hit = 0
            for sy in range(SS):
                for sx in range(SS):
                    d = math.hypot(x * SS + sx - c, y * SS + sy - c) / big
                    if INNER <= d <= OUTER:
                        hit += 1
            px[x, y] = (255, 255, 255, round(255 * hit / (SS * SS)))
    img.save(OUT)
    print("geschrieben:", OUT)


if __name__ == "__main__":
    main()
