#!/usr/bin/env python3
"""Erzeugt data/loot.lua (Seite "Beute") aus fremden DATEN.

Quelle: AtlasLootClassic fuer Forever (GPL-2.0). Gelesen werden nur die
Datendateien - Bosse, Gegenstandsnummern, Dropraten, Setlisten -, nie Code
oder Grafik:

  AtlasLootClassic_DungeonsAndRaids/data.lua      Dungeons, Schlachtzuege
  AtlasLootClassic_DungeonsAndRaids/forever.lua   ergaenzt fehlende Instanzen
  AtlasLootClassic_DungeonsAndRaids/droprate.lua  Dropchance je NPC
  AtlasLootClassic_DungeonsAndRaids/Locales/constants.de.lua, AtlasLootClassic/
      Locales/constants.de.lua                    deutsche Bossnamen
  AtlasLootClassic_Factions/data.lua              Ruf-Belohnungen
  AtlasLootClassic_PvP/data.lua                   PvP-Belohnungen
  AtlasLootClassic_Collections/data.lua           Sets (nur die Set-Tabellen)
  AtlasLootClassic/Data/ItemSet.lua               Gegenstaende je Set

TBC-, Wrath- und SoD-Dateien bleiben aussen vor. Die Dateien werden
GEPARST (ein kleiner Lua-Tokenizer), nie ausgefuehrt. Namen, Symbole und
Qualitaet der Gegenstaende stehen NICHT in der Ausgabe - die liefert der
Client zur Laufzeit.

    python3 -I .github/scripts/import_loot.py <Ordner atlas> [data/loot.lua]
"""
import os
import re
import sys

FOREVER_ITEM_MIN = 100000   # Gegenstaende ab dieser Nummer sind neu in Forever

# Deutsche Namen der Instanzen (Fallback; im Spiel nennt sie der Client
# ueber C_Map.GetAreaInfo, wenn die Gebietsnummer bekannt ist).
INSTANCE_DE = {
    "Ragefire": "Der Flammenschlund", "WailingCaverns": "Die Höhlen des Wehklagens",
    "TheDeadmines": "Die Todesminen", "ShadowfangKeep": "Burg Schattenfang",
    "BlackfathomDeeps": "Tiefschwarze Grotte", "TheStockade": "Das Verlies",
    "Gnomeregan": "Gnomeregan", "RazorfenKraul": "Kral der Klingenhauer",
    "ScarletMonasteryGraveyard": "Scharlachrotes Kloster: Friedhof",
    "ScarletMonasteryLibrary": "Scharlachrotes Kloster: Bibliothek",
    "ScarletMonasteryArmory": "Scharlachrotes Kloster: Waffenkammer",
    "ScarletMonasteryCathedral": "Scharlachrotes Kloster: Kathedrale",
    "RazorfenDowns": "Hügel der Klingenhauer", "Uldaman": "Uldaman",
    "Zul'Farrak": "Zul'Farrak", "Maraudon": "Maraudon",
    "TheTempleOfAtal'Hakkar": "Der Tempel von Atal'Hakkar",
    "BlackrockDepths": "Schwarzfelstiefen", "LowerBlackrockSpire": "Untere Schwarzfelsspitze",
    "UpperBlackrockSpire": "Obere Schwarzfelsspitze", "DireMaulEast": "Düsterbruch: Ost",
    "DireMaulWest": "Düsterbruch: West", "DireMaulNorth": "Düsterbruch: Nord",
    "Scholomance": "Scholomance", "Stratholme": "Stratholme",
    "WorldBosses": "Weltbosse", "MoltenCore": "Geschmolzener Kern",
    "Onyxia": "Onyxias Hort", "Zul'Gurub": "Zul'Gurub", "BlackwingLair": "Pechschwingenhort",
    "TheRuinsofAhnQiraj": "Ruinen von Ahn'Qiraj", "TheTempleofAhnQiraj": "Tempel von Ahn'Qiraj",
    "Naxxramas": "Naxxramas",
    "TheHallOfThanes": "Hall of Thanes", "TheRuinsOfLordaeron": "Ruins of Lordaeron",
    "ExcavationSiteWetlands": "Excavation Site", "TheCityOfDalaran": "City of Dalaran",
    "CityOfDalaran": "City of Dalaran", "TheDrownedCity": "The Drowned City",
    "KroldokStronghold": "Krol'dok Stronghold", "AlcazPrison": "Alcaz Prison",
    "BlackmawHold": "Blackmaw Hold", "ShapersTerrace": "Shaper's Terrace",
    "MountHyjal": "Hyjal Summit", "BarrowDeepsRaid": "Barrow Deeps", "OnyxiasLairNew": "Onyxias Hort (Forever)",
}
FACTION_DE = {
    "ArgentDawn": "Argentumdämmerung", "Timbermaw": "Holzschlundfeste",
    "ThoriumBrotherhood": "Thoriumbruderschaft", "CenarionCircle": "Zirkel des Cenarius",
    "ZandalarTribe": "Stamm der Zandalar", "BroodOfNozdormu": "Brut Nozdormus",
    "HydraxianWaterlords": "Hydraxianer", "BloodsailBuccaneers": "Blutsegelbukaniere",
    "WintersaberTrainers": "Wintersäblerausbilder",
}
PVP_DE = {
    "AlteracValley": "Alteractal", "WarsongGulch": "Kriegshymnenschlucht",
    "ArathiBasin": "Arathibecken", "ClassSets": "Klassensets", "Armor": "Rüstung",
    "Weapons": "Waffen", "PvPMounts": "Reittiere", "Insignia": "Insignien",
}
SETS_DE = {
    "TierSets": "Tier-Sets", "DungeonSets": "Dungeon-Sets", "ZGSets": "Sets aus Zul'Gurub",
    "AQSets": "Sets aus Ahn'Qiraj", "MiscSets": "Weitere Sets",
}
STANDING_DE = {
    "Exalted": "Ehrfürchtig", "Revered": "Respektvoll", "Honored": "Wohlwollend",
    "Friendly": "Freundlich", "Neutral": "Neutral",
    "FACTION_STANDING_LABEL8": "Ehrfürchtig", "FACTION_STANDING_LABEL7": "Respektvoll",
    "FACTION_STANDING_LABEL6": "Wohlwollend", "FACTION_STANDING_LABEL5": "Freundlich",
    "FACTION_STANDING_LABEL4": "Neutral",
    "Epic": "Episch", "Rare": "Selten", "Uncommon": "Ungewöhnlich",
}

# --------------------------------------------------------------------------
# Lua lesen, nicht ausfuehren
# --------------------------------------------------------------------------

TOKEN = re.compile(r"""
    (?P<ws>\s+)
  | (?P<lcom>--\[(?P<eq>=*)\[.*?\](?P=eq)\])
  | (?P<com>--[^\n]*)
  | (?P<lstr>\[(?P<eq2>=*)\[.*?\](?P=eq2)\])
  | (?P<str>"(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*')
  | (?P<num>0[xX][0-9a-fA-F]+|\d+\.?\d*(?:[eE][-+]?\d+)?|\.\d+)
  | (?P<name>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<op>\.\.\.|\.\.|==|~=|<=|>=|[-+*/%^#<>=(){}\[\];:,.])
""", re.S | re.X)


def tokenize(text):
    out, pos = [], 0
    while pos < len(text):
        m = TOKEN.match(text, pos)
        if not m:
            pos += 1
            continue
        pos = m.end()
        kind = m.lastgroup
        if kind in ("ws", "com", "lcom"):
            continue
        if kind in ("eq", "eq2"):
            kind = "lstr"
        val = m.group(0)
        if kind == "str":
            val = bytes(val[1:-1], "utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")
        elif kind == "num":
            val = float(int(val, 16)) if val.lower().startswith("0x") else float(val)
        out.append((kind, val))
    return out


class Opaque:
    """Ein Ausdruck, der nicht ausgewertet wird - nur seine Bausteine."""
    def __init__(self, toks):
        self.toks = toks

    def strings(self):
        return [v for k, v in self.toks if k == "str"]

    def names(self):
        return [v for k, v in self.toks if k == "name"]


class Parser:
    def __init__(self, toks):
        self.t, self.i = toks, 0

    def peek(self, o=0):
        j = self.i + o
        return self.t[j] if j < len(self.t) else (None, None)

    def take(self):
        tok = self.peek()
        self.i += 1
        return tok

    def table(self):
        assert self.take() == ("op", "{")
        arr, keyed, n = [], [], 0
        while self.peek() != ("op", "}"):
            k = self.peek()
            if k == ("op", "["):
                self.take()
                key = self.expr()
                assert self.take() == ("op", "]")
                assert self.take() == ("op", "=")
                keyed.append((key, self.expr()))
            elif k[0] == "name" and self.peek(1) == ("op", "="):
                self.take()
                self.take()
                keyed.append((k[1], self.expr()))
            else:
                arr.append(self.expr())
            if self.peek() in (("op", ","), ("op", ";")):
                self.take()
        self.take()
        return {"arr": arr, "keyed": keyed}

    def expr(self):
        """Literal, Tabelle oder ein undurchsichtiger Ausdruck bis , ; } ]"""
        k = self.peek()
        if k == ("op", "{"):
            return self.table()
        start, depth = self.i, 0
        while True:
            tok = self.peek()
            if tok[0] is None:
                break
            if depth == 0 and tok in (("op", ","), ("op", ";"), ("op", "}"), ("op", "]")):
                break
            if tok[0] == "op" and tok[1] in "([{":
                depth += 1
            elif tok[0] == "op" and tok[1] in ")]}":
                depth -= 1
            self.take()
        toks = self.t[start:self.i]
        if len(toks) == 1:
            kind, val = toks[0]
            if kind in ("num", "str"):
                return val
            if kind == "name" and val == "nil":
                return None
            if kind == "name" and val in ("true", "false"):
                return val == "true"
        if len(toks) == 2 and toks[0] == ("op", "-") and toks[1][0] == "num":
            return -toks[1][1]
        return Opaque(toks)


def data_tables(path):
    """Alle Zuweisungen data["X"] = { ... } einer Datei, in Reihenfolge."""
    toks = tokenize(open(path, encoding="utf-8").read())
    out, i = [], 0
    while i < len(toks) - 5:
        if (toks[i] == ("name", "data") and toks[i + 1] == ("op", "[") and toks[i + 2][0] == "str"
                and toks[i + 3] == ("op", "]") and toks[i + 4] == ("op", "=") and toks[i + 5] == ("op", "{")):
            p = Parser(toks)
            p.i = i + 5
            out.append((toks[i + 2][1], p.table()))
            i = p.i
        else:
            i += 1
    return out


def get(tbl, key):
    for k, v in tbl["keyed"]:
        if k == key:
            return v
    return None


def diff_lists(tbl):
    """[ (Name der Schwierigkeit, Liste) ] einer Bossgruppe."""
    out = []
    for k, v in tbl["keyed"]:
        if isinstance(k, Opaque) and isinstance(v, dict):
            names = k.names()
            if names:
                out.append((names[0], v))
    return out


def load_locale(paths):
    loc = {}
    for p in paths:
        if not os.path.exists(p):
            continue
        for m in re.finditer(r'AL\["((?:\\.|[^"\\])*)"\]\s*=\s*"((?:\\.|[^"\\])*)"', open(p, encoding="utf-8").read()):
            loc[m.group(1).replace('\\"', '"')] = m.group(2).replace('\\"', '"').strip()
    return loc


def label(expr, loc, fallback=""):
    """Anzeigename aus einem Namensausdruck: AL["x"] -> deutsch, "x" -> x."""
    if isinstance(expr, str):
        return re.sub(r"\|c[0-9a-fA-F]{8}|\|r|\|T[^|]*\|t", "", expr).strip()
    if isinstance(expr, Opaque):
        names, strs = expr.names(), expr.strings()
        for key in strs:
            if key in STANDING_DE:
                return STANDING_DE[key]
        if "FACTION_STANDING_LABEL8" in str([v for _, v in expr.toks]):
            pass
        for k, v in expr.toks:
            if k == "str" and v.startswith("FACTION_STANDING_LABEL"):
                return STANDING_DE.get(v, fallback)
        if strs:
            s = strs[0]
            if "%s" in s and len(strs) > 1:
                s = s.replace("%s", strs[1])
            elif "%s" in s:
                nums = [str(int(v)) if v == int(v) else str(v) for k, v in expr.toks if k == "num"]
                if nums:
                    s = s.replace("%s", nums[0])
            return loc.get(s, s).replace("%s", "").strip()
    return fallback


def items_of(lst):
    """(Platz, Nummer) aller echten Gegenstaende einer Liste."""
    out = []
    for e in lst["arr"]:
        if not isinstance(e, dict) or len(e["arr"]) < 2:
            continue
        slot, iid = e["arr"][0], e["arr"][1]
        if isinstance(slot, float) and isinstance(iid, float) and iid > 0 and iid == int(iid):
            out.append((int(slot), int(iid)))
    out.sort(key=lambda x: x[0])
    return out


def merge_diffs(group):
    """Gegenstaende ueber alle Schwierigkeiten; nur einer Fraktion: a/h."""
    seen, order = {}, []
    for dname, lst in diff_lists(group):
        flag = "a" if dname == "ALLIANCE_DIFF" else "h" if dname == "HORDE_DIFF" else ""
        for _, iid in items_of(lst):
            if iid not in seen:
                seen[iid] = set()
                order.append(iid)
            seen[iid].add(flag or "*")
    out = []
    for iid in order:
        f = seen[iid]
        out.append((iid, "" if "*" in f or ("a" in f and "h" in f) else ("a" if "a" in f else "h")))
    return out


def load_droprates(path):
    rates, npc = {}, None
    if not os.path.exists(path):
        return rates
    for line in open(path, encoding="utf-8"):
        m = re.match(r"\s*\[(\d+)\]\s*=\s*\{\s*$", line)
        if m:
            npc = int(m.group(1))
            rates[npc] = {}
            continue
        m = re.match(r"\s*\[(\d+)\]\s*=\s*([\d.]+)", line)
        if m and npc is not None:
            rates[npc][int(m.group(1))] = float(m.group(2))
    return rates


def load_itemsets(path):
    sets = {}
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{\s*\{([\d,\s]+)\}[^\n]*?--\s*([^\n]+)", open(path, encoding="utf-8").read()):
        sid = int(m.group(1))
        if sid not in sets:
            sets[sid] = ([int(x) for x in m.group(2).split(",") if x.strip()], m.group(3).strip())
    return sets


def rate_text(r):
    if r >= 10:
        return str(int(round(r)))
    s = ("%.1f" % r) if r >= 1 else ("%.2f" % r)
    return s.rstrip("0").rstrip(".") or "0"


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


# --------------------------------------------------------------------------

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    root = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else "data/loot.lua"
    dr = os.path.join(root, "AtlasLootClassic_DungeonsAndRaids")
    loc = load_locale([os.path.join(root, "AtlasLootClassic", "Locales", "constants.de.lua"),
                       os.path.join(dr, "Locales", "constants.de.lua")])
    rates = load_droprates(os.path.join(dr, "droprate.lua"))
    itemsets = load_itemsets(os.path.join(root, "AtlasLootClassic", "Data", "ItemSet.lua"))

    insts = []   # (key, cat, kind, area, name, levels, bosses[(name, extra, items)])

    def add_raid_tables(path, seen_names):
        for key, t in data_tables(path):
            name = INSTANCE_DE.get(key)
            if not name or name in seen_names:
                continue
            ct = get(t, "ContentType")
            ctn = " ".join(ct.names()) if isinstance(ct, Opaque) else ""
            forever = "FOREVER" in ctn
            cat = "r" if ("RAID" in ctn or key == "WorldBosses") else "d"
            area = get(t, "MapID")
            lr = get(t, "LevelRange")
            levels = ""
            if isinstance(lr, dict):
                nums = [int(v) for v in lr["arr"] if isinstance(v, float)]
                if len(nums) >= 3:
                    levels = "%d-%d" % (nums[1], nums[2])
            elif isinstance(lr, Opaque):
                nums = [int(v) for k, v in lr.toks if k == "num"]
                if len(nums) >= 3:
                    levels = "%d-%d" % (nums[1], nums[2])
            bosses = []
            items = get(t, "items")
            for g in (items["arr"] if isinstance(items, dict) else []):
                if not isinstance(g, dict):
                    continue
                if get(g, "ExtraList") or get(g, "IgnoreAsSource"):
                    pass
                bname = label(get(g, "name"), loc)
                if not bname or "Loot will be updated" in bname:
                    continue
                npc = get(g, "npcID")
                npc = int(npc) if isinstance(npc, float) else (int(npc["arr"][0]) if isinstance(npc, dict) and npc["arr"] and isinstance(npc["arr"][0], float) else None)
                its = merge_diffs(g)
                if not its:
                    continue
                parts = []
                for iid, flag in its:
                    s = str(iid)
                    r = rates.get(npc, {}).get(iid) if npc else None
                    if r is not None:
                        s += ":" + rate_text(r)
                    parts.append(s + flag)
                bosses.append((bname, str(npc) if npc else "", ",".join(parts)))
            if bosses:
                seen_names.add(name)
                insts.append((key, cat, "community" if forever else "classic",
                              int(area) if isinstance(area, float) else 0, name, levels, bosses))

    seen = set()
    add_raid_tables(os.path.join(dr, "data.lua"), seen)
    add_raid_tables(os.path.join(dr, "forever.lua"), seen)

    # Ruf
    for key, t in data_tables(os.path.join(root, "AtlasLootClassic_Factions", "data.lua")):
        if key not in FACTION_DE:
            continue
        fid = get(t, "FactionID")
        bosses = []
        items = get(t, "items")
        for g in (items["arr"] if isinstance(items, dict) else []):
            if not isinstance(g, dict):
                continue
            its = merge_diffs(g)
            if its:
                bosses.append((label(get(g, "name"), loc, "Belohnungen"), "", ",".join(str(i) + f for i, f in its)))
        if bosses:
            insts.append((key, "f", "classic", int(fid) if isinstance(fid, float) else 0, FACTION_DE[key], "", bosses))

    # Sets: je Set ein Eintrag mit seinen Gegenstaenden
    def set_bosses(g):
        out = []
        for dname, lst in diff_lists(g):
            flag = "a" if dname == "ALLIANCE_DIFF" else "h" if dname == "HORDE_DIFF" else ""
            for _, sid in items_of(lst):
                if sid not in itemsets:
                    continue
                its, sname = itemsets[sid]
                if any(b[1] == "s%d" % sid for b in out):
                    continue
                out.append((sname, "s%d" % sid, ",".join(str(i) + flag for i in its)))
        return out

    # PvP
    for key, t in data_tables(os.path.join(root, "AtlasLootClassic_PvP", "data.lua")):
        if key not in PVP_DE:
            continue
        is_set = "SET_ITTYPE" in str([v for _, v in (get(t, "TableType").toks if isinstance(get(t, "TableType"), Opaque) else [])])
        bosses = []
        items = get(t, "items")
        for g in (items["arr"] if isinstance(items, dict) else []):
            if not isinstance(g, dict):
                continue
            gname = label(get(g, "name"), loc, PVP_DE[key])
            if is_set:
                for sname, extra, its in set_bosses(g):
                    bosses.append((sname, extra, its))
                continue
            its = merge_diffs(g)
            if its:
                bosses.append((gname, "", ",".join(str(i) + f for i, f in its)))
        if bosses:
            insts.append((key, "p", "classic", 0, PVP_DE[key], "", bosses))

    for key, t in data_tables(os.path.join(root, "AtlasLootClassic_Collections", "data.lua")):
        if key not in SETS_DE:
            continue
        bosses = []
        items = get(t, "items")
        for g in (items["arr"] if isinstance(items, dict) else []):
            if isinstance(g, dict):
                bosses.extend(set_bosses(g))
        if bosses:
            insts.append((key, "s", "classic", 0, SETS_DE[key], "", bosses))

    # Ausgabe
    n_boss = sum(len(i[6]) for i in insts)
    n_items = sum(len(b[2].split(",")) for i in insts for b in i[6])
    uniq = set()
    for i in insts:
        for b in i[6]:
            for p in b[2].split(","):
                uniq.add(re.match(r"\d+", p).group(0))
    L = []
    L.append("--------------------------------------------------")
    L.append("-- WeintCodex :: Beute - was wo faellt (Seite \"Beute\")")
    L.append("--------------------------------------------------")
    L.append("-- ERZEUGT von .github/scripts/import_loot.py - nicht von Hand aendern.")
    L.append("-- HERKUNFT (nur fuer Betreuer, im Spiel steht nur die Art):")
    L.append("--   Bosse, Gegenstandsnummern, Dropraten, Ruf-, PvP- und Setlisten:")
    L.append("--   die Datendateien von AtlasLootClassic (Forever-Fassung), Lizenz")
    L.append("--   GPL-2.0. Nur Daten, kein Code, keine Grafik; TBC/Wrath/SoD nicht.")
    L.append("--   Art `classic` fuer Classic-Inhalte, `community` fuer neue Inhalte")
    L.append("--   von Forever (Instanzen und Gegenstaende ab Nummer %d)." % FOREVER_ITEM_MIN)
    L.append("-- Namen, Symbole und Qualitaet der Gegenstaende liefert der Client.")
    L.append("-- %d Bereiche, %d Bosse/Gruppen, %d Eintraege, %d Gegenstaende." % (len(insts), n_boss, n_items, len(uniq)))
    L.append("-- FORMAT:")
    L.append("--   i[n] = Schluessel, Rubrik (d Dungeon, r Schlachtzug, f Ruf, p PvP, s Sets),")
    L.append("--          Art, Gebiet/Fraktion (Nummer oder 0), Name, Stufen  (Tabulator)")
    L.append("--   b[n] = { je Boss/Gruppe: Name, NPC oder s<Set>, Gegenstaende }")
    L.append("--          Gegenstand = Nummer[:Dropchance in %][a|h nur Allianz/Horde]")
    L.append("--------------------------------------------------")
    L.append("")
    L.append("WeintCodex = WeintCodex or {}")
    L.append("WeintCodex.LootData = {")
    L.append("    FOREVER_ITEM_MIN = %d," % FOREVER_ITEM_MIN)
    L.append("    i = {")
    for key, cat, kind, area, name, levels, _ in insts:
        L.append("        " + lua_str("\t".join([key, cat, kind, str(area), name, levels])) + ",")
    L.append("    },")
    L.append("    b = {")
    for n, inst in enumerate(insts, 1):
        L.append("        [%d] = {" % n)
        for bname, extra, its in inst[6]:
            L.append("            " + lua_str("\t".join([bname, extra, its])) + ",")
        L.append("        },")
    L.append("    },")
    L.append("}")
    text = "\n".join(L) + "\n"
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write(text)
    print("%s: %d Bereiche, %d Bosse, %d Eintraege, %d Gegenstaende, %d Bytes"
          % (out_path, len(insts), n_boss, n_items, len(uniq), len(text.encode("utf-8"))))


if __name__ == "__main__":
    main()
