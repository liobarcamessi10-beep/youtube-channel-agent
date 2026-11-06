# YouTube channel agent (Lebanese Arabic, used cars / practical guides)

Weekly routine, Monday 10:00 Beirut. Two long videos per week. The human reviews and uploads; nothing is published from here.

1. Setup: `bash pipeline/setup.sh` (rebuilds tools in /tmp/yt-work, installs the yt-* skills).
2. Ideas: propose 3 ideas for the channel (use /yt-plan, /yt-viral if possible). Wait for the user to pick 2.
3. Per video, in `videos/NN-slug/`:
   - `script.md` with /yt-script (Lebanese dialect, no invented numbers, mark facts the user must verify).
   - `description.md` with /yt-package + /yt-seo (Arabic + English, checklist, chapters from out/timeline.json).
   - `scenes.py` (spoken text per scene, copied from the script) and `video.html` (visuals; start from videos/01-*/video.html: 1920x1080, Cairo font, captions, data-s sentence sync, no emoji, no invented numbers).
   - Preview: `cd /tmp/yt-work/vid && NODE_PATH=$(npm root -g) node build.js preview` and look at prev/*.png before the full render.
   - Build: `bash pipeline/make.sh videos/NN-slug` -> out/video-myvoice.mp4 and out/video-rami.mp4.
4. Send the user the videos + description. Remind them: AI-altered voice must be disclosed in YouTube Studio.
5. Commit script/description/scenes/html (not mp4) and push.

Voice: edge-tts ar-LB-RamiNeural at +12%, converted to the user's timbre with OpenVoice v2 (voice/me.wav, watermark kept on).
