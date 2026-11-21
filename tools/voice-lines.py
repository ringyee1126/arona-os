#!/usr/bin/env python3
"""정해진 대사(Arona.qml 의 aronaLines / planaLines)를 학습한 목소리로 미리 만들어 assets/voice/<who>/<이름>.wav 에 넣는다.
voice-lines.py [arona|plana] [--force]     이미 있는 파일은 건너뛴다 (대사를 고쳤으면 그 wav 를 지우고 다시 실행)."""
import re, json, sys, subprocess, pathlib
Q = pathlib.Path.home() / ".config/quickshell"
src = (Q / "Arona.qml").read_text()
force = "--force" in sys.argv
for who in [a for a in sys.argv[1:] if not a.startswith("-")] or ["arona", "plana"]:
    block = src.split(f"readonly property var {who}Lines: ({{", 1)[1].split("})", 1)[0]
    lines = {k: json.loads(f'"{t}"') for k, t in re.findall(r'^\s*"([\w-]+)":\s*"((?:[^"\\]|\\.)*)",?\s*$', block, re.M)}
    assert len(lines) > 50, len(lines)
    out = Q / "assets/voice" / who; out.mkdir(parents=True, exist_ok=True)
    for i, (k, t) in enumerate(lines.items(), 1):
        f = out / f"{k}.wav"
        if f.exists() and not force: continue
        print(f"[{who} {i}/{len(lines)}] {k}: {t!r}", flush=True)
        subprocess.run([str(pathlib.Path.home() / ".local/bin/shittim-say"), "--render", who, t, str(f)], check=True)
