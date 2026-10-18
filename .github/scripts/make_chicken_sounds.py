#!/usr/bin/env python3
"""Toene der Huehnerjagd (ui/flightgames.lua), seit 6.78.3.0.

6.79.0.0 (Beta-Test: "Toene sind echt schlecht, das muss nach Huhn
klingen"): neu gerechnet wie eine Stimme statt aus glatten Wellen -
Impulsfolge der "Stimmbaender" mit Zittern (Jitter) und Rauheit, durch
Resonatoren (Formanten) im Bereich eines Schnabels, dazu Hauchrauschen.
Ein Huhn gackert in kurzen, rauen Silben ("bok bok bok") und endet mit
einem langen, ansteigenden "BAAK!". Keine Aufnahme, nichts von anderen.

    pip install numpy scipy soundfile
    python3 .github/scripts/make_chicken_sounds.py

schreibt media/sounds/huhn_*.ogg (Ogg Vorbis, mono, 44,1 kHz).
"""
import os

import numpy as np
import soundfile as sf
from scipy.signal import lfilter

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "sounds")
rng = np.random.default_rng(11)


def resonator(x, freq, bw):
    """Zweipoliger Resonator (Formant) bei freq mit Bandbreite bw."""
    r = np.exp(-np.pi * bw / RATE)
    th = 2 * np.pi * freq / RATE
    a = [1, -2 * r * np.cos(th), r * r]
    b = [1 - r]
    return lfilter(b, a, x)


def pulses(f0_curve, jitter=0.04, rough=0.35):
    """Stimmimpulse: je Periode ein kurzer, schiefer Puls, mit Zittern."""
    n = len(f0_curve)
    out = np.zeros(n)
    ph, i = 0.0, 0
    while i < n:
        f = f0_curve[i] * (1 + jitter * rng.standard_normal())
        period = max(8, int(RATE / max(f, 40)))
        amp = 1 + rough * rng.standard_normal()
        w = min(period, n - i)
        k = np.arange(w)
        out[i:i + w] += amp * np.exp(-k / (period * 0.18)) * np.sin(np.pi * k / max(period * 0.35, 1)).clip(0)
        i += period
    return out


def syllable(sec, f0_start, f0_peak, f0_end, formants, breath=0.25, peak_at=0.35, attack=0.008, release=0.04):
    n = int(RATE * sec)
    x = np.linspace(0, 1, n)
    f0 = np.where(x < peak_at,
                  f0_start + (f0_peak - f0_start) * (x / peak_at),
                  f0_peak + (f0_end - f0_peak) * ((x - peak_at) / (1 - peak_at)))
    src = pulses(f0)
    src += breath * rng.standard_normal(n)
    v = np.zeros(n)
    for f, bw, g in formants:
        v += g * resonator(src, f, bw)
    e = np.ones(n)
    a, r = int(RATE * attack), int(RATE * release)
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r)
    return v * e


# Formanten: offenes "a" eines schmalen Schnabels, nasal und hell.
HEN = [(950, 180, 1.0), (1750, 220, 0.8), (2900, 300, 0.5), (4200, 500, 0.25)]
CHICK = [(3200, 400, 1.0), (4800, 600, 0.5)]
UNDEAD = [(520, 160, 1.0), (1150, 220, 0.7), (2300, 300, 0.3)]


def bok():
    return syllable(0.075, 420, 520, 380, HEN, breath=0.3, peak_at=0.3, release=0.03)


def baak(scale=1.0):
    return syllable(0.32 * scale, 450, 1050, 700, HEN, breath=0.22, peak_at=0.25, release=0.09)


def gap(sec):
    return np.zeros(int(RATE * sec))


def norm(s, peak=0.85):
    m = np.max(np.abs(s)) or 1
    return s / m * peak


def write(name, s):
    sf.write(os.path.join(OUT, name + ".ogg"), norm(s).astype(np.float32), RATE, format="OGG", subtype="VORBIS")


def main():
    os.makedirs(OUT, exist_ok=True)
    # bok bok bok BAAK!
    write("huhn_gack", np.concatenate([bok(), gap(0.06), bok(), gap(0.06), bok(), gap(0.05), baak()]))
    # bok-bok (zwei Glucker)
    write("huhn_pock", np.concatenate([bok(), gap(0.08), bok()]))
    # BAAK-aak! (Schreck)
    write("huhn_bwaak", np.concatenate([baak(1.2), gap(0.03), syllable(0.15, 800, 900, 500, HEN, release=0.08)]))
    # Kueken: zwei hohe, steigende Piepser.
    pp = lambda: syllable(0.11, 2600, 3600, 3300, CHICK, breath=0.05, peak_at=0.6, release=0.04)
    write("huhn_piep", np.concatenate([pp(), gap(0.05), pp()]))
    # Zombie: tiefes, gezogenes Graaaak mit Gurgeln.
    z = syllable(0.55, 180, 260, 140, UNDEAD, breath=0.5, peak_at=0.3, release=0.15)
    z *= 1 + 0.5 * np.sin(2 * np.pi * 17 * np.arange(len(z)) / RATE)
    write("huhn_zombie", z)
    # Bombe: kurzer Schreck, dann Bumm.
    n = int(RATE * 0.6)
    boom = lfilter([1], [1, -0.985], rng.standard_normal(n)) * np.exp(-np.linspace(0, 7, n))
    boom = boom / (np.max(np.abs(boom)) or 1)
    write("huhn_bumm", np.concatenate([0.6 * norm(baak(0.6)), boom]))
    # Goldhuhn: stolzes Kikeriki in vier Silben.
    ki = lambda f: syllable(0.09, f, f * 1.15, f, HEN, breath=0.15, peak_at=0.5, release=0.03)
    write("huhn_gold", np.concatenate([ki(700), gap(0.03), ki(820), gap(0.03), ki(900),
                                       gap(0.02), syllable(0.45, 900, 1250, 800, HEN, breath=0.15, peak_at=0.3, release=0.15)]))


if __name__ == "__main__":
    main()
