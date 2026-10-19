#!/usr/bin/env python3
"""Erzeugt data/beasts.lua (Wildtierkunde des Jaegers) aus fremden DATEN.

Liest drei Datendateien eines Jaeger-Addons fuer Forever - nur deren Daten,
nie Code oder Grafik (der Code dieses Addons ist "All rights reserved", die
Datendateien sind es ausdruecklich nicht und stehen unter den Lizenzen ihrer
Quellen):

  Forever/Beasts.lua         Tierliste, Familie, Stufe, Rang, Angriffstempo
                             (cMaNGOS classic-db, GPL-3.0), Lagen der Spawns
                             (pfQuest, MIT; einige warcraft.wiki.gg CC BY-SA
                             4.0, QuestieDB GPL-3.0), neue Tiere von Forever
                             (von Hand und EG Link, CC BY 4.0), gelehrte
                             Faehigkeiten (Blizzards Client-Tabellen).
  Forever/Data.lua           Familien und Faehigkeiten mit den Stufen je Rang
                             (Blizzards Client-Tabellen).
  Forever/Locales/deDE.lua   deutsche Namen (Client-Tabellen, pfQuest).

Die Dateien werden GEPARST (regulaere Ausdruecke), nie ausgefuehrt.

    python3 -I .github/scripts/import_beasts.py <Ordner Forever> [data/beasts.lua]
"""
import os
import re
import sys

# Klassische uiMapIDs der Gebiete (Classic/Forever-Client). Gebiete ohne
# Nummer (Instanzen, neue Inseln) behalten ihren Namen, bekommen aber keine
# Kartenpunkte - eine geratene Kartennummer zeichnete an falscher Stelle.
MAPS = {
    "Durotar": 1411, "Mulgore": 1412, "The Barrens": 1413, "Alterac Mountains": 1416,
    "Arathi Highlands": 1417, "Badlands": 1418, "Blasted Lands": 1419,
    "Tirisfal Glades": 1420, "Silverpine Forest": 1421, "Western Plaguelands": 1422,
    "Eastern Plaguelands": 1423, "Hillsbrad Foothills": 1424, "The Hinterlands": 1425,
    "Dun Morogh": 1426, "Searing Gorge": 1427, "Burning Steppes": 1428,
    "Elwynn Forest": 1429, "Deadwind Pass": 1430, "Duskwood": 1431, "Loch Modan": 1432,
    "Redridge Mountains": 1433, "Stranglethorn Vale": 1434, "Swamp of Sorrows": 1435,
    "Westfall": 1436, "Wetlands": 1437, "Teldrassil": 1438, "Darkshore": 1439,
    "Ashenvale": 1440, "Thousand Needles": 1441, "Stonetalon Mountains": 1442,
    "Desolace": 1443, "Feralas": 1444, "Dustwallow Marsh": 1445, "Tanaris": 1446,
    "Azshara": 1447, "Felwood": 1448, "Un'Goro Crater": 1449, "Moonglade": 1450,
    "Silithus": 1451, "Winterspring": 1452, "Stormwind City": 1453, "Orgrimmar": 1454,
    "Ironforge": 1455, "Thunder Bluff": 1456, "Darnassus": 1457, "Undercity": 1458,
    "Alterac Valley": 1459,
}
MAX_SPOTS = 10  # je Tier und Gebiet: genug fuer die Karte, klein im Speicher


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def block(text, name):
    """Inhalt der Tabelle `name = { ... }` (Klammern gezaehlt)."""
    m = re.search(r"\b" + re.escape(name) + r"\s*=\s*\{", text)
    if not m:
        return ""
    i, depth = m.end(), 1
    while depth and i < len(text):
        c = text[i]
        if c == '"':
            i += 1
            while text[i] != '"':
                i += 2 if text[i] == "\\" else 1
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        i += 1
    return text[m.end():i - 1]


def pairs(body):
    return dict(re.findall(r'\[\s*"((?:[^"\\]|\\.)*)"\s*\]\s*=\s*"((?:[^"\\]|\\.)*)"', body))


def main():
    src = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else "data/beasts.lua"
    beasts_txt = open(os.path.join(src, "Beasts.lua"), encoding="utf-8").read()
    data_txt = open(os.path.join(src, "Data.lua"), encoding="utf-8").read()
    de_txt = open(os.path.join(src, "Locales", "deDE.lua"), encoding="utf-8").read()

    de_fam = pairs(block(de_txt, "families"))
    de_abil = pairs(block(de_txt, "abilities"))
    de_zone = pairs(block(de_txt, "zones"))
    de_beast = {int(k): v for k, v in re.findall(r'\[(\d+)\]\s*=\s*"((?:[^"\\]|\\.)*)"', block(de_txt, "beasts"))}

    # Familien: Name, Symbol, Faehigkeiten.
    families = []
    for line in block(data_txt, "PD.Families").splitlines():
        m = re.search(r'name = "([^"]+)", icon = "([^"]+)".*abilities = \{([^}]*)\}', line)
        if m:
            families.append((m.group(1), m.group(2), re.findall(r'"([^"]+)"', m.group(3))))
    fam_index = {f[0]: i + 1 for i, f in enumerate(families)}

    # Faehigkeiten: Stufen je Rang.
    abilities = []
    for m in re.finditer(r'\["([^"]+)"\] = \{ icon = (\d+),(?: new = true,)? ranks = \{([^}]*(?:\}[^}]*)*?)\} \}',
                         block(data_txt, "PD.Abilities")):
        abilities.append((m.group(1), int(m.group(2)), [int(x) for x in re.findall(r"R\((\d+)\)", m.group(3))]))
    ab_index = {a[0]: i + 1 for i, a in enumerate(abilities)}

    # Spawns.
    spots = {}
    for m in re.finditer(r'^\s*\["((?:[^"\\]|\\.)*)"\] = \{(.*)\},?\s*$', block(beasts_txt, "PD.Spots"), re.M):
        per = {}
        for z, pts in re.findall(r'\["([^"]+)"\]=\{((?:\{[^}]*\},?)*)\}', m.group(2)):
            per[z] = [(float(a), float(b)) for a, b in re.findall(r"\{([\d.]+),([\d.]+)\}", pts)]
        spots[m.group(1)] = per

    zones, zone_index = [], {}

    def zid(name):
        if name not in zone_index:
            zones.append(name)
            zone_index[name] = len(zones)
        return zone_index[name]

    rows, spot_rows, counts = [], [], {}
    for line in block(beasts_txt, "PD.BeastList").splitlines():
        m = re.match(r'\s*\{ id = (\d+), n = "((?:[^"\\]|\\.)*)", f = "([^"]+)", l = (nil|"[^"]*"), '
                     r'z = \{([^}]*)\}, s = ([\d.]+|nil)(.*)\},?\s*$', line)
        if not m:
            continue
        nid, en, fam, lvl, zl, swing, rest = m.groups()
        nid = int(nid)
        lvl = "" if lvl == "nil" else lvl.strip('"')
        swing = "" if swing == "nil" else ("%g" % float(swing))
        flags = ("r" if "rare = true" in rest else "") + ("e" if "elite = true" in rest else "") \
            + ("n" if "new = true" in rest else "")
        zlist = re.findall(r'"([^"]+)"', zl)
        taught = []
        tm = re.search(r"t = \{([^}]*)\}", rest)
        if tm:
            for a, r in re.findall(r'\["([^"]+)"\] = (\d+)', tm.group(1)):
                if a in ab_index:
                    taught.append("%d:%s" % (ab_index[a], r))
        name = de_beast.get(nid, en)
        fi = fam_index.get(fam)
        if not fi:
            continue
        counts[fam] = counts.get(fam, 0) + 1
        rows.append((fi, name, "        [%d] = %s," % (nid, lua_str("\t".join([
            str(fi), name, lvl, flags, swing, ",".join(str(zid(z)) for z in zlist), ",".join(taught)])))))
        parts = []
        for z, pts in sorted(spots.get(en, {}).items()):
            base = z.split("#")[0]
            if base not in MAPS or not pts:
                continue
            step = max(1, len(pts) / MAX_SPOTS)
            pick = [pts[int(i * step)] for i in range(min(MAX_SPOTS, len(pts)))]
            parts.append("%d:%s" % (zid(base), "".join("%03d%03d" % (min(999, round(x * 1000)), min(999, round(y * 1000)))
                                                       for x, y in pick)))
        if parts:
            spot_rows.append("        [%d] = %s," % (nid, lua_str(";".join(parts))))

    rows.sort(key=lambda r: (r[0], r[1]))
    o = []
    o.append("--------------------------------------------------")
    o.append("-- WeintCodex :: Wildtierkunde - zaehmbare Tiere fuer Jaeger")
    o.append("--------------------------------------------------")
    o.append("-- ERZEUGT von .github/scripts/import_beasts.py - nicht von Hand aendern.")
    o.append("-- HERKUNFT (nur fuer Betreuer, im Spiel steht nur die Art):")
    o.append("--   Tierliste, Familie, Stufe, Rang, Angriffstempo: cMaNGOS classic-db")
    o.append("--     (GPL-3.0) -> Art `classic`; neue Tiere von Forever (von Hand und")
    o.append("--     EG Link von Efficient Games, CC BY 4.0) -> Art `community`.")
    o.append("--   Lagen der Spawns: pfQuest (MIT, (c) 2017-2021 Eric Mauser/Shagu),")
    o.append("--     einige warcraft.wiki.gg (CC BY-SA 4.0) und QuestieDB (GPL-3.0).")
    o.append("--   Gelehrte Faehigkeiten, Raenge, Familien, deutsche Namen: Tabellen des")
    o.append("--     Forever-Beta-Clients (Blizzard, ueber wago.tools), Tiernamen pfQuest.")
    o.append("--   Gesammelt in den Datendateien eines Jaeger-Addons fuer Forever, die")
    o.append("--   ausdruecklich nicht \"All rights reserved\" sind; dessen Code und")
    o.append("--   Grafik sind es - davon ist nichts uebernommen.")
    o.append("-- FORMAT (je Eintrag ein Text, Felder durch Tabulator):")
    o.append("--   b[NPC] = Familie, Name, Stufe, Merkmale (r selten, e Elite, n neu in")
    o.append("--            Forever), Angriffstempo, Gebiete (Nummern in Z), Lehrt")
    o.append("--            (Faehigkeit:Rang durch Komma)")
    o.append("--   s[NPC] = je Gebiet \"Z:xxxyyy...\" durch \";\" (Lage in Tausendsteln)")
    o.append("--   F[i] = { key, Name, Symbol, { Faehigkeiten } }, A[i] = { key, Name, Symbol, { Stufe je Rang } }")
    o.append("--   Z[i] = { Name, uiMapID oder false }")
    o.append("--------------------------------------------------")
    o.append("")
    o.append("WeintCodex = WeintCodex or {}")
    o.append("WeintCodex.BeastData = {")
    o.append("    F = {")
    for key, icon, abl in families:
        o.append("        { %s, %s, %s, { %s } }," % (lua_str(key), lua_str(de_fam.get(key, key)), lua_str(icon),
                                                  ", ".join(str(ab_index[a]) for a in abl if a in ab_index)))
    o.append("    },")
    o.append("    A = {")
    for key, icon, ranks in abilities:
        o.append("        { %s, %s, %d, { %s } }," % (lua_str(key), lua_str(de_abil.get(key, key)), icon,
                                                  ", ".join(str(r) for r in ranks)))
    o.append("    },")
    o.append("    Z = {")
    for z in zones:
        o.append("        { %s, %s }," % (lua_str(de_zone.get(z, z)), MAPS.get(z, "false")))
    o.append("    },")
    o.append("    b = {")
    o.extend(r[2] for r in rows)
    o.append("    },")
    o.append("    s = {")
    o.extend(spot_rows)
    o.append("    },")
    o.append("}")
    with open(out, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(o) + "\n")
    print("%d Tiere, %d mit Lagen, %d Familien, %d Faehigkeiten, %d Gebiete -> %s (%d Bytes)" % (
        len(rows), len(spot_rows), len(families), len(abilities), len(zones), out, os.path.getsize(out)))


if __name__ == "__main__":
    main()
