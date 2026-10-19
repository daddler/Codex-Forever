#!/usr/bin/env python3
"""Symbol der Spalte fuer "Beute" (media/icons/nav_beute.tga).

Gezeichnet wie die anderen Spaltensymbole: weisse Flaeche mit Alpha,
128 x 128, TGA 32 Bit, Ursprung unten links. Eine Truhe mit gewoelbtem
Deckel, Fuge und Schloss - eigenes Bild, kein Material des Spiels.

    python3 .github/scripts/make_nav_beute.py
"""
import os
import struct

N, SS = 128, 4
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "icons", "nav_beute.tga")


def rrect(x, y, x0, y0, x1, y1, r):
    cx = min(max(x, x0 + r), x1 - r)
    cy = min(max(y, y0 + r), y1 - r)
    return (x - cx) ** 2 + (y - cy) ** 2 <= r * r and x0 <= x <= x1 and y0 <= y <= y1


def inside(x, y):
    # y waechst nach unten (0 oben)
    body = rrect(x, y, 18, 58, 110, 108, 8)
    # Deckel: Halbellipse ueber dem Koerper
    lid = ((x - 64) / 46.0) ** 2 + ((y - 54) / 32.0) ** 2 <= 1 and y <= 54 and 18 <= x <= 110
    seam = 54 <= y <= 60 and not (54 <= x <= 74)
    lock = rrect(x, y, 56, 50, 72, 72, 4)
    keyhole = rrect(x, y, 62, 57, 66, 66, 2)
    bands = (34 <= x <= 39 or 89 <= x <= 94) and 26 <= y <= 108
    shape = (body or lid) and not seam
    gap = rrect(x, y, 51, 45, 77, 77, 6)
    return (shape and not bands and not gap) or (lock and not keyhole)


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
