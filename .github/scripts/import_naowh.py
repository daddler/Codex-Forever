#!/usr/bin/env python3
"""Abgleich mit dem Addon "Naowh Forever: Dungeon Journal" (1.4.0.0).

Aufruf (im Wurzelordner des Repos):

    python3 .github/scripts/import_naowh.py <NaowhForever_DungeonJournal-Ordner>

Schreibt data/dungeon_journal_nf.lua (erzeugt - nicht von Hand aendern) und
druckt einen Bericht: was uebernommen ist, was nicht, und warum.

UEBERNOMMEN WERDEN NUR FAKTEN - Gegenstandsnummern je Boss, Dropchancen,
Stufen der Bosse, Eingaenge, welche Gegenstaende der Server (noch) nicht
kennt. Keine Texte (die Tipps des Addons sind seine eigenen Saetze und
bleiben dort), kein Code, keine Grafik. Das Addon nennt keine Lizenz.

Woher das Addon seine Daten hat (nur fuer Betreuer, im Spiel steht nur die
Art `community`): Beute und Dropchancen von Wowhead Forever und wowsrc.com
(Beute in Forever), Bosse mit NPC- und Encounter-Nummern aus den
Clienttabellen (wago.tools, Build 1.60.1.x), "noch nicht im Spiel" aus
ItemSparse plus dem, was der Server tatsaechlich schickt.

DROPCHANCEN: bei Bossen, die es schon in Classic gab, zaehlt Wowhead die
Kills aus Classic Era und Forever zusammen - die Zahl ist eine Mischung.
Unter 10 Kills nennt das Addon keine (bei uns: keine Zahl, nie 0 %).

Gelesen wird ueber .github/scripts/nf_dump.lua (Datendateien in leerer
Umgebung) und .github/scripts/journal_dump.lua (der eigene Bestand vor
diesem Abgleich).
"""

import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NF_VERSION = "1.1.47"

# Schluessel des Addons -> Dungeon des Codex (Fluegel zusammengefasst).
# Schlachtzuege (Barrow Deeps, Hyjal Summit, Onyxias Hort) fehlen mit
# Absicht: ihre Listen kommen aus dem Beta-Client (data/raids.lua), die
# Reihenfolge des Addons ist nach eigener Angabe die eines Erfolgs, und
# Beute nennt es dort keine.
DUNGEON_MAP = {
    "AlcazPrison": "alcaz_island_prison", "BlackfathomDeeps": "blackfathom_deeps",
    "BlackmawHold": "blackmaw_hold", "BlackrockDepths": "blackrock_depths",
    "Dalaran": "city_of_dalaran", "Deadmines": "the_deadmines", "DireMaul": "dire_maul",
    "DrownedCity": "drowned_city", "ExcavationSite": "excavation_site",
    "Gnomeregan": "gnomeregan", "HallOfThanes": "hall_of_thanes",
    "Kroldok": "kroldok_stronghold", "LowerBlackrockSpire": "lower_blackrock_spire",
    "Maraudon": "maraudon", "RagefireChasm": "ragefire_chasm",
    "RazorfenDowns": "razorfen_downs", "RazorfenKraul": "razorfen_kraul",
    "RuinsOfLordaeron": "ruins_of_lordaeron", "ScarletMonasteryArmory": "scarlet_monastery",
    "ScarletMonasteryCathedral": "scarlet_monastery",
    "ScarletMonasteryGraveyard": "scarlet_monastery",
    "ScarletMonasteryLibrary": "scarlet_monastery", "Scholomance": "scholomance",
    "ShadowfangKeep": "shadowfang_keep", "ShapersTerrace": "shapers_terrace",
    "Stockade": "the_stockade", "Stratholme": "stratholme", "SunkenTemple": "sunken_temple",
    "Uldaman": "uldaman", "UpperBlackrockSpire": "upper_blackrock_spire",
    "WailingCaverns": "wailing_caverns", "ZulFarrak": "zulfarrak",
}

# Gegner des Addons, die im Codex Teil eines Kampfes sind: (Dungeon, Name)
# -> (Boss, `from`). `from` steht vor der Zeile, wie im Journal.
BOSS_ALIAS = {
    ("the_deadmines", "Sneed"): ("sneeds_shredder", "Sneed"),
    ("stratholme", "Balnazzar"): ("balnazzar", None),
    ("uldaman", 'Eric "The Swift"'): ("the_lost_dwarves", None),
    ("uldaman", "Olaf"): ("the_lost_dwarves", None),
    ("blackrock_depths", "Chest of The Seven"): ("the_seven", None),
    ("blackrock_depths", "Anub'shiah"): ("ring_of_law", "Anub'shiah"),
    ("blackrock_depths", "Eviscerator"): ("ring_of_law", "Eviscerator"),
    ("blackrock_depths", "Gorosh the Dervish"): ("ring_of_law", "Gorosh"),
    ("blackrock_depths", "Grizzle"): ("ring_of_law", "Grizzle"),
    ("blackrock_depths", "Hedrum the Creeper"): ("ring_of_law", "Hedrum"),
    ("blackrock_depths", "Ok'thor the Breaker"): ("ring_of_law", "Ok'thor"),
}

TRASH = "Gegner unterwegs"

# Gegenstandsart aus Classic-Tabellen (nur fuer "noch nicht im Spiel").
WEAPON = {0: "Axt", 1: "Axt", 2: "Bogen", 3: "Schusswaffe", 4: "Streitkolben",
          5: "Streitkolben", 6: "Stangenwaffe", 7: "Schwert", 8: "Schwert", 10: "Stab",
          13: "Faustwaffe", 15: "Dolch", 16: "Wurfwaffe", 18: "Armbrust", 19: "Zauberstab"}
ARMOR = {1: "Stoff", 2: "Leder", 3: "Schwere Rüstung", 4: "Platte", 6: "Schild"}

report = []


def say(line=""):
    report.append(line)


def lua_str(s):
    s = str(s)
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def norm(name):
    s = name.lower()
    s = re.sub(r"^the ", "", s)
    return re.sub(r"[^a-z0-9]", "", s)


def as_list(v):
    if v is None:
        return []
    if isinstance(v, list):
        return v
    return [v[k] for k in sorted(v, key=int)]


def run_dump(script, *args):
    out = subprocess.run(["lua5.1", script, *args], cwd=ROOT, capture_output=True, text=True, check=True)
    return json.loads(out.stdout)


def build(nf, cx):
    names = {e["id"]: e for e in cx["items"]}
    not_yet = {int(k): v for k, v in nf["notYet"].items()}
    info = {int(k): v for k, v in nf["bossInfo"].items()}
    abil = {int(k): as_list(v) for k, v in (nf.get("abilities") or {}).items()}
    codex = {d["id"]: d for d in cx["dungeons"]}

    def item(i, chance, prefix=None):
        e = names.get(i, {})
        n, s, q = e.get("n"), e.get("s"), e.get("q")
        ny = not_yet.get(i)
        if ny:
            n = n or ny[6]
            q = q if q is not None else ny[4]
            if s is None:
                s = WEAPON.get(ny[1]) if ny[0] == 2 else ARMOR.get(ny[1]) if ny[0] == 4 else None
        return {"id": i, "n": n, "s": s, "q": q, "c": chance if chance and chance > 0 else None,
                "from": prefix}

    out = {"loot": {}, "others": {}, "levels": {}, "entrances": {}, "notyet": {}, "abilities": {}}
    stats = {"chance": 0, "items": 0, "unnamed": 0}
    for d in nf["dungeons"]:
        did = DUNGEON_MAP.get(d["key"])
        if not did:
            say(f"  - {d['name']}: kein Dungeon im Codex (Schlachtzug) - uebersprungen")
            continue
        cd = codex[did]
        bosses = {norm(b["name"]): b["id"] for b in cd["bosses"]}
        bosses.update({norm(b["alt"]): b["id"] for b in cd["bosses"] if b.get("alt")})
        if not cd["entrance"] and d.get("entrance") and did not in out["entrances"]:
            e = d["entrance"]
            out["entrances"][did] = (e["map"], round(e["x"] / 100, 3), round(e["y"] / 100, 3))
        for wing in as_list(d.get("wings")):
            for b in as_list(wing.get("bosses")):
                ids = as_list(b.get("loot"))
                chances = as_list(b.get("chance"))
                alias = BOSS_ALIAS.get((did, b["name"]))
                bid, prefix = alias if alias else (bosses.get(norm(b["name"])), None)
                if bid and b.get("npc") and info.get(b["npc"]):
                    lo, hi = info[b["npc"]][0], info[b["npc"]][1]
                    if lo > 0 and hi > 0:
                        have = out["levels"].setdefault(did, {}).get(bid)
                        out["levels"][did][bid] = (min(lo, have[0]), max(hi, have[1])) if have else (lo, hi)
                if bid and b.get("npc") and abil.get(b["npc"]):
                    have = out["abilities"].setdefault(did, {}).setdefault(bid, [])
                    have.extend(x for x in abil[b["npc"]] if x not in have)
                if not ids:
                    continue
                rows = [item(i, chances[k] if k < len(chances) else None, prefix) for k, i in enumerate(ids)]
                stats["items"] += len(rows)
                stats["chance"] += sum(1 for r in rows if r["c"])
                stats["unnamed"] += sum(1 for r in rows if not r["n"])
                for r in rows:
                    if r["id"] in not_yet:
                        out["notyet"][r["id"]] = r
                if b.get("trash"):
                    group, kind = TRASH, None
                elif bid:
                    lst = out["loot"].setdefault(did, {}).setdefault(bid, [])
                    seen = {r["id"] for r in lst}
                    lst.extend(r for r in rows if r["id"] not in seen)
                    continue
                else:
                    group = b["name"]
                    kind = "Seltener Gegner" if b.get("rare") else None
                groups = out["others"].setdefault(did, [])
                g = next((x for x in groups if x["name"] == group), None)
                if not g:
                    g = {"name": group, "note": kind, "items": []}
                    groups.append(g)
                seen = {r["id"] for r in g["items"]}
                g["items"].extend(r for r in rows if r["id"] not in seen)
    say(f"  Beute: {stats['items']} Zeilen, {stats['chance']} mit Dropchance, "
        f"{stats['unnamed']} ohne Namen im Bestand (der Client nennt ihn)")
    say(f"  Noch nicht im Spiel: {len(out['notyet'])} der gelisteten Gegenstaende")
    say(f"  Stufen: {sum(len(v) for v in out['levels'].values())} Bosse")
    say(f"  Faehigkeiten: {sum(len(v) for v in out['abilities'].values())} Bosse")
    say(f"  Eingaenge ergaenzt: {', '.join(sorted(out['entrances'])) or 'keine'}")
    return out


def lua_row(r):
    s = f"{{ {r['id']}, {lua_str(r['n']) if r['n'] else 'nil'}, {lua_str(r['s']) if r['s'] else 'nil'}, " \
        f"{r['q'] if r['q'] is not None else 'nil'}"
    if r["c"]:
        s += f", chance = {r['c']}"
    if r.get("from"):
        s += f", from = {lua_str(r['from'])}"
    return s + " }"


def write(nf, dd):
    L = []
    w = L.append
    w("--------------------------------------------------")
    w(f"-- WeintCodex :: Dungeon-Journal, Abgleich mit Naowh Forever {NF_VERSION}")
    w("--------------------------------------------------")
    w("-- ERZEUGT von .github/scripts/import_naowh.py - nicht von Hand aendern;")
    w("-- neu erzeugen. Ergaenzt data/dungeon_journal.lua und den Abgleich mit")
    w("-- ForeverGuide (data/dungeon_journal_fg.lua) ueber J.MergeNaowh().")
    w("--")
    w(f"-- Stand: Daten des Addons vom {nf['date']}, Client-Build {nf['build']}.")
    w("-- HERKUNFT (nur fuer Betreuer): Beute und Dropchancen von Wowhead Forever")
    w("-- und wowsrc.com, Bosse und Stufen aus den Clienttabellen, \"noch nicht im")
    w("-- Spiel\" aus ItemSparse und dem, was der Server schickt. Im Spiel steht nur")
    w("-- die Art: `community`.")
    w("--")
    w("--   NF_LOOT[Dungeon][Boss]  Beute { Nummer, Name, Platz, Qualitaet,")
    w("--                           chance = % (fehlt: unbekannt, nie 0), from }")
    w("--   NF_OTHERS[Dungeon]      weitere Beute: Gegner unterwegs, seltene")
    w("--                           Gegner, Truhen ohne eigenen Boss")
    w("--   BOSS_LEVEL[Dungeon][Boss] { von, bis }")
    w("--   NOT_YET[Nummer]         der Server kennt den Gegenstand (noch) nicht -")
    w("--                           der Client zeigte ewig \"lädt …\"")
    w("--   NF_ENTRANCES            Eingaenge, wo noch keiner bekannt war")
    w("--")
    w("-- DROPCHANCEN alter Bosse zaehlen Kills aus Classic und Forever zusammen.")
    w("--------------------------------------------------")
    w("")
    w("local J = WeintCodex.DungeonJournal")
    w("")
    w("J.NF_SOURCE = {")
    w('    kind  = "community",')
    w('    date  = "27.10.2026",')
    w('    label = "Beute: Wissensstand aus der Beta, Dropchancen gezählt (alte Bosse zusammen mit Classic)",')
    w("}")
    w("")
    w("J.NF_LOOT = {")
    for did in sorted(dd["loot"]):
        w(f"    {did} = {{")
        for bid in sorted(dd["loot"][did]):
            w(f"        {bid} = {{")
            for r in dd["loot"][did][bid]:
                w(f"            {lua_row(r)},")
            w("        },")
        w("    },")
    w("}")
    w("")
    w("J.NF_OTHERS = {")
    for did in sorted(dd["others"]):
        w(f"    {did} = {{")
        for g in dd["others"][did]:
            note = f", note = {lua_str(g['note'])}" if g["note"] else ""
            w(f"        {{ name = {lua_str(g['name'])}{note}, items = {{")
            for r in g["items"]:
                w(f"            {lua_row(r)},")
            w("        } },")
        w("    },")
    w("}")
    w("")
    w("J.BOSS_LEVEL = {")
    for did in sorted(dd["levels"]):
        parts = ", ".join(f"{bid} = {{ {lo}, {hi} }}" for bid, (lo, hi) in sorted(dd["levels"][did].items()))
        w(f"    {did} = {{ {parts} }},")
    w("}")
    w("")
    w("-- Faehigkeiten je Boss als Zaubernummern (Clienttabellen). Name und")
    w("-- Beschreibung nennt der Client; nennt er keine, steht die Faehigkeit nicht da.")
    w("J.BOSS_ABILITIES = {")
    for did in sorted(dd["abilities"]):
        parts = ", ".join(f"{bid} = {{ {', '.join(str(x) for x in ids)} }}" for bid, ids in sorted(dd["abilities"][did].items()))
        w(f"    {did} = {{ {parts} }},")
    w("}")
    w("")
    w("J.NOT_YET = {")
    for i in sorted(dd["notyet"]):
        w(f"    [{i}] = true,")
    w("}")
    w("")
    w("J.NF_ENTRANCES = {")
    for did in sorted(dd["entrances"]):
        m, x, y = dd["entrances"][did]
        w(f"    {did} = {{ {{ map = {m}, x = {x}, y = {y} }} }},")
    w("}")
    w("")
    w("J.MergeNaowh()")
    path = os.path.join(ROOT, "data", "dungeon_journal_nf.lua")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    say(f"  -> {os.path.relpath(path, ROOT)} ({os.path.getsize(path) // 1024} KB)")


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    nf = run_dump(".github/scripts/nf_dump.lua", os.path.join(sys.argv[1], "Data"))
    cx = run_dump(".github/scripts/journal_dump.lua")
    say(f"Naowh Forever Dungeon Journal {NF_VERSION}, Daten vom {nf['date']} (Build {nf['build']})")
    write(nf, build(nf, cx))
    print("\n".join(report))


if __name__ == "__main__":
    main()
