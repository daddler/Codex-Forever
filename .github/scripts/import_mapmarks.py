#!/usr/bin/env python3
"""Geistheiler und Uebergaenge auf der Weltkarte -> data/mapmarks.lua (6.21.0.0).

Liest die Symboltabelle eines Karten-Addons (Leatrix_Maps_Icons.lua) und
schreibt NUR DIE LAGEN in unser Format - wie beim Aufdecken der Karte
(import_mapreveal.py): Tatsachen ueber das Spiel, kein Code, keine Texte.
Uebernommen werden zwei Arten:

  Geistheiler   je Karte die Lagen (0..1)
  Uebergaenge   je Karte Lage, Richtung des Pfeils (Bogenmass, gegen den
                Uhrzeigersinn, 0 = nach oben) und die Karte, in die er
                fuehrt. Der Name dieser Karte kommt im Spiel vom Client
                (C_Map.GetMapInfo) - in der Sprache des Spielers.
                Pfeile innerhalb derselben Karte ("dem Weg nach Westen
                folgen") brauchen einen Satz und bleiben weg.

Aufruf:
    python3 -I .github/scripts/import_mapmarks.py <Pfad zu Leatrix_Maps_Icons.lua>

Die Datei wird nur gelesen, nie ausgefuehrt.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "mapmarks.lua")

ZONE = re.compile(r"--\[\[([^\]]+)\]\]\s*\[(\d+)\]\s*=\s*\{")
SPIRIT = re.compile(r'^\s*\{"Spirit",\s*([\d.]+),\s*([\d.]+),')
ARROW = re.compile(r'^\s*\{"Arrow",\s*([\d.]+),\s*([\d.]+),.*,\s*(-?[\d.]+),\s*(\d+)\s*\},?\s*$')


def parse(text):
    spirit, arrows, skipped = {}, {}, 0
    zone = None
    for line in text.splitlines():
        m = ZONE.search(line)
        if m:
            zone = int(m.group(2))
            continue
        if zone is None:
            continue
        m = SPIRIT.match(line)
        if m:
            x, y = float(m.group(1)), float(m.group(2))
            if not (0 <= x <= 100 and 0 <= y <= 100):
                raise SystemExit(f"Karte {zone}: Geistheiler ausserhalb: {line.strip()}")
            spirit.setdefault(zone, []).append((x / 100, y / 100))
            continue
        if line.strip().startswith('{"Arrow"'):
            m = ARROW.match(line)
            if not m:
                raise SystemExit(f"Karte {zone}: Pfeil nicht lesbar: {line.strip()[:80]}")
            x, y, rot, to = float(m.group(1)), float(m.group(2)), float(m.group(3)), int(m.group(4))
            if to == zone:
                skipped += 1
                continue
            arrows.setdefault(zone, []).append((x / 100, y / 100, rot, to))
    return spirit, arrows, skipped


def num(v):
    s = f"{v:.4f}".rstrip("0").rstrip(".")
    return s if s not in ("", "-0") else "0"


def write(spirit, arrows, skipped):
    ns = sum(len(v) for v in spirit.values())
    na = sum(len(v) for v in arrows.values())
    out = [
        "--------------------------------------------------",
        "-- WeintCodex :: Geistheiler und Uebergaenge auf der Weltkarte",
        "--------------------------------------------------",
        "-- ERZEUGT von .github/scripts/import_mapmarks.py - nicht von Hand aendern.",
        "-- Nur Lagen (Tatsachen ueber das Spiel), kein Code, keine Texte. Gelesen",
        "-- von ui/mapmarks.lua.",
        "--",
        "-- spirit[Karte]    = { x1, y1, x2, y2, ... }          (0..1)",
        "-- crossings[Karte] = { x, y, Richtung, Zielkarte, ... } (Richtung: Bogenmass,",
        "--                    gegen den Uhrzeigersinn, 0 = nach oben)",
        f"-- {ns} Geistheiler auf {len(spirit)} Karten, {na} Uebergaenge auf {len(arrows)} Karten"
        f" ({skipped} Pfeile innerhalb einer Karte weggelassen).",
        "--------------------------------------------------",
        "",
        "WeintCodex = WeintCodex or {}",
        "WeintCodex.MapMarksData = {",
        "    spirit = {",
    ]
    for zone in sorted(spirit):
        vals = ", ".join(f"{num(x)}, {num(y)}" for x, y in spirit[zone])
        out.append(f"        [{zone}] = {{ {vals} }},")
    out.append("    },")
    out.append("    crossings = {")
    for zone in sorted(arrows):
        vals = ", ".join(f"{num(x)}, {num(y)}, {num(r)}, {to}" for x, y, r, to in arrows[zone])
        out.append(f"        [{zone}] = {{ {vals} }},")
    out.append("    },")
    out.append("}")
    out.append("")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print(f"geschrieben: data/mapmarks.lua ({ns} Geistheiler, {na} Uebergaenge, {skipped} weggelassen)")


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    with open(sys.argv[1], encoding="utf-8-sig") as f:
        text = f.read()
    write(*parse(text))


if __name__ == "__main__":
    main()
