#!/usr/bin/env python3
"""미리 만든 대사(assets/voice/<who>/*.wav)를 받아써서 대본과 견준다. 중간에 끊겼거나 다르게 읽은 파일은 지운다
(→ voice-lines.py 를 다시 돌리면 그 대사만 새로 만든다).   venv/bin/python voice-check.py [arona|plana]   종료 코드 1 = 지운 것이 있음"""
import re, json, sys, pathlib, difflib
from faster_whisper import WhisperModel
Q = pathlib.Path.home() / ".config/quickshell"
src = (Q / "Arona.qml").read_text()
READ = {r"caps\s*lock": "캡스 락", r"wi-?fi": "와이파이", r"gemini": "제미나이", r"api": "에이피아이", r"mb": "메가바이트", r"steam": "스팀", r"pdf": "피디에프"}
def han(t):
    for a, b in READ.items(): t = re.sub(a, b, t, flags=re.I)
    return re.sub(r"[^가-힣]", "", t)
m = WhisperModel("large-v3", device="cpu", compute_type="int8", cpu_threads=6)
bad = 0
for who in sys.argv[1:] or ["arona", "plana"]:
    block = src.split(f"readonly property var {who}Lines: ({{", 1)[1].split("})", 1)[0]
    for k, t in re.findall(r'^\s*"([\w-]+)":\s*"((?:[^"\\]|\\.)*)",?\s*$', block, re.M):
        f = Q / "assets/voice" / who / f"{k}.wav"
        if not f.exists(): continue
        want = han(json.loads(f'"{t}"'))
        got = han(" ".join(s.text for s in m.transcribe(str(f), language="ko", condition_on_previous_text=False)[0]))
        whole = difflib.SequenceMatcher(None, want, got).ratio()
        tail = difflib.SequenceMatcher(None, want[-8:], got[-10:]).ratio()      # 끝이 잘렸는지는 전체 비율로는 안 보인다
        if whole < 0.8 or tail < 0.6:
            bad += 1; f.unlink(); print(f"다시: {who}/{k} 전체 {whole:.2f} 끝 {tail:.2f}  대본={want}  들림={got}", flush=True)
print("지운 파일", bad)
sys.exit(1 if bad else 0)
