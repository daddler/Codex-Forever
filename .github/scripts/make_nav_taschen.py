#!/usr/bin/env python3
"""Symbol der Spalte fuer "Taschen" (media/icons/nav_taschen.tga), 6.25.0.0.

Gezeichnet wie die anderen Spaltensymbole: weisse Flaeche mit Alpha,
128 x 128, TGA 32 Bit, Ursprung unten links. Eine Tasche mit Henkel,
Klappe und Schliesse - eigenes Bild, kein Material des Spiels.

    python3 .github/scripts/make_nav_taschen.py
"""
import math
import os
import struct

N, SS = 128, 4
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "icons", "nav_taschen.tga")


def rrect(x, y, x0, y0, x1, y1, r):
    cx = min(max(x, x0 + r), x1 - r)
    cy = min(max(y, y0 + r), y1 - r)
    return (x - cx) ** 2 + (y - cy) ** 2 <= r * r and x0 <= x <= x1 and y0 <= y <= y1


def inside(x, y):
    # Koerper
    body = rrect(x, y, 22, 40, 106, 112, 14)
    # Henkel: Ring ueber dem Koerper
    d = math.hypot(x - 64, y - 42)
    handle = 18 <= d <= 27 and y <= 42
    # Klappe abgesetzt: schmale Fuge, Schliesse in der Mitte bleibt
    seam = 66 <= y <= 71 and 22 <= x <= 106 and not (54 <= x <= 74)
    clasp_hole = rrect(x, y, 59, 72, 69, 82, 3)
    return (body and not seam and not clasp_hole) or handle


def main():
    px = bytearray()
    for row in range(N):
        y_top = N - 1 - row          # TGA: unterste Zeile zuerst
        for x in range(N):
            hit = 0
            for sy in range(SS):
                for sx in range(SS):
                    if inside(x + (sx + 0.5) / SS, y_top + (sy + 0.5) / SS):
                        hit += 1
            a = round(255 * hit / (SS * SS))
            px += bytes((255, 255, 255, a))
    head = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, N, N, 32, 8)
    with open(OUT, "wb") as fh:
        fh.write(head + px)
    print(OUT)


if __name__ == "__main__":
    main()
