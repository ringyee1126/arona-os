#!/usr/bin/env bash
# 내장 스피커 켜기 (LG 그램 15Z95U).  실행:  sudo bash ~/shittim-os/tools/fix-speaker.sh   → 끝나면 다시 시작
# 하는 일: 스냅샷 → 빌드 도구 설치 → 스피커 드라이버 선택 모듈 다시 빌드(shittim-speaker-rebuild) → 커널 업데이트용 훅 설치
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "sudo로 실행해 주세요: sudo bash $0"; exit 1; }
R=$(cd "$(dirname "$0")/.." && pwd)/airootfs
snapper -c root create -d "내장 스피커 드라이버 전"
pacman -S --needed linux-headers pahole base-devel
install -m755 "$R/usr/local/bin/shittim-speaker-rebuild" /usr/local/bin/
install -Dm644 "$R/etc/pacman.d/hooks/shittim-speaker.hook" /etc/pacman.d/hooks/shittim-speaker.hook
shittim-speaker-rebuild
echo; echo "끝났어요. 다시 시작한 뒤 소리가 나는지 확인해 주세요."
