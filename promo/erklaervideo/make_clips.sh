#!/bin/bash
# Schneidet die Ausschnitte aus ../out als Einzelbilder (15 fps, JPEG) nach clips/<name>/.
cd "$(dirname "$0")"; mkdir -p clips
grep -v '^#' clips.txt | while read n f st d cx cy cw ch bl; do
  mkdir -p clips/$n; rm -f clips/$n/*.jpg
  if [ "$bl" = "-" ]; then
    vf="crop=$cw:$ch:$cx:$cy"
  else
    IFS=, read bx by bw bh <<< "$bl"
    vf="split[a][b];[b]crop=$bw:$bh:$bx:$by,boxblur=14:3[bb];[a][bb]overlay=$bx:$by,crop=$cw:$ch:$cx:$cy"
  fi
  ffmpeg -v error -y -ss $st -t $d -i ../out/$f -vf "$vf,scale='min(1500,iw*1.8)':-2:flags=lanczos,fps=15" -q:v 3 clips/$n/%03d.jpg </dev/null
  echo "$n $(ls clips/$n | wc -l)"
done
# Bildzahl je Ausschnitt fuer index.html
python3 - <<'PY'
import os, json
d = {n: len([f for f in os.listdir("clips/" + n) if f.endswith(".jpg")]) for n in sorted(os.listdir("clips")) if os.path.isdir("clips/" + n)}
open("clips.js", "w").write("window.CLIPS = " + json.dumps(d) + ";\n")
PY
