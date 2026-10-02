"""
Das Logo der Oberfläche ("WCUI") in den Größen bauen, in denen das Spiel es zeigt.

    python3 .github/scripts/make_logo.py

Quelle ist .github/scripts/logo/wcui.png (512x512, mit Alphakanal) - das
Logo, das der Projektinhaber für die WeintCodex-Oberfläche vorgegeben hat
(Beta-Test 6.9.0.2). Kein Spielmaterial.

Geschrieben werden TGA mit weichem Alphakanal nach media/ui/, je Größe
eine Datei in der Nähe der Anzeigegröße - ein Bild, das das Spiel um
mehr als das Doppelte verkleinert, flimmert an den feinen Goldkanten:

    logo_32.tga   Symbol an der Minikarte (~20 px), Tooltip (16 px)
    logo_64.tga   Willkommens-Assistent (64 px), Seitenleiste von /wcui (40 px)

Verkleinert wird mit vormultipliziertem Alpha (RGBa), sonst bekommen die
Ränder einen dunklen Saum.
"""

import os
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, ".github", "scripts", "logo", "wcui.png")
OUT = os.path.join(ROOT, "media", "ui")
SIZES = {"logo_32": 32, "logo_64": 64}


def main():
    src = Image.open(SRC).convert("RGBA")
    if src.size[0] != src.size[1]:
        sys.exit("Quelle muss quadratisch sein: %r" % (src.size,))
    for name, size in SIZES.items():
        img = src.convert("RGBa").resize((size, size), Image.LANCZOS).convert("RGBA")
        path = os.path.join(OUT, name + ".tga")
        img.save(path, compression=None, orientation=1)  # oben links, wie die anderen Grafiken (0x28)
        print("media/ui/" + name + ".tga")


if __name__ == "__main__":
    main()
