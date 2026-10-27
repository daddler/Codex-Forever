"""
Musik fuer das Erklaervideo (nach music2.py des Werbevideos).
Neu: Arten "calm" (ohne Drums, Achtel-Arpeggio) und "groove" (ohne Snare),
drei Akkordfolgen und drei Arpeggio-Muster im Wechsel je Szene.

Liest timeline.json (bpm, Szenen mit Startbar und Laenge in Takten,
Art je Szene) und baut darauf einen Track in a-Moll:
Fläche (Supersaw), Arpeggio, Bass, Drums, Riser/Impacts an Szenenwechseln,
Sidechain-Pumpen, Hall. Ausgabe: music2.wav (44.1 kHz Stereo).
"""
import json, sys
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
rng = np.random.default_rng(7)

tl = json.load(open(sys.argv[1]))
BPM = tl["bpm"]
BEAT = 60 / BPM
BAR = 4 * BEAT
TOTAL_BARS = tl["bars"]
N = int((TOTAL_BARS * BAR + 4) * SR)

L = np.zeros(N); R = np.zeros(N)          # Summe Musik (ohne Drums-Sidechain)
padL = np.zeros(N); padR = np.zeros(N)    # wird gepumpt
bass = np.zeros(N)
drums = np.zeros(N)
fx = np.zeros(N)
side = np.ones(N)                         # Sidechain-Huellkurve

def s(t):
    return int(round(t * SR))

def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)

# Bandbegrenzte Saegezahn-Tabelle
TAB = 4096
ph = np.arange(TAB) / TAB
SAW = np.zeros(TAB)
for k in range(1, 60):
    SAW += ((-1) ** (k + 1)) * np.sin(2 * np.pi * k * ph) / k
SAW *= 2 / np.pi

def osc(freq, n, table=SAW, phase=0.0):
    idx = (phase + np.arange(n) * freq / SR) % 1.0 * TAB
    return table[idx.astype(int) % TAB]

def lp(x, fc, order=2):
    sos = signal.butter(order, min(fc, SR * 0.45), "low", fs=SR, output="sos")
    return signal.sosfilt(sos, x)

def hp(x, fc, order=2):
    sos = signal.butter(order, fc, "high", fs=SR, output="sos")
    return signal.sosfilt(sos, x)

def bp(x, lo, hi):
    sos = signal.butter(2, [lo, hi], "band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)

def add(buf, at, x, g=1.0):
    a = s(at)
    if a >= len(buf):
        return
    b = min(len(buf), a + len(x))
    buf[a:b] += g * x[: b - a]

# a-Moll, drei Folgen; je Szene eine, damit es ueber 10 Minuten nicht eintoenig wird.
PROGS = [
  [(57, [57, 60, 64, 69]), (53, [53, 57, 60, 65]), (48, [52, 55, 60, 67]), (55, [55, 59, 62, 67])],   # Am F C G
  [(53, [53, 57, 60, 65]), (55, [55, 59, 62, 67]), (52, [52, 55, 59, 64]), (57, [57, 60, 64, 69])],   # F G Em Am
  [(50, [50, 53, 57, 62]), (57, [57, 60, 64, 69]), (53, [53, 57, 60, 65]), (52, [52, 56, 59, 64])],   # Dm Am F E
]
PROG = [
    (57, [57, 60, 64, 69]),   # Am
    (53, [53, 57, 60, 65]),   # F
    (48, [52, 55, 60, 67]),   # C
    (55, [55, 59, 62, 67]),   # G
]

# ---------- Szenenplan -> je Takt ein Zustand ----------
state = ["main"] * TOTAL_BARS
prog_of = [0] * TOTAL_BARS
pat_of = [0] * TOTAL_BARS
starts = []
for k, sc in enumerate(tl["scenes"]):
    starts.append(sc["bar"])
    for b in range(sc["bar"], min(TOTAL_BARS, sc["bar"] + sc["bars"])):
        state[b] = sc["music"]
        prog_of[b] = k % 3 if sc["music"] not in ("intro", "outro") else 0
        pat_of[b] = k % 3
def chord_at(b):
    return PROGS[prog_of[b]][b % 4]

def lvl(b):
    """(pad, arp, bass, kick, hats, snare)"""
    return {
        "intro":  (0.9, 0.0, 0.0, 0, 0, 0),
        "soft":   (0.7, 0.6, 0.6, 0, 1, 0),
        "main":   (1.0, 1.0, 1.0, 1, 1, 1),
        "big":    (1.1, 1.0, 1.1, 1, 2, 1),
        "outro":  (0.9, 0.7, 0.9, 1, 1, 1),
        "calm":   (0.75, 0.45, 0.5, 0, 0, 0),
        "groove": (0.9, 0.8, 0.9, 1, 1, 0),
        "end":    (0.7, 0.0, 0.0, 0, 0, 0),
    }[state[b]]

# ---------- Fläche ----------
DET = [-0.11, -0.06, -0.025, 0, 0.025, 0.06, 0.11]
for b in range(TOTAL_BARS):
    root, chord = chord_at(b)
    g = lvl(b)[0]
    if g == 0:
        continue
    n = s(BAR) + s(0.6)
    t = np.arange(n) / SR
    xl = np.zeros(n); xr = np.zeros(n)
    for note in chord:
        f = midi(note)
        for i, d in enumerate(DET):
            v = osc(f * 2 ** (d / 12), n, phase=rng.random())
            pan = (i / (len(DET) - 1))
            xl += v * (1 - pan * 0.7); xr += v * (0.3 + pan * 0.7)
    # weiche Huellkurve, Ueberlappung
    env = np.minimum(1, t / 0.25) * np.minimum(1, np.maximum(0, (n / SR - t) / 0.6))
    cut = 900 if state[b] in ("intro", "end") else (1500 if state[b] == "calm" else 2600)
    if state[b] == "big":
        cut = 4200
    xl = lp(xl * env, cut, 4); xr = lp(xr * env, cut, 4)
    add(padL, b * BAR, xl, 0.018 * g)
    add(padR, b * BAR, xr, 0.018 * g)

# ---------- Arpeggio (Sechzehntel, Pluck) ----------
PATS = [[0, 2, 1, 3, 2, 1, 3, 2], [0, 1, 2, 3, 2, 1, 0, 2], [3, 1, 2, 0, 1, 2, 3, 1]]
for b in range(TOTAL_BARS):
    g = lvl(b)[1]
    if g == 0:
        continue
    root, chord = chord_at(b)
    PAT = PATS[pat_of[b]]
    calm = state[b] == "calm"
    for i in range(16):
        if calm and i % 2:
            continue                      # ruhig: nur Achtel
        note = chord[PAT[i % 8]] + 12
        if i % 4 == 3:
            note += 12 if b % 2 else 0
        n = s(BEAT * 0.5)
        t = np.arange(n) / SR
        x = osc(midi(note), n) * 0.6 + osc(midi(note) * 1.003, n) * 0.4
        x = lp(x * np.exp(-t * 14), 3200) * 0.6 + lp(x * np.exp(-t * 40), 7000) * 0.4
        pan = 0.5 + 0.35 * np.sin(i * 0.9)
        add(L, b * BAR + i * BEAT / 4, x * (1 - pan) * 2, 0.085 * g)
        add(R, b * BAR + i * BEAT / 4, x * pan * 2, 0.085 * g)

# ---------- Bass ----------
for b in range(TOTAL_BARS):
    g = lvl(b)[2]
    if g == 0:
        continue
    root = chord_at(b)[0] - 24
    for i in range(8):
        n = s(BEAT / 2)
        t = np.arange(n) / SR
        f = midi(root + (12 if i % 4 == 3 else 0))
        x = np.sin(2 * np.pi * f * t) + 0.35 * lp(osc(f, n), 500)
        x *= np.minimum(1, t / 0.005) * np.minimum(1, (n / SR - t) / 0.02)
        add(bass, b * BAR + i * BEAT / 2, x, 0.1 * g)

# ---------- Drums ----------
def kick():
    n = s(0.45); t = np.arange(n) / SR
    f = 52 + 110 * np.exp(-t * 30)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 10)
    x[: s(0.004)] += rng.normal(0, 0.5, s(0.004))
    return np.tanh(x * 1.6)

def snare():
    n = s(0.3); t = np.arange(n) / SR
    noise = bp(rng.normal(0, 1, n), 1200, 9000) * np.exp(-t * 16)
    tone = np.sin(2 * np.pi * 185 * t) * np.exp(-t * 25)
    return noise * 0.8 + tone * 0.6

def hat(open_=False):
    n = s(0.25 if open_ else 0.05); t = np.arange(n) / SR
    return hp(rng.normal(0, 1, n), 8000) * np.exp(-t * (12 if open_ else 80))

K, S_, H, HO = kick(), snare(), hat(), hat(True)
for b in range(TOTAL_BARS):
    _, _, _, kk, hh, sn = lvl(b)
    t0 = b * BAR
    for q in range(4):
        if kk:
            add(drums, t0 + q * BEAT, K, 0.36)
            a = s(t0 + q * BEAT); e = min(N, a + s(BEAT))
            tt = np.arange(e - a) / SR
            side[a:e] = np.minimum(side[a:e], 1 - 0.55 * np.exp(-tt * 9))
        if sn and q in (1, 3):
            add(drums, t0 + q * BEAT, S_, 0.22)
        if hh:
            add(drums, t0 + q * BEAT + BEAT / 2, HO if hh > 1 else H, 0.11)
            if hh > 1:
                add(drums, t0 + q * BEAT + BEAT / 4, H, 0.04)
                add(drums, t0 + q * BEAT + 3 * BEAT / 4, H, 0.04)
    # Fill im letzten Takt vor einem Szenenwechsel
    if (b + 1) in starts and sn:
        for i in range(4):
            add(drums, t0 + 3 * BEAT + i * BEAT / 4, S_, 0.12 + 0.05 * i)

# ---------- Riser, Impact, Crash an Szenenwechseln ----------
def riser(dur):
    n = s(dur); t = np.arange(n) / SR; p = t / dur
    x = rng.normal(0, 1, n)
    out = np.zeros(n)
    blk = 2048
    for i in range(0, n, blk):
        fc = 400 + 9000 * p[i] ** 2
        out[i:i + blk] = bp(x[i:i + blk], fc * 0.6, min(fc * 1.6, 20000))
    tone = np.sin(2 * np.pi * np.cumsum(200 + 900 * p ** 2) / SR) * 0.25
    return (out * 0.7 + tone) * p ** 2

def impact():
    n = s(2.2); t = np.arange(n) / SR
    boom = np.sin(2 * np.pi * np.cumsum(30 + 60 * np.exp(-t * 6)) / SR) * np.exp(-t * 2.5)
    crash = hp(rng.normal(0, 1, n), 5000) * np.exp(-t * 2.2) * 0.35
    return boom * 0.8 + crash

RIS = riser(BAR)
IMP = impact()
for i, sc in enumerate(tl["scenes"]):
    if i == 0:
        continue
    at = sc["bar"] * BAR
    big = sc.get("drop")
    add(fx, at - (BAR if big else BEAT * 2), RIS if big else riser(BEAT * 2), 0.18 if big else 0.1)
    add(fx, at, IMP, 0.24 if big else 0.13)

# ---------- Lead-Melodie (nur in den grossen Teilen) ----------
MOTIF = [(0, 76, 1), (1, 81, 1), (2, 79, .5), (2.5, 76, 1.5),
         (4, 77, 1), (5, 76, .5), (5.5, 74, .5), (6, 72, 2),
         (8, 72, 1), (9, 74, 1), (10, 76, .5), (10.5, 79, 1.5),
         (12, 79, 1), (13, 74, 1), (14, 71, 1), (15, 74, 1)]
leadL = np.zeros(N); leadR = np.zeros(N)
for b in range(0, TOTAL_BARS, 1):
    if state[b] not in ("big", "outro"):
        continue
    off = (b % 4) * 4
    for beat, note, ln in MOTIF:
        if not (off <= beat < off + 4):
            continue
        n = s(ln * BEAT + 0.15); t = np.arange(n) / SR
        f = midi(note) * (1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(1, t / 0.3))
        ph_ = np.cumsum(f) / SR
        x = SAW[(ph_ % 1 * TAB).astype(int)] * 0.5 + SAW[((ph_ * 1.006) % 1 * TAB).astype(int)] * 0.5
        env = np.minimum(1, t / 0.012) * np.minimum(1, np.maximum(0, (n / SR - t) / 0.15))
        x = lp(x * env, 3800)
        at = b * BAR + (beat - off) * BEAT
        add(leadL, at, x, 0.05); add(leadR, at, x, 0.05)
# Ping-Pong-Echo
dly = s(BEAT * 0.75)
echoL = np.zeros(N); echoR = np.zeros(N)
echoL[dly:] = leadR[:-dly] * 0.35 + leadL[:-dly] * 0.0
echoR[2 * dly:] = leadL[:-2 * dly] * 0.3
L += leadL + lp(echoL, 3000); R += leadR + lp(echoR, 3000)

# ---------- Mix ----------
padL *= side; padR *= side
bass *= side
mL = hp(L + padL + bass + drums + fx, 32)
mR = hp(R + padR + bass + drums + fx, 32)

# Hall
n = s(2.4); t = np.arange(n) / SR
irL = rng.normal(0, 1, n) * np.exp(-t * 2.8); irR = rng.normal(0, 1, n) * np.exp(-t * 2.8)
irL = lp(irL, 6000); irR = lp(irR, 6000)
wetL = signal.oaconvolve(L + padL + 0.3 * fx, irL)[:N] * 0.012
wetR = signal.oaconvolve(R + padR + 0.3 * fx, irR)[:N] * 0.012
mL += wetL; mR += wetR

# Ende ausblenden
end = s(TOTAL_BARS * BAR + 3)
fade = np.ones(N); fade[end - s(3):end] = np.linspace(1, 0, s(3)); fade[end:] = 0
mL *= fade; mR *= fade

peak = max(np.abs(mL).max(), np.abs(mR).max())
mL = np.tanh(mL / peak * 1.1) * 0.9; mR = np.tanh(mR / peak * 1.1) * 0.9
wavfile.write(sys.argv[2], SR, (np.stack([mL, mR], 1) * 32767).astype(np.int16))
print("bars", TOTAL_BARS, "sec", TOTAL_BARS * BAR)
