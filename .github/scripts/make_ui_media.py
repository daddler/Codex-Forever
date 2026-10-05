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


def _sword(u, v):
    # Ein Schwert entlang u (Spitze bei +u): Klinge, Parierstange, Griff.
    blade = -0.42 <= u <= 0.72 and abs(v) <= 0.085 - max(0.0, u - 0.56) * 0.5
    guard = -0.50 <= u <= -0.40 and abs(v) <= 0.26
    grip = -0.78 <= u <= -0.50 and abs(v) <= 0.06
    return blade or guard or grip


def icon_combat(x, y):
    # Zwei gekreuzte Schwerter (Spitzen oben): "im Kampf".
    a = 0.7071
    u1, v1 = (x - y) * a, (x + y) * a       # Spitze oben rechts
    u2, v2 = (-x - y) * a, (-x + y) * a     # Spitze oben links
    return _sword(u1, v1) or _sword(u2, v2)


def icon_tank(x, y):
    # Ein Schild: oben gerade, unten spitz.
    if y < -0.62 or y > 0.78 or abs(x) > 0.62:
        return False
    if y <= 0.1:
        return True
    # Untere Haelfte laeuft zur Spitze bei y = 0.78 zu.
    half = 0.62 * (0.78 - y) / 0.68
    return abs(x) <= half


def icon_dps(x, y):
    # Ein Schwert, Spitze oben rechts - kraeftiger als die gekreuzten
    # (klein auf dem Gruppenrahmen war die schmale Klinge kaum zu sehen).
    a = 0.7071
    u, v = (x - y) * a, (x + y) * a
    blade = -0.40 <= u <= 0.74 and abs(v) <= 0.15 - max(0.0, u - 0.50) * 0.6
    guard = -0.52 <= u <= -0.36 and abs(v) <= 0.40
    grip = -0.84 <= u <= -0.52 and abs(v) <= 0.11
    return blade or guard or grip


def icon_leader(x, y):
    # Eine Krone: Band unten, drei Zacken oben.
    if 0.25 <= y <= 0.55 and abs(x) <= 0.72:
        return True
    if -0.55 <= y < 0.25 and abs(x) <= 0.72:
        for cx in (-0.62, 0.0, 0.62):
            # Zacke: Dreieck mit Spitze bei y = -0.55
            half = 0.26 * (y + 0.55) / 0.80
            if abs(x - cx) <= half:
                return True
    return False


def icon_check(x, y):
    # Ein Haken.
    def seg(px_, py_, ax, ay, bx, by, r):
        vx, vy = bx - ax, by - ay
        t = max(0.0, min(1.0, ((px_ - ax) * vx + (py_ - ay) * vy) / (vx * vx + vy * vy)))
        return math.hypot(px_ - (ax + t * vx), py_ - (ay + t * vy)) <= r
    return seg(x, y, -0.62, 0.02, -0.18, 0.46, 0.14) or seg(x, y, -0.18, 0.46, 0.66, -0.50, 0.14)


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


# --------------------------------------------------------------------
# Stil der Oberflaeche 2.0 (docs/design/ui-2.0.md): Balkenglanz, weicher
# Schein und Zielmarke. Alle drei weiss bzw. grau - gefaerbt wird im
# Spiel per SetVertexColor, damit jede Farbe in core/ui.lua bleibt.
# --------------------------------------------------------------------

# Balken: senkrechter Verlauf, oben hell, unten dunkler. Ein Statusbalken
# MULTIPLIZIERT seine Farbe mit der Textur - heller als die Farbe geht
# also nicht; der Glanz entsteht aus dem Abstand zwischen oben und unten.
BAR_W, BAR_H = 128, 32
BAR_TOP, BAR_KNEE, BAR_BOTTOM = 1.00, 0.88, 0.70
BAR_KNEE_AT = 0.45


def render_bar():
    pixels = []
    for y in range(BAR_H):
        t = (y + 0.5) / BAR_H
        if t <= BAR_KNEE_AT:
            v = BAR_TOP + (BAR_KNEE - BAR_TOP) * (t / BAR_KNEE_AT)
        else:
            v = BAR_KNEE + (BAR_BOTTOM - BAR_KNEE) * ((t - BAR_KNEE_AT) / (1 - BAR_KNEE_AT))
        c = round(255 * v)
        pixels.extend([(c, c, c, 255)] * BAR_W)
    return pixels


# Schein: ein weich auslaufendes Rechteck. Im Spiel als Neunteiler
# (SetTextureSliceMargins mit FEATHER) um einen Rahmen gelegt - schwarz
# ist es ein Schatten, im Akzent das Leuchten des Ziels, weiss der
# Schein unter der Maus.
def render_glow(size, feather):
    pixels = []
    for y in range(size):
        for x in range(size):
            dx = max(0.0, feather - (x + 0.5), (x + 0.5) - (size - feather))
            dy = max(0.0, feather - (y + 0.5), (y + 0.5) - (size - feather))
            d = math.hypot(dx, dy) / feather          # 0 innen, 1 am Rand
            a = max(0.0, 1.0 - d)
            a = a * a * (3 - 2 * a)                   # weiches Auslaufen
            pixels.append((255, 255, 255, round(255 * a)))
    return pixels


# Weiche Maske ums Charaktermodell (6.6.2.5): innen voll, zu allen vier
# Raendern hin weich auf null. Das Spiel legt sie per AddMaskTexture auf
# die Hintergrundbilder des Modells - die Bilder laufen dann in den
# Grund des Fensters aus, statt mit harter Kante zu enden. Grau in allen
# Kanaelen UND im Alpha, damit es egal ist, welchen Kanal der Client
# als Maske liest. Gestreckt auf das ganze Modellfeld (~400 x 460):
# 22 von 128 Pixeln sind dort rund 70 px Auslauf.
def render_softmask(size, feather):
    def ramp(i):
        d = min(i + 0.5, size - (i + 0.5)) / feather   # 0 am Rand, 1 innen
        a = max(0.0, min(1.0, d))
        return a * a * (3 - 2 * a)
    pixels = []
    for y in range(size):
        for x in range(size):
            c = round(255 * ramp(x) * ramp(y))
            pixels.append((c, c, c, c))
    return pixels


# Zielmarke: zwei gestaffelte Winkel, die auf den Balken zeigen (Spitze
# rechts; die rechte Marke ist dieselbe Datei, gespiegelt). Aussen
# halbdurchsichtig, innen voll, mit schwarzer Kontur - die Kontur bleibt
# beim Faerben schwarz.
MARK = 32
MARK_OUTER = [(2, 5), (10, 5), (19, 16), (10, 27), (2, 27), (11, 16)]
MARK_INNER = [(12, 5), (20, 5), (29, 16), (20, 27), (12, 27), (21, 16)]
MARK_OUTLINE = 1.4


def seg_dist(px_, py_, ax, ay, bx, by):
    vx, vy = bx - ax, by - ay
    t = ((px_ - ax) * vx + (py_ - ay) * vy) / (vx * vx + vy * vy)
    t = max(0.0, min(1.0, t))
    return math.hypot(px_ - (ax + t * vx), py_ - (ay + t * vy))


def near_polygon(x, y, poly, r):
    n = len(poly)
    return any(seg_dist(x, y, *poly[i], *poly[(i + 1) % n]) <= r for i in range(n))


def render_mark():
    pixels = []
    step = 1.0 / SAMPLES
    for py in range(MARK):
        for px in range(MARK):
            fill_a, line = 0.0, 0
            for sy in range(SAMPLES):
                for sx in range(SAMPLES):
                    x = px + (sx + 0.5) * step
                    y = py + (sy + 0.5) * step
                    if inside_polygon(x, y, MARK_INNER):
                        fill_a += 1.0
                    elif inside_polygon(x, y, MARK_OUTER):
                        fill_a += 0.55
                    elif near_polygon(x, y, MARK_INNER, MARK_OUTLINE) or near_polygon(x, y, MARK_OUTER, MARK_OUTLINE):
                        line += 1
            n = SAMPLES * SAMPLES
            fa, la = fill_a / n, line / n
            a = min(1.0, fa + la)
            c = round(255 * (fa / a)) if a > 0 else 0
            pixels.append((c, c, c, round(255 * a)))
    return pixels


# Codex-Zeichen (6.7.0.2): ein Astrolab aus feinen Linien - Ringe,
# Teilstriche, ein Kompassstern. Weiss mit weichem Alpha; im Spiel mit
# ~4 % Deckkraft hinter dem Ruf ("Welt-Codex"), erst beim Hinsehen zu
# sehen. Eigene Form, kein Spielmaterial.
SIGIL = 256


def render_sigil(size):
    c = size / 2.0
    rings = ((0.95, 1.1), (0.88, 0.8), (0.60, 0.8), (0.34, 0.8), (0.10, 0.9))
    stroke = 0.9          # halbe Linienstaerke in Pixeln (weich auslaufend)

    def line_alpha(d, w):
        return max(0.0, min(1.0, (w + stroke - d) / stroke)) if d < w + stroke else 0.0

    # Kompassstern: vier lange Spitzen, vier kurze (Umriss).
    star = []
    for k in range(8):
        ang = math.pi / 2 - k * math.pi / 4
        rr = 0.80 if k % 2 == 0 else 0.42
        star.append((math.cos(ang) * rr, math.sin(ang) * rr))
    inner = 0.12
    outline = []
    for k in range(8):
        a0 = math.pi / 2 - k * math.pi / 4
        tip = star[k]
        side = (math.cos(a0 - math.pi / 8) * inner, math.sin(a0 - math.pi / 8) * inner)
        outline.append((tip, side))
    pixels = []
    for y in range(size):
        for x in range(size):
            u, v = (x + 0.5 - c) / c, (c - (y + 0.5)) / c
            r = math.hypot(u, v)
            a = 0.0
            for rad, w in rings:
                a = max(a, 0.9 * line_alpha(abs(r - rad) * c, w * 0.5))
            # Teilstriche zwischen den aeusseren Ringen: 32, jeder vierte lang.
            if 0.84 <= r <= 0.97:
                ang = math.atan2(v, u)
                step = 2 * math.pi / 32
                k = round(ang / step)
                d = abs(ang - k * step) * r * c
                if k % 4 == 0 or r >= 0.88:
                    a = max(a, 0.8 * line_alpha(d, 0.4))
            # Sternumriss: Spitze -> Seite -> naechste Spitze.
            for k in range(8):
                tip, side = outline[k]
                nxt = outline[(k + 1) % 8][0]
                prev_side = (math.cos(math.pi / 2 - k * math.pi / 4 + math.pi / 8) * inner,
                             math.sin(math.pi / 2 - k * math.pi / 4 + math.pi / 8) * inner)
                for (ax, ay), (bx, by) in ((prev_side, tip), (tip, side)):
                    d = seg_dist(u * c, v * c, ax * c, ay * c, bx * c, by * c)
                    a = max(a, line_alpha(d, 0.5))
            pixels.append((255, 255, 255, round(255 * a)))
    return pixels


def icon_report(x, y):
    # Eine Sprechblase mit zwei Zeilen: "in den Chat melden" (6.9.0.8).
    def in_round_rect(px_, py_, x0, y0, x1, y1, r):
        cx = min(max(px_, x0 + r), x1 - r)
        cy = min(max(py_, y0 + r), y1 - r)
        return math.hypot(px_ - cx, py_ - cy) <= r
    bubble = in_round_rect(x, y, -0.76, -0.66, 0.76, 0.34, 0.22)
    tail = inside_polygon(x, y, [(-0.44, 0.30), (-0.08, 0.30), (-0.54, 0.76)])
    if not (bubble or tail):
        return False
    lines = abs(x) <= 0.46 and (-0.36 <= y <= -0.22 or -0.06 <= y <= 0.08)
    return not lines


# ------------------------------------------------------------------
# Startseite (6.11.0.3): Ecken mit Rahmen, Formen der Wegmarken,
# Schraffur der Erfahrung und vier Linien-Symbole. Alles weiss; die
# Farbe setzt das Spiel per SetVertexColor.
# ------------------------------------------------------------------

def _coverage(size, inside):
    """Anteil je Pixel (0..1) aus 4x4 Unterabtastung; inside(px, py) in Pixeln."""
    out = []
    step = 1.0 / SAMPLES
    for py in range(size):
        for px in range(size):
            hit = 0
            for sy in range(SAMPLES):
                for sx in range(SAMPLES):
                    if inside(px + (sx + 0.5) * step, py + (sy + 0.5) * step):
                        hit += 1
            out.append(hit / (SAMPLES * SAMPLES))
    return out


def _white(cov):
    return [(255, 255, 255, round(255 * c)) for c in cov]


def render_round(radius, ring):
    """16x16, Ecke oben links, Kreis um (radius, radius).

    ring=False: die Flaeche AUSSERHALB des Bogens (wird in der Farbe des
    Untergrunds gefaerbt und stanzt die Ecke aus).
    ring=True: der Bogen selbst, 1 Bildpunkt breit, innen an der Kante -
    er schliesst an die geraden Rahmenlinien an, die bei `radius` beginnen.
    """
    def inside(x, y):
        if x > radius or y > radius:
            return False
        d = math.hypot(x - radius, y - radius)
        if ring:
            return radius - 1.0 <= d <= radius
        return d > radius
    return _white(_coverage(16, inside))


def render_disc(size):
    c = size / 2.0
    return _white(_coverage(size, lambda x, y: math.hypot(x - c, y - c) <= c - 0.5))


def render_diamond(size):
    c = size / 2.0
    return _white(_coverage(size, lambda x, y: abs(x - c) + abs(y - c) <= c - 0.5))


def render_stripes(size, period, on):
    """Schraeg (wie "/"), kachelbar: Periode teilt die Groesse."""
    return _white(_coverage(size, lambda x, y: ((x + y) % period) < on))


def _seg(px_, py_, ax, ay, bx, by, r):
    vx, vy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px_ - ax) * vx + (py_ - ay) * vy) / (vx * vx + vy * vy)))
    return math.hypot(px_ - (ax + t * vx), py_ - (ay + t * vy)) <= r


LW = 0.075   # Strichstaerke der Linien-Symbole (Feld -1..1)


def icon_book(x, y):
    # Ein aufgeschlagenes Buch: zwei Seiten, Ruecken in der Mitte.
    pts = [(-0.78, -0.50), (-0.06, -0.38), (0.06, -0.38), (0.78, -0.50)]
    lines = [((-0.78, -0.50), (-0.78, 0.50)), ((-0.78, 0.50), (0.0, 0.62)),
             ((0.0, 0.62), (0.78, 0.50)), ((0.78, 0.50), (0.78, -0.50)),
             ((-0.78, -0.50), (0.0, -0.38)), ((0.0, -0.38), (0.78, -0.50)),
             ((0.0, -0.38), (0.0, 0.62))]
    return any(_seg(x, y, a[0], a[1], b[0], b[1], LW) for a, b in lines)


def icon_quest(x, y):
    # Das Ausrufezeichen ueber dem Questgeber.
    bar = inside_polygon(x, y, [(-0.16, -0.78), (0.16, -0.78), (0.09, 0.30), (-0.09, 0.30)])
    return bar or math.hypot(x, y - 0.62) <= 0.15


def icon_gate(x, y):
    # Ein Tor mit Rundbogen: Eingang zum Dungeon.
    if _seg(x, y, -0.66, 0.78, 0.66, 0.78, LW):
        return True
    outer = _seg(x, y, -0.66, 0.78, -0.66, -0.06, LW) or _seg(x, y, 0.66, 0.78, 0.66, -0.06, LW)
    r = math.hypot(x, y + 0.06)
    arch = y <= -0.06 and abs(r - 0.66) <= LW
    inner = _seg(x, y, -0.30, 0.78, -0.30, 0.10, LW) or _seg(x, y, 0.30, 0.78, 0.30, 0.10, LW)
    r2 = math.hypot(x, y - 0.10)
    arch2 = y <= 0.10 and abs(r2 - 0.30) <= LW
    return outer or arch or inner or arch2


def icon_hammer(x, y):
    # Ein Hammer, Stiel schraeg: reparieren.
    # Feld: y waechst nach UNTEN - oben rechts heisst x > 0, y < 0.
    a = 0.7071
    u, v = (x - y) * a, (x + y) * a          # u entlang des Stiels, Kopf oben rechts
    handle = -0.84 <= u <= 0.36 and abs(v) <= 0.08
    head = 0.30 <= u <= 0.66 and abs(v) <= 0.44
    return handle or head


def make_home_media():
    os.makedirs(OUT, exist_ok=True)
    files = []
    for r in (8, 12, 14):
        files.append(("round%d_mask" % r, 16, render_round(r, False)))
        files.append(("round%d_ring" % r, 16, render_round(r, True)))
    files.append(("disc", 32, render_disc(32)))
    files.append(("diamond", 32, render_diamond(32)))
    files.append(("stripes", 32, render_stripes(32, 16, 8)))
    for name, fn in (("icon_book", icon_book), ("icon_quest", icon_quest),
                     ("icon_gate", icon_gate), ("icon_hammer", icon_hammer)):
        files.append((name, ICON, render_shape(ICON, fn)))
    for name, size, pixels in files:
        target = os.path.join(OUT, name + ".tga")
        write_tga(target, size, size, pixels)
        print("geschrieben:", os.path.relpath(target, ROOT))


def main():
    os.makedirs(OUT, exist_ok=True)
    make_home_media()
    target = os.path.join(OUT, "arrow.tga")
    write_tga(target, SIZE, SIZE, render(ARROW))
    print("geschrieben:", os.path.relpath(target, ROOT))

    for name, fn in (("icon_plus", icon_plus), ("icon_close", icon_close),
                     ("icon_reset", icon_reset), ("icon_gear", icon_gear),
                     ("icon_combat", icon_combat), ("icon_tank", icon_tank),
                     ("icon_dps", icon_dps), ("icon_leader", icon_leader),
                     ("icon_check", icon_check), ("icon_report", icon_report)):
        target = os.path.join(OUT, name + ".tga")
        write_tga(target, ICON, ICON, render_shape(ICON, fn))
        print("geschrieben:", os.path.relpath(target, ROOT))

    for name, w, h, pixels in (("bar", BAR_W, BAR_H, render_bar()),
                               ("glow", 32, 32, render_glow(32, 8)),
                               ("glow_wide", 64, 64, render_glow(64, 24)),
                               ("targetmark", MARK, MARK, render_mark()),
                               ("softmask", 128, 128, render_softmask(128, 22)),
                               ("sigil", SIGIL, SIGIL, render_sigil(SIGIL))):
        target = os.path.join(OUT, name + ".tga")
        write_tga(target, w, h, pixels)
        print("geschrieben:", os.path.relpath(target, ROOT))

    size, sheet = render_arrow_sheet()
    target = os.path.join(OUT, "arrow3d.tga")
    write_tga(target, size, size, sheet)
    print("geschrieben:", os.path.relpath(target, ROOT))


if __name__ == "__main__":
    main()
