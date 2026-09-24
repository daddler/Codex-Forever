"""
Die Grafiken der optionalen Oberfläche erzeugen - ohne Bildbibliothek.

    python3 .github/scripts/make_ui_media.py

Schreibt nach media/ui/.

**Warum es das gibt.** Eine Binärdatei sagt nicht, wie sie entstanden
ist. Der Questpfeil ist eine Form aus sieben Zahlen; wer ihn schlanker
oder stumpfer haben will, ändert hier eine Zahl, statt ein Bild von
vorn zu zeichnen.

**Warum eigene Formen.** Die Vorlage für die Oberfläche (EllesmereUI)
steht unter "all rights reserved" - ihre Texturen gehören nicht in
dieses Addon. Die Spieltexturen gehören Blizzard. Was hier entsteht,
gehört niemandem sonst.

**Warum weiss.** Der Pfeil wird im Spiel per SetVertexColor gefärbt
(Kurs: Erfolgsgrün, sonst Normaltext). Eine farbige Textur liesse sich
nur abdunkeln, nicht umfärben.

**Warum TGA und nicht BLP.** Die Datei ist 64x64 und braucht einen
weichen Alphakanal. Unkomprimiert sind das 16 KB - weniger als der
Aufwand, einen BLP-Schreiber mit Alpha hierher zu holen.
"""

import os
import struct

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "media", "ui")

SIZE = 64
SAMPLES = 4  # 4x4 Unterabtastung je Pixel: glatte Kanten ohne Bibliothek


def write_tga(path, width, height, pixels):
    """pixels: Liste von (r, g, b, a) zeilenweise von OBEN nach unten."""
    header = struct.pack(
        "<BBBHHBHHHHBB",
        0,      # keine Bildkennung
        0,      # keine Farbtabelle
        2,      # unkomprimiertes Echtfarbbild
        0, 0, 0,
        0, 0,   # Ursprung
        width, height,
        32,     # Bits je Pixel
        0x28,   # 8 Bit Alpha, Ursprung OBEN links
    )
    body = bytearray()
    for (r, g, b, a) in pixels:
        body += bytes((b, g, r, a))
    with open(path, "wb") as handle:
        handle.write(header)
        handle.write(bytes(body))


def inside_polygon(x, y, poly):
    """Gerade-ungerade-Regel; poly in Pixelkoordinaten, y nach unten."""
    hit = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if (yi > y) != (yj > y):
            cross = (xj - xi) * (y - yi) / (yj - yi) + xi
            if x < cross:
                hit = not hit
        j = i
    return hit


def render(poly):
    pixels = []
    step = 1.0 / SAMPLES
    for py in range(SIZE):
        for px in range(SIZE):
            covered = 0
            for sy in range(SAMPLES):
                for sx in range(SAMPLES):
                    x = px + (sx + 0.5) * step
                    y = py + (sy + 0.5) * step
                    if inside_polygon(x, y, poly):
                        covered += 1
            alpha = round(255 * covered / (SAMPLES * SAMPLES))
            pixels.append((255, 255, 255, alpha))
    return pixels


# Der Questpfeil: zeigt nach OBEN (Rotation 0 = geradeaus). Eine
# Pfeilspitze mit eingezogenem Heck statt eines Schafts - bei 40 px auf
# dem Bildschirm liest sich ein Schaft als Strich, nicht als Richtung.
TIP_Y = 4        # Spitze
WING_Y = 54      # Fluegelenden
WING_X = 12      # Abstand der Fluegel vom Rand
NOTCH_Y = 40     # Einzug des Hecks
CENTER = SIZE / 2.0

ARROW = [
    (CENTER, TIP_Y),
    (SIZE - WING_X, WING_Y),
    (CENTER, NOTCH_Y),
    (WING_X, WING_Y),
]


def main():
    os.makedirs(OUT, exist_ok=True)
    target = os.path.join(OUT, "arrow.tga")
    write_tga(target, SIZE, SIZE, render(ARROW))
    print("geschrieben:", os.path.relpath(target, ROOT))


if __name__ == "__main__":
    main()
