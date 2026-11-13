#!/usr/bin/env python3
"""NPC-Nummer und deutscher Name je Boss des Dungeonkompendiums (1.10.10.0).

Aufruf (im Wurzelordner des Repos):

    python3 -I .github/scripts/make_boss_npcs.py [NaowhForever_DungeonJournal-Ordner]

Schreibt data/boss_npcs.lua (erzeugt - nicht von Hand aendern).

WOZU: Die Bosskaempfe (ui/bossmod.lua) muessen erkennen, ob ein getoeteter
Gegner ein Boss des Kompendiums war - auch ohne Kampfbeginn-Meldung des
Spiels und ohne Bossrahmen (alte Dungeons). Das Kompendium
(data/dungeons.lua, data/dungeons_classic.lua) kennt nur englische Namen;
Spieler mit deutschem Client sehen "Hochlord Omokk". Die NPC-Nummer im
GUID haengt an keiner Sprache.

WOHER: NPC-Nummer und deutscher Name stehen in data/loot.lua (Beute je Boss,
erzeugt aus AtlasLootClassic, nur Daten). Welcher Eintrag dort zu welchem
Boss des Kompendiums gehoert, sagt die BEUTE: die Bosse des Kompendiums
haben ihre Beute in data/dungeon_journal_nf.lua und _fg.lua (Schluessel =
Boss-ID des Kompendiums). Gleiche Gegenstaende = derselbe Boss. Kein Name
wird verglichen, keiner geraten: ohne eindeutige Ueberschneidung (mind. 2
gemeinsame Gegenstaende, kein Gleichstand) bleibt ein Boss ohne Nummer.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "boss_npcs.lua")


def read(name):
    with open(os.path.join(ROOT, "data", name), encoding="utf-8") as f:
        return f.read()


def compendium():
    """{dungeon: {boss: englischer Name}}"""
    out = {}
    for name in ("dungeons.lua", "dungeons_classic.lua"):
        text = read(name)
        for m in re.finditer(r'\bid\s*=\s*"([a-z0-9_]+)"[^{}]*?\bbosses\s*=\s*\{', text, re.S):
            dungeon = m.group(1)
            depth, i = 1, m.end()
            while depth and i < len(text):
                depth += {"{": 1, "}": -1}.get(text[i], 0)
                i += 1
            body = text[m.end():i]
            for b in re.finditer(r'\{\s*id\s*=\s*"([a-z0-9_]+)",\s*name\s*=\s*"([^"]+)"', body):
                out.setdefault(dungeon, {})[b.group(1)] = b.group(2)
    return out


def journal_loot():
    """{dungeon: {boss: set(Gegenstaende)}} aus NF und FG."""
    out = {}
    for name, table in (("dungeon_journal_nf.lua", "NF_LOOT"), ("dungeon_journal_fg.lua", None)):
        text = read(name)
        if table:
            m = re.search(table + r"\s*=\s*\{", text)
            text = text[m.end():] if m else ""
        for dm in re.finditer(r'^    ([a-z0-9_]+) = \{\n(.*?)^    \},', text, re.S | re.M):
            dungeon = dm.group(1)
            for bm in re.finditer(r'^        ([a-z0-9_]+) = \{\n(.*?)^        \},', dm.group(2), re.S | re.M):
                items = {int(x) for x in re.findall(r'\{\s*(\d+),', bm.group(2))}
                if items:
                    out.setdefault(dungeon, {}).setdefault(bm.group(1), set()).update(items)
    return out


def loot_bosses():
    """[(deutscher Name, npc, set(Gegenstaende))] aus data/loot.lua."""
    out = []
    for name, npc, items in re.findall(r'"([^"\t]+)\t(\d+)\t([^"]*)"', read("loot.lua")):
        ids = {int(x) for x in re.findall(r'(\d+)(?::[\d.]+)?[ah]?', items)}
        out.append((name, int(npc), ids))
    return out


def main():
    comp, jl, lb = compendium(), journal_loot(), loot_bosses()
    rows, found, missing = [], 0, []
    for dungeon in sorted(comp):
        for boss, en in sorted(comp[dungeon].items()):
            items = jl.get(dungeon, {}).get(boss, set())
            scored = sorted(((len(items & ids), de, npc) for de, npc, ids in lb), reverse=True)
            best = scored[0] if scored else (0, None, None)
            tie = len(scored) > 1 and scored[1][0] == best[0] and scored[1][2] != best[2]
            if best[0] >= 2 and not tie:
                rows.append((dungeon, boss, best[2], best[1], en))
                found += 1
            else:
                missing.append(f"{dungeon}/{boss}")
    # Eine Nummer fuer mehrere Bosse (Gruppen wie "Grimmige Saeufer") ist
    # mehrdeutig: dann bekommt keiner sie.
    count = {}
    for r in rows:
        count[r[2]] = count.get(r[2], 0) + 1
    for r in [r for r in rows if count[r[2]] > 1]:
        rows.remove(r)
        found -= 1
        missing.append(f"{r[0]}/{r[1]} (Nummer {r[2]} mehrdeutig)")
    # Was die vorige Fassung dieser Datei schon wusste, bleibt: die Nummer
    # eines Bosses aendert sich nicht, nur weil eine neue Beuteliste keine
    # eindeutige Ueberschneidung mehr hergibt (1.0.6.1: drei gingen so verloren).
    if os.path.exists(OUT):
        have = {(r[0], r[1]) for r in rows}
        used = {r[2] for r in rows}
        for npc, d, b, de, en in re.findall(
                r'^    \[(\d+)\] = \{ "([^"]+)", "([^"]+)", "((?:[^"\\]|\\.)*)", "((?:[^"\\]|\\.)*)" \},',
                open(OUT, encoding="utf-8").read(), re.M):
            if (d, b) in have or int(npc) in used or b not in comp.get(d, {}):
                continue
            rows.append((d, b, int(npc), de.replace('\\"', '"'), comp[d][b]))
            have.add((d, b)); used.add(int(npc)); found += 1
            missing = [m for m in missing if m != f"{d}/{b}"]
        rows.sort()
    # 1.0.6.1: mit dem Ordner von Naowh Forever: Dungeon Journal bekommen
    # Bosse ohne eindeutige Beute ihre Nummer von dort - je Dungeon ueber den
    # englischen Namen (dieselbe Zuordnung wie import_naowh.py). Deutscher
    # Name aus dessen deDE, sonst der englische ("Sammelpunkt n" sind
    # Platzhalter des Clients, kein Name).
    if len(sys.argv) > 1 and os.path.isdir(sys.argv[1]):
        import json
        import subprocess
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import import_naowh as N
        data = os.path.join(sys.argv[1], "Data")
        nf = json.loads(subprocess.run(["lua5.1", os.path.join(ROOT, ".github", "scripts", "nf_dump.lua"), data],
                                       check=True, capture_output=True, text=True).stdout)
        de = dict((int(k), v) for k, v in re.findall(r'\[(\d+)\] = "((?:[^"\\]|\\.)*)"',
                  open(os.path.join(data, "Names", "deDE.lua"), encoding="utf-8").read()))
        have = {(r[0], r[1]) for r in rows}
        used = {r[2] for r in rows}
        for d in nf["dungeons"]:
            did = N.DUNGEON_MAP.get(d["key"])
            if did not in comp:
                continue
            byname = {N.norm(en): b for b, en in comp[did].items()}
            for w in N.as_list(d.get("wings")):
                for nb in N.as_list(w.get("bosses")):
                    b, npc = byname.get(N.norm(nb.get("name", ""))), nb.get("npc")
                    if not b or not npc or (did, b) in have or npc in used:
                        continue
                    name = de.get(npc) or ""
                    if not name or name.startswith("Sammelpunkt"):
                        name = comp[did][b]
                    rows.append((did, b, npc, name, comp[did][b]))
                    have.add((did, b)); used.add(npc); found += 1
                    missing = [m for m in missing if m != f"{did}/{b}"]
        rows.sort()
    lines = [
        "--------------------------------------------------",
        "-- WeintCodex :: NPC-Nummern der Bosse des Dungeonkompendiums",
        "--------------------------------------------------",
        "-- ERZEUGT von .github/scripts/make_boss_npcs.py - nicht von Hand aendern.",
        "-- Zuordnung ueber gleiche Beute (data/loot.lua <-> Journal), kein Name",
        "-- verglichen. B[npc] = { Dungeon, Boss, deutscher Name, englischer Name }.",
        f"-- {found} Bosse mit Nummer, {len(missing)} ohne (keine eindeutige Beute).",
        "--------------------------------------------------",
        "",
        "WeintCodex = WeintCodex or {}",
        "WeintCodex.BossNpcs = {",
    ]
    for dungeon, boss, npc, de, en in rows:
        q = lambda s: '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'
        lines.append(f"    [{npc}] = {{ {q(dungeon)}, {q(boss)}, {q(de)}, {q(en)} }},")
    lines.append("}")
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print(f"{found} Bosse mit Nummer, {len(missing)} ohne -> {os.path.relpath(OUT, ROOT)}")
    if "-v" in sys.argv:
        print("ohne:", ", ".join(missing))


if __name__ == "__main__":
    main()
