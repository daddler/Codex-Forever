# Erklärvideo WeintCodex – Forever Edition

Erklärvideo für das Addon mit rund 10 Minuten in 1920×1080, auf Deutsch, mit Sprecher, Untertiteln und Musik.
Aufbau und Stil kommen vom Werbevideo (`Companion-Forever/promo/werbevideo`, Branch `claude/discord-bot-cleanup-dplmua`).
Die gerenderte Fassung liegt nicht im Repo, weil sie zu groß ist. Die Spielaufnahmen (`out/`) liegen ebenfalls nicht im Repo.

## Aufbau

| Datei | Zweck |
|---|---|
| `tts/script.json` | Sprechertext: 15 Szenen, 132 Sätze. Die Sätze sind auch die Untertitel. |
| `tts/build_voice_piper.py`, `tts/scenes.py` | Vorschau-Stimme mit Piper (`de_DE-thorsten-high`). Legt die Szenen auf ganze Takte (110 BPM) mit 2 Takten Titelkarte. In `scenes.py` steht die Musikart je Szene. Ergebnis: `voice.wav`, `timeline.json`, `timeline.js`. |
| `tts/split_el.py`, `tts/build_voice_el.py` | ElevenLabs-Aufnahme an den Pausen schneiden, den Sätzen zuordnen, Zeitleiste bauen (aus dem Werbevideo). |
| `clips.txt`, `make_clips.sh` | Ausschnitte aus den Spielaufnahmen: Zeit, Zuschnitt aufs Fenster, Bereiche mit fremden Namen unscharf. Ergebnis: `clips/<name>/*.jpg` (15 fps) und `clips.js`. |
| `assets/` | Logo, Navigationssymbole, Dungeon-Header (aus `Codex-Forever/media`), Bilder der Willkommens-Szenen und die neuen Bilder (Quelle: `bilder/shots_neu.html`, gleicher Stil wie `make_welcome.py`). |
| `index.html` | Alle Szenen. Jede Bildtafel hängt an einem Satz (`PLAN`), dadurch passt sie zu jeder Stimme. Gesteuert über `setTime(t)`. |
| `music2.py` | Musik aus `timeline.json`, a-Moll, 110 BPM. Neu sind „calm“ und „groove“, drei Akkordfolgen und drei Arpeggio-Muster im Wechsel. |
| `mix.sh` | Stimme bearbeiten, Ducking, Lautheit −14 LUFS. Die Länge kommt aus `timeline.json`. |
| `render.js`, `preview.js` | Bild für Bild mit Playwright (`playwright-core` und `/usr/bin/chromium`, oder `CHROME=…`). |
| `kapitel.py` | Kapitelverzeichnis für YouTube aus `timeline.json`. |

## Bauen

```bash
pip install piper-tts scipy soundfile numpy        # dazu für ElevenLabs die Whisper-Modelle wie im Werbevideo
npm install
./make_clips.sh                                    # braucht ../out mit den Aufnahmen (nicht im Repo)
# Stimme, entweder Vorschau:
python3 tts/build_voice_piper.py /pfad/de_DE-thorsten-high.onnx "$PWD"
# oder ElevenLabs (voice/elevenlabs_roger.mp3), dann in timeline.js "voice": "elevenlabs" setzen (Abspann):
#   cd tts && python3 split_el.py && python3 build_voice_el.py ..
python3 music2.py timeline.json music2.wav
./mix.sh
node render.js "$PWD"
D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 video_noaudio.mp4)
ffmpeg -i video_noaudio.mp4 -i mix.wav -filter_complex "[1:a]atrim=0:$D,afade=t=out:st=$(python3 -c "print($D-2.2)"):d=2.2[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 256k -movflags +faststart ../out/WeintCodex_Erklaervideo.mp4
python3 kapitel.py > ../out/kapitel.txt
```

## Regeln für den Inhalt

- Alle Fakten stammen aus dem Code von Codex-Forever (Stand 1.4.0.0). Seitennamen und Schalter sind so geschrieben, wie sie im Addon heißen.
- Es gibt keine Taktiken: Das Addon zeigt die Fähigkeiten der Bosse, die Taktik kommt nur vom Bot (`/weintboss`).
- Es werden keine fremden Addons genannt. Der Ausschnitt „Handel“ ist deshalb so zugeschnitten, dass die rechte Spalte fehlt.
- Es gibt kein Material aus Mists of Pandaria.
- Fremde Spielernamen sind weggeschnitten oder unscharf (`clips.txt`, Spalte `blur`). Beispieldaten sind mit „Beispiel“ gekennzeichnet.
- Im Abspann steht „Stimme: ElevenLabs“, in der Piper-Vorschau zusätzlich „(Vorschau: Piper)“.
