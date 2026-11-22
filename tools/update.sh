#!/usr/bin/env bash
# ARONA OS 업데이트: 이미 설치해서 쓰고 있는 컴퓨터를 최신 상태로 만든다 (다시 설치하지 않는다).
#   터미널(Super+Enter)에서:  curl -fsSL https://raw.githubusercontent.com/ringyee1126/arona-os/master/tools/update.sh | bash
#   한 번 하고 나면:          아로나 검색 → "ARONA OS 업데이트"
# 하는 일: 1) 최신 파일 받기(~/.local/share/arona-os)  2) 셸·단축키·스크립트 바꾸기(바뀌는 파일은 백업)  3) 관리자 권한 부분(apply-update.sh)
# 건드리지 않는 것: 설정 값(~/.config/shittim), 만든 목소리, 음악·다운로드, 직접 깐 프로그램.
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo "sudo 없이 실행해 주세요 (필요할 때 비밀번호를 물어봅니다)."; exit 1; }
[[ -d ~/.config/quickshell && -f /usr/local/bin/shittim-install ]] || { echo "ARONA OS 가 설치된 컴퓨터가 아닌 것 같아요."; exit 1; }
if [[ -d ~/shittim-os/.git ]]; then      # 개발 노트북: 설정은 이미 최신이다(여기서 고친 것) - 덮어쓰지 않고 시스템 부분만
    exec sudo bash ~/shittim-os/tools/apply-update.sh
fi
D=~/.local/share/arona-os; B=~/.cache/arona-os-update/backup-$(date +%Y%m%d-%H%M%S); S=$D/airootfs/home/sensei

echo "== 최신 파일 받는 중…"
if [[ -d $D/.git ]]; then git -C "$D" fetch -q --depth 1 origin master && git -C "$D" reset -q --hard FETCH_HEAD
else git clone -q --depth 1 https://github.com/ringyee1126/arona-os.git "$D"; fi

echo "== 셸 · 단축키 · 스크립트"
# OS 의 코드: 항상 새것으로 (바뀌는 파일은 $B 에 백업). 사용자가 넣은 파일(목소리 등)은 지우지 않는다.
rsync -a --backup --backup-dir="$B" --relative "$S/./.config/quickshell" "$S/./.config/hypr/hyprland.lua" \
      "$S/./.local/bin" "$S/./.local/share/applications" ~/
# 그 밖의 설정: 없는 것만 채운다 (사용자가 바꾼 값을 지키려고). 설정 값·음악·다운로드는 아예 건드리지 않는다.
rsync -a --ignore-existing --exclude=/.config/shittim --exclude=/음악 --exclude=/다운로드 "$S/" ~/
chmod +x ~/.local/bin/shittim-*
[[ -d $B ]] && echo "바뀐 파일의 이전 판: $B"

echo "== 관리자 권한이 필요한 부분 (비밀번호를 물어봅니다)"
sudo bash "$D/tools/apply-update.sh"
echo "일본어 목소리를 쓰려면 따로 만들어야 해요:  shittim-voice-setup ja   (몇 시간 걸려요. 설명: $D/README.md)"
