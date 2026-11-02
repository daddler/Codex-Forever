#!/usr/bin/env python3
"""Meme-Toene fuer "Raus da!" (1.10.1.0, Wunsch des Besitzers; vier seit 1.10.3.0).

Aufruf (im Wurzelordner des Repos):

    python3 .github/scripts/make_meme_sounds.py <Ordner mit den mp3> [Schluessel ...]

Ohne Schluessel alle; mit Schluessel nur diese (z. B. meme_hallo).

Die mp3 liegen NICHT im Repo; der Besitzer hat sie geliefert. Dieses Skript
haelt fest, welcher Ausschnitt genommen wurde und warum, damit ein neuer
Schnitt nachvollziehbar bleibt.

SCHNITT. Ohne Spracherkennung (kein Modell in der Bauumgebung) aus
Lautstaerke und Spektrogramm: Sprache erscheint dort als gestapelte,
gebogene Obertoene, Hintergrund als Rauschen oder gleichbleibender Ton.
  * raus: Stimme 3,60-5,35 s; davor nur Hintergrund und ein Knall (1,7 s).
  * fahr: drei laute Rufe 3,70-8,40 s; davor Motorbrummen, danach Leiseres.
  * rose: 1,94-7,33 s - vom Besitzer nach Gehoer festgelegt (1.10.2.0);
    der erste Schnitt 0,25-4,10 s nach dem Spektrogramm lag daneben.
  * hallo: 17,50-20,80 s - vom Besitzer festgelegt (1.10.3.0).
Jeder Ton: mono, 44,1 kHz, Ogg Vorbis, Lautheit angeglichen (-16 LUFS,
Spitze -1,5 dB), 0,02 s Ein- und 0,12 s Ausblenden gegen Knacken.
"""

import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "media", "sounds")

# Schluessel -> (Quelldatei, Start, Ende)
CUTS = {
    "meme_raus": ("raus.mp3", 3.60, 5.35),
    "meme_fahr": ("fahr.mp3", 3.70, 8.40),
    "meme_rose": ("rose.mp3", 1.94, 7.33),
    "meme_hallo": ("hallo.mp3", 17.50, 20.80),
}


def ffmpeg():
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        return "ffmpeg"


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    only = set(sys.argv[2:])
    unknown = only - set(CUTS)
    if unknown:
        sys.exit("Unbekannt: " + ", ".join(sorted(unknown)))
    src = sys.argv[1]
    ff = ffmpeg()
    for key, (name, start, end) in CUTS.items():
        if only and key not in only:
            continue
        length = end - start
        filters = ",".join([
            "loudnorm=I=-16:TP=-1.5:LRA=11",
            "afade=t=in:st=0:d=0.02",
            f"afade=t=out:st={length - 0.12:.3f}:d=0.12",
        ])
        target = os.path.join(OUT, key + ".ogg")
        subprocess.run([ff, "-hide_banner", "-loglevel", "error", "-y",
                        "-ss", f"{start:.2f}", "-i", os.path.join(src, name),
                        "-t", f"{length:.2f}", "-af", filters, "-ac", "1", "-ar", "44100",
                        "-map", "0:a:0", "-vn", "-c:a", "libvorbis", "-q:a", "5", "-map_metadata", "-1", target], check=True)
        print(f"{key}: {start:.2f}-{end:.2f} s -> {os.path.relpath(target, ROOT)}")


if __name__ == "__main__":
    main()
