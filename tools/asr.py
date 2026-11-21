# 꺼낸 음성을 받아쓴다: asr.py <ogg 폴더> <이름>  →  data/<이름>/*.wav + data/<이름>.list (GPT-SoVITS 형식)
import sys, pathlib, subprocess
from faster_whisper import WhisperModel
src, name = pathlib.Path(sys.argv[1]), sys.argv[2]
out = pathlib.Path("data") / name; out.mkdir(parents=True, exist_ok=True)
m = WhisperModel("large-v3", device="cpu", compute_type="int8", cpu_threads=8)
rows = []
for f in sorted(src.glob("*.ogg")):
    w = out / (f.stem + ".wav")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(f), "-ac", "1", "-ar", "32000", str(w)], check=True)
    segs, info = m.transcribe(str(w), language="ko", beam_size=5, condition_on_previous_text=False)
    text = " ".join(s.text.strip() for s in segs).strip()
    rows.append(f"{w.resolve()}|{name}|ko|{text}|{info.duration:.2f}")
    print(rows[-1].split("/")[-1], flush=True)
pathlib.Path(f"data/{name}.tsv").write_text("\n".join(rows) + "\n")
