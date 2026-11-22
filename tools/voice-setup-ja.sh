#!/usr/bin/env bash
# 아로나·프라나의 일본어 목소리를 만든다 (설정 → 소리 → 목소리 언어 → 일본어 에서 쓴다).   실행:  shittim-voice-setup ja
#   sudo 아님 · 인터넷 필요 · 램 14GB 이상 · CPU 로 3시간쯤 (한국어 목소리 환경이 없으면 그것부터 설치: +30분, 디스크 20GB)
# 먼저 Steam 에서 블루 아카이브를 설치해 둘 것 (그 안의 일본어 음성 VOC_JP 로 학습한다). 만든 목소리는 혼자 쓰는 용도로만.
# 정해진 대사는 일본어로 말하고(tools/voice-lines-ja.json), 대화 답변은 일본어 목소리가 한국어 글을 읽는다.
# shortcut: 통째로 돌려 본 적은 없다(음성 꺼내기·받아쓰기·참조 고르기만 확인). 멈추면 그 단계부터 손으로 이어서 실행한다.
set -euo pipefail
T=$(cd "$(dirname "$0")" && pwd); V=~/.local/share/shittim-voice
A=~/.local/share/Steam/steamapps/common/BlueArchive/BlueArchive_Data/StreamingAssets/PUB/Resource/GameData/MediaResources/Audio/VOC_JP
[[ -f $A/JP_Arona.molru ]] || { echo "블루 아카이브(일본어 음성)가 없어요: $A"; exit 1; }
[[ -x $V/venv/bin/python && -d $V/GPT-SoVITS/GPT_SoVITS/pretrained_models ]] || bash "$T/voice-setup.sh" env
cd "$V"
for p in "plana JP_NP0035" "arona JP_Arona"; do      # 하나씩: 같이 돌리면 램이 모자란다
  set -- $p; n=$1-ja
  [[ -f voices/$n/gpt.ckpt ]] && continue             # 이미 만든 목소리는 건너뛴다
  python "$T/molru-extract.py" "$A/$2.molru" "raw/$2"
  venv/bin/python "$T/asr.py" "raw/$2" "$n" ja
  python "$T/mklist.py" "$n"
  venv/bin/python "$T/voice-train.py" "$n" 8 15
  mkdir -p "voices/$n"
  # 참조 음성 고르기: 평서문(ref)은 5초에 가장 가까운 것, 묻는 문장(ref-q)은 ？/か 로 끝나는 것 (3~9초; 억양은 참조를 따라간다)
  python - "$n" <<'PY'
import sys, shutil, pathlib
n = sys.argv[1]; rows = [l.split("|") for l in pathlib.Path(f"data/{n}.tsv").read_text().splitlines()]
rows = [(w, t.strip(), float(d)) for w, _, _, t, d in rows if 3 <= float(d) <= 9 and t.strip()]
ask = lambda t: t.rstrip("。 ").endswith(("？", "?", "か"))
for name, pool in (("ref", [r for r in rows if not ask(r[1])]), ("ref-q", [r for r in rows if ask(r[1])])):
    if not pool: print(n, name, "없음"); continue
    w, t, d = min(pool, key=lambda r: abs(r[2] - 5))
    shutil.copy(w, f"voices/{n}/{name}.wav"); pathlib.Path(f"voices/{n}/{name}.txt").write_text(t + "\n"); print(n, name, d, t)
PY
  [[ -f voices/$n/ref.wav ]] || { echo "참조 음성을 고르지 못했어요: $n"; exit 1; }
  cp "GPT-SoVITS/SoVITS_weights_v2ProPlus/${n}_e8_s"*.pth "voices/$n/sovits.pth"
  cp "GPT-SoVITS/GPT_weights_v2ProPlus/$n-e15.ckpt" "voices/$n/gpt.ckpt"     # 이 파일이 생겨야 shittim-say 가 일본어 목소리를 쓴다
  # shortcut: 한국어와 달리 받아써서 확인(voice-check.py)하지 않는다. 이상한 대사는 assets/voice/<이름>-ja/<대사>.wav 를 지우고 다시 실행.
  python "$T/voice-lines.py" "$n"
done
echo "끝. 설정 → 소리 → 목소리 언어 → 일본어 를 고르면 들립니다."
