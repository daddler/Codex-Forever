"""
Symbole des Sammel-Atlas erzeugen (ui/gatheratlas.lua, 6.82.0.0).

    python3 .github/scripts/make_gather_icons.py

Schreibt media/ui/gather_herb.tga, gather_ore.tga, gather_chest.tga,
gather_fish.tga - je 64x64 RGBA, Ursprung oben links.

**Eigene Formen.** Kein Bild aus dem Spiel, keins aus einem anderen
Addon: Blatt, Erzbrocken, Truhe und Fisch sind hier aus ein paar Zahlen
gezeichnet.

**Weiss mit dunklem Rand.** Das Spiel faerbt das Symbol per
SetVertexColor (Farben in core/ui.lua, GameColors.gather*). Weiss wird
zur Farbe der Art, der dunkle Rand bleibt dunkel - lesbar auf jedem Grund
der Karte, auch bei 14 Bildpunkten.

Gezeichnet in 256x256, dann verkleinert (glatte Kanten).
"""

import os
import struct

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "media", "ui")
BIG, SIZE = 256, 64
RIM = 18          # Breite des dunklen Rands (in 256er Punkten)


def write_tga(path, img):
    img = img.convert("RGBA")
    w, h = img.size
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
    body = bytearray()
    for r, g, b, a in (img.get_flattened_data() if hasattr(img, 'get_flattened_data') else img.getdata()):
        body += bytes((b, g, r, a))
    with open(path, "wb") as f:
        f.write(header)
        f.write(bytes(body))


def compose(mask, detail=None):
    """mask: weisse Form (L). detail: dunkle Linien in der Form (L)."""
    rim = mask.filter(ImageFilter.MaxFilter(RIM * 2 + 1))
    img = Image.new("RGBA", (BIG, BIG), (0, 0, 0, 0))
    img.paste((20, 16, 12, 235), (0, 0), rim)
    img.paste((255, 255, 255, 255), (0, 0), mask)
    if detail is not None:
        img.paste((40, 34, 28, 255), (0, 0), detail)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def blank():
    return Image.new("L", (BIG, BIG), 0)


def herb():
    m, d = blank(), blank()
    dd = ImageDraw.Draw(d)
    # Blatt: Schnitt zweier Kreise (eine Linse), schraeg von unten links
    # nach oben rechts; Stiel unten links, Mittelrippe dunkel.
    a, b = blank(), blank()
    ImageDraw.Draw(a).ellipse((-10, 40, 210, 260), fill=255)
    ImageDraw.Draw(b).ellipse((50, -20, 270, 200), fill=255)
    m.paste(255, (0, 0), Image.composite(a, blank(), b))
    ImageDraw.Draw(m).line((30, 230, 80, 180), fill=255, width=20)
    dd.line((70, 190, 200, 60), fill=255, width=10)
    return compose(m, d)


def ore():
    m, d = blank(), blank()
    dm, dd = ImageDraw.Draw(m), ImageDraw.Draw(d)
    pts = [(128, 34), (210, 90), (200, 190), (128, 226), (52, 186), (44, 96)]
    dm.polygon(pts, fill=255)
    # Facetten
    dd.line((128, 34, 128, 130), fill=255, width=9)
    dd.line((44, 96, 128, 130), fill=255, width=9)
    dd.line((210, 90, 128, 130), fill=255, width=9)
    dd.line((128, 130, 128, 226), fill=255, width=9)
    return compose(m, d)


def chest():
    m, d = blank(), blank()
    dm, dd = ImageDraw.Draw(m), ImageDraw.Draw(d)
    dm.rounded_rectangle((34, 92, 222, 214), radius=14, fill=255)
    dm.pieslice((34, 40, 222, 144), 180, 360, fill=255)
    dm.rectangle((34, 92, 222, 110), fill=255)
    dd.line((34, 112, 222, 112), fill=255, width=10)
    dd.rectangle((112, 100, 144, 146), fill=255)
    return compose(m, d)


def fish():
    m, d = blank(), blank()
    dm, dd = ImageDraw.Draw(m), ImageDraw.Draw(d)
    dm.ellipse((30, 80, 190, 176), fill=255)
    dm.polygon([(170, 128), (232, 70), (220, 128), (232, 186)], fill=255)
    dd.ellipse((60, 110, 82, 132), fill=255)
    dd.arc((100, 94, 150, 162), 300, 60, fill=255, width=8)
    return compose(m, d)


def ring():
    # 6.84.7.0: Loch so gross, dass das Vorkommen des Spiels ganz frei steht.
    # 6.84.6.0 (Beta-Test: "sehr gross, sieht nicht gut aus"): ein sauberer,
    # duenner Ring ohne dunklen Rand des Symbol-Stils, nur ein weicher
    # Schatten aussen, damit er auf hellem Boden lesbar bleibt. Eingefaerbt
    # wird im Spiel.
    from PIL import ImageFilter as F
    size = BIG
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sh = Image.new("L", (size, size), 0)
    ImageDraw.Draw(sh).ellipse((6, 6, size - 6, size - 6), outline=255, width=26)
    sh = sh.filter(F.GaussianBlur(6))
    img.paste((0, 0, 0, 255), (0, 0), sh.point(lambda v: int(v * 0.55)))
    rg = Image.new("L", (size, size), 0)
    ImageDraw.Draw(rg).ellipse((12, 12, size - 12, size - 12), outline=255, width=16)
    img.paste((255, 255, 255, 255), (0, 0), rg)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in (("herb", herb), ("ore", ore), ("chest", chest), ("fish", fish), ("ring", ring)):
        path = os.path.join(OUT, "gather_" + name + ".tga")
        write_tga(path, fn())
        print("geschrieben:", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main()
