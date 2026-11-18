#!/usr/bin/env python3
"""Eigene Bilder fuer das Design "Konsole" (ui/console.lua, 1.0.7.44).

Wunsch: "so aehnlich wie moeglich Richtung Spartan UI, mit Ornamenten".
Angelehnt ist nur die Anordnung (Mittelstueck mit Buckel und runder
Fassung fuer die Karte, geschwungene Dornen, Seitenteile mit Ziernaht,
eingelassene Schaechte hinter den Leisten). Kein Bild von SpartanUI -
alles hier ist aus Formeln gerechnet.

    python3 .github/scripts/make_console_media.py
"""
import math
import os
import struct

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "ui")
rng = np.random.default_rng(11)


def write_tga(name, v, a):
    h, w = v.shape
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
    g = np.clip(v * 255 + 0.5, 0, 255).astype(np.uint8)
    al = np.clip(a * 255 + 0.5, 0, 255).astype(np.uint8)
    px = np.stack([g, g, g, al], axis=-1)
    with open(os.path.join(OUT, name + ".tga"), "wb") as f:
        f.write(header)
        f.write(px.tobytes())


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def value_noise(h, w, cell):
    gh, gw = h // cell + 2, w // cell + 2
    g = rng.random((gh, gw))
    ys = np.arange(h) / cell
    xs = np.arange(w) / cell
    y0 = ys.astype(int)
    x0 = xs.astype(int)
    fy = (ys - y0)[:, None]
    fx = (xs - x0)[None, :]
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    a = g[y0][:, x0]
    b = g[y0][:, x0 + 1]
    c = g[y0 + 1][:, x0]
    d = g[y0 + 1][:, x0 + 1]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def stone(h, w):
    # Grauer Stein mit Flecken und leichten senkrechten Laeufen,
    # nach unten dunkler.
    n = (0.5 * value_noise(h, w, 32) + 0.3 * value_noise(h, w, 9) + 0.2 * value_noise(h, w, 3))
    spots = value_noise(h, w, 5)
    v = 0.17 + 0.13 * n
    v -= 0.06 * smooth(0.84, 0.95, spots)          # dunkle Flecken
    drip = value_noise(1, w, 6)[0] if False else value_noise(h // 8 + 1, w, 7)
    drip = np.repeat(drip, 8, axis=0)[:h]
    v -= 0.04 * smooth(0.6, 0.9, drip)
    ys = np.arange(h)[:, None] / h
    v *= 1.0 - 0.45 * ys                            # nach unten dunkler
    return v


def bezier(p0, p1, p2, p3, n=400):
    t = np.linspace(0, 1, n)[:, None]
    p0, p1, p2, p3 = (np.array(p, float) for p in (p0, p1, p2, p3))
    return ((1 - t) ** 3) * p0 + 3 * ((1 - t) ** 2) * t * p1 + 3 * (1 - t) * t * t * p2 + t ** 3 * p3


def stroke(mask, pts, w0, w1):
    # Dorn: Kurve mit abnehmender Breite, als Scheiben gestempelt.
    h, w = mask.shape
    yy, xx = np.mgrid[0:h, 0:w]
    n = len(pts)
    for i in range(0, n, 2):
        x, y = pts[i]
        r = w0 + (w1 - w0) * (i / (n - 1))
        if r <= 0.2:
            continue
        x0, x1 = int(max(0, x - r - 2)), int(min(w, x + r + 3))
        y0, y1 = int(max(0, y - r - 2)), int(min(h, y + r + 3))
        if x0 >= x1 or y0 >= y1:
            continue
        d = np.hypot(xx[y0:y1, x0:x1] - x, yy[y0:y1, x0:x1] - y)
        m = np.clip(r + 0.5 - d, 0, 1)
        mask[y0:y1, x0:x1] = np.maximum(mask[y0:y1, x0:x1], m)


def carve(v, mask):
    # Ornament eingraviert: dunkel, oben eine helle Kante, unten Schatten.
    up = np.roll(mask, 1, axis=0)
    down = np.roll(mask, -1, axis=0)
    hi = np.clip(mask - up, 0, 1)      # Oberkante
    lo = np.clip(mask - down, 0, 1)    # Unterkante
    v = v * (1 - mask) + 0.05 * mask
    v += 0.28 * hi
    v -= 0.05 * np.clip(np.roll(mask, 2, axis=0) - mask, 0, 1)
    return v


def rim(v, a, top):
    # helle Fase entlang der Oberkante, darunter eine dunkle Linie
    h, w = v.shape
    ys = np.arange(h)[:, None]
    d = ys - top[None, :]
    v = v + 0.22 * np.exp(-((d - 1.5) / 1.3) ** 2) - 0.08 * np.exp(-((d - 5) / 1.5) ** 2)
    a = a * smooth(-0.5, 1.2, d)
    return v, a


def mirror_pair(fn):
    # Ornament links bauen, rechts gespiegelt
    pass


def center(W=512, H=256):
    TOP0, HUMP = 96.0, 84.0
    cx, cy, R = 256.0, 150.0, 102.0
    xs = np.arange(W)
    top = TOP0 - HUMP * np.exp(-((xs - cx) / 112.0) ** 2)
    v = stone(H, W)
    a = np.ones((H, W))
    v, a = rim(v, a, top)
    yy, xx = np.mgrid[0:H, 0:W]
    r = np.hypot(xx - cx, yy - cy)
    # Ornamente (linke Haelfte, dann gespiegelt)
    m = np.zeros((H, W))
    for side in (-1, 1):
        def P(x, y):
            return (cx + side * x, y)
        # Schwinge aus der Fassung nach aussen, Spitze eingerollt
        stroke(m, bezier(P(98, 108), P(150, 96), P(190, 80), P(236, 90)), 9, 0.6)
        stroke(m, bezier(P(190, 84), P(206, 66), P(190, 56), P(174, 64)), 5, 0.5)
        # Flamme ueber der Schwinge, nach oben zur Fassung
        stroke(m, bezier(P(150, 100), P(130, 80), P(116, 62), P(104, 52)), 6, 0.4)
        # Dorn an der Oberkante entlang bis an den Rand
        stroke(m, bezier(P(126, 106), P(180, 114), P(226, 104), P(256, 101)), 5, 1.6)
        # Dorn aus der Fassung nach unten, eingerollt
        stroke(m, bezier(P(96, 172), P(126, 196), P(120, 226), P(146, 252)), 8.5, 0.8)
        stroke(m, bezier(P(112, 208), P(138, 216), P(160, 206), P(170, 188)), 5, 0.4)
        # Haken aussen, wie ein Horn
        stroke(m, bezier(P(186, 140), P(214, 160), P(212, 200), P(184, 222)), 6.5, 0.5)
        stroke(m, bezier(P(214, 128), P(236, 136), P(244, 150), P(238, 166)), 4, 0.4)
    v = carve(v, m)
    # Fassung: Wulst mit Licht von oben links, innen frei
    ang = np.arctan2(yy - cy, xx - cx)
    light = -np.cos(ang + math.pi * 0.75)          # oben links hell
    band = smooth(R - 2, R, r) * (1 - smooth(R + 9, R + 11, r))
    v = v * (1 - band) + band * (0.30 + 0.16 * light)
    v -= 0.10 * np.exp(-((r - (R + 14)) / 4) ** 2)  # Schatten aussen
    a = a * smooth(R - 2.5, R - 1, r)               # innen durchsichtig
    write_tga("console_center", np.clip(v, 0, 1), np.clip(a, 0, 1))


def side(W=1024, H=256):
    TOP0 = 96.0
    top = np.full(W, TOP0)
    v = stone(H, W)
    a = np.ones((H, W))
    v, a = rim(v, a, top)
    m = np.zeros((H, W))
    # Ziernaht: von der Mitte (rechts) nach aussen auslaufend, mit Haken
    stroke(m, bezier((1024, 108), (820, 106), (520, 124), (200, 128)), 5, 0.4)
    stroke(m, bezier((910, 107), (880, 88), (840, 90), (834, 106)), 4.5, 0.6)
    stroke(m, bezier((660, 115), (580, 102), (480, 106), (420, 118)), 3.5, 0.3)
    stroke(m, bezier((300, 126), (250, 112), (200, 112), (160, 120)), 2.5, 0.3)
    v = carve(v, m)
    write_tga("console_side", np.clip(v, 0, 1), np.clip(a, 0, 1))


def slot(W=256, H=64):
    # eingelassener Schacht hinter einer Leiste
    yy, xx = np.mgrid[0:H, 0:W]
    dx = np.minimum(xx + 0.5, W - xx - 0.5)
    dy = np.minimum(yy + 0.5, H - yy - 0.5)
    d = np.minimum(dx, dy)
    a = smooth(0, 1.5, d) * 0.92
    v = np.full((H, W), 0.035) + 0.02 * value_noise(H, W, 6)
    v += 0.16 * (yy > H - 3) * (d < 3)        # Kante unten hell
    v -= 0.02 * (yy < 3)
    edge = (d < 2.0)
    v = np.where(edge & (yy < H / 2), 0.0, v)
    write_tga("console_slot", np.clip(v, 0, 1), np.clip(a, 0, 1))


if __name__ == "__main__":
    for old in ("console_plate", "console_ring", "console_square"):
        p = os.path.join(OUT, old + ".tga")
        if os.path.exists(p):
            os.remove(p)
    center()
    side()
    slot()
    print("ok")


def welcome_preview():
    """Vorschau fuer den Willkommens-Assistenten (media/welcome/look_konsole.blp)
    aus den eben gerechneten Bildern - dieselbe Anordnung wie im Spiel."""
    import tempfile
    import sys
    from PIL import Image, ImageDraw
    sys.path.insert(0, os.path.dirname(__file__))
    from make_artwork import dxt1_blocks, write_blp

    W, H = 1024, 512
    img = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):   # Spielwelt: dunkler Abendhimmel ueber Gras
        t = y / H
        d.line([(0, y), (W, y)], fill=(int(30 + 20 * t), int(44 + 30 * t), int(58 - 20 * t), 255))
    s = 0.75   # 1 Einheit = 0,75 px (1365 Einheiten auf 1024 px)
    ch = int(208 * s)
    cw = int(416 * s)
    side = Image.open(os.path.join(OUT, "console_side.tga")).convert("RGBA")
    center_img = Image.open(os.path.join(OUT, "console_center.tga")).convert("RGBA")
    sw = W // 2 - cw // 2 + 6
    left = side.resize((sw, ch))
    img.alpha_composite(left, (0, H - ch))
    img.alpha_composite(left.transpose(Image.FLIP_LEFT_RIGHT), (W - sw, H - ch))
    # Karte in der Fassung
    r = int(80 * s)
    cx, cy = W // 2, H - int(86 * s)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(46, 66, 40, 255))
    img.alpha_composite(center_img.resize((cw, ch)), (W // 2 - cw // 2, H - ch))
    d = ImageDraw.Draw(img)
    d.polygon([(cx, cy - 10), (cx - 7, cy + 8), (cx, cy + 3), (cx + 7, cy + 8)], fill=(240, 240, 240, 255))
    slot = Image.open(os.path.join(OUT, "console_slot.tga")).convert("RGBA")
    cols = [(255, 155, 74), (159, 227, 255), (201, 182, 255), (255, 224, 138), (168, 255, 176), (255, 138, 160),
            (208, 208, 208), (127, 208, 255), (255, 207, 127), (176, 255, 239), (90, 90, 90), (90, 90, 90)]

    def bar(cxu, yu, size=34, n=12):
        bw = int((n * (size + 2)) * s)
        bh = int(size * s)
        x0 = W // 2 + int(cxu * s) - bw // 2
        y0 = H - int(yu * s) - bh
        img.alpha_composite(slot.resize((bw + 8, bh + 8)), (x0 - 4, y0 - 4))
        dd = ImageDraw.Draw(img)
        for i in range(n):
            x = x0 + int(i * (size + 2) * s)
            c = cols[i % len(cols)]
            dd.rectangle([x, y0, x + bh - 1, y0 + bh - 1], fill=c, outline=(0, 0, 0, 255))
    bar(-359, 62)
    bar(-359, 20)
    bar(359, 62)
    bar(359, 20)
    d = ImageDraw.Draw(img)

    def unit(x0u, name_col, pct, right=False):
        w, h = int(200 * s), int(31 * s)
        x0 = W // 2 + int(x0u * s) - (0 if right else w)
        y0 = H - int(170 * s) - h
        d.rectangle([x0, y0, x0 + w, y0 + h], fill=(12, 12, 15, 235), outline=(0, 0, 0, 255))
        d.rectangle([x0 + 2, y0 + 2, x0 + 2 + int((w - 4) * pct), y0 + h - 7], fill=name_col)
        d.rectangle([x0 + 2, y0 + h - 5, x0 + w - 2, y0 + h - 2], fill=(63, 111, 224))
    unit(-182, (63, 199, 235), 0.88)
    unit(182, (200, 60, 50), 0.64, right=True)
    # Erfahrung unter Leiste 2
    xw = int(430 * s)
    x0 = W // 2 - int(359 * s) - xw // 2
    d.rectangle([x0, H - int(16 * s), x0 + xw, H - int(8 * s)], fill=(20, 20, 30, 255))
    d.rectangle([x0, H - int(16 * s), x0 + int(xw * 0.6), H - int(8 * s)], fill=(140, 80, 220, 255))
    out = img.convert("RGB").resize((512, 256), Image.LANCZOS)
    with tempfile.TemporaryDirectory() as work:
        dest = os.path.join(os.path.dirname(__file__), "..", "..", "media", "welcome", "look_konsole.blp")
        write_blp(dest, dxt1_blocks(out, work), 512, 256)
    return out


if __name__ == "__main__":
    prev = welcome_preview()
    if len(os.sys.argv) > 1:
        prev.save(os.sys.argv[1])
    print("look_konsole ok")
