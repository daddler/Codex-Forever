#!/usr/bin/env python3
"""Abgleich der Berufe mit dem Addon "SkillUp Forever" (1.9.0.0).

Aufruf (im Wurzelordner des Repos):

    python3 .github/scripts/import_skillup.py <SkillUpForever-Ordner>

Schreibt data/professions_su.lua (erzeugt - nicht von Hand aendern) und
druckt einen Bericht.

UEBERNOMMEN WERDEN NUR FAKTEN, kein Code (das Addon steht unter GPL-3.0,
seine Daten sind Zahlen aus den Clienttabellen):

* Farbschwellen der Rezepte (Data/Thresholds.lua). Das Addon liest sie aus
  den Clienttabellen von Forever (wago.tools, SkillLineAbility, Build
  1.60.1.70707) - neuer als der Stand von data/professions.lua (Build 1.60.1
  ueber ForeverGuide). Uebernommen: Gelb und Grau, wo sie abweichen, und
  Gruen immer so, wie der Client es rechnet: abgerundet (Gelb + Grau) / 2
  (der alte Bestand rundete auf). "Lernen" nur, wo der alte Bestand
  unmoeglich ist (ueber Gelb) - das Addon setzt dort oft den Platzhalter 1
  des Clients, und der waere fuer den Planer falsch.
* Raenge je Beruf (Data/Trainer.lua TrainerRanks/RankQuests,
  Data/Recipes.lua RankBooks): Obergrenze, woher (Lehrer, Buch beim
  Haendler, Quest je Seite), noetige Fertigkeit und Stufe. Herkunft dort:
  CMaNGOS classic-db - im Spiel Art `classic`.

Nicht uebernommen: Rezepte, die nur das Addon kennt (die vier "Lehrer"-
Rezepte darunter sind die alten Heiltraenke der Alchemie, die Forever in die
Erste Hilfe verschoben hat), Preise, Lehrergebuehren, Wege.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SU_VERSION = "0.20.3"
OUT = os.path.join(ROOT, "data", "professions_su.lua")


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def codex_recipes():
    """spell -> (key, learn, yellow, green, grey) aus data/professions.lua."""
    text = read(os.path.join(ROOT, "data", "professions.lua"))
    out = {}
    for key, body in re.findall(r'\["([\w-]+)"\]\s*=\s*\[\[(.*?)\]\]', text, re.S):
        for line in body.strip().splitlines():
            f = line.split("|")[0].split()
            if len(f) < 6:
                continue
            vals = [None if x == "-" else int(x) for x in f[2:6]]
            out[int(f[0])] = (key, *vals)
    return out


def skillup_thresholds(folder):
    text = read(os.path.join(folder, "Data", "Thresholds.lua"))
    m = re.search(r"Source: (.*)", text)
    src = m.group(1).strip() if m else "?"
    t = {}
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*\}", text):
        t[int(m.group(1))] = tuple(int(x) for x in m.groups()[1:])
    return t, src


def table(text, name):
    """Inhalt von `ns.<name> = { ... }` (zwei Ebenen)."""
    m = re.search(r"ns\." + name + r"\s*=\s*\{(.*?)\n\}", text, re.S)
    return m.group(1) if m else ""


def skillup_ranks(folder):
    trainer = read(os.path.join(folder, "Data", "Trainer.lua"))
    recipes = read(os.path.join(folder, "Data", "Recipes.lua"))
    ranks = {}

    def rows(body):
        for line_id, inner in re.findall(r"\[(\d+)\]\s*=\s*\{(.*)\},?\s*$", body, re.M):
            yield int(line_id), re.findall(r"\{([^{}]*)\}", inner)

    # Wie im Addon: Quest, dann Buch, dann Lehrer - wer spaeter kommt, gilt.
    for line_id, items in rows(table(trainer, "RankQuests")):
        quests = {}
        for it in items:
            parts = [x.strip().strip('"') for x in it.split(",")]
            cap, quest, req, level, side = int(parts[0]), int(parts[1]), int(parts[2]), int(parts[3]), parts[4]
            quests.setdefault(cap, {"req": req, "level": level})[side] = quest
        for cap, q in quests.items():
            ranks.setdefault(line_id, {})[cap] = ("quest", q["req"], q["level"], 0, q.get("A", 0), q.get("H", 0))
    for line_id, items in rows(table(recipes, "RankBooks")):
        for it in items:
            cap, book, fee, req, level = (int(x) for x in it.split(","))
            ranks.setdefault(line_id, {})[cap] = ("book", req, level, book, 0, 0)
    for line_id, items in rows(table(trainer, "TrainerRanks")):
        for it in items:
            cap, fee, req, level = (int(x) for x in it.split(","))
            ranks.setdefault(line_id, {})[cap] = ("trainer", req, level, 0, 0, 0)
    return ranks


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    folder = sys.argv[1]
    if os.path.isdir(os.path.join(folder, "SkillUpForever")):
        folder = os.path.join(folder, "SkillUpForever")
    cx = codex_recipes()
    su, src = skillup_thresholds(folder)

    fixes, stats = {}, {"yellow": 0, "grey": 0, "green": 0, "learn": 0}
    for spell, (key, learn, yellow, green, grey) in sorted(cx.items()):
        if spell not in su:
            continue
        o, y, g, gr = su[spell]
        if gr <= y:
            continue
        new_learn = learn
        if learn is not None and learn > y:
            new_learn = o if 1 < o <= y else y
        if (y, g, gr, new_learn) != (yellow, green, grey, learn):
            fixes[spell] = (new_learn, y, g, gr)
            stats["yellow"] += y != yellow
            stats["grey"] += gr != grey
            stats["green"] += g != green
            stats["learn"] += new_learn != learn

    ranks = skillup_ranks(folder)

    out = []
    out.append("--------------------------------------------------")
    out.append("-- WeintCodex :: Berufe - Abgleich der Schwellen und Raenge")
    out.append("--------------------------------------------------")
    out.append("-- ERZEUGT von .github/scripts/import_skillup.py - nicht von Hand")
    out.append("-- aendern; neu erzeugen.")
    out.append("--")
    out.append(f"-- Quelle (nur fuer Betreuer): SkillUp Forever {SU_VERSION}, nur Daten.")
    out.append(f"-- Schwellen: {src}")
    out.append("-- Raenge: CMaNGOS classic-db (Lehrer, Buch, Quest) - Art `classic`.")
    out.append("--")
    out.append("-- P.SU_THRESH[Zauber] = \"Lernen Gelb Gruen Grau\" ersetzt die Zeile aus")
    out.append("-- data/professions.lua (PRO.Recipes). P.RANKS[Linie] = Raenge ueber Lehrling:")
    out.append("-- { Obergrenze, Weg, Fertigkeit, Stufe, Buch, Quest Allianz, Quest Horde }.")
    out.append("--------------------------------------------------")
    out.append("")
    out.append("WeintCodex = WeintCodex or {}")
    out.append("WeintCodex.ProfessionData = WeintCodex.ProfessionData or {}")
    out.append("local P = WeintCodex.ProfessionData")
    out.append("")
    out.append("P.SU_SOURCE = { kind = \"community\", label = \"Farbschwellen aus dem Forever-Client (Build 1.60.1.70707)\" }")
    out.append("P.RANK_SOURCE = { kind = \"classic\", label = \"Ränge der Berufe aus Classic\" }")
    out.append("")
    out.append("P.SU_THRESH = {")
    for spell, (learn, y, g, gr) in sorted(fixes.items()):
        out.append(f"    [{spell}] = \"{'-' if learn is None else learn} {y} {g} {gr}\",")
    out.append("}")
    out.append("")
    out.append("P.RANKS = {")
    for line_id in sorted(ranks):
        rows = []
        for cap in sorted(ranks[line_id]):
            how, req, level, book, qa, qh = ranks[line_id][cap]
            rows.append(f"{{ {cap}, \"{how}\", {req}, {level}, {book}, {qa}, {qh} }}")
        out.append(f"    [{line_id}] = {{ " + ", ".join(rows) + " },")
    out.append("}")
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")

    print(f"Rezepte im Codex: {len(cx)}, beim Addon: {len(su)}, gemeinsam: {len(set(cx) & set(su))}")
    print(f"Korrigiert: {len(fixes)} Rezepte - Gelb {stats['yellow']}, Grau {stats['grey']}, "
          f"Gruen {stats['green']}, Lernen {stats['learn']}")
    print(f"Raenge: {sum(len(v) for v in ranks.values())} in {len(ranks)} Berufen")
    print(f"-> {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
