#!/bin/bash
DUR=$(python3 -c "import json;print(json.load(open(\"timeline.json\"))[\"duration\"]+3)")
ffmpeg -v error -y -i voice.wav -i music2.wav -filter_complex "\
[0:a]aresample=48000,apad=whole_dur=$DUR,highpass=f=75,equalizer=f=250:t=q:w=1:g=-2,equalizer=f=3500:t=q:w=1.2:g=3,acompressor=threshold=0.1:ratio=3:attack=5:release=120:makeup=1.5,aecho=0.85:0.6:28|47:0.12|0.07,pan=stereo|c0=c0|c1=c0,asplit=2[vo][key];\
[1:a]aresample=48000,volume=0.42[mu];\
[mu][key]sidechaincompress=threshold=0.012:ratio=8:attack=15:release=450:makeup=1[duck];\
[vo][duck]amix=inputs=2:normalize=0:duration=longest,atrim=0:$DUR,loudnorm=I=-14:TP=-2.5:LRA=11,alimiter=limit=0.7:level=disabled[out]" -map "[out]" -ar 48000 mix.wav
