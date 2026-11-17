#!/usr/bin/env python3
"""Eigene, farbige Kartensymbole fuer Weltkarte und Minikarte (1.0.7.27).

Wunsch des Spielers: "Mach die Symbole professionell" - gemalte Symbole
statt Spielsymbolen in Kreisen. Alles hier ist aus Formen gerechnet, kein
Material aus dem Spiel oder aus anderen Addons.

Jedes Symbol: Form -> Verlauf -> Glanz -> dunkler Umriss -> weicher
Schatten. Gezeichnet in 256 px, verkleinert auf 64 px (TGA, RGBA).

    python3 .github/scripts/make_map_icons.py
"""
import math
import os
import struct

from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "mapicons")
BIG, SIZE = 256, 64
INK = (28, 20, 12)


def write_tga(name, img):
    img = img.convert("RGBA")
    w, h = img.size
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
    body = bytearray()
    for r, g, b, a in img.getdata():
        body += bytes((b, g, r, a))
    with open(os.path.join(OUT, name + ".tga"), "wb") as f:
        f.write(header)
        f.write(bytes(body))


def mask():
    return Image.new("L", (BIG, BIG), 0)


def grad(top, bottom):
    g = Image.new("RGB", (BIG, BIG))
    d = ImageDraw.Draw(g)
    for y in range(BIG):
        t = y / (BIG - 1)
        d.line([(0, y), (BIG, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return g


class Icon:
    def __init__(self):
        self.parts = []          # (mask, top, bottom)
        self.details = []        # (mask, colour) gezeichnet ueber den Teilen

    def part(self, m, top, bottom):
        self.parts.append((m, top, bottom))

    def detail(self, m, colour):
        self.details.append((m, colour))

    def render(self):
        img = Image.new("RGBA", (BIG, BIG), (0, 0, 0, 0))
        union = mask()
        for m, _, _ in self.parts:
            union = ImageChops.lighter(union, m)
        # Schatten und Umriss.
        outline = union.filter(ImageFilter.MaxFilter(17))
        shadow = outline.filter(ImageFilter.GaussianBlur(10))
        sh = Image.new("RGBA", (BIG, BIG), (0, 0, 0, 0))
        sh.paste((0, 0, 0, 170), (8, 12), shadow)
        img = Image.alpha_composite(img, sh)
        ol = Image.new("RGBA", (BIG, BIG), INK + (255,))
        ol.putalpha(outline)
        img = Image.alpha_composite(img, ol)
        for m, top, bottom in self.parts:
            layer = grad(top, bottom).convert("RGBA")
            layer.putalpha(m)
            img = Image.alpha_composite(img, layer)
            # Innenkante dunkel, damit Teile sich trennen.
            edge = ImageChops.subtract(m, m.filter(ImageFilter.MinFilter(7)))
            e = Image.new("RGBA", (BIG, BIG), INK + (0,))
            e.putalpha(edge.point(lambda v: int(v * 0.8)))
            img = Image.alpha_composite(img, e)
        # Glanz oben links.
        gl = union.filter(ImageFilter.MinFilter(21))
        shine = mask()
        ImageDraw.Draw(shine).ellipse([20, 10, 170, 120], fill=90)
        shine = ImageChops.multiply(shine.filter(ImageFilter.GaussianBlur(20)), gl)
        s = Image.new("RGBA", (BIG, BIG), (255, 255, 240, 0))
        s.putalpha(shine)
        img = Image.alpha_composite(img, s)
        for m, colour in self.details:
            d = Image.new("RGBA", (BIG, BIG), colour + (0,))
            d.putalpha(m)
            img = Image.alpha_composite(img, d)
        return img.resize((SIZE, SIZE), Image.LANCZOS)


def poly(points):
    m = mask()
    ImageDraw.Draw(m).polygon(points, fill=255)
    return m


def ell(box):
    m = mask()
    ImageDraw.Draw(m).ellipse(box, fill=255)
    return m


def rrect(box, r):
    m = mask()
    ImageDraw.Draw(m).rounded_rectangle(box, r, fill=255)
    return m


def lines(pts, w):
    m = mask()
    ImageDraw.Draw(m).line(pts, fill=255, width=w, joint="curve")
    return m


def arc(box, a0, a1, w):
    m = mask()
    ImageDraw.Draw(m).arc(box, a0, a1, fill=255, width=w)
    return m


GOLD = ((255, 222, 120), (196, 128, 32))
BROWN = ((196, 140, 84), (112, 66, 30))
STEEL = ((222, 228, 236), (120, 130, 146))
RED = ((236, 92, 72), (140, 32, 24))
BLUE = ((120, 200, 255), (24, 92, 190))
GREEN = ((150, 226, 110), (48, 128, 40))
CLOTH = ((246, 236, 210), (178, 158, 120))
PURPLE = ((206, 150, 255), (110, 52, 180))


def bag():
    i = Icon()
    i.part(poly([(70, 110), (186, 110), (214, 210), (196, 236), (60, 236), (42, 210)]), *BROWN)
    i.part(poly([(92, 70), (164, 70), (150, 112), (106, 112)]), *BROWN)
    i.part(rrect([84, 100, 172, 122], 10), *RED)
    return i


def anvil():
    i = Icon()
    i.part(poly([(30, 70), (226, 70), (226, 96), (176, 120), (80, 120), (30, 96), (12, 80)]), *STEEL)
    i.part(poly([(100, 118), (156, 118), (166, 180), (90, 180)]), *STEEL)
    i.part(rrect([60, 176, 196, 214], 10), *STEEL)
    return i


def coins():
    i = Icon()
    for k, y in enumerate((170, 140, 110)):
        i.part(ell([56 + k * 4, y, 200 + k * 4, y + 56]), *GOLD)
    i.detail(ell([110, 120, 150, 146]), (150, 96, 20))
    return i


def gavel():
    i = Icon()
    head = poly([(96, 40), (186, 130), (154, 162), (64, 72)])
    i.part(lines([(150, 104), (60, 214)], 28), *BROWN)
    i.part(head, *GOLD)
    i.part(rrect([120, 206, 236, 232], 8), *BROWN)
    return i


def mug():
    i = Icon()
    i.part(arc([150, 96, 222, 186], -90, 90, 22), *BROWN)
    i.part(rrect([50, 70, 172, 226], 16), *BROWN)
    i.part(ell([42, 44, 182, 104]), (255, 255, 248), (226, 220, 200))
    i.detail(lines([(80, 110), (80, 200)], 8), (90, 52, 22))
    i.detail(lines([(142, 110), (142, 200)], 8), (90, 52, 22))
    return i


def letter():
    i = Icon()
    i.part(rrect([28, 64, 228, 196], 12), *CLOTH)
    i.detail(lines([(36, 72), (128, 140), (220, 72)], 10), (120, 96, 60))
    i.part(ell([108, 116, 148, 156]), *RED)
    return i


def book(cover):
    i = Icon()
    i.part(poly([(52, 44), (196, 36), (212, 196), (68, 212)]), *cover)
    i.part(poly([(68, 212), (212, 196), (214, 222), (66, 232)]), *CLOTH)
    i.detail(lines([(120, 76), (164, 74)], 10), (255, 230, 150))
    i.detail(lines([(118, 100), (166, 98)], 10), (255, 230, 150))
    return i


def scroll():
    i = Icon()
    i.part(rrect([56, 56, 200, 200], 18), *CLOTH)
    i.part(rrect([40, 40, 216, 72], 16), *BROWN)
    i.part(rrect([40, 186, 216, 218], 16), *BROWN)
    for y in (100, 126, 152):
        i.detail(lines([(84, y), (172, y)], 8), (120, 96, 60))
    return i


def paw():
    i = Icon()
    i.part(ell([70, 120, 186, 222]), *BROWN)
    for x, y in ((48, 84), (92, 46), (146, 46), (190, 84)):
        i.part(ell([x - 26, y, x + 26, y + 56]), *BROWN)
    return i


def drumstick():
    i = Icon()
    i.part(lines([(160, 160), (214, 214)], 24), (250, 244, 228), (200, 190, 170))
    i.part(ell([196, 192, 230, 226]), (250, 244, 228), (200, 190, 170))
    i.part(ell([214, 178, 244, 208]), (250, 244, 228), (200, 190, 170))
    i.part(poly([(40, 70), (90, 30), (160, 50), (190, 120), (170, 176), (110, 186), (54, 150)]), (236, 150, 70), (150, 70, 24))
    return i


def pouch():
    i = Icon()
    i.part(ell([52, 92, 204, 230]), *PURPLE)
    i.part(poly([(96, 60), (160, 60), (148, 104), (108, 104)]), *PURPLE)
    i.detail(poly([(128, 130), (138, 156), (164, 160), (138, 168), (128, 196), (118, 168), (92, 160), (118, 156)]),
             (255, 246, 200))
    return i


def arrows():
    i = Icon()
    for dx in (-34, 0, 34):
        i.part(lines([(128 + dx, 222), (128 + dx, 70)], 14), *BROWN)
        i.part(poly([(128 + dx, 26), (150 + dx, 78), (106 + dx, 78)]), *STEEL)
        i.part(poly([(116 + dx, 196), (140 + dx, 196), (148 + dx, 232), (108 + dx, 232)]), *RED)
    return i


def cloth():
    i = Icon()
    i.part(rrect([60, 40, 196, 76], 12), *BROWN)
    i.part(rrect([60, 180, 196, 216], 12), *BROWN)
    i.part(rrect([82, 70, 174, 186], 10), (140, 200, 255), (40, 90, 180))
    for y in (96, 122, 148):
        i.detail(lines([(86, y), (170, y + 10)], 6), (200, 236, 255))
    return i


def portal():
    i = Icon()
    i.part(ell([24, 24, 232, 232]), (90, 170, 230), (20, 60, 140))
    i.detail(ell([60, 60, 196, 196]), (12, 30, 70))
    for k in range(3):
        a0 = k * 120
        i.detail(arc([70, 70, 186, 186], a0, a0 + 80, 16), (150, 230, 255))
    i.detail(ell([108, 108, 148, 148]), (220, 250, 255))
    return i


def wings():
    i = Icon()
    i.part(ell([82, 26, 174, 118]), (210, 246, 255), (90, 170, 230))
    i.detail(ell([108, 50, 148, 94]), (20, 50, 100))
    i.part(rrect([110, 106, 146, 232], 10), (210, 246, 255), (90, 170, 230))
    i.part(rrect([56, 122, 200, 156], 10), (210, 246, 255), (90, 170, 230))
    return i


def gryphon_wing():
    i = Icon()
    pts = [(40, 210), (52, 120), (96, 56), (170, 28), (232, 34)]
    for k in range(5):
        y = 70 + k * 30
        i.part(poly([(60 + k * 6, y + 40), (226 - k * 26, y - 30 + k * 6), (230 - k * 26, y - 6 + k * 6), (70 + k * 6, y + 72)]),
               (255, 238, 190), (200, 140, 64))
    i.part(lines(pts[:3], 26), (140, 96, 50), (100, 60, 30))
    return i


def ship():
    i = Icon()
    i.part(poly([(20, 160), (236, 160), (200, 224), (56, 224)]), *BROWN)
    i.part(lines([(128, 30), (128, 164)], 12), *BROWN)
    i.part(poly([(138, 40), (214, 140), (138, 140)]), *CLOTH)
    i.part(poly([(118, 56), (54, 140), (118, 140)]), *CLOTH)
    return i


def signpost():
    i = Icon()
    i.part(rrect([116, 60, 140, 236], 6), *BROWN)
    i.part(poly([(40, 60), (190, 60), (226, 88), (190, 116), (40, 116)]), *GOLD)
    i.part(poly([(216, 132), (66, 132), (30, 160), (66, 188), (216, 188)]), *GOLD)
    return i


ICONS = {
    "vendor": bag, "repair": anvil, "bank": coins, "auction": gavel, "inn": mug,
    "mail": letter, "class": lambda: book(RED), "profession": lambda: book(BLUE),
    "stable": paw, "food": drumstick, "reagents": pouch, "ammo": arrows,
    "trade": cloth, "portal": portal, "spirit": wings, "flight": gryphon_wing,
    "travel": ship, "crossing": signpost,
}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, fn in ICONS.items():
        write_tga(name, fn().render())
    print("ok", len(ICONS))
