import soundfile as sf, numpy as np, json, sys, os, re
os.chdir(os.path.dirname(os.path.abspath(__file__)))
sys.argv = [sys.argv[0], "/tmp"]
src = open("build_voice.py").read()
exec(src[src.index("import difflib"):src.index("def trim")])
from voice import hear
x, sr = sf.read("../video/mix.wav"); x = x.mean(1)
tl = json.load(open("../video/timeline.json"))
bad = 0
for s in tl["subs"]:
    got = hear(x[int(s["t0"] * sr):int(s["t1"] * sr)].astype(np.float32), sr)
    sc = score(s["text"], got)
    if sc < 0.93:
        bad += 1
        print(f"{sc:.2f} {s['text']}\n     -> {got}")
print("schwach:", bad, "von", len(tl["subs"]))
