"""
Nachaufnahme (voice/nachaufnahme.mp3) an den Pausen in Saetze schneiden.
Saetze sind die Zeilen aus tts/script.json, die es in script_v1.json
(Stand der ersten Aufnahme) nicht gab - in ihrer Reihenfolge.
Ergebnis: voice/segments_nach.json  [[a, b], ...]
"""
import json, re, subprocess, sys
import soundfile as sf
V = "../voice/"
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', V + 'nachaufnahme.mp3', '-ar', '44100', '-ac', '1', V + 'nach.wav'], check=True)
x, sr = sf.read(V + 'nach.wav')
log = subprocess.run(['ffmpeg', '-i', V + 'nach.wav', '-af', 'silencedetect=noise=-40dB:d=0.5', '-f', 'null', '-'], capture_output=True, text=True).stderr
st = [float(v) for v in re.findall(r'silence_start: ([\d.]+)', log)]
en = [float(v) for v in re.findall(r'silence_end: ([\d.]+)', log)]
cuts, pos = [], 0.0
for a, b in zip(st, en):
    if a > pos + 0.2: cuts.append([max(0, pos - 0.03), a + 0.08])
    pos = b
if pos < len(x) / sr - 0.2: cuts.append([pos - 0.03, len(x) / sr])
old = {l for s in json.load(open('script_v1.json')) for l in s['lines']}
new = [l for s in json.load(open('script.json')) for l in s['lines'] if l not in old]
print(len(cuts), "Stuecke fuer", len(new), "neue Saetze")
for c, l in zip(cuts, new): print(f"  {c[0]:6.2f}-{c[1]:6.2f}  {l}")
if len(cuts) != len(new): sys.exit("Anzahl passt nicht - Pausen pruefen")
json.dump(cuts, open(V + 'segments_nach.json', 'w'))
