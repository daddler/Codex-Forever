#!/usr/bin/env python3
"""Abgleich mit dem Addon "Naowh Forever: Professions".

    python3 -I .github/scripts/import_naowh_prof.py <NaowhForever_Professions-Ordner>

Schreibt data/professions_nf.lua (erzeugt - nicht von Hand aendern) und druckt
einen Bericht. UEBERNOMMEN WERDEN NUR FAKTEN (Nummern, Stufen, Kosten, Namen
von NPCs, Lagen) - kein Code, keine Texte. Das Addon nennt keine Lizenz.

Woher das Addon seine Daten hat (nur fuer Betreuer; im Spiel steht die Art
`community`): Herkunft, Raenge und Lehrer von Hand aus Wowhead Forever, gelb/
grau aus den Clienttabellen, Reagenzien generiert.

REGELN beim Zusammenfuehren (Client vor Naowh vor Classic):
* Rezepte, die der eigene Bestand (aus dem Client) nicht kennt, kommen dazu -
  aber nur mit benannter Herkunft (Lehrer, Haendler, Beute, Quest). "unknown"
  allein reicht nicht: das sind oft Reste im Client, die man nicht bekommt.
* Ein Rezept, das der Bestand "beim Lehrer" fuehrt, Naowh aber mit Haendler,
  Beute oder Quest belegt, ist KEIN Lehrerrezept (Bericht: "angezeigt, aber
  nicht erlernbar").
* Lernstufe nur, wo der Bestand keine hat; gelb/grau bleiben aus dem Client.
* Herkunft je Rezept (Haendler mit Preis und Lage, Gegner mit Dropchance,
  Bosse, Weltbeute, Quests mit Geber, Ruf), Kosten beim Lehrer, Raenge (Kosten,
  Buecher, Quests mit Lehrern), Lehrer, die der Bestand nicht kennt,
  Haendler fuer Reagenzien und die Sammelstellen (benoetigte Fertigkeit).

Gelesen ueber .github/scripts/nf_prof_dump.lua (Datendateien in leerer
Umgebung).
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "professions_nf.lua")
LINE = {171: "alchemy", 164: "blacksmithing", 333: "enchanting", 202: "engineering", 165: "leatherworking",
        197: "tailoring", 186: "mining", 182: "herbalism", 393: "skinning", 185: "cooking", 129: "first-aid",
        356: "fishing"}
FAC = {"A": "Alliance", "H": "Horde"}


def lua(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def num(v):
    if v is None:
        return ""
    if isinstance(v, float) and v.is_integer():
        v = int(v)
    return str(v)


def ours():
    """Rezepte des Bestands: Zauber -> (Beruf, Lernstufe, Lehrer?)."""
    out = {}
    for fn in ("professions.lua", "professions_su.lua"):
        src = open(os.path.join(ROOT, "data", fn), encoding="utf-8").read()
        for key, body in re.findall(r'\["([a-z-]+)"\] = \[\[\n(.*?)\]\]', src, re.S):
            for line in body.strip().split("\n"):
                f = line.split("|")[0].split()
                if len(f) >= 8 and f[0].isdigit():
                    out[int(f[0])] = (key, None if f[2] == "-" else int(f[2]), "t" in f[7])
    return out


def npc(v):
    # [npc, Name, Fraktion, Karte, x, y, (Preis)]
    return "\t".join([num(v[0]), v[1], v[2] or "", num(v[3]), num(v[4]), num(v[5])])


def sources(r):
    rows = []
    for v in r.get("vendors") or []:
        rows.append("v\t" + npc(v) + "\t" + num(v[6] if len(v) > 6 else None))
    for s in r.get("sellers") or []:
        rows.append("s\t" + "\t".join([s[0], s[1] or "", num(s[3] if len(s) > 3 else None)]))
    for d in r.get("drops") or []:
        rows.append("d\t" + "\t".join([d[0], num(d[1]), num(d[2]), num(d[3]), num(d[4])]))
    for b in r.get("bosses") or []:
        rows.append("b\t" + b[0])
    if r.get("world"):
        rows.append("w\t" + num(r["world"]))
    if r.get("mobs"):
        rows.append("m\t" + num(r["mobs"]))
    if r.get("chests"):
        rows.append("c")
    for q in r.get("quests") or []:
        n = q.get("npc") or [None, "", "", None, None, None]
        rows.append("q\t" + "\t".join([num(q.get("id")), q.get("name") or "", num(q.get("level")), q.get("side") or "",
                                       npc(n)]))
    if r.get("rep"):
        rows.append("r\t" + r["rep"])
    if r.get("cost"):
        rows.append("k\t" + num(r["cost"]))
    return "\n".join(rows)


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    folder = sys.argv[1]
    raw = subprocess.run(["lua5.1", os.path.join(ROOT, ".github", "scripts", "nf_prof_dump.lua"),
                          os.path.join(folder, "Data")], check=True, capture_output=True, text=True).stdout
    d = json.loads(raw)
    have = ours()
    reag = d["prof"].get("RecipeReagents", {})
    names = d["prof"].get("VendorSellerNames", [])

    add, fix, src, ranks, trainers = {}, {}, {}, {}, {}
    stats = {"added": 0, "skipped_unknown": 0, "not_trainer": 0, "learn": 0, "sources": 0, "trainers": 0}
    for line, p in d["recipes"].items():
        key = LINE.get(int(line))
        if not key:
            continue
        known_tr = set()
        for r in p.get("recipes") or []:
            s = r["spell"]
            text = sources(r)
            if text:
                src[s] = text
                stats["sources"] += 1
            h = have.get(s)
            source = r.get("source")
            if h is None:
                if source in (None, "unknown") or not r.get("item"):
                    stats["skipped_unknown"] += 1
                    continue
                parts = []
                rr = reag.get(str(s)) or []
                for i in range(0, len(rr) - 1, 2):
                    parts.append("%d:%d" % (rr[i], rr[i + 1]))
                head = " ".join([str(s), num(r["item"]), num(r.get("skill")) or "-", num(r.get("yellow")) or "-", "-",
                                 num(r.get("grey")) or "-", "x", "t" if source == "trainer" else "-",
                                 num(r.get("recipe")) or "-", "-"])
                add.setdefault(key, []).append(head + "|" + ",".join(parts) + "|")
                stats["added"] += 1
                continue
            f = {}
            if h[2] and source in ("vendor", "drop", "quest") and text:
                f["t"] = 0
                stats["not_trainer"] += 1
            if not h[2] and source == "trainer":
                f["t"] = 1
            if h[1] is None and r.get("skill") is not None:
                f["l"] = r["skill"]
                stats["learn"] += 1
            if f:
                fix[s] = f
        ranks[key] = p.get("ranks") or []
        trainers[key] = p.get("trainers") or []

    # Lehrer, die der Bestand nicht kennt
    src_prof = open(os.path.join(ROOT, "data", "professions.lua"), encoding="utf-8").read()
    known_npc = {int(x) for x in re.findall(r"\{ (\d+), \"", src_prof[src_prof.index("P.TRAINERS"):src_prof.index("P.VENDORS")])}
    new_tr = {}
    for key, lst in trainers.items():
        for t in lst:
            if t[0] not in known_npc:
                new_tr.setdefault(key, []).append(t)
                stats["trainers"] += 1

    out = [
        "--------------------------------------------------",
        "-- WeintCodex :: Berufe - Abgleich mit Naowh Forever: Professions",
        "--------------------------------------------------",
        "-- ERZEUGT von .github/scripts/import_naowh_prof.py - nicht von Hand aendern.",
        "-- Nur Fakten (Nummern, Stufen, Kosten, NPC-Namen, Lagen), Art `community`.",
        "-- Gelesen von modules/professions.lua (Client vor diesem Abgleich vor Classic).",
        "--",
        "-- NF_ADD[Beruf]   Rezepte, die der Bestand nicht kennt (Zeilen wie P.RAW)",
        "-- NF_FIX[Zauber]  { t = 0/1 Lehrer ja/nein, l = Lernstufe }",
        "-- NF_SRC[Zauber]  Herkunft, je Zeile: v Haendler (npc, Name, Fraktion, Karte, x, y, Preis),",
        "--                 s Haendler ohne Lage (Name, Fraktion, Preis), d Gegner (Name, npc,",
        "--                 Stufe von, bis, Chance %), b Boss, w Weltbeute (Zahl der Gegner),",
        "--                 m Zahl der Gegner, c auch aus Truhen, q Quest (id, Name, Stufe, Seite,",
        "--                 Geber wie v), r Ruf, k Kosten beim Lehrer (Kupfer)",
        "-- NF_RANKS[Beruf] Raenge: cap, skill, cost, item (Buch), level, quest {A,H},",
        "--                 vendors/teachers { npc, Name, Fraktion, Karte, x, y, Preis }",
        "-- NF_TRAINERS[Beruf] Lehrer, die der Bestand nicht kennt { npc, Name, Fraktion, Karte, x, y }",
        "-- NF_REAGENT_VENDORS[Gegenstand] = { Preis (Kupfer) oder false, Haendlernamen... }",
        "-- NF_NODES[Name] = { Art, Fertigkeit, Gegenstand }",
        "--------------------------------------------------",
        "",
        "WeintCodex = WeintCodex or {}",
        "WeintCodex.ProfessionData = WeintCodex.ProfessionData or {}",
        "local P = WeintCodex.ProfessionData",
        "",
        'P.NF_SOURCE = { kind = "community", label = "Herkunft, Kosten und Ränge: Wissensstand der Community" }',
        "",
        "P.NF_ADD = {",
    ]
    for key in sorted(add):
        out.append("    [%s] = [[" % lua(key))
        out.extend(add[key])
        out.append("]],")
    out.append("}")
    out.append("")
    out.append("P.NF_FIX = {")
    for s in sorted(fix):
        out.append("    [%d] = { %s }," % (s, ", ".join("%s = %s" % (k, num(v)) for k, v in sorted(fix[s].items()))))
    out.append("}")
    out.append("")
    out.append("P.NF_SRC = {")
    for s in sorted(src):
        esc = src[s].replace("\\", "\\\\").replace('"', '\\"').replace("\t", "\\t").replace("\n", "\\n")
        out.append('    [%d] = "%s",' % (s, esc))
    out.append("}")
    out.append("")

    def ntab(v, price=False):
        cells = [num(v[0]), lua(v[1]), lua(FAC.get(v[2], "")) if v[2] in FAC else "false", num(v[3]), num(v[4]), num(v[5])]
        if price:
            cells.append(num(v[6]) if len(v) > 6 and v[6] is not None else "false")
        return "{ " + ", ".join(c if c != "" else "false" for c in cells) + " }"

    out.append("P.NF_RANKS = {")
    for key in sorted(ranks):
        out.append("    [%s] = {" % lua(key))
        for r in ranks[key]:
            cells = ["cap = %s" % num(r.get("cap")), "skill = %s" % num(r.get("skill"))]
            for k in ("cost", "item", "level"):
                if r.get(k) is not None:
                    cells.append("%s = %s" % (k, num(r[k])))
            q = r.get("quest")
            if q:
                cells.append("quest = { A = %s, H = %s }" % (num(q.get("A")) or "false", num(q.get("H")) or "false"))
            if r.get("questName"):
                cells.append("questName = %s" % lua(r["questName"]))
            if r.get("vendors"):
                cells.append("vendors = { " + ", ".join(ntab(v, True) for v in r["vendors"]) + " }")
            if r.get("teachers"):
                cells.append("teachers = { " + ", ".join(ntab(v) for v in r["teachers"]) + " }")
            out.append("        { " + ", ".join(cells) + " },")
        out.append("    },")
    out.append("}")
    out.append("")
    out.append("P.NF_TRAINERS = {")
    for key in sorted(new_tr):
        out.append("    [%s] = { %s }," % (lua(key), ", ".join(ntab(t) for t in new_tr[key])))
    out.append("}")
    out.append("")
    prices = d["prof"].get("VendorPrices", {})
    sellers = d["prof"].get("VendorSellers", {})
    out.append("P.NF_REAGENT_VENDORS = {")
    for item in sorted(set(list(d["prof"].get("VendorReagents", {}).keys()) + list(sellers.keys())), key=int):
        who = [names[i - 1] for i in sellers.get(item, []) if 0 < i <= len(names)]
        price = prices.get(item)
        out.append("    [%s] = { %s%s }," % (item, num(price) if price is not None else "false",
                                            "".join(", " + lua(n) for n in who)))
    out.append("}")
    out.append("")
    out.append("P.NF_NODES = {")
    for n, v in sorted(d["prof"].get("GatherNodes", {}).items()):
        out.append("    [%s] = { %s, %s, %s }," % (lua(n), lua(v[0]), num(v[1]) or "false", num(v[2]) if len(v) > 2 else "false"))
    out.append("}")
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out) + "\n")
    print(json.dumps(stats))


if __name__ == "__main__":
    main()
