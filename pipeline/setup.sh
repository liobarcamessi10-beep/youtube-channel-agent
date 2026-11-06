#!/usr/bin/env bash
# Rebuild the working tools in $WORK (default /tmp/yt-work). Safe to re-run.
# Needs hosts: speech.platform.bing.com, huggingface.co, us.aws.cdn.hf.co (plus PyPI/npm).
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-/tmp/yt-work}"
mkdir -p "$WORK/vid/audio" "$WORK/vc/ref" "$WORK/vc/ckpt/converter" ~/.claude/skills

# skills
cp -r "$REPO"/skills/yt-* ~/.claude/skills/

# video renderer + Lebanese TTS
cp "$REPO"/pipeline/{video.html,build.js,tts.py,scenes.py} "$WORK/vid/"
[ -d "$WORK/vid/venv" ] || python3 -m venv "$WORK/vid/venv"
"$WORK/vid/venv/bin/pip" install -q edge-tts
if [ ! -f "$WORK/vid/deps/package/files/cairo-arabic-900-normal.woff2" ]; then
  mkdir -p "$WORK/vid/deps" && (cd "$WORK/vid/deps" && npm pack -q @fontsource/cairo@5.2.5 >/dev/null && tar xzf fontsource-cairo-*.tgz)
fi

# voice cloning (OpenVoice v2 tone converter, MIT)
cp "$REPO/pipeline/convert.py" "$WORK/vc/"
cp "$REPO/voice/me.wav" "$WORK/vc/ref/me.wav"
[ -d "$WORK/vc/src" ] || git clone -q --depth 1 https://github.com/myshell-ai/OpenVoice.git "$WORK/vc/src"
[ -d "$WORK/vc/venv" ] || python3 -m venv "$WORK/vc/venv"
"$WORK/vc/venv/bin/pip" install -q torch torchaudio librosa soundfile numpy inflect unidecode eng_to_ipa pypinyin cn2an jieba langid wavmark
for f in config.json checkpoint.pth; do
  [ -s "$WORK/vc/ckpt/converter/$f" ] || curl -sSL -o "$WORK/vc/ckpt/converter/$f" "https://huggingface.co/myshell-ai/OpenVoiceV2/resolve/main/converter/$f"
done
echo "setup ok: $WORK"
