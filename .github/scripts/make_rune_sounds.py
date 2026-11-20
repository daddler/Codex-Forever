#!/usr/bin/env python3
"""Toene der Runenfolge (ui/flightgames.lua), seit 1.0.8.4.

Rueckmeldung: "Beim Spiel Runenfolge gibt es keine Toene." Jede der vier
Runen bekommt einen eigenen Glockenton - so merkt man sich die Folge auch
mit dem Ohr. Die vier Toene liegen auf C-Dur (C5, E5, G5, C6): jede
Mischung klingt zusammen, keine Folge schraeg. Dazu ein kurzer Aufstieg
fuer eine geschaffte Runde und ein tiefer, gedaempfter Ton fuer einen
Fehler. Gerechnet, keine Aufnahme, nichts von anderen.

Klang einer Glocke: Grundton plus leicht unharmonische Teiltoene, die
schneller abklingen als der Grundton; weicher Anschlag (2 ms), damit nichts
knackt.

    pip install numpy soundfile
    python3 .github/scripts/make_rune_sounds.py

schreibt media/sounds/rune_1..4.ogg, rune_ok.ogg, rune_fail.ogg
(Ogg Vorbis, mono, 44,1 kHz).
"""
import os

import numpy as np
import soundfile as sf

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "media", "sounds")

# C5, E5, G5, C6 - eine Rune je Ton.
NOTES = [523.25, 659.25, 783.99, 1046.50]
# Teiltoene einer Glocke: Verhaeltnis, Lautstaerke, Abklingen (je s).
PARTIALS = [(1.0, 1.0, 5.0), (2.0, 0.45, 8.0), (2.76, 0.25, 11.0), (5.4, 0.12, 18.0)]


def bell(freq, secs=0.55, gain=0.55):
    t = np.arange(int(RATE * secs)) / RATE
    out = np.zeros_like(t)
    for ratio, amp, decay in PARTIALS:
        out += amp * np.exp(-decay * t) * np.sin(2 * np.pi * freq * ratio * t)
    attack = np.minimum(1.0, t / 0.002)
    tail = np.minimum(1.0, (secs - t) / 0.03)
    out *= attack * tail
    return gain * out / np.max(np.abs(out))


def write(name, data):
    path = os.path.join(OUT, name + ".ogg")
    sf.write(path, data.astype(np.float32), RATE, format="OGG", subtype="VORBIS")
    print("geschrieben:", os.path.relpath(path))


def main():
    os.makedirs(OUT, exist_ok=True)
    for i, f in enumerate(NOTES, start=1):
        write("rune_%d" % i, bell(f))
    # Geschafft: drei Toene aufwaerts, kurz hintereinander.
    gap = int(RATE * 0.09)
    parts = [bell(f, 0.35, 0.45) for f in (NOTES[0], NOTES[2], NOTES[3])]
    ok = np.zeros(gap * 2 + len(parts[-1]))
    for k, p in enumerate(parts):
        ok[k * gap:k * gap + len(p)] += p
    write("rune_ok", 0.6 * ok / np.max(np.abs(ok)))
    # Fehler: tiefer, gedaempfter Doppelton, leicht verstimmt (schwebt).
    t = np.arange(int(RATE * 0.45)) / RATE
    fail = (np.sin(2 * np.pi * 146.8 * t) + 0.8 * np.sin(2 * np.pi * 155.6 * t)) * np.exp(-6 * t)
    fail *= np.minimum(1.0, t / 0.004) * np.minimum(1.0, (0.45 - t) / 0.03)
    write("rune_fail", 0.5 * fail / np.max(np.abs(fail)))


if __name__ == "__main__":
    main()
