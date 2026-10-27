"""
Vorschau-Stimme mit Piper (de_DE-thorsten-high), bis die ElevenLabs-Aufnahme da ist.

    python3 tts/build_voice_piper.py <modell.onnx> [projektordner]

Erzeugt jeden Satz aus tts/script.json einmal, legt die Szenen auf ganze
Takte (110 BPM) und schreibt voice.wav, timeline.json und timeline.js -
dasselbe Format wie build_voice_el.py, damit music2.py, mix.sh und
index.html beide Wege gleich lesen.
"""
import json, math, os, sys
import numpy as np, soundfile as sf
from piper import PiperVoice, SynthesisConfig

MODEL = sys.argv[1]
DIR = sys.argv[2] if len(sys.argv) > 2 else os.getcwd()
BPM = 110; BAR = 4 * 60 / BPM
GAP = 0.55            # Pause zwischen Saetzen
LEAD = 2 * BAR + 0.5   # Titelkarte (2 Takte), dann Sprache
TAIL = 1.4            # Luft am Szenenende
from scenes import MUSIC, DROP

V = PiperVoice.load(MODEL); SR = V.config.sample_rate
IPA_FIX = [("bˈoːt", "bˈɔt"), ("fˈoːreːvɜ", "fəɾˈɛvɐ"), ("kvˈɛst", "kwˈɛst")]
def say(text):
    cfg = SynthesisConfig(length_scale=1.1, noise_scale=0.6, noise_w_scale=0.8)
    out = []
    for sent in V.phonemize(text):
        s = "".join(sent)
        for a, b in IPA_FIX: s = s.replace(a, b)
        out.append(V.phoneme_ids_to_audio(V.phonemes_to_ids(list(s)), cfg))
    x = np.concatenate(out).astype(np.float32)
    nz = np.nonzero(np.abs(x) > 0.01)[0]
    return x[max(0, nz[0] - 200): nz[-1] + 400] if len(nz) else x

script = json.load(open(os.path.join(DIR, "tts/script.json")))
scenes, subs, chunks = [], [], []
bar = 0
for sc in script:
    t = bar * BAR + LEAD
    for line in sc["lines"]:
        x = say(line); d = len(x) / SR
        chunks.append((t, x)); subs.append({"t0": round(t, 3), "t1": round(t + d, 3), "text": line, "scene": sc["scene"]})
        t += d + GAP
    bars = math.ceil((t - GAP + TAIL - bar * BAR) / BAR)
    scenes.append({"key": sc["scene"], "start": round(bar * BAR, 3), "end": round((bar + bars) * BAR, 3),
                   "bar": bar, "bars": bars, "music": MUSIC.get(sc["scene"], "main"), "drop": sc["scene"] in DROP})
    print(f'{sc["scene"]:12s} {bars:3d} Takte  {bar * BAR:7.1f}s')
    bar += bars
dur = bar * BAR + 2
voice = np.zeros(int(dur * SR) + SR, np.float32)
for t, x in chunks:
    a = int(t * SR); voice[a:a + len(x)] += x
sf.write(os.path.join(DIR, "voice.wav"), voice, SR)
tl = {"bpm": BPM, "bars": bar, "duration": round(dur, 3), "scenes": scenes, "subs": subs}
json.dump(tl, open(os.path.join(DIR, "timeline.json"), "w"), ensure_ascii=False)
open(os.path.join(DIR, "timeline.js"), "w").write("window.TL = " + json.dumps(tl, ensure_ascii=False) + ";\n")
print("Dauer", round(dur, 1), "s")
