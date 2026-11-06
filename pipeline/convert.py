"""Convert each scene's Rami TTS clip to the user's voice timbre with OpenVoice v2."""
import sys, os, glob, subprocess
V = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(V, "src"))
import torch
from openvoice.api import ToneColorConverter

VID = os.path.join(os.path.dirname(V), "vid")
OUT = os.path.join(V, "out"); os.makedirs(OUT, exist_ok=True)
conv = ToneColorConverter(os.path.join(V, "ckpt/converter/config.json"), device="cpu")
conv.load_ckpt(os.path.join(V, "ckpt/converter/checkpoint.pth"))

def wav(src, dst):
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", src, "-ac", "1", "-ar", "22050", dst], check=True)

target_se = conv.extract_se([os.path.join(V, "ref/me.wav")], se_save_path=os.path.join(V, "ref/me_se.pth"))
# source speaker embedding: all of Rami's clips together
srcs = []
for mp3 in sorted(glob.glob(os.path.join(VID, "audio/*.mp3"))):
    w = os.path.join(OUT, os.path.basename(mp3)[:-4] + "_rami.wav"); wav(mp3, w); srcs.append(w)
source_se = conv.extract_se(srcs, se_save_path=os.path.join(V, "ref/rami_se.pth"))

only = sys.argv[1:]  # optional scene numbers, e.g. 00
for w in srcs:
    n = os.path.basename(w)[:2]
    if only and n not in only: continue
    out = os.path.join(OUT, f"{n}.wav")
    conv.convert(audio_src_path=w, src_se=source_se, tgt_se=target_se, output_path=out, tau=0.3)
    print("done", n, flush=True)
