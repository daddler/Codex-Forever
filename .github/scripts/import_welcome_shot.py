"""
Ein Bildschirmfoto aus dem Spiel als Bild des Willkommens-Assistenten.

    python3 .github/scripts/import_welcome_shot.py <szene> <bild> [x y breite] [vorschau.png]

Schneidet ab (x, y) einen Ausschnitt im Verhaeltnis 2:1 aus (ohne Angabe:
das ganze Bild, mittig auf 2:1 gekuerzt), verkleinert auf 512x256 und
schreibt media/welcome/<szene>.blp - dasselbe Format wie make_welcome.py.
Seit 6.119.0.0 (Wunsch: "richtige Screenshots"): Bildschirmfotos des
Spielers statt eigener Zeichnungen.
"""

import os
import sys
import tempfile

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from make_artwork import dxt1_blocks, write_blp  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
W, H = 512, 256


def main():
    scene, src = sys.argv[1], sys.argv[2]
    img = Image.open(src).convert("RGB")
    if len(sys.argv) >= 6:
        x, y, w = int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
    else:
        w = min(img.width, img.height * 2)
        x, y = (img.width - w) // 2, (img.height - w // 2) // 2
    img = img.crop((x, y, x + w, y + w // 2)).resize((W, H), Image.LANCZOS)
    if len(sys.argv) >= 7:
        img.save(sys.argv[6])
    with tempfile.TemporaryDirectory() as work:
        write_blp(os.path.join(ROOT, "media", "welcome", scene + ".blp"), dxt1_blocks(img, work), W, H)
    print("media/welcome/" + scene + ".blp")


if __name__ == "__main__":
    main()
