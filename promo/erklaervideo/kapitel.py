"""Kapitelverzeichnis fuer YouTube aus timeline.json: python3 kapitel.py > ../out/kapitel.txt"""
import json
NAMES = {"intro": "Was ist WeintCodex?", "install": "Installation & erster Start", "window": "Das Hauptfenster",
         "dungeons": "Dungeons", "loot": "Beute & Wunschliste", "character": "Charakter, Lehrer, Taschen",
         "professions": "Berufe & Gewinn", "auction": "Auktionspreise", "map": "Karte & Questpfeil",
         "gathering": "Sammeln & Angeln", "flight": "Fliegen", "sleepingbag": "Entdecken: Bücher & Schlafsack",
         "comfort": "Komfort-Oberfläche", "group": "Gruppe & Gilde", "outro": "Zum Schluss"}
for s in json.load(open("timeline.json"))["scenes"]:
    t = int(s["start"] + (0.5 if s["start"] else 0))
    print(f"{t // 60:02d}:{t % 60:02d} {NAMES[s['key']]}")
