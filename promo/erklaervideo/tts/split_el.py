import json, re, subprocess, sys, difflib
import numpy as np, soundfile as sf
sys.path.insert(0, '.')
try:
    from voice import hear          # sherpa-onnx Whisper (wie im Werbevideo)
except Exception:
    # Ersatz: faster-whisper, wenn sherpa-onnx oder das Modell fehlt
    from faster_whisper import WhisperModel
    _fw = WhisperModel("small", device="cpu", compute_type="int8")
    def hear(x, sr):
        if sr != 16000:
            from scipy.signal import resample_poly
            x = resample_poly(x, 16000, sr).astype(np.float32)
        segs, _ = _fw.transcribe(x, language="de", beam_size=1)
        return " ".join(s.text.strip() for s in segs)
src = open('build_voice.py').read()
exec(src[src.index('def norm'):src.index('def trim')])
subprocess.run(['ffmpeg','-v','error','-y','-i','../voice/elevenlabs_roger.mp3','-ar','44100','-ac','1','../voice/all.wav'], check=True)
x, sr = sf.read('../voice/all.wav')
log = subprocess.run(['ffmpeg','-i','../voice/all.wav','-af','silencedetect=noise=-40dB:d=0.25','-f','null','-'], capture_output=True, text=True).stderr
st = [float(v) for v in re.findall(r'silence_start: ([\d.]+)', log)]
en = [float(v) for v in re.findall(r'silence_end: ([\d.]+)', log)]
# Sprechstücke zwischen den Pausen
cuts = []; pos = 0.0
for a, b in zip(st, en):
    if a > pos: cuts.append((pos, a))
    pos = b
if pos < len(x)/sr - 0.05: cuts.append((pos, len(x)/sr))
texts = [hear(x[int(a*sr):int(b*sr)].astype(np.float32), sr) for a, b in cuts]
lines = [l for s in json.load(open('script.json')) for l in s['lines']]
n, m = len(lines), len(cuts)
# monotone Zuordnung: Satz i = Stücke j..k
best = {(0, 0): (0.0, None)}
for i in range(n):
    for j in range(m):
        if (i, j) not in best: continue
        for k in range(j+1, min(m, j+6)+1):
            sc = best[(i, j)][0] + score(lines[i], ' '.join(texts[j:k]))
            if (i+1, k) not in best or sc > best[(i+1, k)][0]:
                best[(i+1, k)] = (sc, (i, j))
key = (n, m); out = []
while best[key][1]:
    pi, pj = best[key][1]; out.append((pi, pj, key[1])); key = (pi, pj)
out.reverse()
seg = []
for i, j, k in out:
    a, b = cuts[j][0], cuts[k-1][1]
    got = ' '.join(texts[j:k])
    print(f"{score(lines[i], got):.2f} {a:6.2f}-{b:6.2f} {lines[i]}\n      -> {got}")
    seg.append([max(0, a-0.03), b+0.08])
json.dump(seg, open('../voice/segments.json', 'w'))
