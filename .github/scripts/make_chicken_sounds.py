#!/usr/bin/env python3
"""Toene der Huehnerjagd (ui/flightgames.lua), seit 6.78.3.0.

Beta-Test: "die Gackertoene gehen noch nicht" - es gab nur Text. Die Toene
hier sind gerechnet (Saegezahn mit Formanten, gefiltertes Rauschen,
Huellkurven), keine Aufnahme, nichts aus dem Spiel oder von anderen.

    pip install numpy soundfile
    python3 .github/scripts/make_chicken_sounds.py

schreibt media/sounds/huhn_*.ogg (Ogg Vorbis, mono, 44,1 kHz).
"""
import os

import numpy as np
import soundfile as sf

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "sounds")
rng = np.random.default_rng(7)


def t(sec):
    return np.arange(int(RATE * sec)) / RATE


def env(n, attack=0.004, release=0.04):
    e = np.ones(n)
    a, r = int(RATE * attack), int(RATE * release)
    if a: e[:a] = np.linspace(0, 1, a)
    if r: e[-r:] *= np.linspace(1, 0, r)
    return e


def glide_saw(f0, f1, sec):
    """Saegezahn mit Tonhoehe von f0 nach f1 (exponentiell)."""
    x = t(sec)
    f = f0 * (f1 / f0) ** (x / sec)
    ph = 2 * np.pi * np.cumsum(f) / RATE
    s = np.zeros_like(x)
    for k in range(1, 14):
        s += np.sin(k * ph) / k
    return s


def bandpass(sig, lo, hi):
    spec = np.fft.rfft(sig)
    fr = np.fft.rfftfreq(len(sig), 1 / RATE)
    spec[(fr < lo) | (fr > hi)] = 0
    return np.fft.irfft(spec, len(sig))


def formant(sig, centers, width=220):
    """Grob wie ein Schnabel: nur die Bereiche um die Formanten lassen."""
    out = np.zeros_like(sig)
    for c in centers:
        out += bandpass(sig, c - width, c + width)
    return out


def cluck(f0=620, f1=420, sec=0.13, bright=(900, 1900, 3100)):
    s = formant(glide_saw(f0, f1, sec), bright)
    s += 0.25 * bandpass(rng.standard_normal(len(s)), 1500, 4000)
    return s * env(len(s), 0.003, 0.05)


def silence(sec):
    return np.zeros(int(RATE * sec))


def norm(s, peak=0.8):
    m = np.max(np.abs(s)) or 1
    return s / m * peak


def write(name, s):
    sf.write(os.path.join(OUT, name + ".ogg"), norm(s).astype(np.float32), RATE, format="OGG", subtype="VORBIS")


def main():
    os.makedirs(OUT, exist_ok=True)
    # Gack! - ein kurzes, lautes Gackern mit Nachschlag.
    write("huhn_gack", np.concatenate([cluck(700, 480, 0.11), silence(0.03), cluck(980, 520, 0.2)]))
    # Pock pock! - zwei tiefe Glucker.
    write("huhn_pock", np.concatenate([cluck(420, 360, 0.09, (700, 1500)), silence(0.07), cluck(440, 350, 0.1, (700, 1500))]))
    # Bwaak! - langgezogen, faellt ab.
    write("huhn_bwaak", cluck(900, 380, 0.34))
    # Piep! - Kueken: hoch, kurz, steigt.
    x = t(0.14)
    f = 2600 * (3400 / 2600) ** (x / 0.14)
    write("huhn_piep", np.sin(2 * np.pi * np.cumsum(f) / RATE) * env(len(x), 0.004, 0.05))
    # Grrbwak? - Zombie: tief, rauh, mit Zittern.
    z = glide_saw(150, 110, 0.45)
    z = formant(z, (450, 1100), 260) * (1 + 0.6 * np.sin(2 * np.pi * 22 * t(0.45)))
    write("huhn_zombie", np.concatenate([z * env(len(z), 0.01, 0.12), cluck(500, 300, 0.16, (800, 1600))]))
    # BUMM! - Rauschen, tief gefiltert, langes Ausklingen.
    n = rng.standard_normal(int(RATE * 0.7))
    b = bandpass(n, 30, 700) * np.exp(-np.linspace(0, 6, len(n)))
    b += 0.6 * np.sin(2 * np.pi * 55 * t(0.7)) * np.exp(-np.linspace(0, 8, len(n)))
    write("huhn_bumm", b)
    # Goldhuhn - aufsteigendes, helles Glitzern.
    notes = [1047, 1319, 1568, 2093]
    g = np.concatenate([np.sin(2 * np.pi * f * t(0.09)) * env(int(RATE * 0.09), 0.002, 0.05) for f in notes])
    write("huhn_gold", np.concatenate([g, cluck(1100, 700, 0.15)]))


if __name__ == "__main__":
    main()
