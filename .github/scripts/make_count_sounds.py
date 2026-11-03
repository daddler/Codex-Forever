#!/usr/bin/env python3
"""Gesprochene Zaehlung "fuenf ... eins" fuer die Bosskaempfe (1.10.14.0).

Aufruf (im Wurzelordner des Repos, in einer Umgebung mit espeakng-loader
und imageio-ffmpeg):

    pip install espeakng-loader imageio-ffmpeg
    python3 -I .github/scripts/make_count_sounds.py

Schreibt media/sounds/count_1.ogg ... count_5.ogg.

SEIT 1.10.14.1 NICHT MEHR IN GEBRAUCH: die Zaehlung im Repo stammt aus einer
ElevenLabs-Aufnahme des Besitzers (Stimme "René Deutschmann", eins bis zehn
in einer Datei, zweite Aufnahme mit laengeren Pausen (1.10.14.2); geschnitten
0,00-0,56 / 0,56-1,22 / 1,22-1,94 / 1,94-2,62 / 2,66-3,38 s, 10 ms ein-, 50 ms ausgeblendet, -16 LUFS). Die Reihenfolge ist
aus dem Klang bestimmt (scharfes s am Ende von "eins", s vorn und hinten bei
"sechs"), nicht gehoert. Dieses Skript bleibt als Rueckfall.

HERKUNFT: eigene Sprachausgabe mit espeak-ng (Stimme "de"), erzeugt von
.github/scripts/speak_espeak.py. Die Ausgabe eines Sprachprogramms ist kein
Werk des Programms - die Dateien gehoeren uns. Die Stimmen von DBM sind nur
fuer DBM freigegeben und bleiben draussen.
Je Zahl: Stille vorn/hinten weg, Lautheit -16 LUFS, mono 44,1 kHz Vorbis.
"""
import os, subprocess, sys, tempfile
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
WORDS = {1: "eins", 2: "zwei", 3: "drei", 4: "vier", 5: "fünf"}

def main():
    import imageio_ffmpeg
    ff = imageio_ffmpeg.get_ffmpeg_exe()
    tmp = tempfile.mkdtemp()
    args = [sys.executable, "-I", os.path.join(ROOT, ".github", "scripts", "speak_espeak.py"), "de", "x", "150"]
    for n, w in WORDS.items():
        args += [w, os.path.join(tmp, f"{n}.wav")]
    subprocess.run(args, check=True)
    for n in WORDS:
        out = os.path.join(ROOT, "media", "sounds", f"count_{n}.ogg")
        flt = "silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse,loudnorm=I=-16:TP=-1.5"
        subprocess.run([ff, "-v", "error", "-y", "-i", os.path.join(tmp, f"{n}.wav"), "-af", flt,
                        "-ac", "1", "-ar", "44100", "-map", "0:a:0", "-vn", "-c:a", "libvorbis", "-q:a", "5",
                        "-map_metadata", "-1", out], check=True)
        print(os.path.relpath(out, ROOT))

if __name__ == "__main__":
    main()
