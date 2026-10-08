#!/usr/bin/env python3
"""Eigene Warntoene fuer "Raus da" (ui/firealarm.lua), seit 6.25.0.0.

Beta-Test: "noch praegnantere Toene, so wie es GTFO auch hat". GTFO bringt
eigene Tondateien mit - die gehoeren seinen Autoren und kommen hier nicht
hinein. Diese Toene sind gerechnet (Sinus, Rechteck, Saegezahn mit
Huellkurve), kurz, laut und klar voneinander zu unterscheiden.

    pip install numpy soundfile
    python3 .github/scripts/make_sounds.py

schreibt media/sounds/*.ogg (Ogg Vorbis, mono, 44,1 kHz).
"""
import os

import numpy as np
import soundfile as sf

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "sounds")


def t(sec):
    return np.arange(int(RATE * sec)) / RATE


def env(n, attack=0.004, release=0.03):
    e = np.ones(n)
    a, r = int(RATE * attack), int(RATE * release)
    if a: e[:a] = np.linspace(0, 1, a)
    if r: e[-r:] *= np.linspace(1, 0, r)
    return e


def square(f, x, soft=6):
    # Rechteck aus wenigen Obertoenen: scharf, aber ohne Knacksen.
    s = np.zeros_like(x)
    for k in range(1, soft * 2, 2):
        s += np.sin(2 * np.pi * f * k * x) / k
    return s


def saw(f, x, soft=10):
    s = np.zeros_like(x)
    for k in range(1, soft + 1):
        s += np.sin(2 * np.pi * f * k * x) / k
    return s


def silence(sec):
    return np.zeros(int(RATE * sec))


def beep(f, sec, kind="square"):
    x = t(sec)
    w = square(f, x) if kind == "square" else saw(f, x) if kind == "saw" else np.sin(2 * np.pi * f * x)
    return w * env(len(x))


def norm(w, peak=0.8):
    return w / np.max(np.abs(w)) * peak


SOUNDS = {
    # Zwei hohe Pieptoene, schnell: "sofort raus".
    "hoch": lambda: np.concatenate([beep(1760, 0.09), silence(0.04), beep(2093, 0.12)]),
    # Tiefes Brummen in drei Stoessen: "da ist was am Boden".
    "tief": lambda: np.concatenate([beep(196, 0.11, "saw"), silence(0.035),
                                    beep(196, 0.11, "saw"), silence(0.035),
                                    beep(165, 0.16, "saw")]),
    # Drei gleiche, durchdringende Toene.
    "dreifach": lambda: np.concatenate([beep(1319, 0.07), silence(0.05),
                                        beep(1319, 0.07), silence(0.05),
                                        beep(1319, 0.07)]),
    # Hupe: zwei Saegezaehne im Abstand einer kleinen Sekunde, schwebend.
    "hupe": lambda: (lambda x: (saw(415, x) + saw(440, x)) * env(len(x), 0.006, 0.05))(t(0.32)),
    # Sirene: Ton gleitet schnell nach oben.
    "sirene": lambda: (lambda x: np.sin(2 * np.pi * np.cumsum(
        np.linspace(700, 1900, len(x))) / RATE) * env(len(x), 0.005, 0.04))(t(0.35)),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, make in SOUNDS.items():
        path = os.path.join(OUT, name + ".ogg")
        sf.write(path, norm(make()), RATE, format="OGG", subtype="VORBIS")
        print(path)


if __name__ == "__main__":
    main()
