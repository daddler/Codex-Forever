#!/usr/bin/env python3
"""Eigene Bilder fuer das Design "Konsole" (ui/console.lua, 1.0.7.44).

Wunsch: "als viertes Design so, wie Spartan UI es macht". Nur das
Verhalten ist angelehnt (Platten hinter den Leisten, Ring um die Karte) -
kein Bild von SpartanUI, alles aus Formeln gerechnet: dunkler Stein mit
leiser Koernung, Fase oben, Metallkante.

Graustufen mit Alpha (gefaerbt wird im Spiel ueber SetVertexColor).

    python3 .github/scripts/make_console_media.py
"""
import math
import os
import random
import struct

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "ui")


def write_tga(name, w, h, px):
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
    body = bytearray()
    for y in range(h):
        for x in range(w):
            v, a = px(x, y)
            v = max(0, min(255, int(round(v * 255))))
            a = max(0, min(255, int(round(a * 255))))
            body += bytes((v, v, v, a))
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


random.seed(7)
GRID = 32
NOISE = [[random.random() for _ in range(GRID + 1)] for _ in range(GRID + 1)]


def vnoise(u, v):
    # glatte Wertrauschen-Koernung, kachelbar
    u, v = (u % 1.0) * GRID, (v % 1.0) * GRID
    i, j = int(u), int(v)
    fu, fv = u - i, v - j
    fu, fv = fu * fu * (3 - 2 * fu), fv * fv * (3 - 2 * fv)
    a = NOISE[j][i] * (1 - fu) + NOISE[j][i + 1] * fu
    b = NOISE[j + 1][i] * (1 - fu) + NOISE[j + 1][i + 1] * fu
    return a * (1 - fv) + b * fv


def stone(u, v):
    n = 0.55 * vnoise(u, v) + 0.3 * vnoise(u * 2.3, v * 2.3) + 0.15 * vnoise(u * 5.1, v * 5.1)
    return 0.16 + 0.10 * n


def plate(w=512, h=128):
    # Platte: Stein, oben eine helle Fase, ringsum eine Metallkante,
    # Ecken leicht gerundet, Rand exakt 0.
    R = 10.0

    def px(x, y):
        dx = min(x + 0.5, w - x - 0.5)
        dy = min(y + 0.5, h - y - 0.5)
        if dx < R and dy < R:
            d = R - math.hypot(R - dx, R - dy)
        else:
            d = min(dx, dy)
        a = smooth(0.0, 1.5, d)
        v = stone(x / w * 4, y / h)
        if d < 5:                      # Metallkante
            v = 0.42 + 0.18 * math.cos(d / 5 * math.pi)
        elif y < 14:                   # Fase oben
            v += 0.10 * (1 - y / 14)
        v *= 0.9 + 0.1 * (1 - y / h)  # nach unten etwas dunkler
        return v, a
    write_tga("console_plate", w, h, px)


def ring(n=256, square=False):
    # Ring um die Karte: breiter Steinwulst mit Metallkanten innen/aussen,
    # Licht von oben links. Innen frei (Alpha 0).
    def px(x, y):
        cx = (x + 0.5) / n * 2 - 1
        cy = (y + 0.5) / n * 2 - 1
        if square:
            k = 6.0
            r = (abs(cx) ** k + abs(cy) ** k) ** (1 / k)
        else:
            r = math.hypot(cx, cy)
        r0, r1 = 0.80, 0.98          # innen, aussen
        if r < r0 - 0.01 or r > r1 + 0.01:
            return 0.0, 0.0
        a = smooth(r0 - 0.01, r0 + 0.005, r) * (1 - smooth(r1 - 0.005, r1 + 0.01, r))
        t = (r - r0) / (r1 - r0)       # 0 innen, 1 aussen
        bulge = math.sin(t * math.pi)
        light = (-cx - cy) * 0.5 / max(r, 1e-3)
        v = stone(x / n * 3, y / n * 3) + 0.08 * bulge + 0.07 * light * bulge
        if t < 0.12 or t > 0.88:
            v = 0.45 + 0.12 * light
        return v, a
    write_tga("console_square" if square else "console_ring", n, n, px)


if __name__ == "__main__":
    plate()
    ring()
    ring(square=True)
    print("ok")
