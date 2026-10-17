#!/usr/bin/env python3
"""Symbol der Spalte fuer "Buecher" (media/icons/nav_buecher.tga), 6.59.0.0.

Gezeichnet wie die anderen Spaltensymbole: weisse Flaeche mit Alpha,
128 x 128, TGA 32 Bit, Ursprung unten links. Ein aufgeschlagenes Buch - eigenes Bild, kein Material des Spiels.

    python3 .github/scripts/make_nav_taschen.py
"""
import math
import os
import struct

N, SS = 128, 4
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "icons", "nav_buecher.tga")


def rrect(x, y, x0, y0, x1, y1, r):
    cx = min(max(x, x0 + r), x1 - r)
    cy = min(max(y, y0 + r), y1 - r)
    return (x - cx) ** 2 + (y - cy) ** 2 <= r * r and x0 <= x <= x1 and y0 <= y <= y1


def inside(x, y):
    # Aufgeschlagenes Buch: zwei Seiten mit Ruecken, je drei Zeilen frei.
    left = rrect(x, y, 14, 30, 62, 100, 8) and not (x > 60)
    right = rrect(x, y, 66, 30, 114, 100, 8) and not (x < 68)
    spine = 61 <= x <= 67 and 34 <= y <= 106
    base = rrect(x, y, 14, 98, 114, 108, 4)
    lines = False
    for ly in (48, 62, 76):
        if ly <= y <= ly + 4 and (24 <= x <= 54 or 74 <= x <= 104):
            lines = True
    return ((left or right) and not lines) or spine or base


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
