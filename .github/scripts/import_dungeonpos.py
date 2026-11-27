#!/usr/bin/env python3
"""Messpunkte und Kartengrenzen fuer die eigene Lage im Dungeon -> data/dungeonpos.lua (1.0.10.6).

Liest NUR DATEN aus dem Addon MapUtils (GPL-3.0), nie Code:
  shared/InstanceMap/instance_pos_data.lua  Flugmeister mit Weltlage (x, y, z,
                                            Fraktion), die Auswahl je Instanz,
                                            Grenzen je Karte des Spiels (UiMap)
  data/classic/instances.lua                Kartennummer -> Name der Ebene
und ordnet die Grenzen den Ebenen in data/dungeonmaps.lua zu (ueber den
Namen der Ebene; eine Ebene ohne Namen nur, wenn die Instanz genau eine hat).
Die Dateien werden mit regulaeren Ausdruecken gelesen, nie ausgefuehrt.

Wie ui/dungeonpos.lua damit rechnet, steht dort; die Idee (Entfernungen zu
bekannten Flugmeistern ueber die Zielverfolgung des Spiels, daraus die Lage)
stammt aus MapUtils, der Code ist eigener.

Aufruf:
    python3 -I .github/scripts/import_dungeonpos.py <MapUtils-Ordner>
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "dungeonpos.lua")
NUM = r"-?\d+(?:\.\d+)?"


def block(text, name):
    m = re.search(r"IP\." + name + r" = \{(.*?)\n\}", text, re.S)
    if not m:
        raise SystemExit("IP." + name + " nicht gefunden")
    return m.group(1)


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    src = sys.argv[1]
    pos = open(os.path.join(src, "shared", "InstanceMap", "instance_pos_data.lua"), encoding="utf-8").read()
    nodes = {int(k): tuple(float(v) for v in (x, y, z)) + (int(f),)
             for k, x, y, z, f in re.findall(r"\[(\d+)\] = \{(" + NUM + r"), (" + NUM + r"), (" + NUM + r"), (\d+)\}",
                                             block(pos, "nodes"))}
    fallback = [int(v) for v in re.findall(r"\d+", re.search(r"IP\.fallback = \{([^}]*)\}", pos).group(1))]
    anchors = {int(k): [int(v) for v in re.findall(r"\d+", body)]
               for k, body in re.findall(r"\[(\d+)\] = \{([^}]*)\}", block(pos, "anchors"))}
    art = {k: (int(inst),) + tuple(float(v) for v in rest)
           for k, inst, *rest in re.findall(r'\["(\w+)"\] = \{(\d+), (' + NUM + r"), (" + NUM + r"), (" + NUM
                                            + r"), (" + NUM + r")\}", block(pos, "art"))}
    inst = open(os.path.join(src, "data", "classic", "instances.lua"), encoding="utf-8").read()
    names = {}   # [Instanz] = [(Kartennummer, Name oder None)]
    for i, body in re.findall(r"^data\.art\[(\d+)\] = \{\"[^\"]*\", \{(.*)\}\}$", inst, re.M):
        lv = []
        for key, nm in re.findall(r'\{"?(\w+)"?(?:, "([^"]*)")?', body):
            lv.append((key, nm or None))
        names[int(i)] = lv
    # Ebenen unserer Karten (Reihenfolge wie in data/dungeonmaps.lua).
    dm = open(os.path.join(ROOT, "data", "dungeonmaps.lua"), encoding="utf-8").read()
    ours = {}
    for i, body in re.findall(r"^        \[(\d+)\] = \{ name = \"[^\"]*\", floors = \{\n(.*?)\n        \} \},", dm, re.M | re.S):
        fl = []
        for line in body.split("\n"):
            if "tiles =" in line or "files =" in line:
                m = re.search(r'name = "([^"]*)"', line)
                fl.append(m.group(1) if m else None)
        ours[int(i)] = fl
    floors, unmatched = {}, []
    for i, fl in sorted(ours.items()):
        lv = names.get(i, [])
        for idx, nm in enumerate(fl, 1):
            key = None
            if nm:
                key = next((k for k, n in lv if n == nm), None)
            elif len(fl) == 1 and len(lv) == 1:
                key = lv[0][0]
            # Ersatz nach Lage in der Liste: nur, wenn auf einer Seite der Name
            # fehlt (Todesminen: unsere Ebene heisst, die Karte nicht).
            if not key and idx <= len(lv) and (nm is None or lv[idx - 1][1] is None):
                key = lv[idx - 1][0]
            if key and key in art and art[key][0] == i:
                floors.setdefault(i, {})[idx] = art[key][1:]
            elif i in anchors:
                unmatched.append(f"{i}/{idx} {nm}")
    used = sorted({n for i in floors for n in anchors.get(i, [])} | set(fallback))
    out = [
        "--------------------------------------------------",
        "-- WeintCodex :: Eigene Lage im Dungeon - Messpunkte und Kartengrenzen",
        "--------------------------------------------------",
        "-- ERZEUGT von .github/scripts/import_dungeonpos.py - nicht von Hand aendern.",
        "-- HERKUNFT (nur fuer Betreuer): Daten aus MapUtils 1.8.2 (GPL-3.0), nur",
        "-- Zahlen: Weltlage der Flugmeister (Spielfakten), die Auswahl je Instanz",
        "-- und die Grenzen der Karten des Spiels. Art: community. Gelesen von",
        "-- ui/dungeonpos.lua.",
        "--   NODES[Flugpunkt] = { x, y, z, Fraktion (1 Allianz, 2 Horde, 3 beide) }",
        "--   ANCHORS[Instanz] = { Flugpunkte, beste Lage zuerst }, FALLBACK fuer den Rest",
        "--   FLOORS[Instanz][Ebene in data/dungeonmaps.lua] = { x min, x max, y min, y max }",
        "--------------------------------------------------",
        "",
        "WeintCodex = WeintCodex or {}",
        "WeintCodex.DungeonPosData = {",
        '    SOURCE = { kind = "community", label = "Messpunkte und Kartengrenzen von Spielern gesammelt" },',
        "    NODES = {",
    ]
    for n in used:
        x, y, z, f = nodes[n]
        out.append(f"        [{n}] = {{ {x:g}, {y:g}, {z:g}, {f} }},")
    out.append("    },")
    out.append("    FALLBACK = { " + ", ".join(str(n) for n in fallback) + " },")
    out.append("    ANCHORS = {")
    for i in sorted(anchors):
        if i in floors:
            out.append(f"        [{i}] = {{ " + ", ".join(str(n) for n in anchors[i]) + " },")
    out.append("    },")
    out.append("    FLOORS = {")
    for i in sorted(floors):
        parts = ", ".join(f"[{idx}] = {{ {b[0]:g}, {b[1]:g}, {b[2]:g}, {b[3]:g} }}" for idx, b in sorted(floors[i].items()))
        out.append(f"        [{i}] = {{ {parts} }},")
    out.append("    },")
    out.append("}")
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")
    print(f"{len(floors)} Instanzen, {sum(len(v) for v in floors.values())} Ebenen, {len(used)} Messpunkte -> data/dungeonpos.lua")
    if unmatched:
        print("ohne Grenzen:", ", ".join(unmatched))


if __name__ == "__main__":
    main()
