"""
Die Vorschaubilder des Willkommens-Assistenten (ui/welcome.lua) bauen.

    python3 .github/scripts/make_welcome.py [ordner-fuer-png-vorschau]

Quelle ist .github/scripts/welcome/shots.html: eigene Zeichnungen im Stil
von WeintCodex, keine Bildschirmfotos aus dem Spiel (deren Spielwelt und
Symbole gehoeren Blizzard). Je Szene macht ein kopfloser Chromium ein Bild
mit 1024x512, Pillow verkleinert es auf 512x256 (Zweierpotenz) und
make_artwork.py schreibt es als BLP2/DXT1 ohne Mipmaps nach
media/welcome/<szene>.blp - dasselbe Format wie die Dungeonbilder, rund
64 KB je Bild.

Gebraucht werden Pillow und ein Chromium (Umgebungsvariable CHROME oder
/opt/pw-browsers/chromium-*/chrome-linux/chrome).
"""

import glob
import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from make_artwork import dxt1_blocks, write_blp  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PAGE = os.path.join(ROOT, ".github", "scripts", "welcome", "shots.html")
OUT = os.path.join(ROOT, "media", "welcome")

# Das Fenster ist hoeher als die Szene: der kopflose Chromium zieht von der
# Fensterhoehe etwas ab, und abgeschnitten wird danach (crop).
# Die Szenen in shots.html - dieselben Namen stehen in ui/welcome.lua (WL.SHOTS).
SCENES = ["overview", "plates", "group", "windows", "damage", "reminders", "arrow", "helpers"]
SRC_W, SRC_H = 1024, 512
W, H = 512, 256


def chrome():
    found = os.environ.get("CHROME") or shutil.which("chromium") or shutil.which("google-chrome")
    if found:
        return found
    for path in sorted(glob.glob("/opt/pw-browsers/chromium-*/chrome-linux/chrome")):
        return path
    sys.exit("Kein Chromium gefunden (CHROME setzen).")


def shoot(browser, scene, png):
    subprocess.run(
        [browser, "--headless", "--no-sandbox", "--disable-gpu", "--hide-scrollbars",
         "--force-device-scale-factor=1", f"--window-size={SRC_W},{SRC_H + 200}",
         f"--screenshot={png}", f"file://{PAGE}?s={scene}"],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


def main():
    preview = sys.argv[1] if len(sys.argv) > 1 else None
    browser = chrome()
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as work:
        for scene in SCENES:
            png = os.path.join(work, scene + ".png")
            shoot(browser, scene, png)
            img = Image.open(png).convert("RGB").crop((0, 0, SRC_W, SRC_H)).resize((W, H), Image.LANCZOS)
            if preview:
                os.makedirs(preview, exist_ok=True)
                img.save(os.path.join(preview, scene + ".png"))
            write_blp(os.path.join(OUT, scene + ".blp"), dxt1_blocks(img, work), W, H)
            print("media/welcome/" + scene + ".blp")


if __name__ == "__main__":
    main()
