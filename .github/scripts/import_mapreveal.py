#!/usr/bin/env python3
"""Kartenteile zum Aufdecken der Weltkarte -> data/mapreveal.lua (6.20.0.0).

Liest die Tabelle "Reveal Data for Forever" aus dem Addon Leatrix Maps
(Leatrix_Maps_Reveal.lua) und schreibt NUR DIE DATEN in unser Format:
je Kartenbild (C_Map.GetMapArtID) die Kartenteile mit Breite, Hoehe, Lage
und den Bildnummern des Clients. Kein Code, keine Texte - wie beim Abgleich
mit ForeverGuide (6.14.0.0) nur Tatsachen aus den Spieldaten.

Aufruf:
    python3 -I .github/scripts/import_mapreveal.py <Pfad zu Leatrix_Maps_Reveal.lua> [Version]

Die Datei wird nur gelesen, nie ausgefuehrt.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "mapreveal.lua")

ZONE = re.compile(r"--\[\[(\d+): ([^\]]+)\]\]")
ART = re.compile(r"^\s*\[(\d+)\]\s*=\s*\{(.*)\},?\s*$")
ENTRY = re.compile(r'\["(\d+):(\d+):(\d+):(\d+)"\]\s*=\s*"([\d, ]+)"')


def parse(text):
    maps = []
    zone = None
    for line in text.splitlines():
        m = ZONE.search(line)
        if m:
            zone = (int(m.group(1)), m.group(2).strip())
            continue
        m = ART.match(line)
        if not m:
            continue
        if zone is None:
            raise SystemExit("Kartenbild ohne Zone davor: " + line[:60])
        art = int(m.group(1))
        parts = []
        for e in ENTRY.finditer(m.group(2)):
            w, h, x, y = (int(e.group(i)) for i in range(1, 5))
            ids = [int(v) for v in e.group(5).replace(" ", "").split(",") if v]
            # So viele Bilder, wie Kacheln zu 256 hineinpassen - sonst ist
            # der Eintrag kaputt, und ein falsches Bild waere ein gruenes.
            need = -(-w // 256) * -(-h // 256)
            if len(ids) != need:
                raise SystemExit(f"{zone[1]}: {w}x{h} braucht {need} Bilder, hat {len(ids)}")
            parts.append((w, h, x, y, ids))
        if not parts:
            raise SystemExit(f"{zone[1]}: keine Kartenteile")
        parts.sort(key=lambda p: (p[3], p[2], p[0], p[1]))
        maps.append((zone[0], zone[1], art, parts))
        zone = None
    return maps


def lua_string(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write(maps, version):
    n = sum(len(m[3]) for m in maps)
    out = []
    out.append("--------------------------------------------------")
    out.append("-- WeintCodex :: Kartenteile zum Aufdecken der Weltkarte")
    out.append("--------------------------------------------------")
    out.append("-- ERZEUGT von .github/scripts/import_mapreveal.py - nicht von Hand")
    out.append("-- aendern. Quelle: die Tabelle \"Reveal Data for Forever\" im Addon")
    out.append(f"-- Leatrix Maps {version} (nur die Daten: Bildnummern, Groesse, Lage -")
    out.append("-- Tatsachen aus den Spieldaten, kein Code). Gelesen von ui/mapreveal.lua,")
    out.append("-- das sie im Spiel gegen die schon erkundeten Teile haelt.")
    out.append("--")
    out.append("-- build() -> [Kartenbild] = { map = Karte, name = Zone, { Breite, Hoehe, x, y, { Bilder } }, ... }")
    out.append(f"-- {len(maps)} Karten, {n} Kartenteile.")
    out.append("--------------------------------------------------")
    out.append("")
    out.append("WeintCodex = WeintCodex or {}")
    out.append("WeintCodex.MapRevealData = {")
    out.append(f"    source = {lua_string('Leatrix Maps ' + version)},")
    out.append("    -- Gebaut erst, wenn jemand die Karte aufdeckt (ui/mapreveal.lua):")
    out.append("    -- als fertige Tabellen kosteten sie Speicher, den fast niemand braucht.")
    out.append("    build = function() return {")
    for ui, name, art, parts in sorted(maps, key=lambda m: m[0]):
        out.append(f"        [{art}] = {{ map = {ui}, name = {lua_string(name)},")
        for w, h, x, y, ids in parts:
            out.append(f"            {{ {w}, {h}, {x}, {y}, {{ {', '.join(str(i) for i in ids)} }} }},")
        out.append("        },")
    out.append("    } end,")
    out.append("}")
    out.append("")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print(f"geschrieben: data/mapreveal.lua ({len(maps)} Karten, {n} Kartenteile)")


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    with open(sys.argv[1], encoding="utf-8-sig") as f:
        text = f.read()
    version = sys.argv[2] if len(sys.argv) > 2 else "?"
    maps = parse(text)
    write(maps, version)


if __name__ == "__main__":
    main()
