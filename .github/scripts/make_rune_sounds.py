#!/usr/bin/env python3
"""Toene der Runenfolge (ui/flightgames.lua).

1.0.8.4 (Rueckmeldung: "Beim Spiel Runenfolge gibt es keine Toene"): jede
der vier Runen ein eigener Ton, damit man sich die Folge auch mit dem Ohr
merkt.

1.0.8.14 (Wunsch: "mach die Toene besser"): die ersten Toene waren nackte
Sinus-Glocken in Mono ohne Raum - duenn und piepsig, der Fehlerton ein
schwebender Brummton. Jetzt:

* Runen: Kristallklang - Grundton, weiche Obertoene, zwei leicht
  verstimmte Stimmen (Chorus) und ein FM-Anschlag, der nach 80 ms
  verklingt; 6 ms weicher Einsatz, 1,2 s natuerliches Ausklingen.
  Tiefer gelegt (G4, C5, E5, G5 - ein C-Dur-Akkord): voller, weniger
  schrill, jede Mischung klingt zusammen.
* Raum: kleiner Hall (Schroeder: vier Kammfilter, zwei Allpaesse), links
  und rechts verschieden - Stereo mit Breite statt Mono.
* Geschafft: die vier Runen als Arpeggio aufwaerts, der Schlussakkord
  klingt nach.
* Fehler: zwei weiche, tiefe Toene abwaerts (E4 -> C4), gedaempft - sagt
  "nein", ohne zu schnarren.

Gerechnet, keine Aufnahme, nichts von anderen.

    pip install numpy scipy soundfile
    python3 .github/scripts/make_rune_sounds.py

schreibt media/sounds/rune_1..4.ogg, rune_ok.ogg, rune_fail.ogg
(Ogg Vorbis, Stereo, 44,1 kHz).
"""
import os

import numpy as np
import soundfile as sf
from scipy.signal import lfilter

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "sounds")

# G4, C5, E5, G5 - eine Rune je Ton (C-Dur).
NOTES = [392.00, 523.25, 659.25, 783.99]

# Obertoene des Kristalls: Verhaeltnis, Lautstaerke, Abklingen (je s).
PARTIALS = [(1.0, 1.0, 2.6), (2.0, 0.28, 4.5), (3.0, 0.10, 7.0), (4.2, 0.05, 11.0)]


def _t(secs):
    return np.arange(int(RATE * secs)) / RATE


def crystal(freq, secs=1.25, attack=0.006):
    t = _t(secs)
    out = np.zeros_like(t)
    for detune in (-0.0012, 0.0012):          # zwei Stimmen, +-2 Cent
        f = freq * (1 + detune)
        for ratio, amp, decay in PARTIALS:
            out += amp * np.exp(-decay * t) * np.sin(2 * np.pi * f * ratio * t)
    # Anschlag: kurzer FM-Glanz, der schnell verklingt.
    mod = np.sin(2 * np.pi * freq * 3.5 * t) * 1.8 * np.exp(-30 * t)
    out += 0.35 * np.exp(-12 * t) * np.sin(2 * np.pi * freq * t + mod)
    env = np.minimum(1.0, t / attack) * np.minimum(1.0, (secs - t) / 0.08)
    return out * env


def _comb(x, delay, feedback, damp):
    # Kammfilter mit Daempfung im Rueckweg (Tiefpass 1. Ordnung).
    y = np.zeros(len(x) + delay)
    y[:len(x)] = x
    lp = 0.0
    buf = np.zeros(len(y))
    for n in range(len(y)):
        d = buf[n - delay] if n >= delay else 0.0
        lp = d * (1 - damp) + lp * damp
        buf[n] = y[n] + lp * feedback
    return buf


def _allpass(x, delay, g=0.5):
    b = np.zeros(delay + 1)
    a = np.zeros(delay + 1)
    b[0], b[-1] = -g, 1.0
    a[0], a[-1] = 1.0, -g
    return lfilter(b, a, x)


def reverb(x, combs, mix=0.22, tail=0.9):
    pad = np.concatenate([x, np.zeros(int(RATE * tail))])
    wet = np.zeros(len(pad))
    for d in combs:
        c = _comb(pad, d, 0.78, 0.35)[:len(pad)]
        wet += c
    wet /= len(combs)
    wet = _allpass(wet, 225)
    wet = _allpass(wet, 556)
    return (1 - mix) * pad + mix * wet


def stereo(mono):
    # Links und rechts verschiedene Raeume: Breite ohne Verschieben.
    left = reverb(mono, (1116, 1188, 1277, 1356))
    right = reverb(mono, (1139, 1211, 1300, 1379))
    n = min(len(left), len(right))
    st = np.stack([left[:n], right[:n]], axis=1)
    # Ende sanft auf null.
    fade = int(RATE * 0.15)
    st[-fade:] *= np.linspace(1, 0, fade)[:, None]
    return st


def normalize(st, peak):
    return peak * st / np.max(np.abs(st))


def write(name, data):
    path = os.path.join(OUT, name + ".ogg")
    sf.write(path, data.astype(np.float32), RATE, format="OGG", subtype="VORBIS")
    print("geschrieben:", os.path.relpath(path))


def main():
    os.makedirs(OUT, exist_ok=True)
    for i, f in enumerate(NOTES, start=1):
        write("rune_%d" % i, normalize(stereo(crystal(f)), 0.5))

    # Geschafft: Arpeggio G4 C5 E5 G5, dann C6 obendrauf, alles klingt nach.
    gap = int(RATE * 0.075)
    notes = NOTES + [1046.50]
    total = gap * (len(notes) - 1) + int(RATE * 1.4)
    ok = np.zeros(total)
    for k, f in enumerate(notes):
        tone = crystal(f, 1.4) * (0.75 if k < len(notes) - 1 else 1.0)
        ok[k * gap:k * gap + len(tone)] += tone
    write("rune_ok", normalize(stereo(ok), 0.5))

    # Fehler: zwei weiche, tiefe Toene abwaerts, gedaempft (nur Grundton
    # und eine leise Oktave, schnelles Abklingen).
    def soft(freq, secs):
        t = _t(secs)
        x = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * freq * 2 * t)
        return x * np.exp(-5.5 * t) * np.minimum(1.0, t / 0.012) * np.minimum(1.0, (secs - t) / 0.05)

    first, second = soft(329.63, 0.32), soft(261.63, 0.55)
    off = int(RATE * 0.16)
    fail = np.zeros(off + len(second))
    fail[:len(first)] += first
    fail[off:] += second
    write("rune_fail", normalize(stereo(fail), 0.45))


if __name__ == "__main__":
    main()
