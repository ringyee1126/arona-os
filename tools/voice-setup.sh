#!/usr/bin/env bash
# 아로나·프라나 목소리를 처음부터 만든다 (새로 설치한 컴퓨터용). 2026-11-22 에 손으로 한 순서를 그대로 적은 것.
#   bash ~/shittim-os/tools/voice-setup.sh        sudo 아님 · 인터넷 필요 · 디스크 20GB · 램 14GB 이상 · CPU 로 4~5시간
# 먼저 Steam 에서 블루 아카이브를 설치해 둘 것 (그 안의 한국어 음성으로 학습한다). 만든 목소리는 혼자 쓰는 용도로만.
# shortcut: 처음부터 끝까지 한 번에 돌려 본 적은 없다(단계별로만 확인). 중간에 멈추면 그 단계부터 손으로 이어서 실행한다.
set -euo pipefail
T=$(cd "$(dirname "$0")" && pwd); V=~/.local/share/shittim-voice
A=~/.local/share/Steam/steamapps/common/BlueArchive/BlueArchive_Data/StreamingAssets/PUB/Resource/GameData/MediaResources/Audio/VOC_KR
[[ -f $A/KR_Arona.molru ]] || { echo "블루 아카이브가 없어요: $A"; exit 1; }
mkdir -p "$V" && cd "$V"
# 1) 환경: uv(파이썬 3.11) + GPT-SoVITS + CPU torch + 기본 모델(4.5GB)
python -m venv boot && boot/bin/pip install -q uv; UV=$V/boot/bin/uv
[[ -d GPT-SoVITS ]] || git clone --depth 1 https://github.com/RVC-Boss/GPT-SoVITS.git      # 확인한 커밋: 6d51ffc (2026-11-12)
$UV venv -q --python 3.11 venv
sed -e 's/^onnxruntime-gpu.*/onnxruntime/' -e '/^onnxruntime; /d' GPT-SoVITS/requirements.txt > req-cpu.txt
$UV pip install -q -p venv torch torchaudio torchcodec --index-url https://download.pytorch.org/whl/cpu
$UV pip install -q -p venv -r GPT-SoVITS/extra-req.txt --no-deps
$UV pip install -q -p venv -r req-cpu.txt resampy
H=https://huggingface.co/XXXXRT/GPT-SoVITS-Pretrained/resolve/main
curl -fL -C - -o pretrained_models.zip $H/pretrained_models.zip; curl -fsSL -o nltk_data.zip $H/nltk_data.zip; curl -fsSL -o ojt.tar.gz $H/open_jtalk_dic_utf_8-1.11.tar.gz
venv/bin/python -c 'import zipfile,sys,tarfile,os,pyopenjtalk
zipfile.ZipFile("pretrained_models.zip").extractall("GPT-SoVITS/GPT_SoVITS"); zipfile.ZipFile("nltk_data.zip").extractall(sys.prefix)
tarfile.open("ojt.tar.gz").extractall(os.path.dirname(pyopenjtalk.__file__))'
rm -f pretrained_models.zip nltk_data.zip ojt.tar.gz
[[ ${1:-} == env ]] && exit 0     # voice-setup-ja.sh: 환경만 설치하고 일본어 목소리만 만들 때
# 2) 음성 꺼내기 → 받아쓰기 → 학습 목록 (아로나는 손으로 고쳐 둔 목록 tools/arona.list 를 쓴다)
python "$T/molru-extract.py" "$A/KR_Arona.molru" raw/KR_Arona; python "$T/molru-extract.py" "$A/KR_NP0035.molru" raw/KR_NP0035
cp "$T/asr.py" "$T/mklist.py" .
venv/bin/python asr.py raw/KR_Arona arona; venv/bin/python asr.py raw/KR_NP0035 plana
venv/bin/python mklist.py plana; cp "$T/arona.list" data/arona.list
# 3) 학습 (하나씩: 같이 돌리면 램이 모자란다) → 목소리 설치 (참조 음성: 평서문 ref, 묻는 문장 ref-q)
ref() { mkdir -p "voices/$1"; cp "data/$1/$2.wav" "voices/$1/$4.wav"; echo "$3" > "voices/$1/$4.txt"; }
for n in plana arona; do
  venv/bin/python "$T/voice-train.py" $n 8 15
  mkdir -p voices/$n; cp GPT-SoVITS/GPT_weights_v2ProPlus/$n-e15.ckpt voices/$n/gpt.ckpt; cp GPT-SoVITS/SoVITS_weights_v2ProPlus/${n}_e8_s*.pth voices/$n/sovits.pth
done
ref arona KR_Arona_0002 "다양한 수업과 일정이 준비되어 있으니 원하시는 스케줄을 선택해주세요." ref
ref arona KR_Arona_0106 "어떤 업무를 하실 건가요, 선생님?" ref-q
ref plana KR_NP0035_0004 "학생들이 기다리고 있습니다. 저는 선생님을 보조하겠습니다." ref
ref plana KR_NP0035_0003 "오늘은 어떤 업무부터 시작하시겠습니까?" ref-q
# 4) 정해진 대사 만들기 + 받아써서 확인
bash "$T/voice-build.sh" arona; bash "$T/voice-build.sh" plana
echo "끝. 설정 → 소리 → 목소리가 켜져 있으면 바로 들립니다."
