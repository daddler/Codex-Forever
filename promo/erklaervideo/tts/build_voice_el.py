"""
Sprecherspur + Zeitleiste.

Nimmt die ElevenLabs-Aufnahme (von split_el.py in Saetze zerlegt), legt
die Szenen auf ganze Takte (110 BPM, 2 Takte Titelkarte) und schreibt:
  voice.wav       – die Sprecherspur, 22.05 kHz mono
  timeline.json   – für music2.py
  timeline.js     – window.TL für die Videoseite
"""
import json, math, os, re, sys
import numpy as np
from scipy.io import wavfile

HERE = os.path.dirname(os.path.abspath(__file__))
VIDEO = sys.argv[1]
BPM = 110
BAR = 240 / BPM
GAP = 0.45          # Pause zwischen Sätzen einer Szene
LEAD = 2 * BAR + 0.5  # Titelkarte (2 Takte), dann Sprache
TAIL = 1.4          # Luft nach dem letzten Satz
sys.path.insert(0, HERE)
from scenes import MUSIC, DROP

# Aussprache: was Thorsten als deutsches Wort liest, schreiben wir so,
# wie es klingen soll. Untertitel bleiben korrekt geschrieben.
SAY = [
    (r"WeintCompanion", "Weint Kompänjen"),
    (r"Companion", "Kompänjen"),
    (r"WeintCodex", "Weint-Kodex"),
    (r"Weint-Ökosystem", "Weint Ökosystem"),
    (r"WoW Forever", "Wau Forever"),
    (r"Backup", "Bäckapp"),
    (r"Addon", "Äddonn"),
    (r"Material-Tracker", "Material-Träcker"),
    (r"Dungeon", "Dandschen"),
    (r"Raid", "Rejd"),
    (r"Questhelfer", "Quest-Helfer"),
    (r"PC", "Pe-Zeh"),
    (r"Ökosystem", "Öko-System"),
    (r"zeig's", "zeigs"),
]

def spoken(text):
    for a, b in SAY:
        text = re.sub(a, b, text)
    return text

# Sprache: fertige ElevenLabs-Aufnahme (../el/all.wav), von split_el.py
# an den Pausen in die Sätze zerlegt (../el/segments.json).
import soundfile as sf
_x, SR = sf.read(os.path.join(HERE, "..", "voice", "all.wav"))
_seg = json.load(open(os.path.join(HERE, "..", "voice", "segments.json")))
script = json.load(open(os.path.join(HERE, "script.json")))
# Erste Aufnahme: Saetze aus script_v1.json (Stand der Aufnahme), per Text gefunden.
# Neue Saetze kommen aus der Nachaufnahme (split_nach.py), in ihrer Reihenfolge.
v1 = [l for s in json.load(open(os.path.join(HERE, "script_v1.json"))) for l in s["lines"]]
assert len(_seg) == len(v1)
byText = {l: _x[int(a * SR):int(b * SR)].astype(np.float32) for l, (a, b) in zip(v1, _seg)}
nachP = os.path.join(HERE, "..", "voice", "nach.wav")
nach = []
if os.path.exists(nachP):
    _n, _sr = sf.read(nachP)
    assert _sr == SR
    nach = [_n[int(a * SR):int(b * SR)].astype(np.float32) for a, b in json.load(open(os.path.join(HERE, "..", "voice", "segments_nach.json")))]
clips = []
for s in script:
    for l in s["lines"]:
        if l in byText: clips.append(byText[l])
        else:
            assert nach, "Satz fehlt in beiden Aufnahmen: " + l
            clips.append(nach.pop(0))

scenes, subs, voice_parts = [], [], []
bar = 0
ci = 0
for sc in script:
    start = bar * BAR
    t = start + LEAD
    for line in sc["lines"]:
        x = clips[ci]; ci += 1
        d = len(x) / SR
        voice_parts.append((t, x))
        subs.append({"t0": round(t - 0.05, 3), "t1": round(t + d + 0.15, 3), "text": line, "scene": sc["scene"]})
        t += d + GAP
    need = t - GAP + TAIL - start
    if sc["scene"] == "outro":
        need += 2.5
    bars = max(2, math.ceil(need / BAR))
    scenes.append({"key": sc["scene"], "start": round(start, 3), "end": round(start + bars * BAR, 3),
                   "bar": bar, "bars": bars, "music": MUSIC[sc["scene"]],
                   "drop": sc["scene"] in DROP})
    bar += bars

total_bars = bar + 2
duration = scenes[-1]["end"] + 1.5
vo = np.zeros(int((duration + 1) * SR), dtype=np.float32)
for t, x in voice_parts:
    a = int(t * SR); vo[a:a + len(x)] += x
vo /= max(1e-6, np.abs(vo).max()) / 0.9
wavfile.write(os.path.join(VIDEO, "voice.wav"), SR, (vo * 32767).astype(np.int16))

tl = {"voice": "elevenlabs", "bpm": BPM, "bars": total_bars, "duration": round(duration, 3), "scenes": scenes, "subs": subs}
json.dump(tl, open(os.path.join(VIDEO, "timeline.json"), "w"), ensure_ascii=False, indent=1)
open(os.path.join(VIDEO, "timeline.js"), "w").write("window.TL = " + json.dumps(tl, ensure_ascii=False) + ";\n")
for s in scenes:
    print(s["key"], s["start"], s["end"], s["bars"])
print("Dauer", duration)
