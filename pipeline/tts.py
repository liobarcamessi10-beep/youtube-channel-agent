import sys, subprocess, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scenes import SCENES
W = os.path.dirname(os.path.abspath(__file__))
env = dict(os.environ, SSL_CERT_FILE="/root/.ccr/ca-bundle.crt")
out = []
for i, (kind, text) in enumerate(SCENES):
    mp3 = f"{W}/audio/{i:02d}.mp3"; srt = f"{W}/audio/{i:02d}.srt"
    subprocess.run([f"{W}/venv/bin/edge-tts", "--proxy", os.environ["HTTPS_PROXY"], "--voice", "ar-LB-RamiNeural", "--rate=+12%",
                    "--text", text, "--write-media", mp3, "--write-subtitles", srt], check=True, env=env)
    d = float(subprocess.check_output(["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0",mp3]))
    out.append({"kind": kind, "dur": d})
    print(i, kind, round(d,1))
json.dump(out, open(f"{W}/audio/durs.json","w"))
print("total", round(sum(o["dur"] for o in out),1))
