#!/usr/bin/env python3
"""Gelaendekarte fuer den Routenplaner -> data/nav/*.lua (6.32.0.0).

Liest die gepackten Gelaendedaten des Addons Shortest Path Forever
(Nav/Nav<Karte>.lua, Nav/Nav<Karte>_<n>.lua) und schreibt NUR DATEN in unser
Format - kein Code. Die Dateien werden nur gelesen und zerlegt, nie
ausgefuehrt. Herkunft laut Kopf jener Dateien: eigenes Backen des Clients
(wow_classic_beta) mit Mappster/DotRecast durch den Autor von Shortest Path
Forever. Art im Codex: beta.

Uebernommen werden je Kartenabschnitt (ADT-Kachel):
  graph  Wegenetz zwischen den Eingaengen des Abschnitts (zlib + Base64,
         unveraendert; entpackt im Spiel mit C_EncodingUtil)
  grid   begehbare Zellen der Grundflaeche (ebenso unveraendert)
  fcell  NEU: zu jeder Ebene (Hoehle, Stadt unter dem Berg) die Zelle, in der
         sie liegt - je 3 Zeichen Base64, zlib + Base64. Aus "floor" gerechnet;
         Hoehen und Uebergaenge der Ebenen bleiben weg (6 MB, die der Planer
         nicht braucht).
Die Hoehen der Grundflaeche (height) bleiben ebenfalls weg.

Aufruf:
    python3 -I .github/scripts/import_nav.py <Ordner ShortestPathForever>
"""
import base64
import os
import re
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "nav")
B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
VAL = {c: i for i, c in enumerate(B64)}

HEAD = re.compile(r"^\s*(cx0|cy0|nx|ny|cells|swim)\s*=\s*(-?[\d.]+),", re.M)
LINE = re.compile(r'^data\.packed\.(graph|grid|floor)\[(\d+)\]\s*=\s*\{(.*)\}\s*$')
STR = re.compile(r'"([A-Za-z0-9+/=]*)"')
MAX_FILE = 900_000


def num(s, i, width):
    v = 0
    for k in range(width):
        v = v * 64 + VAL[s[i + k]]
    return v


def unpack(blocks):
    return b"".join(zlib.decompress(base64.b64decode(b)) for b in blocks).decode("ascii")


def pack(text):
    raw = zlib.compress(text.encode("ascii"), 9)
    return base64.b64encode(raw).decode("ascii")


def enc(v, width):
    out = []
    for _ in range(width):
        out.append(B64[v % 64])
        v //= 64
    return "".join(reversed(out))


def floor_cells(raw):
    # n(3) | n x [cell(3) count(1) count x [value(1) height(2) steps(2)]] | ...
    n, pos, cells = num(raw, 0, 3), 3, []
    for _ in range(n):
        cell, count = num(raw, pos, 3), VAL[raw[pos + 3]]
        pos += 4 + count * 5
        cells.extend([cell] * count)
    return "".join(enc(c, 3) for c in cells)


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    nav = os.path.join(sys.argv[1], "Nav")
    maps = sorted({int(m.group(1)) for f in os.listdir(nav) for m in [re.match(r"Nav(\d+)\.lua$", f)] if m})
    os.makedirs(OUT, exist_ok=True)
    for old in os.listdir(OUT):
        if old.endswith(".lua"):
            os.remove(os.path.join(OUT, old))
    files = []
    total = 0
    for m in maps:
        with open(os.path.join(nav, f"Nav{m}.lua"), encoding="utf-8") as f:
            head = dict(HEAD.findall(f.read()))
        fields = {"graph": {}, "grid": {}, "floor": {}}
        parts = sorted((f for f in os.listdir(nav) if re.match(rf"Nav{m}_\d+\.lua$", f)),
                       key=lambda f: int(re.search(r"_(\d+)\.", f).group(1)))
        for part in parts:
            with open(os.path.join(nav, part), encoding="utf-8") as f:
                for line in f:
                    mm = LINE.match(line.strip())
                    if mm:
                        fields[mm.group(1)][int(mm.group(2))] = STR.findall(mm.group(3))
        lines = [f"    [{k}] = {{ {', '.join(chr(34) + b + chr(34) for b in blocks)} }},"
                 for k, blocks in sorted(fields["graph"].items())]
        grid = [f"    [{k}] = {{ {', '.join(chr(34) + b + chr(34) for b in blocks)} }},"
                for k, blocks in sorted(fields["grid"].items())]
        fcell = [f'    [{k}] = "{pack(floor_cells(unpack(blocks)))}",'
                 for k, blocks in sorted(fields["floor"].items())]
        header = (f"WeintCodex.NavData[{m}] = WeintCodex.NavData[{m}] or {{ cx0 = {head['cx0']}, cy0 = {head['cy0']}, "
                  f"nx = {head['nx']}, ny = {head['ny']}, cells = {head['cells']}, swim = {head['swim']}, "
                  f"graph = {{}}, grid = {{}}, fcell = {{}} }}")
        # In Dateien unter MAX_FILE aufteilen.
        chunks, cur, size = [], [], 0
        for kind, rows in (("graph", lines), ("grid", grid), ("fcell", fcell)):
            for row in rows:
                if size + len(row) > MAX_FILE and cur:
                    chunks.append(cur)
                    cur, size = [], 0
                cur.append((kind, row))
                size += len(row) + 1
        if cur:
            chunks.append(cur)
        for i, chunk in enumerate(chunks, 1):
            name = f"nav{m}_{i}.lua"
            out = ["-- ERZEUGT von .github/scripts/import_nav.py - nicht von Hand aendern.",
                   f"-- Gelaendekarte, Kontinent {m}, Teil {i}/{len(chunks)}. Herkunft: eigenes Backen des",
                   "-- Clients (wow_classic_beta, Mappster/DotRecast) durch Shortest Path Forever. Art: beta.",
                   "-- Gelesen von ui/navmesh.lua.",
                   "WeintCodex = WeintCodex or {}",
                   "WeintCodex.NavData = WeintCodex.NavData or {}",
                   header,
                   f"local D = WeintCodex.NavData[{m}]"]
            kind_now = None
            for kind, row in chunk:
                if kind != kind_now:
                    if kind_now:
                        out.append("}) do D." + kind_now + "[k] = v end")
                    out.append("for k, v in pairs({")
                    kind_now = kind
                out.append(row)
            out.append("}) do D." + kind_now + "[k] = v end")
            out.append("")
            text = "\n".join(out)
            with open(os.path.join(OUT, name), "w", encoding="ascii") as f:
                f.write(text)
            files.append(f"data/nav/{name}")
            total += len(text)
    print("geschrieben:", len(files), "Dateien,", round(total / 1e6, 1), "MB")
    for f in files:
        print(f)


if __name__ == "__main__":
    main()
