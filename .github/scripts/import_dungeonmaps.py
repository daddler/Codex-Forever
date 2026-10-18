#!/usr/bin/env python3
"""Dungeonkarten -> data/dungeonmaps.lua (6.72.0.0).

Liest die Tabelle ns.MapDungeonMaps aus dem Addon OpenMap
(Data/DungeonMaps.lua, MIT-Lizenz) und schreibt NUR DIE DATEN in unser
Format: je Instanz (achte Rueckgabe von GetInstanceInfo) ihre Ebenen, je
Ebene die zwoelf Bildnummern (4 x 3 Kacheln zu 256 px) der Karte, die im
Forever-Client liegt, und der englische Name der Ebene. Kein Code, kein
Bild: die Kacheln liefert der Client selbst.

Nicht uebernommen: OpenMaps gezeichnete Karten der neuen Forever-Dungeons
(Data/DungeonDrawn.lua) - eigene Bilder eines Zeichners, nur fuer OpenMap
freigegeben, nicht unter MIT.

Aufruf:
    python3 -I .github/scripts/import_dungeonmaps.py <Pfad zu OpenMap/Data/DungeonMaps.lua> [Version]

Die Datei wird nur gelesen, nie ausgefuehrt.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "dungeonmaps.lua")

INST = re.compile(r"^\s*\[(\d+)\]\s*=\s*\{\s*--\s*(.+?)\s*$")
FLOOR = re.compile(r"^\s*\{\s*tiles\s*=\s*\{([\d,\s]+)\}(.*)\},?\s*$")
NAME = re.compile(r'name\s*=\s*"((?:[^"\\]|\\.)*)"')
WING = re.compile(r'wing\s*=\s*"((?:[^"\\]|\\.)*)"')

MIT = """-- Die Tabelle stammt aus OpenMap (Data/DungeonMaps.lua) und steht unter
-- dieser Lizenz:
--
--   MIT License
--   Copyright (c) 2026 OpenMap contributors
--
--   Permission is hereby granted, free of charge, to any person obtaining a copy
--   of this software and associated documentation files (the "Software"), to deal
--   in the Software without restriction, including without limitation the rights
--   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--   copies of the Software, and to permit persons to whom the Software is
--   furnished to do so, subject to the following conditions:
--
--   The above copyright notice and this permission notice shall be included in all
--   copies or substantial portions of the Software.
--
--   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--   SOFTWARE.
"""


def parse(text):
    out, cur = [], None
    for line in text.splitlines():
        m = INST.match(line)
        if m:
            cur = {"id": int(m.group(1)), "name": m.group(2), "floors": []}
            out.append(cur)
            continue
        m = FLOOR.match(line)
        if m and cur is not None:
            tiles = [int(x) for x in re.findall(r"\d+", m.group(1))]
            if len(tiles) != 12:
                raise SystemExit("Ebene ohne 12 Kacheln: %r" % line)
            rest = m.group(2)
            n, w = NAME.search(rest), WING.search(rest)
            cur["floors"].append({"tiles": tiles, "name": n and n.group(1), "wing": w and w.group(1)})
    return [i for i in out if i["floors"]]


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    src = sys.argv[1]
    ver = sys.argv[2] if len(sys.argv) > 2 else "?"
    with open(src, encoding="utf-8") as f:
        insts = parse(f.read())
    lines = [
        "--------------------------------------------------",
        "-- WeintCodex :: Dungeonkarten (Bildnummern des Clients)",
        "--------------------------------------------------",
        "-- ERZEUGT von .github/scripts/import_dungeonmaps.py - nicht von Hand",
        "-- aendern; neu erzeugen.",
        "--",
        "-- HERKUNFT `community`: OpenMap %s hat die Bildnummern aus den UiMap-" % ver,
        "-- Tabellen und den Dateien einer Forever-Installation gelesen. Die",
        "-- Bilder selbst liegen im Client (Blizzards Karten der klassischen",
        "-- Instanzen) - WeintCodex liefert keines davon aus. Ungemessen: ob jede",
        "-- Nummer im Client wirklich ein Bild ist (ui/dungeonmap.lua prueft",
        "-- SetTexture und zeigt sonst nichts).",
        "--",
        "-- [Instanz-ID aus GetInstanceInfo] = { name = englisch, floors = {",
        "--     { tiles = { 12 Bildnummern, zeilenweise }, name = Ebene (englisch) }, ... } }",
        "--",
    ]
    lines += MIT.rstrip("\n").split("\n")
    lines += [
        "--------------------------------------------------",
        "",
        "WeintCodex = WeintCodex or {}",
        "WeintCodex.DungeonMapData = {",
        '    SOURCE = { kind = "community", label = "Karten aus dem Client, Zuordnung unbestätigt" },',
        "    MAPS = {",
    ]
    for i in insts:
        lines.append("        [%d] = { name = %s, floors = {" % (i["id"], lua_str(i["name"])))
        for fl in i["floors"]:
            extra = ""
            if fl["name"]:
                extra += ", name = " + lua_str(fl["name"])
            if fl["wing"]:
                extra += ", wing = " + lua_str(fl["wing"])
            lines.append("            { tiles = { %s }%s }," % (", ".join(str(t) for t in fl["tiles"]), extra))
        lines.append("        } },")
    lines += ["    },", "}", ""]
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print("%d Instanzen, %d Ebenen -> %s" % (len(insts), sum(len(i["floors"]) for i in insts), OUT))


if __name__ == "__main__":
    main()
