#!/usr/bin/env python3
"""Eigene Bilder fuer das Glitzern an Kraeutern und Erz (ui/sparkles.lua).

1.0.7.22: Das Verhalten folgt Lueur (Halo am Boden, Schleier darunter,
drehende Schwaden, Kometenboegen, funkelnder Kern, aufsteigende Funken) -
die BILDER von Lueur sind nicht lizenziert und werden NICHT verwendet.
Alles hier ist aus Formeln gerechnet.

Jedes Bild ist weiss mit Alpha (gefaerbt wird im Spiel), quadratisch wo es
gedreht wird, und am Rand exakt 0 - ein Rand ueber 0 zeichnet im Spiel
eine harte Kante (genau der Querbalken des alten Bodenscheins).

    python3 .github/scripts/make_sparkle_media.py
"""
import math
import os
import struct

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "ui")


def write_tga(name, w, h, alpha):
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
    body = bytearray()
    for y in range(h):
        for x in range(w):
            a = max(0, min(255, int(round(alpha(x, y) * 255))))
            body += bytes((255, 255, 255, a))
    with open(os.path.join(OUT, name + ".tga"), "wb") as f:
        f.write(header)
        f.write(bytes(body))


def smooth(e0, e1, x):
    if x <= e0:
        return 0.0
    if x >= e1:
        return 1.0
    t = (x - e0) / (e1 - e0)
    return t * t * (3 - 2 * t)


def polar(n, x, y):
    cx = (x + 0.5) / n * 2 - 1
    cy = (y + 0.5) / n * 2 - 1
    return math.hypot(cx, cy), math.atan2(cy, cx)


def soft_glow(n=128):
    # Gauss, zum Rand sanft auf 0 gezogen.
    def a(x, y):
        r, _ = polar(n, x, y)
        return math.exp(-r * r * 4.5) * (1 - smooth(0.75, 1.0, r))
    write_tga("spark_glow", n, n, a)


def ring(n=256):
    # Duenner, weicher Ring mit leichtem Innenschein.
    def a(x, y):
        r, _ = polar(n, x, y)
        band = math.exp(-((r - 0.78) / 0.045) ** 2)
        inner = 0.18 * math.exp(-((r - 0.70) / 0.12) ** 2)
        return (band + inner) * (1 - smooth(0.93, 1.0, r))
    write_tga("spark_ring", n, n, a)


def wisp(n=256):
    # Schwaden: zwei verwischte Spiralfaeden im Band 0.45-0.9.
    def a(x, y):
        r, t = polar(n, x, y)
        v = 0.0
        for k in (0, math.pi):
            ang = (t + k - r * 3.2) % (2 * math.pi)
            v += math.exp(-((ang - math.pi) / 0.9) ** 2)
        band = math.exp(-((r - 0.66) / 0.17) ** 2)
        return min(1.0, v * band * 0.9) * (1 - smooth(0.92, 1.0, r))
    write_tga("spark_wisp", n, n, a)


def arcs(n=256):
    # Drei Kometen auf dem Ring: heller Kopf, langer Schweif.
    def a(x, y):
        r, t = polar(n, x, y)
        band = math.exp(-((r - 0.78) / 0.035) ** 2)
        v = 0.0
        for k in range(3):
            d = (t - k * 2 * math.pi / 3) % (2 * math.pi)   # 0 = Kopf, Schweif dahinter
            tail = (math.exp(-d / 0.9) * smooth(0.0, 0.12, d)) if d < 2.2 else 0.0
            v = max(v, tail)
        return band * v * (1 - smooth(0.92, 1.0, r))
    write_tga("spark_arcs", n, n, a)


def flare(n=128):
    # Vierstrahliger Stern mit weichem Kern.
    def a(x, y):
        r, t = polar(n, x, y)
        core = math.exp(-r * r * 30)
        ray = (abs(math.cos(2 * t)) ** 24) * math.exp(-r * 3.2)
        ray2 = (abs(math.cos(2 * t + math.pi / 4 * 2)) ** 40) * math.exp(-r * 5) * 0.0
        return min(1.0, core + ray + ray2) * (1 - smooth(0.85, 1.0, r))
    write_tga("spark_flare", n, n, a)


def beam(w=64, h=256):
    # Lichtsaeule: quer Gauss, unten weich angesetzt, oben lang ausklingend.
    def a(x, y):
        cx = (x + 0.5) / w * 2 - 1
        v = (y + 0.5) / h            # 0 oben, 1 unten
        across = math.exp(-cx * cx * 6) * (1 - smooth(0.8, 1.0, abs(cx)))
        up = smooth(0.0, 0.85, v)    # oben aus
        foot = 1 - smooth(0.9, 1.0, v)
        return across * up * up * foot
    write_tga("spark_beam", w, h, a)


if __name__ == "__main__":
    soft_glow()
    ring()
    wisp()
    arcs()
    flare()
    beam()
    print("ok")
