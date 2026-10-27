"""
Sprecherspur + Zeitleiste.

Spricht jede Zeile aus script.json einzeln (Coqui Thorsten VITS), misst
die Länge, legt Szenen auf ganze Takte (Musik-BPM) und schreibt:
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
GAP = 0.32          # Pause zwischen Sätzen einer Szene
LEAD = 0.55         # Sprechbeginn nach Szenenstart
TAIL = 0.9          # Luft nach dem letzten Satz
MUSIC = {"intro": "intro", "three": "big", "codex": "main", "companion": "main",
         "bot": "main", "guild": "soft", "orders": "big", "start": "main", "outro": "outro"}
DROP = {"three", "orders", "outro"}

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

sys.path.insert(0, HERE)
os.chdir(HERE)
from voice import say, hear, SR

import difflib
def norm(s):
    s = s.lower()
    for a, b in (("eins", "1"), ("zwei", "2"), ("drei", "3"), ("fünften", "5."), ("weint", "w"), ("wind", "w"), ("wein", "w")):
        s = s.replace(a, b)
    return re.sub(r"[^a-zäöüß0-9 ]", "", s.replace("-", " "))
def score(a, b):
    return difflib.SequenceMatcher(None, norm(a), norm(b)).ratio()

def trim(x, thr=0.01):
    idx = np.where(np.abs(x) > thr * np.abs(x).max())[0]
    return x[max(0, idx[0] - 200): idx[-1] + 600] if len(idx) else x

import soundfile as sf
from scipy.signal import resample_poly
_m, _msr = sf.read(os.path.join(VIDEO, "music2.wav"))
BED = resample_poly(_m.mean(1), SR, _msr)[int(30 * SR):]
BED = BED / np.abs(BED).max() * 0.2

script = json.load(open(os.path.join(HERE, "script.json")))
clips = []
for sc in script:
    for line in sc["lines"]:
        best = None
        for k, ns in enumerate((0.667, 0.6, 0.72, 0.55, 0.667, 0.6, 0.63, 0.7)):
            wav = trim(say(spoken(line), length=1.04, noise=ns))
            got = hear(wav)
            y = wav / np.abs(wav).max() * 0.8
            noisy = (y + BED[:len(y)]).astype(np.float32)
            got2 = hear(noisy)
            sc_ = min(score(line, got), score(line, got2))
            if best is None or sc_ > best[0]:
                best = (sc_, wav, got)
            if sc_ > 0.97:
                break
        clips.append(best[1])
        print(f"  {best[0]:.2f} {line}\n       -> {best[2]}")

scenes, subs, voice_parts = [], [], []
bar = 0
ci = 0
for sc in script:
    start = bar * BAR
    t = start + (1.15 if sc["scene"] in DROP else LEAD)
    for line in sc["lines"]:
        x = clips[ci]; ci += 1
        d = len(x) / SR
        voice_parts.append((t, x))
        subs.append({"t0": round(t - 0.05, 3), "t1": round(t + d + 0.15, 3), "text": line})
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

tl = {"bpm": BPM, "bars": total_bars, "duration": round(duration, 3), "scenes": scenes, "subs": subs}
json.dump(tl, open(os.path.join(VIDEO, "timeline.json"), "w"), ensure_ascii=False, indent=1)
open(os.path.join(VIDEO, "timeline.js"), "w").write("window.TL = " + json.dumps(tl, ensure_ascii=False) + ";\n")
for s in scenes:
    print(s["key"], s["start"], s["end"], s["bars"])
print("Dauer", duration)
