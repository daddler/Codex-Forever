#!/usr/bin/env python3
"""Reisedaten fuer den Routenplaner -> data/travel.lua (6.31.2.0).

Liest die Datendateien des Addons Shortest Path Forever (Data/Taxi.lua,
Data/Routes.lua, Data/Transports.lua, Data/Portals.lua, Data/Teleports.lua,
Data/Walks.lua)
und schreibt NUR DATEN in unser Format - kein Code, keine Texte ausser
englischen Ortsnamen als Notbehelf (im Spiel nennt der Client die Namen in
der Sprache des Spielers). Wie bei import_mapmarks.py: die Dateien werden nur
gelesen und als Tabellen zerlegt, nie ausgefuehrt.

Herkunft laut Kopf jener Dateien: wago.tools DB2 (Build 1.60.1.70338),
cmangos classic-db, Flugzeiten aus InFlight (MIT). Art im Codex: classic.

Aufruf:
    python3 -I .github/scripts/import_travel.py <Ordner ShortestPathForever>
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "travel.lua")

TOKEN = re.compile(r'''
    (?P<ws>\s+|--\[\[.*?\]\]|--[^\n]*)
  | (?P<str>"(?:[^"\\]|\\.)*")
  | (?P<num>-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)
  | (?P<name>[A-Za-z_][A-Za-z0-9_.]*)
  | (?P<sym>[{}\[\]=,;])
  | (?P<other>\.\.\.|\S)
''', re.S | re.X)


def tokens(text):
    pos = 0
    out = []
    while pos < len(text):
        m = TOKEN.match(text, pos)
        if not m:
            raise SystemExit(f"nicht lesbar bei {pos}: {text[pos:pos + 40]!r}")
        pos = m.end()
        kind = m.lastgroup
        if kind == "ws":
            continue
        out.append((kind, m.group(kind)))
    return out


class Parser:
    def __init__(self, toks):
        self.t, self.i = toks, 0

    def peek(self, k=0):
        return self.t[self.i + k] if self.i + k < len(self.t) else (None, None)

    def take(self, value=None):
        tok = self.t[self.i]
        if value is not None and tok[1] != value:
            raise SystemExit(f"erwartet {value}, gefunden {tok}")
        self.i += 1
        return tok

    def value(self):
        kind, v = self.peek()
        if v == "{":
            return self.table()
        self.take()
        if kind == "str":
            return bytes(v[1:-1], "utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")
        if kind == "num":
            return float(v) if ("." in v or "e" in v.lower()) else int(v)
        if v == "nil":
            return None
        if v in ("true", "false"):
            return v == "true"
        raise SystemExit(f"Wert erwartet, gefunden {v}")

    def table(self):
        self.take("{")
        arr, rec, n = [], {}, 0
        while self.peek()[1] != "}":
            if self.peek()[1] == "[":
                self.take("[")
                key = self.value()
                self.take("]")
                self.take("=")
                rec[key] = self.value()
            elif self.peek()[0] == "name" and self.peek(1)[1] == "=":
                key = self.take()[1]
                self.take("=")
                rec[key] = self.value()
            else:
                n += 1
                arr.append(self.value())
            if self.peek()[1] in (",", ";"):
                self.take()
        self.take("}")
        if rec and arr:
            for i, v in enumerate(arr):
                rec[i + 1] = v
            return rec
        return rec if rec else arr


def read(path, ns):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    # Nur die Zuweisungen "ns.Name = {...}" und "ns.Name[id] = {...}".
    p = Parser(tokens(text))
    while p.i < len(p.t):
        kind, v = p.peek()
        if kind == "name" and v.startswith("ns.") and v.count(".") == 1:
            p.take()
            name = v[3:]
            if p.peek()[1] == "[":
                p.take("[")
                key = p.value()
                p.take("]")
                p.take("=")
                tbl = ns.setdefault(name, {})
                tbl[key] = p.value()
            elif p.peek()[1] == "=":
                p.take("=")
                val = p.value()
                if isinstance(ns.get(name), dict) and isinstance(val, dict):
                    ns[name].update(val)
                elif isinstance(val, list) and isinstance(ns.get(name), dict):
                    for i, x in enumerate(val):
                        ns[name][i + 1] = x
                elif isinstance(val, list):
                    ns[name] = {i + 1: x for i, x in enumerate(val)}
                else:
                    ns[name] = val
        else:
            p.i += 1


def num(v):
    s = f"{v:.1f}"
    return s[:-2] if s.endswith(".0") else s


def q(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


FACTION = {"Alliance": 1, "Horde": 2}


def items(t):
    if isinstance(t, list):
        return list(enumerate(t, 1))
    return sorted(t.items())


def write(ns):
    w = []
    w += ["--------------------------------------------------",
          "-- WeintCodex :: Reisedaten fuer den Routenplaner",
          "--------------------------------------------------",
          "-- ERZEUGT von .github/scripts/import_travel.py - nicht von Hand aendern.",
          "-- Weltkoordinaten (Kontinent = Instanzkarte, n = Norden, w = Westen, in",
          "-- Spieleinheiten), Zeiten in Sekunden bzw. ms im Umlauf. Gelesen von",
          "-- ui/route.lua. Herkunft: wago.tools DB2 1.60.1.70338, cmangos classic-db,",
          "-- InFlight (MIT); zusammengestellt vom Addon Shortest Path Forever. Art: classic.",
          "--------------------------------------------------",
          "",
          "WeintCodex = WeintCodex or {}",
          "WeintCodex.TravelData = {",
          "    -- taxi[id] = { Kontinent, n, w, Fraktion (1 Allianz, 2 Horde, 0 beide), Name }",
          "    taxi = {"]
    for k, t in items(ns["TaxiNodes"]):
        w.append(f"        [{k}] = {{ {t['map']}, {num(t['x'])}, {num(t['y'])}, {FACTION.get(t.get('faction'), 0)}, {q(t['name'])} }},")
    w += ["    },", "    -- flights = { von, nach, Sekunden, ... } (direkte Strecken)", "    flights = {"]
    for _, p in items(ns["TaxiPaths"]):
        w.append(f"        {p['from']}, {p['to']}, {p['seconds']},")
    w += ["    },", "    -- docks[id] = { Kontinent, n, w } (wo man einsteigt)", "    docks = {"]
    for k, d in items(ns["Docks"]):
        p = d.get("walk") or d
        w.append(f"        [{k}] = {{ {p['map']}, {num(p['x'])}, {num(p['y'])} }},")
    w += ["    },",
          "    -- routes[id] = { Art, Fraktion, Umlauf ms, { Anleger, Ankunft, Abfahrt, ... },",
          "    --                { an, ab, Kontinent, n, w, ... } } (Bahn, zum Messen der Abfahrt)",
          "    routes = {"]
    for k, r in items(ns["Routes"]):
        stops = ", ".join(f"{s['dock']}, {s['arrive']}, {s['depart']}" for _, s in items(r["stops"]))
        frames = ", ".join(f"{f[1]}, {f[2]}, {f[3]}, {num(f[4])}, {num(f[5])}" for _, f in items(r["frames"])
                           for f in [dict(items(f))])
        w.append(f"        [{k}] = {{ {q(r['kind'])}, {FACTION.get(r.get('faction'), 0)}, {r['period']}, {{ {stops} }},")
        w.append(f"            {{ {frames} }} }},")
    w += ["    },", "    -- portals = { { Kontinent, n, w, Ziel Kontinent, n, w, Sekunden }, ... }", "    portals = {"]
    for _, p in items(ns["Portals"]):
        a, b = p["from"], p["to"]
        w.append(f"        {{ {a['map']}, {num(a['x'])}, {num(a['y'])}, {b['map']}, {num(b['x'])}, {num(b['y'])}, {p.get('seconds', 5)} }},")
    w += ["    },",
          "    -- teleports: Zauber oder Gegenstand, Zauberzeit ms, Ziel oder bind (Ruhestein)",
          "    teleports = {"]
    for _, t in items(ns["Teleports"]):
        item = str(t["item"]) if t.get("item") else "nil"
        cast = t.get("cast", 10000)
        if t.get("bind"):
            w.append(f"        {{ spell = {t['spell']}, item = {item}, cast = {cast}, bind = true }},")
        elif t.get("to"):
            to = t["to"]
            reag = ", ".join(f"[{i}] = {c}" for i, c in items(t.get("reagents") or {}))
            w.append(f"        {{ spell = {t['spell']}, item = {item}, cast = {cast}, to = {{ {to['map']}, {num(to['x'])}, {num(to['y'])} }}, reagents = {{ {reag} }} }},")
    w += ["    },", "    -- landmasses = { { Kontinent, minN, maxN, minW, maxW }, ... } (Inseln: nicht zu Fuss)", "    landmasses = {"]
    for _, l in items(ns.get("Landmasses") or []):
        w.append(f"        {{ {l['map']}, {num(l['minX'])}, {num(l['maxX'])}, {num(l['minY'])}, {num(l['maxY'])} }},")
    # Echte Laufstrecken zwischen festen Orten (Spieleinheiten, aus der
    # Gelaendekarte vorberechnet): places = { { Kontinent, n, w }, ... },
    # walks = { Ort a, Ort b, Strecke (false: kein Weg), Rueckweg (0: gleich), ... }
    places, index = [], {}
    for c, tbl in items(ns.get("WalkPlaces") or {}):
        for key, xy in sorted(tbl.items()):
            index[(c, key)] = len(places) + 1
            places.append((c, xy[1] if isinstance(xy, dict) else xy[0], xy[2] if isinstance(xy, dict) else xy[1]))
    w += ["    },", "    places = {"]
    for c, n, ww in places:
        w.append(f"        {{ {c}, {num(n)}, {num(ww)} }},")
    w += ["    },", "    walks = {"]
    count = 0
    for c, tbl in items(ns.get("Walks") or {}):
        for pair, v in sorted(tbl.items()):
            a, b = pair.split(" ")
            v = [x for _, x in items(v)] if isinstance(v, dict) else v
            dry = "false" if v[0] is False else str(v[0])
            rev = "0"
            if len(v) >= 3:
                rev = "false" if v[2] is False else str(v[2])
            w.append(f"        {index[(c, a)]}, {index[(c, b)]}, {dry}, {rev},")
            count += 1
    w += ["    },", "}", ""]
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(w))
    print(f"geschrieben: data/travel.lua ({len(ns['TaxiNodes'])} Flugpunkte, {len(ns['TaxiPaths'])} Strecken, "
          f"{len(ns['Routes'])} Linien, {len(ns['Portals'])} Portale, {len(ns['Teleports'])} Teleports)")


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    ns = {}
    for f in ("Data/Taxi.lua", "Data/Routes.lua", "Data/Transports.lua", "Data/Portals.lua", "Data/Teleports.lua",
              "Data/Walks.lua"):
        read(os.path.join(sys.argv[1], f), ns)
    write(ns)


if __name__ == "__main__":
    main()
