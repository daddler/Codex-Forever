#!/usr/bin/env python3
"""Herkunft der Rezepte und Rangbuecher aus der Questie-Datenbank fuer Forever.

    python3 -I .github/scripts/import_recipesources.py <QuestieDB-Ordner>

Liest die Rezeptgegenstaende aus data/professions.lua (Spalte "Rezept") und
die Rangbuecher aus data/professions_su.lua (P.RANKS) und schreibt je
Gegenstand, wer ihn verkauft, wer ihn fallen laesst (Gegner, Objekte) und
welche Quest ihn gibt - nach data/recipe_sources.lua. Nur Tatsachen
(Nummern, Namen, Lagen), Art `community`.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_questdb as Q  # noqa: E402

ROOT = Q.ROOT
OUT = os.path.join(ROOT, "data", "recipe_sources.lua")
WORLD = 8      # mehr Gegner als das: "Weltbeute", ohne Liste
MAX_SRC = 4    # sonst hoechstens so viele je Art
SPAWNS = 1     # eine Lage je NPC reicht fuer den Pfeil

# Felder der Gegenstaende (Types/Meta.t.lua, QuestieDBItemKeys)
I_DROPS, I_OBJ, I_QUEST, I_VENDOR = 2, 3, 6, 14
# NPC: 7 Lagen, 13 freundlich zu
N_SPAWNS, N_FRIENDLY = 7, 13


def wanted():
    items = set()
    with open(os.path.join(ROOT, "data", "professions.lua"), encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^\d+ \d+ \d+ \d+ \d+ \d+ \w \S+ (\d+) ", line)
            if m:
                items.add(int(m.group(1)))
    with open(os.path.join(ROOT, "data", "professions_su.lua"), encoding="utf-8") as f:
        for m in re.finditer(r'"book", \d+, \d+, (\d+)', f.read()):
            items.add(int(m.group(1)))
    return items


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    folder = sys.argv[1]
    st = Q.Store(Q.read_meta(os.path.join(folder, "QuestieDB_Forever.toc")))
    zmap = Q.zone_map(folder)
    need = wanted()
    _, items = st.entity("Item-", [I_DROPS, I_OBJ, I_QUEST, I_VENDOR], need)

    rows, need_npc, need_obj, need_q = {}, set(), set(), set()
    for i in sorted(items):
        it = items[i]
        v = Q.ids(it.get(I_VENDOR))[:MAX_SRC]
        d = Q.ids(it.get(I_DROPS))
        o = Q.ids(it.get(I_OBJ))[:MAX_SRC]
        q = Q.ids(it.get(I_QUEST))[:MAX_SRC]
        world = len(d) > WORLD
        d = [] if world else d[:MAX_SRC]
        if not (v or d or o or q or world):
            continue
        rows[i] = (v, d, o, q, world)
        need_npc.update(v + d)
        need_obj.update(o)
        need_q.update(q)

    nids, npcs = st.entity("Npc-", [N_SPAWNS], need_npc)
    oids, objs = st.entity("Object-", [4], need_obj)
    qids, quests = st.entity("Quest-", [], need_q)
    nde, ode, qde = st.german("Npc", nids), st.german("Object", oids), st.german("Quest", qids)

    def place(spawns):
        by = Q.spawns_by_map(spawns, zmap, SPAWNS)
        for ui in sorted(by):
            x, y = by[ui][0]
            return "%d\t%s\t%s" % (ui, Q.num(x * 100), Q.num(y * 100))
        return "\t\t"

    out = [
        "--------------------------------------------------",
        "-- WeintCodex :: Herkunft der Rezepte und Rangbuecher",
        "--------------------------------------------------",
        "-- ERZEUGT von .github/scripts/import_recipesources.py - nicht von Hand",
        "-- aendern. Herkunft: Datenbank der Community fuer Forever (`community`).",
        "-- Nur Tatsachen (Nummern, Namen, Lagen).",
        "--",
        "-- r[Gegenstand] = Haendler, Gegner, Objekte, Quests (Tabulator, Listen mit",
        "--                 Komma), dann \"w\", wenn er Weltbeute ist (viele Gegner)",
        "-- n[NPC]  = Name, Karte, x, y (0..100), Fraktion (A/H/AH)",
        "-- o[Obj]  = Name   ·   q[Quest] = Name",
        "--------------------------------------------------",
        "",
        "WeintCodex = WeintCodex or {}",
        "WeintCodex.RecipeSources = {",
        '    source = { kind = "community", label = "Herkunft der Rezepte: Wissensstand der Community" },',
        "    r = {",
    ]
    for i, (v, d, o, q, world) in sorted(rows.items()):
        out.append("        [%d] = %s," % (i, Q.lua_str("\t".join([Q.csv(v), Q.csv(d), Q.csv(o), Q.csv(q), "w" if world else ""]))))
    out.append("    },")
    out.append("    n = {")
    for i in sorted(need_npc):
        n = npcs.get(i, {})
        name = nde.get(i) or Q.text(n.get(1)) or "?"
        fr = Q.text(n.get(N_FRIENDLY)) or ""
        out.append("        [%d] = %s," % (i, Q.lua_str("\t".join([Q.text(name), place(n.get(N_SPAWNS)), fr if isinstance(fr, str) else ""]))))
    out.append("    },")
    out.append("    o = {")
    for i in sorted(need_obj):
        out.append("        [%d] = %s," % (i, Q.lua_str(Q.text(ode.get(i) or objs.get(i, {}).get(1) or "?"))))
    out.append("    },")
    out.append("    q = {")
    for i in sorted(need_q):
        out.append("        [%d] = %s," % (i, Q.lua_str(Q.text(qde.get(i) or quests.get(i, {}).get(1) or "?"))))
    out.append("    },")
    out.append("}")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print(len(rows), "Gegenstaende,", len(need_npc), "NPCs")


if __name__ == "__main__":
    main()
