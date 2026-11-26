#!/usr/bin/env python3
"""Gelaendekarte fuer den Routenplaner -> data/nav/*.lua (6.32.0.0, neu 1.0.10.1).

Liest die gepackten Gelaendedaten des Addons Shortest Path Forever
(Nav/Nav<Karte>.lua, Nav/Nav<Karte>_<n>.lua) und schreibt NUR DATEN in unser
Format - kein Code. Die Dateien werden nur gelesen und zerlegt, nie
ausgefuehrt.

Seit 1.0.10.1 liest das Skript das NEUE Format (Shortest Path 1.45.x:
"format = 4, graphFormat = 1, floorFormat = 1"), gebacken aus dem
Live-Client (wowf 1.60.1.71037) mit den mmaps von TrinityCore. Es rechnet
es in das alte Format um, das ui/navmesh.lua liest (Format 1 von Shortest
Path) - der Code im Spiel bleibt unveraendert. Art im Codex: beta (gebacken,
nicht von uns gemessen).

Umrechnung je Kartenabschnitt (ADT-Kachel, cells x cells Zellen):
  grid    neu: Palette aus Wert * 256 + Maske der Schritte in 8 Richtungen
          (gerichtet). Alt: Wert * 16 + 4 Schalter (Wand +x, Wand +y,
          Schraege +x+y offen, Schraege +x-y offen). Eine Wand steht, wenn
          NICHT beide Richtungen offen sind (vorsichtig: kein Weg, den man nur
          herunter kann, wird zum Aufstieg).
  height  unveraendert (gleiche Kodierung, gleiche begehbare Zellen).
  floor   neu: Ebenen mit gerichteten Uebergaengen (Masken, Landeschichten,
          Ausnahmen). Alt: Ebenen mit Maske (Uebergang zur Flaeche, die der
          eigenen Hoehe am naechsten liegt) und ausdrueckliche Uebergaenge
          (Knoten, Richtung, Schicht). Nur Uebergaenge, die in BEIDE
          Richtungen gehen - ui/navmesh.lua kennt keine Einbahn. Spruenge ueber
          mehrere Zellen ("drops") und die Freiraum-Angaben entfallen - das
          alte Format kennt nur Nachbarn.
  fcell   zu jeder Ebene die Zelle (wie bisher aus den Ebenen gerechnet).
  graph   neu: binaer (Varints, zwoelf Stroeme). Alt: je Eingang
          Zelle/Knoten(3) Schicht(1) Teil(2) Kanten(1), je Kante
          Richtung(1) Ziel(2) Kosten(2) Laenge(2). Seit 1.0.10.4 alle
          Kanten (auch die Strassen-Kanten); Kosten = Laenge mal Aufschlag
          abseits der Strasse (Data/RoadEdges.lua, OFFROAD), Laenge echt.
  road    1.0.10.4: Strassenanteil je Zelle (Data/RoadCells.lua, aus den
          Bodentexturen des Clients gebacken) und je Knoten
          (RoadNodeCoverage); ui/navmesh.lua schlaegt abseits auf.

Aufruf:
    python3 -I .github/scripts/import_nav.py <Ordner ShortestPathForever>
"""
import base64
import math
import os
import re
import shutil
import sys
import tempfile
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "nav")
B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
VAL = {c: i for i, c in enumerate(B64)}
TILE = 1600 / 3

HEAD = re.compile(r"^\s*(cx0|cy0|nx|ny|cells|swim|zstep|format|graphFormat|floorFormat)\s*=\s*(-?[\d.]+),", re.M)
LINE = re.compile(r'^data\.packed\.(graph|grid|floor|height)\[(\d+)\]\s*=\s*\{(.*)\}\s*$')
STR = re.compile(r'"([A-Za-z0-9+/=]*)"')
MAX_FILE = 900_000

DX = [1, -1, 0, 0, 1, 1, -1, -1]
DY = [0, 0, 1, -1, 1, -1, 1, -1]
OPP = [1, 0, 3, 2, 7, 6, 5, 4]

stats = {}


def count(key, n=1):
    stats[key] = stats.get(key, 0) + n


# --------------------------------------------------------------- Bausteine

def num(s, i, width):
    v = 0
    for k in range(width):
        v = v * 64 + VAL[s[i + k]]
    return v


def enc(v, width):
    if v < 0 or v >= 64 ** width:
        raise ValueError(f"{v} passt nicht in {width} Zeichen")
    out = []
    for _ in range(width):
        out.append(B64[v % 64])
        v //= 64
    return "".join(reversed(out))


def unpack(blocks):
    return b"".join(zlib.decompress(base64.b64decode(b)) for b in blocks)


def lit_raw(raw):
    """Rohe zlib-Bytes -> Lua-Zeichenkette (6.41.3.0, D.bin): Steuerzeichen,
    Anfuehrungszeichen und Rueckstrich als \\ddd, alles andere roh."""
    out = []
    for b in raw:
        if b < 32 or b == 127 or b == 34 or b == 92:
            out.append("\\%03d" % b)
        else:
            out.append(chr(b))
    return '"' + "".join(out) + '"'


def pack(text):
    return lit_raw(zlib.compress(text.encode("ascii"), 9))


def pack_blocks(text, size=60000):
    return [pack(text[i:i + size]) for i in range(0, max(len(text), 1), size)]


# --------------------------------------------------------------- Gitter

def decode_grid(s):
    """Neues Gitter -> (Werte, Masken) je Zelle."""
    cnt = VAL[s[0]]
    pal = [num(s, 1 + e * 2, 2) for e in range(cnt)]
    i, val, mask, vc, mc = 1 + cnt * 2, [], [], 0, 0
    while i < len(s):
        sym = VAL[s[i]]
        i += 1
        if sym >= 48:
            val += [vc] * (sym - 47)
            mask += [mc] * (sym - 47)
        else:
            if sym == 47:
                code, i = num(s, i, 2), i + 2
            else:
                code = pal[sym]
            vc, mc = code // 256, code % 256
            val.append(vc)
            mask.append(mc)
    return val, mask


def encode_grid(val, mask, C):
    """Altes Gitter: Wert * 16 + Schalter, ab 48 Wiederholung."""
    def opened(a, d):
        x, y = a // C + DX[d], a % C + DY[d]
        if x < 0 or y < 0 or x >= C or y >= C:
            return True  # Rand: das Gitter des Nachbarn entscheidet nicht hier
        b = x * C + y
        return (mask[a] >> d) & 1 == 1 and (mask[b] >> OPP[d]) & 1 == 1
    syms = []
    for a in range(C * C):
        v = val[a]
        flag = 0
        if v:
            x, y = a // C, a % C
            if x + 1 < C and val[a + C] and not opened(a, 0):
                flag |= 1
            if y + 1 < C and val[a + 1] and not opened(a, 2):
                flag |= 2
            if x + 1 < C and y + 1 < C and val[a + C + 1] and opened(a, 4):
                flag |= 4
            if x + 1 < C and y > 0 and val[a + C - 1] and opened(a, 5):
                flag |= 8
        code = v * 16 + flag
        if code >= 48:
            raise ValueError(f"Gitterwert {v} zu gross")
        syms.append(code)
    out, i = [], 0
    while i < len(syms):
        c = syms[i]
        out.append(B64[c])
        j = i + 1
        while j < len(syms) and syms[j] == c and j - i <= 16:
            j += 1
        rep = j - i - 1
        if rep:
            out.append(B64[47 + rep])
        i = j
    return "".join(out)


# --------------------------------------------------------------- Ebenen

def decode_floors(s, val, C, floor_format):
    """Neues Ebenen-Feld -> Ebenen [(Zelle, Wert, Hoehe)] und gerichtete
    Uebergaenge [(Knoten, Richtung 0-7, Schicht)]."""
    N = C * C
    floors, at, first = [], {}, {}
    pos, lc = 3, 0
    for _ in range(num(s, 0, 3)):
        sym = VAL[s[pos]]
        pos += 1
        if sym < 63:
            lc += sym
        else:
            lc += 63 + num(s, pos, 3)
            pos += 3
        node = N + len(floors)
        floors.append((lc, VAL[s[pos]], num(s, pos + 1, 2) - 2048, num(s, pos + 3, 2)))
        at[node] = lc
        first.setdefault(lc, node)
        pos += 5
    last = N + len(floors)
    masks = {N + i: f[3] for i, f in enumerate(floors)}
    links = []
    # Grund -> Ebene: Knoten mit Maske.
    nbase = num(s, pos, 3)
    pos += 3
    base, node = [], 0
    for _ in range(nbase):
        d = VAL[s[pos]]
        pos += 1
        if d == 63:
            d = 63 + num(s, pos, 3)
            pos += 3
        node += d
        base.append(node)
        masks[node] = num(s, pos, 2)
        pos += 2
    implicit = floor_format == 1
    ov = {"p": pos + 3, "end": pos, "next": 0, "ord": 0}

    def advance():
        if ov["p"] >= ov["end"]:
            ov["next"] = math.inf
            return
        d = VAL[s[ov["p"]]]
        ov["p"] += 1
        if d == 63:
            d = 63 + num(s, ov["p"], 3)
            ov["p"] += 3
        ov["next"] += d

    if implicit:
        ov["end"] = ov["p"] + num(s, pos, 3)
        pos = ov["end"]
        advance()

    def landing(frm, d, p):
        layers = VAL[s[p]]
        p += 1
        if layers == 0:
            n = num(s, p, 2)
            p += 2
            for _ in range(n):
                links.append((frm, d, VAL[s[p]]))
                p += 1
        else:
            layer = 0
            while layers:
                if layers & 1:
                    links.append((frm, d, layer))
                layer, layers = layer + 1, layers >> 1
        return p

    def directed(frm):
        nonlocal pos
        bits = masks.get(frm, 0)
        if not bits:
            return
        cell = frm if frm < N else at[frm]
        x, y = cell // C, cell % C
        for d in range(8):
            if (bits >> d) & 1:
                layer = None
                if implicit:
                    tx, ty = x + DX[d], y + DY[d]
                    if 0 <= tx < C and 0 <= ty < C:
                        t = tx * C + ty
                        f0 = first.get(t)
                        if frm < N:
                            if f0 is not None and at.get(f0 + 1) != t:
                                layer = 1
                        elif f0 is None:
                            layer = 0
                if layer is None:
                    pos = landing(frm, d, pos)
                else:
                    ov["ord"] += 1
                    if ov["ord"] == ov["next"]:
                        ov["p"] = landing(frm, d, ov["p"])
                        advance()
                    else:
                        links.append((frm, d, layer))

    for frm in range(N, last):
        directed(frm)
    for b in base:
        directed(b)
    drops = num(s, pos, 3)
    count("drops", drops)
    return floors, links


def decode_heights(s, val, C, step):
    """Hoehen der Grundflaeche (wie Heights in ui/navmesh.lua)."""
    z, pos, rep, delta, last = {}, 0, 0, 0, 0
    for i in range(C * C):
        if val[i]:
            if i % C > 0 and (i - 1) in z:
                pred = z[i - 1]
            elif i >= C and (i - C) in z:
                pred = z[i - C]
            else:
                pred = last
            if rep > 0:
                rep -= 1
                v = pred + delta
            else:
                sym = VAL[s[pos]]
                if sym == 47:
                    v, pos = num(s, pos + 1, 2) - 2048, pos + 3
                else:
                    delta, pos = sym - 23, pos + 1
                    while pos < len(s) and VAL[s[pos]] >= 48:
                        rep, pos = rep + VAL[s[pos]] - 47, pos + 1
                    v = pred + delta
            last, z[i] = v, v
    return {i: v * step for i, v in z.items()}


def encode_floors(floors, links, val, zb, C):
    """Altes Ebenen-Feld (Format 1). Nur Uebergaenge, deren Gegenrichtung es
    auch gibt. Einer von einer Ebene, der auf der Flaeche landet, die ihrer
    Hoehe am naechsten liegt, wird ein Bit ihrer Maske (so liest
    ui/navmesh.lua die Maske); einer vom Grund zu einer Ebene, deren eigener
    Uebergang zurueckfuehrt, entfaellt (ui/navmesh.lua ergaenzt ihn). Alle
    anderen: ausdruecklich, Knoten(3) Richtung(1) Schicht(1)."""
    N = C * C
    nfirst, ncount = {}, {}
    for i, (cell, *_rest) in enumerate(floors):
        nfirst.setdefault(cell, N + i)
        ncount[cell] = ncount.get(cell, 0) + 1

    def fz(node):
        return floors[node - N][2]

    def cell_of(node):
        return node if node < N else floors[node - N][0]

    def nearest(t, h):
        best, gap = None, None
        if val[t]:
            best, gap = t, abs(zb[t] - h) if t in zb else 1e9
        f = nfirst.get(t)
        while f is not None and f - N < len(floors) and floors[f - N][0] == t:
            d = abs(fz(f) - h)
            if gap is None or d < gap:
                best, gap = f, d
            f += 1
        return best

    masks = [0] * len(floors)
    seen = set()
    resolved = []
    for frm, d, layer in links:
        cell = cell_of(frm)
        tx, ty = cell // C + DX[d], cell % C + DY[d]
        if not (0 <= tx < C and 0 <= ty < C):
            count("links_outside")
            continue
        t = tx * C + ty
        if layer == 0:
            if not val[t]:
                count("links_no_ground")
                continue
            land = t
        else:
            if layer > ncount.get(t, 0):
                count("links_no_floor")
                continue
            land = nfirst[t] + layer - 1
        if land == frm or (frm, d, land) in seen:
            continue
        seen.add((frm, d, land))
        resolved.append((frm, d, layer, land))
    # Nur Uebergaenge, die in beide Richtungen gehen (vorsichtig, wie das
    # Gitter): ui/navmesh.lua sucht auch vom Ziel aus und kennt keine
    # Einbahn - ein Sprung herunter waere dort ein Aufstieg.
    pairs = {(frm, land) for frm, d, layer, land in resolved}
    both = [r for r in resolved if (r[3], r[0]) in pairs]
    count("links_oneway", len(resolved) - len(both))
    recs, implied = [], set()
    for frm, d, layer, land in both:
        if frm >= N and land == nearest(cell_of(land), fz(frm)):
            masks[frm - N] |= 1 << d
            count("links_mask")
            if land < N:
                implied.add((land, frm))
        elif frm >= N:
            recs.append(enc(frm, 3) + B64[d] + B64[layer])
            count("x_floor_to_" + ("base" if land < N else "floor"))
            if land < N:
                implied.add((land, frm))
    for frm, d, layer, land in both:
        if frm < N:
            if (frm, land) in implied:
                count("links_implied")
            else:
                count("x_base_to_" + ("base" if land < N else "floor"))
                recs.append(enc(frm, 3) + B64[d] + B64[layer])
    count("links_explicit", len(recs))
    groups = []
    for i, (cell, v, h, _) in enumerate(floors):
        if groups and groups[-1][0] == cell:
            groups[-1][1].append((v, h, masks[i]))
        else:
            groups.append((cell, [(v, h, masks[i])]))
    out = [enc(len(groups), 3)]
    for cell, items in groups:
        if len(items) > 63:
            raise ValueError("zu viele Ebenen in einer Zelle")
        out.append(enc(cell, 3) + B64[len(items)])
        for v, h, mk in items:
            out.append(B64[v] + enc(h + 2048, 2) + enc(mk, 2))
    out.append(enc(len(recs), 3))
    out.extend(recs)
    fcell = "".join(enc(cell, 3) for cell, *_r in floors)
    return "".join(out), fcell, nfirst


# --------------------------------------------------------------- Wegenetz

def varint(s, p):
    v = s[p]
    if v < 128:
        return v, p + 1
    total, scale = v - 128, 128
    while True:
        p += 1
        v = s[p]
        total += (v % 128) * scale
        scale *= 128
        if v < 128:
            break
    return total, p + 1


def signed(v):
    half = v // 2
    return half if v % 2 == 0 else -half - 1


def perimeter_cell(place, C):
    if place < C:
        return place
    if place < 2 * C:
        return (C - 1) * C + place - C
    if place < 3 * C - 2:
        return (place - 2 * C + 1) * C
    if place < 4 * C - 4:
        return (place - 3 * C + 3) * C + C - 1
    return place - (4 * C - 4)


def decode_graph(s, C, ny, k, prefs=None):
    """Neues Wegenetz -> Knoten [(Zelle, Schicht, Teil, [(Richtung, Ziel, Kosten, Laenge)])].
    1.0.10.4: alle Kanten (Grund- und Strassenkanten); Kosten = Laenge mal
    Strassenaufschlag der Kante (prefs, in Kantenreihenfolge), Laenge echt."""
    cs = TILE / C
    n, pos = varint(s, 0)
    p, size = [0] * 13, 0
    for i in range(1, 13):
        p[i] = size
        length, pos = varint(s, pos)
        size += length
    for i in range(1, 13):
        p[i] += pos
    end = pos + size
    mode, p[3] = varint(s, p[3])
    rows = []
    for _ in range(n):
        place, p[1] = varint(s, p[1])
        layer, p[2] = varint(s, p[2])
        comp, p[3] = varint(s, p[3])
        degree, p[4] = varint(s, p[4])
        suffix, p[5] = varint(s, p[5])
        row = {"cell": perimeter_cell(place, C), "layer": layer,
               "comp": mode if comp == 0 else comp - 1, "deg": degree, "base": degree - suffix,
               "off": p[6]}
        p[6] += degree
        for j in (7, 8, 9):
            row[j] = p[j]
            extra, p[j + 3] = varint(s, p[j + 3])
            p[j] += degree + extra
        rows.append(row)
    nodes = []
    edge_index = [0]
    for ordinal, r in enumerate(rows):
        x, y = r["cell"] // C, r["cell"] % C
        local, prev = ordinal, {}
        tp, wp, sp = r[7], r[8], r[9]
        edges = []
        for e in range(r["deg"]):
            gi = edge_index[0]
            edge_index[0] += 1
            if e == r["base"]:
                local, prev = ordinal, {}
            off = s[r["off"] + e]
            t, tp = varint(s, tp)
            w, wp = varint(s, wp)
            sw, sp = varint(s, sp)
            t, w, sw = signed(t), signed(w), signed(sw)
            if off == 4:
                t += local
                local = t
                dest = rows[t]["cell"]
                ax, ay = abs(dest // C - x), abs(dest % C - y)
                dist = max(ax, ay) + (math.sqrt(2) - 1) * min(ax, ay)
            else:
                t += prev.get(off, 0)
                prev[off] = t
                dx, dy = off // 3 - 1, off % 3 - 1
                dist = math.sqrt(2) if dx and dy else 1
            walk = math.floor(dist * cs + 0.5) + w
            real = walk + sw
            pref = prefs[gi] if prefs is not None and gi < len(prefs) else OFFROAD
            edges.append((off, t, int(math.floor(real * pref + 0.5)), real, e >= r["base"]))
            if e >= r["base"]:
                count("road_edges")
        nodes.append((r["cell"], r["layer"], r["comp"], edges))
    if prefs is not None and len(prefs) not in (0, edge_index[0]):
        count("road_ratio_mismatch")
    return nodes, end


def encode_graph(nodes, nfirst_of, C, k):
    """Altes Wegenetz. nfirst_of(k) -> {Zelle: erster Ebenenknoten} fuer
    den Abschnitt k (Schicht > 0 eines Eingangs ist eine Ebene)."""
    N = C * C
    nf = nfirst_of(k)
    head, body = [enc(len(nodes), 2)], []
    for cell, layer, comp, edges in nodes:
        if layer == 0:
            local = cell
        else:
            f0 = nf.get(cell)
            if f0 is None:
                count("entrance_no_floor")
                local = cell
            else:
                local = f0 + layer - 1
        if len(edges) > 63:
            # Grundkanten immer (sie tragen den Zusammenhang), Strassenkanten
            # nach Kosten in die freien Plaetze.
            base = sorted((e for e in edges if not e[4]), key=lambda e: e[2])
            road = sorted((e for e in edges if e[4]), key=lambda e: e[2])
            keep = (base + road)[:63]
            count("edges_cut", len(edges) - len(keep))
            count("edges_cut_base", max(0, len(base) - 63))
            edges = keep
        head.append(enc(local, 3) + B64[min(layer, 63)] + enc(min(comp, 4095), 2) + B64[len(edges)])
        for off, t, cost, walk, _road in edges:
            if cost >= 4096 or walk >= 4096 or cost < 0:
                count("cost_clamped")
            body.append(B64[off] + enc(t, 2) + enc(max(0, min(cost, 4095)), 2) + enc(max(0, min(walk, 4095)), 2))
        count("edges", len(edges))
    return "".join(head) + "".join(body)


# --------------------------------------------------------------- Strassen

OFFROAD = 1.5   # ein Meter abseits der Strasse zaehlt so viel (Shortest Path: Voreinstellung)


def read_road_tables(path):
    """Data/RoadCells.lua bzw. RoadEdges.lua -> {Tabelle: {Karte: {k: Text}}} (nur gelesen)."""
    out, table, m = {}, None, None
    if not os.path.exists(path):
        return out
    with open(path, encoding="utf-8") as f:
        for line in f:
            t = re.match(r"^ns\.(\w+) = \{", line)
            if t:
                table = out.setdefault(t.group(1), {})
                continue
            mm = re.match(r"^\t\[(\d+)\] = \{", line)
            if mm and table is not None:
                m = table.setdefault(int(mm.group(1)), {})
                continue
            e = re.match(r'^\t\t\[(\d+)\] = "([^"]*)",', line)
            if e and m is not None:
                m[int(e.group(1))] = e.group(2)
    return out


def road_prefs(s):
    """Kantenfaktoren eines Abschnitts (Gehen): "=" + Anzahl(2) Standardkanten
    (abseits), sonst vier Zeichen, das erste ist die Wahl."""
    out, pos = [], 0
    while pos < len(s):
        if s[pos] == "=":
            out += [OFFROAD] * num(s, pos + 1, 2)
            pos += 3
        else:
            out.append(1 + VAL[s[pos]] / 63 * (OFFROAD - 1))
            pos += 4
    return out


def road_field(cells, nodes, C):
    """Strassenanteil je Zelle (0-63, ein Zeichen je Zelle, C*C) und dahinter
    nach "|" die Ausnahmen je Knoten (Knoten(3) Anteil(1)); oder None."""
    cov = [0] * (C * C)
    lc, pos = 0, 0
    s = cells or ""
    while pos + 2 < len(s):
        run, c = num(s, pos, 2), VAL[s[pos + 2]]
        pos += 3
        if c:
            for i in range(lc, min(lc + run, C * C)):
                cov[i] = c
        lc += run
    if not any(cov) and not nodes:
        return None
    text = "".join(B64[c] for c in cov).rstrip("A")
    return text + ("|" + nodes if nodes else "")


# --------------------------------------------------------------- Lauf

def read_map(nav, m):
    with open(os.path.join(nav, f"Nav{m}.lua"), encoding="utf-8") as f:
        head = dict(HEAD.findall(f.read()))
    if head.get("format") != "4" or head.get("graphFormat") != "1":
        raise SystemExit(f"Karte {m}: Format {head.get('format')}/{head.get('graphFormat')} - "
                         "dieses Skript liest nur format 4 / graphFormat 1.")
    fields = {"graph": {}, "grid": {}, "floor": {}, "height": {}}
    parts = sorted((f for f in os.listdir(nav) if re.match(rf"Nav{m}_\d+\.lua$", f)),
                   key=lambda f: int(re.search(r"_(\d+)\.", f).group(1)))
    for part in parts:
        with open(os.path.join(nav, part), encoding="utf-8") as f:
            for line in f:
                mm = LINE.match(line.strip())
                if mm:
                    fields[mm.group(1)][int(mm.group(2))] = STR.findall(mm.group(3))
    return head, fields


def convert_map(head, fields, roads=None, m=None):
    C = int(head["cells"])
    ny = int(head["ny"])
    ff = int(head.get("floorFormat", 0))
    out = {"graph": {}, "grid": {}, "fcell": {}, "floor": {}, "height": {}, "road": {}}
    roads = roads or {}
    rc = roads.get("RoadCells", {}).get(m, {})
    re_ = roads.get("RoadEdges", {}).get(m, {})
    rn = roads.get("RoadNodeCoverage", {}).get(m, {})
    for key in set(rc) | set(rn):
        rf = road_field(rc.get(key), rn.get(key), C)
        if rf:
            out["road"][key] = pack(rf)
            count("road_clusters")
    nfirst = {}
    vals = {}
    for key, blocks in fields["grid"].items():
        g = unpack(blocks).decode("ascii")
        val, mask = decode_grid(g)
        if len(val) != C * C:
            raise ValueError(f"Gitter {key}: {len(val)} Zellen")
        vals[key] = val
        out["grid"][key] = pack_blocks(encode_grid(val, mask, C))
    step = float(head.get("zstep", 2))
    for key, blocks in fields["floor"].items():
        if key not in vals:
            continue
        fl, links = decode_floors(unpack(blocks).decode("latin-1"), vals[key], C, ff)
        hb = fields["height"].get(key)
        zb = decode_heights(unpack(hb).decode("ascii"), vals[key], C, step) if hb else {}
        fs, fcell, nf = encode_floors(fl, links, vals[key], zb, C)
        nfirst[key - 1] = nf
        out["floor"][key] = pack_blocks(fs)
        if fcell:
            out["fcell"][key] = pack(fcell)
    for key, blocks in fields["height"].items():
        out["height"][key] = [lit_raw(base64.b64decode(b)) for b in blocks]
    for key, blocks in fields["graph"].items():
        raw = unpack(blocks)
        prefs = road_prefs(re_[key]) if key in re_ else None
        nodes, end = decode_graph(raw, C, ny, key - 1, prefs)
        if end != len(raw):
            count("graph_tail_mismatch")
        if len(nodes) >= 4096:
            raise ValueError(f"Abschnitt {key}: {len(nodes)} Eingaenge")
        out["graph"][key] = pack_blocks(encode_graph(nodes, lambda k: nfirst.get(k, {}), C, key - 1))
    return out


def write_map(m, head, out, files, outdir):
    header = (f"WeintCodex.NavData[{m}] = WeintCodex.NavData[{m}] or {{ cx0 = {head['cx0']}, cy0 = {head['cy0']}, "
              f"nx = {head['nx']}, ny = {head['ny']}, cells = {head['cells']}, swim = {head['swim']}, "
              f"zstep = {head.get('zstep', 2)}, bin = true, offroad = {OFFROAD}, graph = {{}}, grid = {{}}, fcell = {{}}, floor = {{}}, height = {{}}, road = {{}} }}")
    rows = []
    for kind in ("graph", "grid", "fcell", "floor", "height", "road"):
        for k, v in sorted(out[kind].items()):
            body = v if isinstance(v, str) else "{ " + ", ".join(v) + " }"
            rows.append((kind, f"    [{k}] = {body},"))
    chunks, cur, size = [], [], 0
    for kind, row in rows:
        if size + len(row) > MAX_FILE and cur:
            chunks.append(cur)
            cur, size = [], 0
        cur.append((kind, row))
        size += len(row) + 1
    if cur:
        chunks.append(cur)
    total = 0
    for i, chunk in enumerate(chunks, 1):
        name = f"nav{m}_{i}.lua"
        text = ["-- ERZEUGT von .github/scripts/import_nav.py - nicht von Hand aendern.",
                f"-- Gelaendekarte, Kontinent {m}, Teil {i}/{len(chunks)}. Herkunft: Backen des Live-Clients",
                "-- (wowf 1.60.1, mmaps von TrinityCore) durch Shortest Path Forever, umgerechnet. Art: beta.",
                "-- Gelesen von ui/navmesh.lua.",
                "WeintCodex = WeintCodex or {}",
                "WeintCodex.NavData = WeintCodex.NavData or {}",
                header,
                f"local D = WeintCodex.NavData[{m}]"]
        now = None
        for kind, row in chunk:
            if kind != now:
                if now:
                    text.append("}) do D." + now + "[k] = v end")
                text.append("for k, v in pairs({")
                now = kind
            text.append(row)
        text.append("}) do D." + now + "[k] = v end")
        text.append("")
        body = "\n".join(text)
        with open(os.path.join(outdir, name), "w", encoding="latin-1", newline="\n") as f:
            f.write(body)
        files.append(f"data/nav/{name}")
        total += len(body)
    return total


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    nav = os.path.join(sys.argv[1], "Nav")
    maps = sorted({int(m.group(1)) for f in os.listdir(nav) for m in [re.match(r"Nav(\d+)\.lua$", f)] if m})
    # Erst alles umrechnen, dann ersetzen - ein Fehler laesst data/nav stehen.
    roads = read_road_tables(os.path.join(sys.argv[1], "Data", "RoadCells.lua"))
    roads.update(read_road_tables(os.path.join(sys.argv[1], "Data", "RoadEdges.lua")))
    tmp = tempfile.mkdtemp(prefix="nav_")
    files, total = [], 0
    try:
        for m in maps:
            head, fields = read_map(nav, m)
            total += write_map(m, head, convert_map(head, fields, roads, m), files, tmp)
        os.makedirs(OUT, exist_ok=True)
        for old in os.listdir(OUT):
            if old.endswith(".lua"):
                os.remove(os.path.join(OUT, old))
        for f in os.listdir(tmp):
            shutil.move(os.path.join(tmp, f), os.path.join(OUT, f))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    print("geschrieben:", len(files), "Dateien,", round(total / 1e6, 1), "MB")
    for k in sorted(stats):
        print(" ", k, stats[k])
    for f in files:
        print(f)


if __name__ == "__main__":
    main()
