#!/usr/bin/env python3
"""Questhilfe auf der Weltkarte -> data/questdb.lua (6.30.0.0).

Liest die Questdatenbank fuer Forever (QuestieDB_Forever.toc, "Baked mode":
Base64 + zlib + CBOR in den Metadaten der TOC) und schreibt NUR TATSACHEN
in unser Format: Quests (Name, Stufen, Rassen/Klassen, Geber, Abgabe, Ziele,
Voraussetzungen), dazu die Lagen der beteiligten NPCs und Objekte auf den
Karten des Spiels (uiMapID, 0..1). Kein Code, keine Questtexte - nur Namen
(deutsch, wo vorhanden). Herkunft im Spiel: `community`.

Aufruf:
    python3 -I .github/scripts/import_questdb.py <Pfad zum Ordner QuestieDB>

Braucht das Paket cbor2. Die Datenbank wird nur gelesen, nie ausgefuehrt.
"""
import base64
import os
import re
import sys
import zlib

import cbor2

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "questdb.lua")

GIVER_SPAWNS = 6       # Lagen je Geber/Abgabe und Karte
TARGET_SPAWNS = 25     # Lagen je Ziel und Karte (gleichmaessig ausgewaehlt; 6.30.7.0: 10 -> 25)
ITEM_SOURCES = 6       # hoechstens so viele Quellen je Gegenstand


def read_meta(toc):
    meta = {}
    with open(toc, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^## (X-[^:]+): (.*)$", line.rstrip("\n"))
            if m:
                meta[m.group(1)] = m.group(2)
    return meta


class Store:
    def __init__(self, meta):
        self.meta = meta

    def get(self, key):
        v = self.meta.get(key)
        if v is None:
            return None
        m = re.match(r"^~(\d+)~$", v)
        if m:
            return "".join(self.meta[key + "-" + str(i)] for i in range(1, int(m.group(1)) + 1))
        return v

    @staticmethod
    def b64(s):
        return base64.b64decode(s + "=" * (-len(s) % 4))

    def packed(self, key):
        raw = self.b64(self.get(key))
        for w in (15, -15, 31):
            try:
                return cbor2.loads(zlib.decompress(raw, w))
            except zlib.error:
                pass
        raise SystemExit("nicht zu entpacken: " + key)

    def entity(self, prefix, tables, only=None):
        ids = self.packed("X-%sIDS" % prefix)
        out = {}
        for i in ids:
            if only is not None and i not in only:
                continue
            s = self.get("X-%s%d-S" % (prefix, i))
            row = cbor2.loads(self.b64(s)) if s else {}
            rec = {}
            if isinstance(row, dict):
                rec = {k: v for k, v in row.items() if isinstance(k, int)}
            elif isinstance(row, list):
                rec = {k: v for k, v in enumerate(row, 1) if v is not None}
            for f in tables:
                t = self.get("X-%s%d-%d" % (prefix, i, f))
                if t:
                    rec[f] = cbor2.loads(self.b64(t))
            out[i] = rec
        return ids, out

    def german(self, entity, ids):
        key = "X-l10n-deDE-" + entity
        if self.get(key) is None:
            return {}
        block = self.packed(key)
        names = el(block, 0)
        out = {}
        for pos, i in enumerate(ids):
            n = el(names, pos)
            if n:
                out[i] = n
        return out


def text(v):
    if isinstance(v, bytes):
        return v.decode("utf-8", "replace")
    return v


def zone_map(folder):
    path = os.path.join(folder, "support", "Forever", "Zones", "areaIdToUiMapId.lua")
    out = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^\s*\[(\d+)\]\s*=\s*(\d+),", line)
            if m:
                out[int(m.group(1))] = int(m.group(2))
    return out


def el(v, k):
    """Element k (ab 0) einer CBOR-Liste - Listen mit Luecken kommen als
    Tabelle mit Schluesseln ab 1."""
    if isinstance(v, list):
        return v[k] if len(v) > k else None
    if isinstance(v, dict):
        return v.get(k + 1)
    return None


def vals(v):
    if isinstance(v, dict):
        return [v[k] for k in sorted(v)]
    return v or []


def ids(v):
    return [int(x) for x in vals(v) if isinstance(x, int)]


def pick(points, n):
    if len(points) <= n:
        return points
    step = len(points) / n
    return [points[int(i * step)] for i in range(n)]


def spawns_by_map(spawns, zmap, n):
    out = {}
    for area, pts in (spawns.items() if isinstance(spawns, dict) else []):
        ui = zmap.get(int(area))
        if not ui:
            continue
        good = []
        for p in vals(pts):
            x, y = el(p, 0), el(p, 1)
            if isinstance(x, (int, float)) and isinstance(y, (int, float)) and x >= 0 and y >= 0:
                good.append((x, y))
        if good:
            out.setdefault(ui, []).extend(good)
    return {k: pick(v, n) for k, v in out.items()}


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def csv(xs):
    return ",".join(str(x) for x in xs)


def num(v):
    s = ("%.3f" % (v / 100.0)).rstrip("0").rstrip(".")
    return s if s else "0"


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    folder = sys.argv[1]
    st = Store(read_meta(os.path.join(folder, "QuestieDB_Forever.toc")))
    zmap = zone_map(folder)

    qids, quests = st.entity("Quest-", [2, 3, 10, 12, 13, 16])
    qde = st.german("Quest", qids)

    need_npc, need_obj, need_item = set(), set(), set()
    for q in quests.values():
        sb, fb, ob = q.get(2), q.get(3), q.get(10)
        need_npc.update(ids(el(sb, 0)))
        need_obj.update(ids(el(sb, 1)))
        need_npc.update(ids(el(fb, 0)))
        need_obj.update(ids(el(fb, 1)))
        for grp, target in ((0, need_npc), (1, need_obj), (2, need_item)):
            for e in vals(el(ob, grp)):
                if isinstance(el(e, 0), int):
                    target.add(el(e, 0))
    iids, items = st.entity("Item-", [2, 3], need_item)
    for it in items.values():
        need_npc.update(ids(it.get(2))[:ITEM_SOURCES])
        need_obj.update(ids(it.get(3))[:ITEM_SOURCES])
    nids, npcs = st.entity("Npc-", [7], need_npc)
    oids, objs = st.entity("Object-", [4], need_obj)
    nde, ode = st.german("Npc", nids), st.german("Object", oids)

    givers = set()
    for q in quests.values():
        for v in (q.get(2), q.get(3)):
            givers.update(ids(el(v, 0)))
            givers.update(ids(el(v, 1)))

    lines = [
        "--------------------------------------------------",
        "-- WeintCodex :: Questhilfe - Quests, Geber, Ziele",
        "--------------------------------------------------",
        "-- ERZEUGT von .github/scripts/import_questdb.py - nicht von Hand aendern.",
        "-- Nur Tatsachen ueber das Spiel (Namen, Stufen, Lagen), kein Code, keine",
        "-- Questtexte. Herkunft: Datenbank der Community fuer Forever (`community`).",
        "-- Gelesen von ui/questhelper.lua.",
        "--",
        "-- JE EINTRAG EIN TEXT (6.30.5.0): als Tabellen belegte der Bestand 7 MB",
        "-- Speicher (80 000 kleine Tabellen), als Text gut 1 MB. ui/questhelper.lua",
        "-- liest einen Eintrag erst, wenn die Karte ihn braucht. Felder durch",
        "-- Tabulator getrennt, Listen durch Komma:",
        "-- q[Quest] = Name, Stufe, ab Stufe, Rassen, Klassen, Geber-NPC, Geber-Objekt,",
        "--            Abgabe-NPC, Abgabe-Objekt, Ziel-NPC, Ziel-Objekt, Gegenstand,",
        "--            alle vorher, eine vorher, schliesst aus",
        "-- n[NPC] / o[Objekt] = Name, dann je Karte \"Karte:x,y,x,y\" durch \";\" getrennt",
        "-- i[Gegenstand] = NPCs, Objekte   (wer ihn fallen laesst)",
        "--------------------------------------------------",
        "",
        "WeintCodex = WeintCodex or {}",
        "WeintCodex.QuestDBData = {",
        "    q = {",
    ]
    nq = 0
    for i in sorted(quests):
        q = quests[i]
        name = text(qde.get(i) or q.get(1))
        if not name:
            continue
        sb, fb, ob = q.get(2), q.get(3), q.get(10)

        def grp(lst, k):
            return ids(el(lst, k))

        def targets(k):
            return [el(e, 0) for e in vals(el(ob, k)) if isinstance(el(e, 0), int)]
        races = int(q.get(6) or 0) & 0xFFFFFFFF
        fields = [name.replace("\t", " "), str(int(q.get(5) or 0)), str(int(q.get(4) or 0)),
                  str(races), str(int(q.get(7) or 0)),
                  csv(grp(sb, 0)), csv(grp(sb, 1)), csv(grp(fb, 0)), csv(grp(fb, 1)),
                  csv(targets(0)), csv(targets(1)), csv(targets(2)),
                  csv(ids(q.get(12))), csv(ids(q.get(13))), csv(ids(q.get(16)))]
        lines.append("        [%d] = %s," % (i, lua_str("\t".join(fields)).replace("\t", "\\t")))
        nq += 1
    lines.append("    },")

    def places(table, names, key, out_name):
        lines.append("    %s = {" % out_name)
        n = 0
        for i in sorted(table):
            rec = table[i]
            name = text(names.get(i) or rec.get(1))
            per = spawns_by_map(rec.get(key), zmap, GIVER_SPAWNS if i in givers else TARGET_SPAWNS)
            if not name or not per:
                continue
            segs = []
            for ui in sorted(per):
                segs.append("%d:%s" % (ui, ",".join(num(x) + "," + num(y) for x, y in per[ui])))
            lines.append("        [%d] = %s," % (i, lua_str(name.replace("\t", " ")) [:-1] + "\\t" + ";".join(segs) + '"'))
            n += 1
        lines.append("    },")
        return n
    nn = places(npcs, nde, 7, "n")
    no = places(objs, ode, 4, "o")
    lines.append("    i = {")
    for i in sorted(items):
        it = items[i]
        a, b = ids(it.get(2))[:ITEM_SOURCES], ids(it.get(3))[:ITEM_SOURCES]
        if a or b:
            lines.append('        [%d] = "%s\\t%s",' % (i, csv(a), csv(b)))
    lines.append("    },")
    lines.append("}")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("%d Quests, %d NPCs, %d Objekte -> %s (%d KB)" % (
        nq, nn, no, os.path.relpath(OUT, ROOT), os.path.getsize(OUT) // 1024))


if __name__ == "__main__":
    main()
