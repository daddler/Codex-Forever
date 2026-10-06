#!/usr/bin/env python3
"""Abgleich mit dem Addon ForeverGuide (6.14.0.0).

Aufruf (im Wurzelordner des Repos):

    python3 .github/scripts/import_foreverguide.py <ForeverGuide-Ordner>

Schreibt zwei Dateien, beide erzeugt - nicht von Hand aendern:

    data/dungeon_journal_fg.lua   Quests mit Ketten, Orte, Eingaenge und die
                                  Beute der alten Dungeons, gegen den Bestand
                                  von data/dungeon_journal.lua abgeglichen
    data/professions.lua          Rezepte und Lehrer der Berufe

und druckt einen Bericht: was uebernommen ist, was nicht, und warum.

UEBERNOMMEN WERDEN NUR FAKTEN - Nummern, Stufen, Koordinaten, Zuordnungen,
englische Namen (der Client nennt im Spiel seine eigenen). Keine Texte,
kein Code. ForeverGuide nennt keine Lizenz; es selbst sammelt aus der
Questie-Datenbank fuer Forever, foreverchanges.pro und wowforevertalents.com
(Rezepte aus dem Client, Build 1.60.1). Gelesen wird ueber
.github/scripts/fg_dump.lua (Datendateien in leerer Umgebung) und
.github/scripts/codex_dump.lua (der eigene Bestand).
"""

import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FG_VERSION = "1.25.6"
FG_DATE = "06.10.2026"

# ForeverGuide-Schluessel -> Dungeon des Codex (Fluegel zusammengefasst).
DUNGEON_MAP = {
    "rfc": "ragefire_chasm", "thanes": "hall_of_thanes", "lordaeron": "ruins_of_lordaeron",
    "wc": "wailing_caverns", "dm": "the_deadmines", "sfk": "shadowfang_keep",
    "excavation": "excavation_site", "bfd": "blackfathom_deeps", "stocks": "the_stockade",
    "dalaran": "city_of_dalaran", "gnomer": "gnomeregan", "rfk": "razorfen_kraul",
    "smgy": "scarlet_monastery", "smlib": "scarlet_monastery", "smarm": "scarlet_monastery",
    "smcath": "scarlet_monastery", "drowned": "drowned_city", "rfd": "razorfen_downs",
    "kroldok": "kroldok_stronghold", "ulda": "uldaman", "zf": "zulfarrak", "mara": "maraudon",
    "alcaz": "alcaz_island_prison", "st": "sunken_temple", "brd": "blackrock_depths",
    "lbrs": "lower_blackrock_spire", "blackmaw": "blackmaw_hold", "dme": "dire_maul",
    "shapers": "shapers_terrace", "dmn": "dire_maul", "dmw": "dire_maul",
    "scholo": "scholomance", "stratlive": "stratholme", "stratdead": "stratholme",
    "ubrs": "upper_blackrock_spire",
}
# Gleicher Dungeon, zwei Eingaenge.
ENTRANCE_LABEL = {"stratlive": "Haupttor", "stratdead": "Dienstboteneingang"}

# Bossnamen von ForeverGuide, die anders heissen als im Codex - aber
# derselbe Kampf sind. Alles andere ohne Gegenstueck steht als "weitere
# Beute" mit seinem Namen (Truhen, seltene Gegner, Begleiter).
BOSS_ALIAS = {
    ("blackrock_depths", "Chest of The Seven"): "the_seven",
    ("stratholme", "Balnazzar"): "balnazzar",
    ("uldaman", 'Eric "The Swift"'): "the_lost_dwarves",
    ("uldaman", "Olaf"): "the_lost_dwarves",
}
BOSS_PREFIX_ALIAS = {("blackrock_depths", "Ring of Law: "): "ring_of_law"}

# Gegenstandsplatz, Englisch -> wie data/dungeon_journal.lua ihn schreibt.
SLOT_DE = {
    "Head": "Kopf", "Neck": "Hals", "Shoulder": "Schulter", "Back": "Rücken", "Chest": "Brust",
    "Shirt": "Hemd", "Tabard": "Wappenrock", "Wrist": "Handgelenke", "Hands": "Hände",
    "Waist": "Taille", "Legs": "Beine", "Feet": "Füße", "Finger": "Finger", "Trinket": "Schmuck",
    "One-Hand": "Einhändig", "Two-Hand": "Zweihändig", "Main Hand": "Waffenhand",
    "Off Hand": "Schildhand", "Held In Off-hand": "In Schildhand geführt", "Ranged": "Distanz",
    "Thrown": "Wurfwaffe", "Relic": "Relikt", "Bag": "Tasche", "Quest": "Questgegenstand",
    "Key": "Schlüssel", "Cloth": "Stoff", "Leather": "Leder", "Mail": "Schwere Rüstung",
    "Plate": "Platte", "Shield": "Schild", "Dagger": "Dolch", "Sword": "Schwert", "Axe": "Axt",
    "Mace": "Streitkolben", "Staff": "Stab", "Polearm": "Stangenwaffe",
    "Fist Weapon": "Faustwaffe", "Bow": "Bogen", "Gun": "Schusswaffe", "Crossbow": "Armbrust",
    "Wand": "Zauberstab", "Idol": "Götze", "Libram": "Buchband", "Totem": "Totem",
    "Miscellaneous": "Verschiedenes", "Consumable": "Verbrauchbar", "Reagent": "Reagenz",
    "Container": "Behälter", "Junk": "Plunder", "Trade Goods": "Handwerkswaren",
    "Blacksmithing": "Schmiedekunst (Pläne)", "Engineering": "Ingenieurskunst (Bauplan)",
    "Tailoring": "Schneiderei (Muster)", "Leatherworking": "Lederverarbeitung (Muster)",
    "Alchemy": "Alchemie (Rezept)", "Enchanting": "Verzauberkunst (Formel)",
    "Cooking": "Kochkunst (Rezept)", "First Aid": "Erste Hilfe (Handbuch)",
    "Fishing": "Angeln (Buch)", "Book": "Buch", "Projectile": "Munition", "Arrow": "Pfeil",
    "Bullet": "Kugel", "Quiver": "Köcher", "Ammo Pouch": "Munitionsbeutel",
    "Mount": "Reittier", "Other": "Sonstiges",
}

CLASS_BITS = [(1, "WARRIOR"), (2, "PALADIN"), (4, "HUNTER"), (8, "ROGUE"), (16, "PRIEST"),
              (64, "SHAMAN"), (128, "MAGE"), (256, "WARLOCK"), (1024, "DRUID")]

# Karten der Classic-Welt (UiMapID), auf denen eine Marke Sinn hat: die
# Gebiete und Hauptstaedte. Liegt ein Geber woanders (in einer Instanz),
# bekommt er keinen Ort.
WORLD_MAPS = set(range(1411, 1459))

PROFESSION_LINES = {
    "alchemy": 171, "blacksmithing": 164, "enchanting": 333, "engineering": 202,
    "leatherworking": 165, "tailoring": 197, "mining": 186, "herbalism": 182,
    "skinning": 393, "cooking": 185, "first-aid": 129, "fishing": 356,
}
PROFESSION_DE = {
    "alchemy": "Alchemie", "blacksmithing": "Schmiedekunst", "enchanting": "Verzauberkunst",
    "engineering": "Ingenieurskunst", "leatherworking": "Lederverarbeitung",
    "tailoring": "Schneiderei", "mining": "Bergbau", "herbalism": "Kräuterkunde",
    "skinning": "Kürschnerei", "cooking": "Kochkunst", "first-aid": "Erste Hilfe",
    "fishing": "Angeln",
}

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


def num(v):
    if isinstance(v, float) and v.is_integer():
        return int(v)
    return v


def as_list(v):
    if v is None:
        return []
    if isinstance(v, list):
        return v
    if isinstance(v, dict):
        return [v[k] for k in sorted(v, key=lambda k: int(k))]
    return [v]


def run_dump(script, *args):
    out = subprocess.run(["lua5.1", script, *args], cwd=ROOT, capture_output=True, text=True, check=True)
    return json.loads(out.stdout)


def slot_de(se):
    if not se:
        return None
    parts = [p.strip() for p in se.split(",")]
    out = []
    for p in parts:
        if p not in SLOT_DE:
            say(f"  ! unbekannter Platz {p!r} - englisch uebernommen")
        out.append(SLOT_DE.get(p, p))
    return ", ".join(out)


def quality_table(fg):
    q = {}
    for line in fg["CAT_DATA"].split("\n"):
        p = line.split()
        if len(p) == 8:
            q[int(p[0])] = int(p[6])
    return q


# ----------------------------------------------------------------------
# Dungeons
# ----------------------------------------------------------------------

def build_dungeons(fg, cx):
    qual = quality_table(fg)
    dq = {int(k): v for k, v in fg["DQ"].items() if re.fullmatch(r"\d+", k)}
    dnpc = {int(k): v for k, v in fg["DNPC"].items()}
    dobj = {int(k): v for k, v in fg["DOBJ"].items()}
    dritem = {int(k): v for k, v in fg["DRITEM"].items()}
    ditem = {int(k): v for k, v in fg["DITEM"].items()}
    bosses = {d["id"]: {norm(b["name"]): b["id"] for b in d["bosses"]} for d in cx["dungeons"]}
    journal = cx["journal"]
    have_quests = {qid for e in journal.values() for qid in e["quests"]}
    have_places = set(cx["places"])

    def item_name(i):
        e = dritem.get(i)
        return e["n"] if e else None

    def item_quality(i):
        if i in qual:
            return qual[i]
        e = dritem.get(i)
        return e.get("q") if e else None

    # Questie legt NPCs, die IM Dungeon stehen, auf den Eingang. Ein Punkt
    # dort waere eine Marke vor der Tuer fuer jemanden, der drinnen wartet:
    # solche Geber heissen "im Dungeon" und bekommen keinen Ort.
    entrance_spots = [(int(d["map"]), d["x"], d["y"]) for d in fg["DUNGEONS"] if d.get("map") and d.get("x")]

    def at_entrance(m, x, y):
        return any(m == em and abs(x - ex) < 0.6 and abs(y - ey) < 0.6 for em, ex, ey in entrance_spots)

    inside_count = [0]

    def place_of(entity_id, table, who=None):
        e = table.get(entity_id)
        if not e:
            return None
        sp = as_list(e.get("sp"))
        if not sp:
            return {"name": who or e["n"]}
        first = as_list(sp[0])
        m, x, y = int(first[0]), first[1], first[2]
        if at_entrance(m, x, y):
            inside_count[0] += 1
            return {"name": who or e["n"], "inside": True}
        if m not in WORLD_MAPS or not (0 < x < 100 and 0 < y < 100):
            return {"name": who or e["n"]}
        return {"name": who or e["n"], "map": m, "x": round(x / 100, 4), "y": round(y / 100, 4)}

    quests_by_dungeon, places, entrances = {}, {}, {}
    chain, chain_names = {}, {}
    skipped = {"keine Nummer": 0, "keine Stufe": 0}
    added = 0
    for d in fg["DUNGEONS"]:
        did = DUNGEON_MAP[d["key"]]
        # Eingang
        if d.get("map") and d.get("x"):
            e = {"map": int(d["map"]), "x": round(d["x"] / 100, 4), "y": round(d["y"] / 100, 4)}
            if d["key"] in ENTRANCE_LABEL:
                e["label"] = ENTRANCE_LABEL[d["key"]]
            lst = entrances.setdefault(did, [])
            if not any(abs(o["x"] - e["x"]) < 0.001 and abs(o["y"] - e["y"]) < 0.001 and o["map"] == e["map"] for o in lst):
                lst.append(e)
        for qref in as_list(d.get("q")):
            if not isinstance(qref, (int, float)):
                skipped["keine Nummer"] += 1
                continue
            qid = int(qref)
            q = dq.get(qid)
            if not q:
                continue
            # Kette auch fuer Quests, die schon im Journal stehen.
            # Nur Glieder mit Namen (aus ForeverGuide oder dem Journal) - eine
            # nackte Nummer sagt dem Spieler nichts.
            def named(p):
                return int(p) in dq or int(p) in have_quests
            prev = [int(p) for p in as_list(q.get("ps")) if isinstance(p, (int, float)) and named(p)]
            nxt = q.get("nx")
            if isinstance(nxt, (int, float)) and not named(nxt):
                nxt = None
            if prev or nxt:
                chain[qid] = {"prev": prev, "next": int(nxt) if isinstance(nxt, (int, float)) else None}
                for p in prev + ([int(nxt)] if isinstance(nxt, (int, float)) else []):
                    if p in dq:
                        chain_names[p] = dq[p]["n"]
            if qid in have_quests or any(qid == x["id"] for x in quests_by_dungeon.get(did, [])):
                continue
            if not isinstance(q.get("lv"), (int, float)):
                skipped["keine Stufe"] += 1
                continue
            rec = {"id": qid, "name": q["n"], "level": int(q["lv"])}
            if isinstance(q.get("rl"), (int, float)):
                rec["requires"] = min(int(q["rl"]), rec["level"])
            fa = q.get("fa")
            rec["faction"] = {"A": "alliance", "H": "horde"}.get(fa, "both")
            cl = q.get("cl")
            if isinstance(cl, (int, float)):
                rec["classes"] = [tok for bit, tok in CLASS_BITS if int(cl) & bit]
            giver = None
            starters = [int(s) for s in as_list(q.get("s")) if isinstance(s, (int, float))]
            objs = [int(s) for s in as_list(q.get("so")) if isinstance(s, (int, float))]
            if starters:
                giver = place_of(starters[0], dnpc)
            elif objs:
                giver = place_of(objs[0], dobj)
            if giver:
                rec["giverNpc"] = giver
                if "map" in giver and qid not in have_places:
                    places[qid] = {"map": giver["map"], "x": giver["x"], "y": giver["y"], "who": giver["name"]}
            si = q.get("si")
            if isinstance(si, (int, float)):
                rec["startItem"] = [int(si), (ditem.get(int(si)) or {}).get("n") or item_name(int(si)) or ("#" + str(int(si)))]
            finishers = [int(s) for s in as_list(q.get("f")) if isinstance(s, (int, float))]
            if finishers:
                t = place_of(finishers[0], dnpc)
                if t:
                    rec["turninNpc"] = t
            rw = q.get("rw") or {}
            if isinstance(rw.get("m"), (int, float)) and rw["m"] > 0:
                rec["money"] = int(rw["m"])
            for kind in ("c", "i"):
                lst = []
                for pair in as_list(rw.get(kind)):
                    pair = as_list(pair)
                    iid = int(pair[0])
                    lst.append([iid, item_name(iid) or ("#" + str(iid)), item_quality(iid)])
                if lst:
                    rec["choice" if kind == "c" else "fixed"] = lst
            quests_by_dungeon.setdefault(did, []).append(rec)
            added += 1

    # Beute: nur fuer Bosse, die im Journal noch keine haben.
    loot, others = {}, {}
    loot_count, other_count, noq = 0, 0, 0
    for key, lst in fg["LOOT"].items():
        did = DUNGEON_MAP[key]
        have = journal.get(did, {}).get("loot", {})
        for b in as_list(lst):
            items = as_list(b.get("items"))
            if not items:
                continue
            bid = BOSS_ALIAS.get((did, b["n"])) or bosses[did].get(norm(b["n"]))
            frm = None
            for (pd, prefix), alias in BOSS_PREFIX_ALIAS.items():
                if pd == did and b["n"].startswith(prefix):
                    bid, frm = alias, b["n"][len(prefix):]
            if bid and bid in have:
                continue
            rows = []
            for it in items:
                iid = int(it["id"])
                q = item_quality(iid)
                if q is None:
                    noq += 1
                rows.append([iid, it["n"], slot_de(it.get("se")) or "Gegenstand", q, frm])
            if bid:
                tgt = loot.setdefault(did, {}).setdefault(bid, [])
                seen = {r[0] for r in tgt}
                for r in rows:
                    if r[0] not in seen:
                        tgt.append(r)
                        seen.add(r[0])
                        loot_count += 1
            else:
                others.setdefault(did, []).append({"name": b["n"], "items": rows})
                other_count += len(rows)

    say("== Dungeons")
    say(f"  {added} Quests neu ({sum(1 for d in quests_by_dungeon)} Dungeons), "
        f"{skipped['keine Nummer']} ohne Questnummer und {skipped['keine Stufe']} ohne Stufe nicht uebernommen")
    for did in sorted(quests_by_dungeon):
        say(f"    {did}: {len(quests_by_dungeon[did])}")
    only_codex = sorted(have_quests - set(dq))
    say(f"  {len(only_codex)} Quests nur im Codex (bleiben): {only_codex}")
    say(f"  {len(chain)} Quests mit Vor- oder Folgequest, {len(chain_names)} Namen dazu")
    say(f"  {len(places)} neue Orte von Questgebern; {inside_count[0]} Geber/Abgaben im Dungeon (ohne Ort)")
    say(f"  {sum(len(v) for v in entrances.values())} Eingaenge in {len(entrances)} Dungeons")
    say(f"  Beute (Classic): {loot_count} Gegenstaende an Bossen, {other_count} weitere; "
        f"{noq} ohne Qualitaet aus den Clienttabellen")
    return {"quests": quests_by_dungeon, "places": places, "entrances": entrances, "chain": chain,
            "chain_names": chain_names, "loot": loot, "others": others}


def lua_place(p):
    s = f"name = {lua_str(p['name'])}"
    if p.get("inside"):
        s += ", inside = true"
    if "map" in p:
        s += f", map = {p['map']}, x = {p['x']}, y = {p['y']}"
    return "{ " + s + " }"


def lua_items(lst):
    out = []
    for e in lst:
        q = "nil" if e[2] is None else str(e[2])
        out.append(f"{{ {e[0]}, {lua_str(e[1])}, {q} }}")
    return "{ " + ", ".join(out) + " }"


def write_dungeons(dd):
    L = []
    w = L.append
    w("--------------------------------------------------")
    w("-- WeintCodex :: Dungeon-Journal, Abgleich mit ForeverGuide " + FG_VERSION)
    w("--------------------------------------------------")
    w("-- ERZEUGT von .github/scripts/import_foreverguide.py - nicht von Hand")
    w("-- aendern; neu erzeugen. Ergaenzt data/dungeon_journal.lua (das bleibt,")
    w("-- was es ist: handgepflegt, mit eigenen deutschen Texten).")
    w("--")
    w("-- WAS HIER STEHT, und nur das, was im Journal noch fehlte:")
    w("--   QUESTS   Nummer, Stufe, Mindeststufe, Fraktion, Klasse, Geber und")
    w("--            Abgabe (NPC mit Lage), Belohnungen, Vor- und Folgequest -")
    w("--            Fakten, keine Texte. Ein Ziel steht nicht da: das Journal")
    w("--            schreibt seine Ziele selbst, und abgeschrieben wird nicht.")
    w("--   ORTE     wo eine dieser Quests beginnt (wie J.PLACES)")
    w("--   EINGAENGE  je Dungeon, Lage auf der Weltkarte")
    w("--   BEUTE    der alten Dungeons, nur an Bossen ohne Beute im Journal.")
    w("--            Herkunft CLASSIC: die Listen stammen aus Classic (ForeverGuide")
    w("--            ueber foreverchanges.pro, Dropraten von Classic-Wowhead) -")
    w("--            Blizzard hat die Beute fuer Forever ueberarbeitet. Keine")
    w("--            Dropchance; Qualitaet aus den Clienttabellen (nil: unbekannt,")
    w("--            der Client faerbt den Namen selbst).")
    w("--")
    w("-- HERKUNFT der Quests: `community` - ForeverGuide sammelt sie aus der")
    w("-- Questie-Datenbank fuer Forever (Classic-Kartennummern wie J.PLACES).")
    w("--------------------------------------------------")
    w("")
    w("local J = WeintCodex.DungeonJournal")
    w("")
    w("J.FG_SOURCE = {")
    w('    kind  = "community",')
    w(f'    date  = "{FG_DATE}",')
    w(f'    label = "Quests: Addon ForeverGuide {FG_VERSION} (Questie-Datenbank für Forever)",')
    w("}")
    w("J.CLASSIC_LOOT_SOURCE = {")
    w('    kind  = "classic",')
    w(f'    label = "Beute aus Classic (über ForeverGuide {FG_VERSION}) – Forever hat die Beute überarbeitet",')
    w("}")
    w("")
    w("J.FG_QUESTS = {")
    for did in sorted(dd["quests"]):
        w(f"    {did} = {{")
        for q in sorted(dd["quests"][did], key=lambda q: (q["level"], q["id"])):
            parts = [f"id = {q['id']}", f"name = {lua_str(q['name'])}", f"level = {q['level']}"]
            if "requires" in q:
                parts.append(f"requires = {q['requires']}")
            parts.append(f'faction = "{q["faction"]}"')
            if q.get("classes"):
                parts.append("classes = { " + ", ".join(f'"{c}"' for c in q["classes"]) + " }")
            if q.get("giverNpc"):
                parts.append("giverNpc = " + lua_place(q["giverNpc"]))
            if q.get("turninNpc"):
                parts.append("turninNpc = " + lua_place(q["turninNpc"]))
            if q.get("startItem"):
                parts.append(f"startItem = {{ {q['startItem'][0]}, {lua_str(q['startItem'][1])} }}")
            if q.get("money"):
                parts.append(f"money = {q['money']}")
            if q.get("choice"):
                parts.append("choice = true, rewards = " + lua_items(q["choice"]))
                if q.get("fixed"):
                    parts.append("fixed = " + lua_items(q["fixed"]))
            elif q.get("fixed"):
                parts.append("rewards = " + lua_items(q["fixed"]))
            w("        { " + ", ".join(parts) + " },")
        w("    },")
    w("}")
    w("")
    w("J.FG_PLACES = {")
    for qid in sorted(dd["places"]):
        p = dd["places"][qid]
        w(f"    [{qid}] = {{ map = {p['map']}, x = {p['x']}, y = {p['y']}, who = {lua_str(p['who'])} }},")
    w("}")
    w("")
    w("-- Vor- und Folgequest (Nummern); Namen dazu fuer Quests ausserhalb des Journals.")
    w("J.CHAIN = {")
    for qid in sorted(dd["chain"]):
        c = dd["chain"][qid]
        parts = []
        if c["prev"]:
            parts.append("prev = { " + ", ".join(str(p) for p in c["prev"]) + " }")
        if c["next"]:
            parts.append(f"next = {c['next']}")
        w(f"    [{qid}] = {{ " + ", ".join(parts) + " },")
    w("}")
    w("J.CHAIN_NAMES = {")
    for qid in sorted(dd["chain_names"]):
        w(f"    [{qid}] = {lua_str(dd['chain_names'][qid])},")
    w("}")
    w("")
    w("J.ENTRANCES = {")
    for did in sorted(dd["entrances"]):
        parts = []
        for e in dd["entrances"][did]:
            s = f"map = {e['map']}, x = {e['x']}, y = {e['y']}"
            if e.get("label"):
                s += f", label = {lua_str(e['label'])}"
            parts.append("{ " + s + " }")
        w(f"    {did} = {{ " + ", ".join(parts) + " },")
    w("}")
    w("")
    w("-- { Nummer, Name, Platz, Qualitaet (nil: unbekannt), from = Gegner (optional) }")
    w("-- Je Dungeon eine Funktion: gebaut erst, wenn jemand die Beute dieses")
    w("-- Dungeons aufschlaegt (J.EnsureClassic) - als fertige Tabellen kosteten")
    w("-- alle zusammen rund 200 KB, die fast niemand je ansieht.")
    w("J.CLASSIC_LOOT = {")
    for did in sorted(dd["loot"]):
        w(f"    {did} = function() return {{")
        for bid in sorted(dd["loot"][did]):
            w(f"        {bid} = {{")
            for r in dd["loot"][did][bid]:
                q = "nil" if r[3] is None else str(r[3])
                frm = f", from = {lua_str(r[4])}" if r[4] else ""
                w(f"            {{ {r[0]}, {lua_str(r[1])}, {lua_str(r[2])}, {q}{frm} }},")
            w("        },")
        w("    } end,")
    w("}")
    w("J.CLASSIC_OTHERS = {")
    for did in sorted(dd["others"]):
        w(f"    {did} = function() return {{")
        for g in dd["others"][did]:
            w(f"        {{ name = {lua_str(g['name'])}, items = {{")
            for r in g["items"]:
                q = "nil" if r[3] is None else str(r[3])
                w(f"            {{ {r[0]}, {lua_str(r[1])}, {lua_str(r[2])}, {q} }},")
            w("        } },")
        w("    } end,")
    w("}")
    w("")
    w("J.MergeForeverGuide()")
    path = os.path.join(ROOT, "data", "dungeon_journal_fg.lua")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    say(f"  -> {os.path.relpath(path, ROOT)} ({os.path.getsize(path) // 1024} KB)")


# ----------------------------------------------------------------------
# Berufe
# ----------------------------------------------------------------------

def build_professions(fg):
    pname = {int(k): v.split("\t")[0] for k, v in fg["PNAME"].items()}
    profs, raw, names = [], {}, {}
    total, sod, nolearn = 0, 0, 0
    for p in fg["PROFS"]:
        key = p["key"]
        secs = as_list(p.get("secs"))
        lines = []
        for r in as_list(fg["PREC"].get(key)):
            if r.get("sod"):
                sod += 1
                continue
            if not isinstance(r.get("s"), (int, float)):
                continue
            total += 1

            def f(k):
                v = r.get(k)
                return str(int(v)) if isinstance(v, (int, float)) else "-"
            if f("l") == "-":
                nolearn += 1
            flags = ("t" if r.get("tr") else "") + ("b" if r.get("bop") else "")
            reag = as_list(r.get("r"))
            pairs = []
            for i in range(0, len(reag) - 1, 2):
                rid, cnt = int(reag[i]), int(reag[i + 1])
                pairs.append(f"{rid}:{cnt}")
                if rid in pname:
                    names[rid] = pname[rid]
            if isinstance(r.get("i"), (int, float)) and int(r["i"]) in pname:
                names[int(r["i"])] = pname[int(r["i"])]
            st = r.get("st") or "s"
            sec = secs[int(r["sec"]) - 1] if isinstance(r.get("sec"), (int, float)) and 0 < int(r["sec"]) <= len(secs) else "-"
            lines.append(" ".join([f("s"), f("i"), f("l"), f("y"), f("g"), f("x"), st, flags or "-",
                                   f("src"), f("mf")]) + "|" + ",".join(pairs) + "|" + r["n"])
        lines.sort(key=lambda s: (int(s.split()[2]) if s.split()[2] != "-" else 999, s.split("|")[2]))
        raw[key] = lines
        profs.append({"key": key, "spell": int(p["spell"]), "line": PROFESSION_LINES.get(key),
                      "cat": int(p.get("cat", 1)), "count": len(lines)})
    trainers = {}
    for key, lst in fg["PTRAIN"].items():
        out = []
        for t in as_list(lst):
            # Ohne gueltige Lage (Annora steht in Uldaman) bleibt der Lehrer,
            # aber ohne Karte - eine Marke bei (-1, -1) waere keine Lage.
            placed = (isinstance(t.get("m"), (int, float)) and isinstance(t.get("x"), (int, float))
                      and 0 < t["x"] < 100 and 0 < t.get("y", -1) < 100)
            out.append({"id": int(t["id"]), "name": t["n"], "map": int(t["m"]) if placed else None,
                        "x": t["x"] if placed else None, "y": t["y"] if placed else None,
                        "fr": t.get("fr"), "rk": int(t.get("rk") or 1)})
        trainers[key] = out
    vend = {}
    for iid, lst in fg["PVEND"].items():
        npcs = sorted({int(as_list(e)[0]) for e in as_list(lst)})
        vend[int(iid)] = npcs
    vnpc = {int(k): v for k, v in fg["PVNPC"].items()}
    say("== Berufe")
    say(f"  {total} Rezepte uebernommen, {sod} aus 'Season of Discovery' weggelassen, "
        f"{nolearn} ohne Lernstufe")
    for p in profs:
        say(f"    {p['key']}: {p['count']}")
    say(f"  {sum(len(v) for v in trainers.values())} Lehrer, {len(vend)} Rezepte bei Haendlern "
        f"({len(vnpc)} Haendler, Classic), {len(names)} englische Namen als Rueckfall")
    return {"profs": profs, "raw": raw, "trainers": trainers, "vend": vend, "vnpc": vnpc, "names": names}


def write_professions(pd):
    L = []
    w = L.append
    w("--------------------------------------------------")
    w("-- WeintCodex :: Berufe - Rezepte und Lehrer")
    w("--------------------------------------------------")
    w("-- ERZEUGT von .github/scripts/import_foreverguide.py - nicht von Hand")
    w("-- aendern; neu erzeugen.")
    w("--")
    w("-- HERKUNFT `community`: das Addon ForeverGuide " + FG_VERSION + " hat die Rezepte aus dem")
    w("-- Forever-Client gelesen (Build 1.60.1, ueber wowforevertalents.com) und")
    w("-- die Lehrer aus der Questie-Datenbank fuer Forever. Uebernommen sind nur")
    w("-- Fakten (Nummern, Fertigkeitsstufen, Reagenzien, Lagen). Die Haendler")
    w("-- fuer Rezepte stammen aus Classic (cmangos) und heissen so (`classic`).")
    w("-- Weggelassen: der Abschnitt \"Season of Discovery\" - im Client, ob in")
    w("-- Forever lernbar, ist nicht belegt.")
    w("--")
    w("-- REZEPTE als Zeilen, je Beruf ein Text; gelesen erst, wenn die Seite den")
    w("-- Beruf zeigt (WeintCodex.ProfessionData.Recipes):")
    w("--   Zauber Gegenstand Lernen Gelb Gruen Grau Stand Merkmale Rezept Gunst|Reagenzien|Name")
    w("--   Stand: n neu in Forever, c geaendert, s wie Classic")
    w("--   Merkmale: t beim Lehrer, b Rezept beim Aufheben gebunden; \"-\" leer")
    w("--   Reagenzien: Nummer:Anzahl, mit Komma")
    w("--------------------------------------------------")
    w("")
    w("WeintCodex = WeintCodex or {}")
    w("WeintCodex.ProfessionData = WeintCodex.ProfessionData or {}")
    w("local P = WeintCodex.ProfessionData")
    w("")
    w("P.SOURCE = {")
    w('    kind  = "community",')
    w(f'    date  = "{FG_DATE}",')
    w(f'    label = "Addon ForeverGuide {FG_VERSION}: Rezepte aus dem Forever-Client (Build 1.60.1), Lehrer aus der Questie-Datenbank",')
    w("}")
    w("P.VENDOR_SOURCE = {")
    w('    kind  = "classic",')
    w(f'    label = "Händler für Rezepte aus Classic (über ForeverGuide {FG_VERSION})",')
    w("}")
    w("")
    w("-- cat: 1 Hauptberuf (herstellend), 2 Hauptberuf (sammelnd), 3 Nebenberuf")
    w("P.PROFS = {")
    for p in pd["profs"]:
        w(f'    {{ key = "{p["key"]}", spell = {p["spell"]}, line = {p["line"]}, cat = {p["cat"]}, '
          f'name = {lua_str(PROFESSION_DE[p["key"]])} }},')
    w("}")
    w("")
    w("P.RAW = {")
    for key in [p["key"] for p in pd["profs"]]:
        w(f'    ["{key}"] = [[')
        for line in pd["raw"][key]:
            w(line)
        w("]],")
    w("}")
    w("")
    w("-- Lehrer: { npc, Name, Karte, x, y (0..100), Fraktion, Rang 1-4 }")
    w("-- Rang: bis zu welcher Stufe er lehrt (1 Lehrling 75, 2 Geselle 150,")
    w("-- 3 Experte 225, 4 Fachmann 300).")
    w("P.TRAINERS = {")
    for key in [p["key"] for p in pd["profs"]]:
        w(f'    ["{key}"] = {{')
        for t in sorted(pd["trainers"].get(key, []), key=lambda t: (-t["rk"], t["name"])):
            fr = f'"{"Alliance" if t["fr"] == "A" else "Horde"}"' if t["fr"] in ("A", "H") else "nil"
            loc = f'{t["map"]}, {t["x"]}, {t["y"]}' if t["map"] else "nil, nil, nil"
            w(f'        {{ {t["id"]}, {lua_str(t["name"])}, {loc}, {fr}, {t["rk"]} }},')
        w("    },")
    w("}")
    w("")
    w("-- Rezeptgegenstand -> Haendler (Classic)")
    w("P.VENDORS = {")
    for iid in sorted(pd["vend"]):
        w(f"    [{iid}] = {{ " + ", ".join(str(n) for n in pd["vend"][iid]) + " },")
    w("}")
    w("P.VENDOR_NPC = {")
    for nid in sorted(pd["vnpc"]):
        v = pd["vnpc"][nid]
        fr = f'"{"Alliance" if v.get("fr") == "A" else "Horde"}"' if v.get("fr") in ("A", "H") else "nil"
        if isinstance(v.get("m"), (int, float)) and isinstance(v.get("x"), (int, float)):
            w(f'    [{nid}] = {{ {lua_str(v["n"])}, {int(v["m"])}, {v["x"]}, {v["y"]}, {fr} }},')
        else:
            w(f'    [{nid}] = {{ {lua_str(v["n"])}, nil, nil, nil, {fr} }},')
    w("}")
    w("")
    w("-- Englische Namen als Rueckfall, bis der Client seine nennt.")
    w("P.NAMES = {")
    for iid in sorted(pd["names"]):
        w(f"    [{iid}] = {lua_str(pd['names'][iid])},")
    w("}")
    path = os.path.join(ROOT, "data", "professions.lua")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    say(f"  -> {os.path.relpath(path, ROOT)} ({os.path.getsize(path) // 1024} KB)")



# Voelker (Bit = 1 << (Volk - 1)), fuer den Bericht.
RACE_BITS = [(1, "Mensch"), (2, "Orc"), (4, "Zwerg"), (8, "Nachtelf"), (16, "Untoter"),
             (32, "Tauren"), (64, "Gnom"), (128, "Troll")]


def build_classquests(fg):
    q = fg["CLASS_Q"]
    npc_raw = fg["CLASS_NPC"]
    npcs = {}
    for k, v in npc_raw.items():
        f = v.split("\t")
        m = int(f[5]) if f[5] not in ("", "0") else None
        x = float(f[6]) if f[6] else None
        y = float(f[7]) if f[7] else None
        if m not in WORLD_MAPS:
            m, x, y = None, None, None
        npcs[int(k)] = {"name": f[1], "map": m, "x": x, "y": y, "fr": f[10]}
    classes = {name: [] for _, name in CLASS_BITS}
    used = set()
    nostart = noloc = spells = 0
    for k in sorted(q, key=lambda k: int(k)):
        v = q[k]
        e = {"id": int(k), "name": v["n"], "lv": num(v["lv"]), "rl": num(v["rl"])}
        if v.get("ra"):
            e["ra"] = num(v["ra"])
        for key, field in (("s", "giver"), ("e", "turnin")):
            if v.get(key):
                e[field] = num(v[key])
                if num(v[key]) in npcs:
                    used.add(num(v[key]))
        if v.get("si"):
            e["start"] = "item"
        elif v.get("so"):
            e["start"] = "object"
        if not v.get("s") and not e.get("start"):
            nostart += 1
        if v.get("s") and not (npcs.get(num(v["s"])) and npcs[num(v["s"])]["map"]):
            noloc += 1
        if v.get("pre"):
            e["pre"] = [num(x) for x in as_list(v["pre"])]
        if v.get("nx"):
            e["next"] = num(v["nx"])
        if v.get("sp"):
            e["spell"] = num(v["sp"])
            e["spellName"] = v.get("spn")
            spells += 1
        if v.get("it"):
            e["items"] = [num(x) for x in as_list(v["it"])][0::2]
        if v.get("ch"):
            e["choice"] = [num(x) for x in as_list(v["ch"])][0::2]
        if v.get("m"):
            e["money"] = num(v["m"])
        for bit, name in CLASS_BITS:
            if v["c"] & bit:
                classes[name].append(e)
    trainers = {}
    for cls, ids in fg["CLASS_TRAINERS"].items():
        lst = [num(i) for i in as_list(ids)]
        trainers[cls] = lst
        used.update(i for i in lst if i in npcs)
    say("Klassenquests")
    say(f"  {len(q)} Quests, {sum(len(l) for l in classes.values())} Eintraege je Klasse, {spells} lehren einen Zauber")
    say(f"  ohne Geber {nostart}, Geber ohne Lage {noloc} (nur Name/Nummer bekannt)")
    say(f"  Klassenlehrer: " + ", ".join(f"{c} {len(l)}" for c, l in sorted(trainers.items())))
    return {"classes": classes, "npcs": {i: npcs[i] for i in sorted(used)}, "trainers": trainers}


def write_classquests(cd):
    L = []
    w = L.append
    w("--------------------------------------------------")
    w("-- WeintCodex :: Klassenquests und Klassenlehrer")
    w("--------------------------------------------------")
    w("-- ERZEUGT von .github/scripts/import_foreverguide.py - nicht von Hand")
    w("-- aendern; neu erzeugen.")
    w("--")
    w("-- HERKUNFT `community`: das Addon ForeverGuide " + FG_VERSION + " sammelt die")
    w("-- Klassenquests aus der Questie-Datenbank fuer Forever. Uebernommen sind")
    w("-- nur Fakten: Nummer, Stufe, Mindeststufe, Klassen, Voelker, Geber und")
    w("-- Abgabe (NPC-Nummer), Vor- und Folgequest, gelehrter Zauber, Belohnungen.")
    w("-- Keine Ziele, keine Texte - der Name steht nur als englischer Rueckfall,")
    w("-- angezeigt wird der des Clients. Die BELOHNUNGEN stammen aus Classic")
    w("-- (cmangos, ueber ForeverGuide) und heissen so (`classic`).")
    w("--")
    w("-- Je Klasse eine Funktion, gebaut erst beim ersten Zugriff - gebraucht wird")
    w("-- nur die des Charakters.")
    w("--   ra     Voelker (Bit 1 << (Volk - 1)); fehlt: alle")
    w("--   giver/turnin  NPC-Nummer; Name und Lage in NPCS, wenn bekannt")
    w("--   start  \"item\"/\"object\": beginnt an einem Gegenstand oder Objekt")
    w("--   spell  gelehrter Zauber (spellName: englischer Rueckfall)")
    w("--   items/choice  Belohnung fest / zur Wahl (Gegenstandsnummern)")
    w("--------------------------------------------------")
    w("")
    w("WeintCodex = WeintCodex or {}")
    w("WeintCodex.ClassQuestData = WeintCodex.ClassQuestData or {}")
    w("local Q = WeintCodex.ClassQuestData")
    w("")
    w("Q.SOURCE = {")
    w('    kind  = "community",')
    w(f'    date  = "{FG_DATE}",')
    w(f'    label = "Klassenquests: Addon ForeverGuide {FG_VERSION} (Questie-Datenbank für Forever)",')
    w("}")
    w("Q.REWARD_SOURCE = {")
    w('    kind  = "classic",')
    w(f'    label = "Belohnungen aus Classic (über ForeverGuide {FG_VERSION})",')
    w("}")
    w("")
    w("local BUILD = {")
    for _, cls in CLASS_BITS:
        w(f"    {cls} = function() return {{")
        for e in cd["classes"][cls]:
            parts = [f"id = {e['id']}", f"name = {lua_str(e['name'])}", f"lv = {e['lv']}", f"rl = {e['rl']}"]
            for key in ("ra", "giver", "turnin", "next", "spell", "money"):
                if key in e:
                    parts.append(f"{key} = {e[key]}")
            if "start" in e:
                parts.append(f'start = "{e["start"]}"')
            if e.get("spellName"):
                parts.append(f"spellName = {lua_str(e['spellName'])}")
            for key in ("pre", "items", "choice"):
                if e.get(key):
                    parts.append(f"{key} = {{ " + ", ".join(str(x) for x in e[key]) + " }")
            w("        { " + ", ".join(parts) + " },")
        w("    } end,")
    w("}")
    w("Q.CLASSES = setmetatable({}, { __index = function(t, class)")
    w("    local f = BUILD[class]")
    w('    if type(f) ~= "function" then return nil end')
    w("    local v = f()")
    w("    rawset(t, class, v)")
    w("    BUILD[class] = nil")
    w("    return v")
    w("end })")
    w("")
    w("-- NPC: { Name (englisch), Karte, x, y (0..100), Fraktion \"A\"/\"H\"/\"AH\" }")
    w("-- Karte nil: Lage unbekannt (oder in einer Instanz).")
    w("Q.NPCS = {")
    for i, n in cd["npcs"].items():
        loc = f"{n['map']}, {num(n['x'])}, {num(n['y'])}" if n["map"] else "nil, nil, nil"
        w(f"    [{i}] = {{ {lua_str(n['name'])}, {loc}, \"{n['fr']}\" }},")
    w("}")
    w("")
    w("-- Klassenlehrer je Klasse (NPC-Nummern, Lage in NPCS).")
    w("Q.TRAINERS = {")
    for cls in sorted(cd["trainers"]):
        w(f"    {cls} = {{ " + ", ".join(str(i) for i in cd["trainers"][cls]) + " },")
    w("}")
    path = os.path.join(ROOT, "data", "classquests.lua")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    say(f"  -> {os.path.relpath(path, ROOT)} ({os.path.getsize(path) // 1024} KB)")


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    fg = run_dump(".github/scripts/fg_dump.lua", sys.argv[1])
    cx = run_dump(".github/scripts/codex_dump.lua")
    write_dungeons(build_dungeons(fg, cx))
    write_professions(build_professions(fg))
    write_classquests(build_classquests(fg))
    print("\n".join(report))


if __name__ == "__main__":
    main()
