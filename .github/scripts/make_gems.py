#!/usr/bin/env python3
"""Kristalle der Juwelen (ui/flightgames.lua), seit 6.81.0.0.

Eigene Zeichnung: je Stein ein geschliffener Umriss (Rund, Achteck,
Sechseck, Smaragdschliff, Raute, Dreieck), aussen Facetten zwischen Umriss
und Tafel, schattiert nach einem Licht von oben links, dazu Tafel, Glanz,
Funkeln und dunkle Kante. 4-fach gezeichnet, dann verkleinert.

    pip install pillow
    python3 .github/scripts/make_gems.py

schreibt media/ui/gem1..6.tga (64x64, RGBA).
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "ui")
S, SS = 64, 4
N = S * SS
C = N / 2
LIGHT = (-0.6, -0.8)  # von oben links

# Farbe je Stein in der Reihenfolge von J (rot, orange, gelb, gruen, blau, violett).
GEMS = [
    ("rund", (225, 40, 55)),
    ("sechseck", (245, 135, 30)),
    ("achteck", (250, 215, 50)),
    ("smaragd", (40, 200, 90)),
    ("dreieck", (45, 140, 245)),
    ("raute", (170, 70, 235)),
]


def poly(kind, r):
    if kind == "rund":
        return [(C + r * math.cos(a), C + r * math.sin(a)) for a in [2 * math.pi * i / 16 - math.pi / 2 for i in range(16)]]
    if kind == "sechseck":
        return [(C + r * math.cos(a), C + r * math.sin(a)) for a in [2 * math.pi * i / 6 for i in range(6)]]
    if kind == "achteck":
        return [(C + r * math.cos(a), C + r * math.sin(a)) for a in [2 * math.pi * i / 8 + math.pi / 8 for i in range(8)]]
    if kind == "smaragd":
        w, h, c = r * 0.78, r * 0.95, r * 0.3
        return [(C - w + c, C - h), (C + w - c, C - h), (C + w, C - h + c), (C + w, C + h - c),
                (C + w - c, C + h), (C - w + c, C + h), (C - w, C + h - c), (C - w, C - h + c)]
    if kind == "dreieck":
        return [(C + r * math.cos(a), C + 0.12 * r + r * math.sin(a)) for a in [-math.pi / 2 + 2 * math.pi * i / 3 for i in range(3)]]
    if kind == "raute":
        return [(C, C - r), (C + r * 0.72, C), (C, C + r), (C - r * 0.72, C)]


def shade(col, f):
    if f >= 0:
        return tuple(int(c + (255 - c) * f) for c in col)
    return tuple(int(c * (1 + f)) for c in col)


def make(kind, col):
    img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    R = N * (0.5 if kind == "dreieck" else 0.47 if kind == "raute" else 0.44)
    outer = poly(kind, R)
    tabk = 0.55 if kind != "dreieck" else 0.45
    inner = [(C + (x - C) * tabk, C + (y - C) * tabk - N * 0.02) for x, y in outer]
    # Schatten unter dem Stein
    sh = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    ImageDraw.Draw(sh).polygon([(x + N * 0.02, y + N * 0.035) for x, y in outer], fill=(0, 0, 0, 120))
    img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(N * 0.02)))
    d = ImageDraw.Draw(img)
    # Facetten: je Kante ein Viereck aussen-innen, Helligkeit nach Normalen.
    n = len(outer)
    for i in range(n):
        a, b = outer[i], outer[(i + 1) % n]
        ia, ib = inner[i], inner[(i + 1) % n]
        mx, my = (a[0] + b[0]) / 2 - C, (a[1] + b[1]) / 2 - C
        L = math.hypot(mx, my) or 1
        dot = (mx * LIGHT[0] + my * LIGHT[1]) / L
        f = 0.45 * dot + (0.08 if i % 2 else -0.08)
        d.polygon([a, b, ib, ia], fill=shade(col, f) + (255,))
        # Teilung jeder Facette in zwei Dreiecke - der Schliff
        m = ((ia[0] + ib[0]) / 2, (ia[1] + ib[1]) / 2)
        d.polygon([a, b, m], fill=shade(col, f - 0.12) + (255,))
    # Tafel mit Verlauf
    tab = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    td = ImageDraw.Draw(tab)
    td.polygon(inner, fill=shade(col, 0.15) + (255,))
    grad = Image.new("L", (N, N), 0)
    gd = ImageDraw.Draw(grad)
    for y in range(N):
        gd.line([(0, y), (N, y)], fill=int(150 * max(0, 1 - y / (N * 0.6))))
    hi = Image.new("RGBA", (N, N), (255, 255, 255, 0))
    hi.putalpha(grad)
    mask = Image.new("L", (N, N), 0)
    ImageDraw.Draw(mask).polygon(inner, fill=255)
    tab = Image.alpha_composite(tab, Image.composite(hi, Image.new("RGBA", (N, N), (0, 0, 0, 0)), mask))
    img = Image.alpha_composite(img, tab)
    d = ImageDraw.Draw(img)
    # Kanten des Schliffs
    edge = shade(col, -0.55) + (255,)
    lite = shade(col, 0.6) + (170,)
    for i in range(n):
        d.line([outer[i], inner[i]], fill=lite, width=SS)
    d.polygon(inner, outline=lite)
    d.line(outer + [outer[0]], fill=edge, width=int(SS * 2.2), joint="curve")
    # Glanz oben links und ein Funkeln
    gl = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    gld = ImageDraw.Draw(gl)
    gx, gy, gr = C - R * 0.32, C - R * 0.38, R * 0.16
    gld.ellipse([gx - gr * 1.6, gy - gr, gx + gr * 1.6, gy + gr], fill=(255, 255, 255, 170))
    gl = gl.filter(ImageFilter.GaussianBlur(SS * 2))
    gl2 = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    g2 = ImageDraw.Draw(gl2)
    sx, sy, sl = C + R * 0.35, C - R * 0.2, R * 0.28
    g2.polygon([(sx, sy - sl), (sx + sl * 0.18, sy), (sx, sy + sl), (sx - sl * 0.18, sy)], fill=(255, 255, 255, 230))
    g2.polygon([(sx - sl, sy), (sx, sy - sl * 0.18), (sx + sl, sy), (sx, sy + sl * 0.18)], fill=(255, 255, 255, 230))
    om = Image.new("L", (N, N), 0)
    ImageDraw.Draw(om).polygon(outer, fill=255)
    gl.putalpha(Image.composite(gl.getchannel("A"), Image.new("L", (N, N), 0), om))
    img = Image.alpha_composite(img, Image.alpha_composite(gl, gl2))
    return img.resize((S, S), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    for i, (kind, col) in enumerate(GEMS, 1):
        make(kind, col).save(os.path.join(OUT, "gem%d.tga" % i))


if __name__ == "__main__":
    main()
