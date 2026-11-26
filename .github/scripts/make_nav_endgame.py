#!/usr/bin/env python3
"""Symbol der Spalte fuer "Endgame" (media/icons/nav_endgame.tga), 1.0.10.0.

Gezeichnet wie die anderen Spaltensymbole: weisse Flaeche mit Alpha,
128 x 128, TGA 32 Bit, Ursprung unten links. Eine Krone mit drei Zacken
und einem Band - eigenes Bild, kein Material des Spiels.

    python3 .github/scripts/make_nav_endgame.py
"""
import os
import struct

N, SS = 128, 4
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "icons", "nav_endgame.tga")


def in_tri(x, y, ax, ay, bx, by, cx, cy):
    d1 = (x - bx) * (ay - by) - (ax - bx) * (y - by)
    d2 = (x - cx) * (by - cy) - (bx - cx) * (y - cy)
    d3 = (x - ax) * (cy - ay) - (cx - ax) * (y - ay)
    neg = d1 < 0 or d2 < 0 or d3 < 0
    pos = d1 > 0 or d2 > 0 or d3 > 0
    return not (neg and pos)


def disc(x, y, cx, cy, r):
    return (x - cx) ** 2 + (y - cy) ** 2 <= r * r


def inside(x, y):
    # y waechst nach unten (0 oben)
    band = 86 <= y <= 104 and 20 <= x <= 108
    body = 66 <= y <= 86 and 20 <= x <= 108
    spikes = (in_tri(x, y, 20, 70, 20, 34, 56, 70) or in_tri(x, y, 108, 70, 108, 34, 72, 70)
              or in_tri(x, y, 38, 70, 64, 22, 90, 70))
    crown = body or spikes
    jewels = disc(x, y, 20, 30, 8) or disc(x, y, 108, 30, 8) or disc(x, y, 64, 18, 9)
    gem = disc(x, y, 64, 95, 5)
    return (crown or band or jewels) and not gem and not (80 <= y <= 86 and 20 <= x <= 108)


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
