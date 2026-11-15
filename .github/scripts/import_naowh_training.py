#!/usr/bin/env python3
"""Zauber, die man ueber Quests lernt, aus Naowh Forever "Training".

    python3 -I .github/scripts/import_naowh_training.py <NaowhForever_Training-Ordner>

Liest Data/TrainingData.lua (Naowh: aus dem Client-Build, Preise von What's
Training) und schreibt data/trainer_quests.lua: je Klasse die Eintraege mit
`quest = true`, die der Lehrerbestand (data/trainer.lua) NICHT fuehrt.
Nur Daten (Stufe, Zaubernummer, Rassen), kein Code. Naowh traegt keine
Lizenz - uebernommen sind Fakten, keine Texte.
"""
import os, re, sys

NF_VERSION = "1.2.33"
CLASSES = {1: "WARRIOR", 2: "PALADIN", 3: "HUNTER", 4: "ROGUE", 5: "PRIEST",
           7: "SHAMAN", 8: "MAGE", 9: "WARLOCK", 11: "DRUID"}

def main():
    src = os.path.join(sys.argv[1], "Data", "TrainingData.lua")
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    known = set(int(x) for x in re.findall(r"\bid = (\d+)", open(os.path.join(root, "data", "trainer.lua"), encoding="utf-8").read()))
    cls, out = None, {}
    for line in open(src, encoding="utf-8"):
        m = re.match(r"^    \[(\d+)\] = \{", line)
        if m:
            cls = CLASSES.get(int(m.group(1)))
            continue
        m = re.match(r"^\s+\{ (\d+), (\d+), \d+,(.*)\},", line)
        if not (m and cls and "quest = true" in m.group(3)):
            continue
        lvl, sid = int(m.group(1)), int(m.group(2))
        if sid in known:
            continue
        races = re.search(r"races = \{ ([\d, ]+) \}", m.group(3))
        out.setdefault(cls, []).append((lvl, sid, races.group(1).replace(" ", "") if races else None))
    lines = [
        "--------------------------------------------------",
        "-- WeintCodex :: Zauber, die man ueber Quests lernt",
        "--------------------------------------------------",
        "-- ERZEUGT von .github/scripts/import_naowh_training.py aus Naowh Forever",
        "-- " + NF_VERSION + " (Training, Daten aus dem Client-Build 1.60.1.70888) - nicht",
        "-- von Hand aendern. Herkunft `community`: kein Lehrer lehrt sie, eine",
        "-- Quest belohnt sie. Nur Zauber, die data/trainer.lua nicht fuehrt.",
        "-- { Stufe, Zaubernummer, Rassen (ClassicRace) oder nil }",
        "--------------------------------------------------",
        "",
        "local T = WeintCodex.TrainerData",
        "T.QUEST_SPELLS = {",
    ]
    total = 0
    for c in sorted(out):
        lines.append("    %s = {" % c)
        for lvl, sid, races in sorted(out[c]):
            total += 1
            lines.append("        { %d, %d%s }," % (lvl, sid, ", { %s }" % races.replace(",", ", ") if races else ""))
        lines.append("    },")
    lines.append("}")
    open(os.path.join(root, "data", "trainer_quests.lua"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print(total, "Zauber ueber Quests")

main()
