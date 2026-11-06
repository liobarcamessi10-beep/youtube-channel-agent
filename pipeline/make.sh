#!/usr/bin/env bash
# Build one video: pipeline/make.sh videos/01-salvage-cars-lebanon
# The folder holds scenes.py (spoken text per scene) and video.html (the visuals).
# Output: <folder>/out/video-myvoice.mp4 and video-rami.mp4 (git-ignored).
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-/tmp/yt-work}"
DIR="$(cd "$1" && pwd)"
export HF_HUB_DISABLE_XET=1 SSL_CERT_FILE="${SSL_CERT_FILE:-/root/.ccr/ca-bundle.crt}"

cp "$DIR/scenes.py" "$DIR/video.html" "$WORK/vid/"
rm -f "$WORK"/vid/audio/* "$WORK"/vc/out/*
python3 -I "$WORK/vid/tts.py"                     # Rami (ar-LB) per scene + sentence timings
(cd "$WORK/vc" && venv/bin/python convert.py)      # same clips in the user's voice

cd "$WORK/vid/audio"
VC="$WORK/vc" python3 -I - <<'PY'
import json, subprocess, os
d = json.load(open('durs.json')); GAP = 0.45; V = os.environ['VC']
for name, src in [('voice.m4a', '{i:02d}.mp3'), ('myvoice.m4a', V + '/out/{i:02d}.wav')]:
    inputs, filt, t = [], [], 0
    for i, x in enumerate(d):
        inputs += ['-i', src.format(i=i)]; ms = int(t * 1000)
        filt.append(f'[{i}]adelay={ms}|{ms}[a{i}]'); t += x['dur'] + GAP
    f = ';'.join(filt) + ';' + ''.join(f'[a{i}]' for i in range(len(d))) + \
        f'amix=inputs={len(d)}:normalize=0,apad=whole_dur={t:.3f},atrim=0:{t:.3f},loudnorm=I=-16:TP=-1.5:LRA=11[out]'
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', *inputs, '-filter_complex', f, '-map', '[out]',
                    '-ac', '2', '-ar', '48000', '-c:a', 'aac', '-b:a', '192k', '../' + name], check=True)
PY

cd "$WORK/vid" && NODE_PATH="$(npm root -g)" node build.js full
mkdir -p "$DIR/out"
ffmpeg -y -loglevel error -i silent.mp4 -i myvoice.m4a -map 0:v -map 1:a -c copy -shortest -movflags +faststart "$DIR/out/video-myvoice.mp4"
ffmpeg -y -loglevel error -i silent.mp4 -i voice.m4a -map 0:v -map 1:a -c copy -shortest -movflags +faststart "$DIR/out/video-rami.mp4"
cp timeline.json "$DIR/out/"
echo "done: $DIR/out"
