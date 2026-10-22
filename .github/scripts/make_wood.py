"""
Holzmaserung fuer das Aussehen „Klassisch“ (6.121.0.0, Wunsch: „Holzrahmen
und gelbe Umrandungen - kein einfaches Braun, sondern hoelzern“).

    python3 .github/scripts/make_wood.py

Eigene, gerechnete Textur (kein Spielmaterial): 256x256, in beide Richtungen
nahtlos kachelbar, dunkel genug, dass helle Schrift darauf lesbar bleibt.
Schreibt media/ui/wood.tga (32 Bit, Alpha voll).
"""

import math
import os
import random

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
N = 256


def periodic_noise(seed, freqs):
    rnd = random.Random(seed)
    waves = [(fx, fy, rnd.uniform(0, 2 * math.pi), amp) for fx, fy, amp in freqs]

    def f(x, y):
        return sum(a * math.sin(2 * math.pi * (fx * x + fy * y) / N + ph) for fx, fy, ph, a in waves)
    return f


def main():
    rnd = random.Random(7)
    # Ringe: viele Frequenzen nur ueber y (unregelmaessige Abstaende),
    # leicht verzogen ueber x - gerade Bretter, keine Wellen.
    rings = [(f, rnd.uniform(0, 2 * math.pi), 1.0 / (1 + f / 6)) for f in rnd.sample(range(4, 48), 14)]
    warp = periodic_noise(1, [(1, 0, 1.6), (2, 1, .8), (1, 2, .5)])
    streak = periodic_noise(2, [(3, 41, .5), (5, 67, .4), (2, 89, .3), (7, 113, .25)])
    img = Image.new("RGBA", (N, N))
    px = img.load()
    total = sum(a for _, _, a in rings)
    for y in range(N):
        for x in range(N):
            yy = y + warp(x, y)
            v = sum(a * math.sin(2 * math.pi * f * yy / N + ph) for f, ph, a in rings) / total
            band = 0.5 + 0.5 * v
            band = band ** 1.6
            light = 0.55 + 0.38 * band + 0.05 * streak(x, y)
            r, g, b = 0.40 * light, 0.24 * light, 0.12 * light
            px[x, y] = (int(min(1, r) * 255), int(min(1, g) * 255), int(min(1, b) * 255), 255)
    out = os.path.join(ROOT, "media", "ui", "wood.tga")
    img.save(out)
    print("media/ui/wood.tga")
    # Dieselbe Maserung fuer die Zeichnungen des Willkommens-Assistenten.
    img.convert("RGB").save(os.path.join(ROOT, ".github", "scripts", "welcome", "wood.png"))


if __name__ == "__main__":
    main()
