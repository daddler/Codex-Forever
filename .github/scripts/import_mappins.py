#!/usr/bin/env python3
"""Bosse auf den Dungeonkarten -> data/dungeonpins.lua (1.0.8.20).

Wunsch: "auf den Dungeon Maps genau positioniert die Bosse; mit Rechtsklick
ins Dungeonjournal von Codex - die Bosse, und wo sie sind, sollen in Codex
enthalten sein".

Quelle sind die Tabellen des Spiels selbst, wie wago.tools sie als CSV
ausliefert (kein Addon, nichts kopiert):

* JournalEncounter: je Boss die Kartengrafik (UiMapID) und seine Lage darauf
  (Map_0 = x, Map_1 = y, 0..1) - das, was das Dungeonkompendium des Spiels
  als Bosspunkt zeichnet.
* UiMapXMapArt + UiMapArtTile: welche Bilddateien eine Kartengrafik hat.

Zugeordnet wird nur, wo die Bilddateien (Ebene 0) einer Kartengrafik
GENAU den zwoelf Kacheln einer Ebene in data/dungeonmaps.lua gleichen - dann
ist es dasselbe Bild, und der Punkt sitzt dort, wo er im Kompendium sitzt.
Bosse: gleicher Name wie im Codex (ohne Gross/Klein und Satzzeichen) oder
ein Eintrag in ALIAS (derselbe Kampf unter spaeterem Namen am selben Ort).
Zuerst die Classic-Tabellen (wow_classic), dann die aktuellen (wow).

Herkunft im Spiel: `classic` - Blizzards Daten, aber aus anderen Fassungen
des Spiels als Forever.

Aufruf:
    for t in JournalEncounter UiMapXMapArt UiMapArtTile; do for p in wow_classic wow; do
      curl -s "https://wago.tools/db2/$t/csv?product=$p" -o "$DIR/${t}_$p.csv"; done; done
    python3 -I .github/scripts/import_mappins.py "$DIR" <Datei mit Codex-Bossen (TSV)>

Die Codex-Bosse (TSV: "B<TAB>dungeon<TAB>boss-id<TAB>Name") liefert
.github/scripts/dump_bosses.lua.
"""
import collections
import csv
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MAPS = os.path.join(ROOT, "data", "dungeonmaps.lua")
OUT = os.path.join(ROOT, "data", "dungeonpins.lua")

# Instanz (8. Rueckgabe von GetInstanceInfo) -> Codex-Dungeons dieser Instanz.
INST = {
    33: ["shadowfang_keep"], 34: ["the_stockade"], 36: ["the_deadmines"], 43: ["wailing_caverns"],
    47: ["razorfen_kraul"], 48: ["blackfathom_deeps"], 70: ["uldaman"], 90: ["gnomeregan"],
    109: ["sunken_temple"], 129: ["razorfen_downs"], 189: ["scarlet_monastery"], 209: ["zulfarrak"],
    229: ["lower_blackrock_spire", "upper_blackrock_spire"], 230: ["blackrock_depths"],
    289: ["scholomance"], 329: ["stratholme"], 349: ["maraudon"], 389: ["ragefire_chasm"],
    429: ["dire_maul"],
}

# Codex-Boss -> Name im Kompendium, wo derselbe Kampf am selben Ort spaeter
# anders heisst (oder mehrere Gegner ein Eintrag sind).
ALIAS = {
    ("the_deadmines", "sneeds_shredder"): "Sneed",
    ("uldaman", "the_lost_dwarves"): "The Lost Dwarves",
    ("zulfarrak", "nekrum"): "Nekrum & Sezz'ziz",
    ("zulfarrak", "sezzziz"): "Nekrum & Sezz'ziz",
    ("blackrock_depths", "theldren"): "Ring of Law",
    ("stratholme", "cannon_master_willey"): "Willey Hopebreaker",
    ("stratholme", "archivist_galford"): "Instructor Galford",
    ("stratholme", "malor_the_zealous"): "Commander Malor",
    ("stratholme", "baron_rivendare"): "Lord Aurius Rivendare",
    ("stratholme", "balnazzar"): "Balnazzar",
}


def norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())


def floors_of(text):
    out, inst, fi = [], None, 0
    for line in text.splitlines():
        m = re.match(r'\s*\[(\d+)\]\s*=\s*\{\s*name\s*=', line)
        if m:
            inst, fi = int(m.group(1)), 0
            continue
        m = re.search(r'tiles\s*=\s*\{([\d,\s]+)\}', line)
        if m and inst is not None:
            fi += 1
            out.append((inst, fi, frozenset(int(x) for x in m.group(1).replace(" ", "").split(",") if x)))
    return out


def main():
    src, tsv = sys.argv[1], sys.argv[2]
    codex = collections.defaultdict(list)
    for line in open(tsv, encoding="utf-8"):
        p = line.rstrip("\n").split("\t")
        if p[0] == "B":
            codex[p[1]].append((p[2], p[3]))
    floors = floors_of(open(MAPS, encoding="utf-8").read())

    def rd(name):
        return list(csv.DictReader(open(os.path.join(src, name), encoding="utf-8")))

    found = {}
    for prod in ("wow_classic", "wow"):
        art = collections.defaultdict(set)
        for r in rd("UiMapArtTile_%s.csv" % prod):
            if r["LayerIndex"] == "0":
                art[int(r["UiMapArtID"])].add(int(r["FileDataID"]))
        x = collections.defaultdict(set)
        for r in rd("UiMapXMapArt_%s.csv" % prod):
            x[int(r["UiMapArtID"])].add(int(r["UiMapID"]))
        floor_of = {}
        for (i, fi, tiles) in floors:
            for a, t in art.items():
                if t == tiles:
                    for u in x[a]:
                        floor_of[u] = (i, fi)
        for r in rd("JournalEncounter_%s.csv" % prod):
            u = int(r["UiMapID"])
            if u not in floor_of:
                continue
            i, fi = floor_of[u]
            jn = norm(r["Name_lang"])
            for dg in INST.get(i, []):
                for bid, bname in codex[dg]:
                    want = norm(ALIAS.get((dg, bid), bname))
                    if want == jn and (i, dg, bid) not in found:
                        found[(i, dg, bid)] = (fi, float(r["Map_0"]), float(r["Map_1"]), u)

    lines = [
        "--------------------------------------------------",
        "-- WeintCodex :: Bosse auf den Dungeonkarten",
        "--------------------------------------------------",
        "-- ERZEUGT von .github/scripts/import_mappins.py - nicht von Hand",
        "-- aendern; neu erzeugen.",
        "--",
        "-- HERKUNFT `classic`: die Tabellen JournalEncounter, UiMapXMapArt und",
        "-- UiMapArtTile des Spiels (Classic- und aktuelle Fassung, gelesen ueber",
        "-- wago.tools). Ein Punkt steht nur, wo die Kartengrafik des Bosses aus",
        "-- denselben Bilddateien besteht wie die Ebene in data/dungeonmaps.lua.",
        "-- Dass Forever die Bosse an denselben Stellen stehen hat, ist eine",
        "-- begruendete Erwartung, nicht gemessen.",
        "--",
        "-- [Instanz] = { { dungeon, boss, Ebene, x, y }, ... }  (x, y: 0..1)",
        "--------------------------------------------------",
        "",
        "WeintCodex = WeintCodex or {}",
        "WeintCodex.DungeonPins = {",
    ]
    total = 0
    for i in sorted(INST):
        rows = [(dg, bid) + found[(i, dg, bid)] for dg in INST[i] for bid, _ in codex[dg] if (i, dg, bid) in found]
        if not rows:
            continue
        lines.append("    [%d] = {" % i)
        for dg, bid, fi, px, py, u in rows:
            lines.append('        { "%s", "%s", %d, %.4f, %.4f },   -- Karte %d' % (dg, bid, fi, px, py, u))
            total += 1
        lines.append("    },")
    lines.append("}")
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print("geschrieben:", os.path.relpath(OUT, ROOT), total, "Bosse")


if __name__ == "__main__":
    main()
