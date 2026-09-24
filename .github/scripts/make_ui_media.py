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

**Der 3D-Pfeil (arrow3d.tga).** 64 Ansichten eines facettierten Pfeils,
von hinten oben gesehen, in einem 8x8-Raster (512x512). Gerechnet von
einem kleinen Rasterer mit Tiefenpuffer weiter unten; grau schattiert,
damit das Spiel ihn per SetVertexColor von Rot nach Grün faerben kann.
Eine Megabyte unkomprimiert - der Preis dafuer, dass er ohne Bibliothek
entsteht und wie jede andere Grafik hier aus Zahlen nachvollziehbar ist.

**Warum TGA und nicht BLP.** Die Datei ist 64x64 und braucht einen
weichen Alphakanal. Unkomprimiert sind das 16 KB - weniger als der
Aufwand, einen BLP-Schreiber mit Alpha hierher zu holen.
"""

import math
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


# ------------------------------------------------------------------
# Symbole fuer Kopfzeilen (Schadensanzeige): 32x32, weiss, eingefaerbt
# im Spiel. Jedes ist eine Funktion "liegt (x, y) in der Form?" auf
# einem Feld von -1 bis 1.
# ------------------------------------------------------------------

ICON = 32


def render_shape(size, inside):
    pixels = []
    step = 1.0 / SAMPLES
    for py in range(size):
        for px in range(size):
            covered = 0
            for sy in range(SAMPLES):
                for sx in range(SAMPLES):
                    x = (px + (sx + 0.5) * step) / size * 2 - 1
                    y = (py + (sy + 0.5) * step) / size * 2 - 1
                    if inside(x, y):
                        covered += 1
            pixels.append((255, 255, 255, round(255 * covered / (SAMPLES * SAMPLES))))
    return pixels


def icon_plus(x, y):
    w = 0.13
    return (abs(x) <= w and abs(y) <= 0.62) or (abs(y) <= w and abs(x) <= 0.62)


def icon_close(x, y):
    u, v = (x + y) * 0.7071, (x - y) * 0.7071
    w = 0.12
    return (abs(u) <= w and abs(v) <= 0.66) or (abs(v) <= w and abs(u) <= 0.66)


def icon_reset(x, y):
    # Ein Ring, oben rechts offen, mit Pfeilspitze am oberen Ende.
    r = math.hypot(x, y)
    a = math.degrees(math.atan2(-y, x)) % 360      # 0 = rechts, gegen den Uhrzeigersinn
    if 0.42 <= r <= 0.62 and not (20 <= a <= 80):
        return True
    # Spitze: Dreieck am Ende bei 80 Grad, zeigt im Uhrzeigersinn.
    ax, ay = math.cos(math.radians(80)) * 0.52, -math.sin(math.radians(80)) * 0.52
    tri = [(ax - 0.28, ay - 0.02), (ax + 0.16, ay - 0.30), (ax + 0.16, ay + 0.26)]
    return inside_polygon(x, y, tri)


def icon_gear(x, y):
    r = math.hypot(x, y)
    if r < 0.24:
        return False
    a = math.atan2(y, x)
    teeth = 8
    phase = (a / (2 * math.pi) * teeth) % 1.0
    outer = 0.78 if 0.25 <= phase <= 0.75 else 0.58
    return r <= outer


# ------------------------------------------------------------------
# Der 3D-Pfeil: ein facettierter Pfeil (Grat in der Mitte), von hinten
# oben gesehen, in 64 Drehungen. Ein kleiner Rasterer mit Tiefenpuffer
# - ohne Bibliothek. Weiss/grau schattiert: die Farbe (rot -> gruen nach
# Abweichung) setzt das Spiel per SetVertexColor darueber.
#
# Bild i zeigt den Pfeil um i * 360/64 Grad GEGEN den Uhrzeigersinn
# gedreht (nach links) - dieselbe Zaehlung wie der Winkel, den
# ui/questarrow.lua ausrechnet.
# ------------------------------------------------------------------

CELL = 64
GRID = 8                       # 8 x 8 = 64 Bilder, 512 x 512
SS = 3                         # Unterabtastung je Achse
PITCH = math.radians(38)       # Blick von hinten oben
DIST = 3.2
FOCAL = 3.1

HALF_W, SHAFT_W, WING_Y, TAIL_Y, TIP_Y3 = 0.70, 0.27, 0.02, -0.78, 1.0
EDGE_Z, RIDGE_Z = 0.13, 0.24


def top_z(x):
    return EDGE_Z + RIDGE_Z * (1 - min(abs(x), HALF_W) / HALF_W)


OUTLINE = [(0.0, TIP_Y3), (-HALF_W, WING_Y), (-SHAFT_W, WING_Y), (-SHAFT_W, TAIL_Y),
           (SHAFT_W, TAIL_Y), (SHAFT_W, WING_Y), (HALF_W, WING_Y)]


def arrow_triangles():
    tris = []
    for sgn in (1, -1):
        pts2 = [(0.0, TIP_Y3), (sgn * HALF_W, WING_Y), (sgn * SHAFT_W, WING_Y),
                (0.0, WING_Y), (sgn * SHAFT_W, TAIL_Y), (0.0, TAIL_Y)]
        P = [(x, y, top_z(x)) for (x, y) in pts2]
        tris += [(P[0], P[1], P[2]), (P[0], P[2], P[3]), (P[3], P[2], P[4]), (P[3], P[4], P[5])]
    n = len(OUTLINE)
    for i in range(n):
        (ax, ay), (bx, by) = OUTLINE[i], OUTLINE[(i + 1) % n]
        a0, b0 = (ax, ay, 0.0), (bx, by, 0.0)
        a1, b1 = (ax, ay, top_z(ax)), (bx, by, top_z(bx))
        tris += [(a0, b0, b1), (a0, b1, a1)]
    return tris


def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def norm(a):
    L = math.sqrt(dot(a, a)) or 1.0
    return (a[0] / L, a[1] / L, a[2] / L)


CENTER_Y = (TIP_Y3 + TAIL_Y) / 2
CAM = (0.0, -DIST * math.cos(PITCH), DIST * math.sin(PITCH))
FWD = norm(sub((0.0, 0.0, 0.0), CAM))
RIGHT = (1.0, 0.0, 0.0)
UP = norm(cross(RIGHT, FWD))
LIGHT = norm((-0.75, -0.30, 0.80))


def render_arrow_frame(yaw):
    W = CELL * SS
    depth = [float("inf")] * (W * W)
    shade = [0.0] * (W * W)
    cov = bytearray(W * W)
    cs, sn = math.cos(yaw), math.sin(yaw)
    scale = W * 0.42

    def rot(p):
        x, y, z = p[0], p[1] - CENTER_Y, p[2]
        return (x * cs - y * sn, x * sn + y * cs, z)

    def project(p):
        v = sub(p, CAM)
        xc, yc, zc = dot(v, RIGHT), dot(v, UP), dot(v, FWD)
        return (W / 2 + xc * FOCAL / zc * scale, W / 2 - yc * FOCAL / zc * scale + W * 0.04, zc)

    for tri in arrow_triangles():
        r = [rot(p) for p in tri]
        n = norm(cross(sub(r[1], r[0]), sub(r[2], r[0])))
        # Zur Kamera wenden (die Dreiecke sind nicht einheitlich gewickelt).
        if dot(n, sub(CAM, r[0])) < 0:
            n = (-n[0], -n[1], -n[2])
        light = 0.22 + 0.85 * max(0.0, dot(n, LIGHT))
        light = min(1.0, light)
        (x0, y0, z0), (x1, y1, z1), (x2, y2, z2) = [project(p) for p in r]
        area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
        if abs(area) < 1e-9:
            continue
        minx, maxx = max(0, int(min(x0, x1, x2))), min(W - 1, int(max(x0, x1, x2)) + 1)
        miny, maxy = max(0, int(min(y0, y1, y2))), min(W - 1, int(max(y0, y1, y2)) + 1)
        for py in range(miny, maxy + 1):
            cy = py + 0.5
            for px in range(minx, maxx + 1):
                cx = px + 0.5
                w0 = ((x1 - cx) * (y2 - cy) - (x2 - cx) * (y1 - cy)) / area
                w1 = ((x2 - cx) * (y0 - cy) - (x0 - cx) * (y2 - cy)) / area
                w2 = 1.0 - w0 - w1
                if w0 < 0 or w1 < 0 or w2 < 0:
                    continue
                z = w0 * z0 + w1 * z1 + w2 * z2
                k = py * W + px
                if z < depth[k]:
                    depth[k] = z
                    shade[k] = light
                    cov[k] = 1

    # Dunkle Kontur (ein Bildpunkt breit): der Pfeil muss auf hellem
    # Schnee genauso lesbar sein wie auf dunklem Boden.
    R = SS
    dil = bytearray(W * W)
    tmp = bytearray(W * W)
    for y in range(W):
        row = y * W
        for x in range(W):
            if cov[row + x]:
                for dx in range(max(0, x - R), min(W, x + R + 1)):
                    tmp[row + dx] = 1
    for x in range(W):
        for y in range(W):
            if tmp[y * W + x]:
                for dy in range(max(0, y - R), min(W, y + R + 1)):
                    dil[dy * W + x] = 1

    out = []
    n2 = SS * SS
    for py in range(CELL):
        for px in range(CELL):
            c = d = 0
            s = 0.0
            for sy in range(SS):
                base = (py * SS + sy) * W + px * SS
                for sx in range(SS):
                    k = base + sx
                    if cov[k]:
                        c += 1
                        s += shade[k]
                    if dil[k]:
                        d += 1
            if d == 0:
                out.append((0, 0, 0, 0))
                continue
            a_shape = c / n2
            a_all = max(a_shape, 0.85 * d / n2)
            lum = (s / n2) / a_all if a_all > 0 else 0.0   # Kontur ist schwarz
            v = max(0, min(255, round(255 * lum)))
            out.append((v, v, v, round(255 * a_all)))
    return out


def render_arrow_sheet():
    size = CELL * GRID
    sheet = [(0, 0, 0, 0)] * (size * size)
    for i in range(GRID * GRID):
        yaw = i * 2 * math.pi / (GRID * GRID)
        frame = render_arrow_frame(yaw)
        ox, oy = (i % GRID) * CELL, (i // GRID) * CELL
        for y in range(CELL):
            base = (oy + y) * size + ox
            sheet[base:base + CELL] = frame[y * CELL:(y + 1) * CELL]
    return size, sheet


def main():
    os.makedirs(OUT, exist_ok=True)
    target = os.path.join(OUT, "arrow.tga")
    write_tga(target, SIZE, SIZE, render(ARROW))
    print("geschrieben:", os.path.relpath(target, ROOT))

    for name, fn in (("icon_plus", icon_plus), ("icon_close", icon_close),
                     ("icon_reset", icon_reset), ("icon_gear", icon_gear)):
        target = os.path.join(OUT, name + ".tga")
        write_tga(target, ICON, ICON, render_shape(ICON, fn))
        print("geschrieben:", os.path.relpath(target, ROOT))

    size, sheet = render_arrow_sheet()
    target = os.path.join(OUT, "arrow3d.tga")
    write_tga(target, size, size, sheet)
    print("geschrieben:", os.path.relpath(target, ROOT))


if __name__ == "__main__":
    main()
