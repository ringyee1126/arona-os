#!/usr/bin/env bash
# 정해진 대사를 만들고(voice-lines.py) 받아써서 확인(voice-check.py)하기를, 틀린 것이 없을 때까지 되풀이한다 (최대 6번).
# voice-build.sh [arona|plana]
cd "$(dirname "$0")"; V=~/.local/share/shittim-voice
for i in 1 2 3 4 5 6; do
    python voice-lines.py "$@" || exit 1
    "$V/venv/bin/python" voice-check.py "$@" 2>/dev/null && { echo "BUILD-OK $*"; exit 0; }
done
python voice-lines.py "$@"; echo "BUILD-GAVE-UP $* (마지막으로 만든 것은 확인 안 됨)"; exit 1
