#!/usr/bin/env bash
# 내장 스피커 켜기 (LG 그램 15Z95U).  실행:  sudo bash ~/shittim-os/tools/fix-speaker.sh   → 끝나면 다시 시작
# 하는 일: 스냅샷 → 빌드 도구 설치 → 스피커 드라이버 선택 모듈 다시 빌드(shittim-speaker-rebuild) → 커널 업데이트용 훅 설치
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "sudo로 실행해 주세요: sudo bash $0"; exit 1; }
R=$(cd "$(dirname "$0")/.." && pwd)/airootfs
snapper -c root create -d "내장 스피커 드라이버 전"
# 설치 USB에서 딸려 온 설정 때문에 pacman 열쇠고리(/etc/pacman.d/gnupg)가 메모리(tmpfs)에 있어서 다시 시작할 때마다 비워졌다.
# → "키링을 쓸 수 없음 / 키를 가져올 수 없음" 오류. 그 설정을 지우고 디스크에 열쇠고리를 새로 만든다.
if [[ -e /etc/systemd/system/etc-pacman.d-gnupg.mount ]] || findmnt -t tmpfs /etc/pacman.d/gnupg >/dev/null; then
  pkill -u root -f 'gnupg.*--homedir /etc/pacman.d/gnupg' 2>/dev/null || true
  rm -f /etc/systemd/system/etc-pacman.d-gnupg.mount; systemctl daemon-reload
  umount -l /etc/pacman.d/gnupg 2>/dev/null || true
fi
if ! pacman-key --list-keys >/dev/null 2>&1 || [[ $(pacman-key --list-keys 2>/dev/null | grep -c '^pub') -lt 10 ]]; then
  pacman-key --init; pacman-key --populate archlinux
fi
pacman -S --needed linux-headers pahole base-devel
install -m755 "$R/usr/local/bin/shittim-speaker-rebuild" /usr/local/bin/
install -Dm644 "$R/etc/pacman.d/hooks/shittim-speaker.hook" /etc/pacman.d/hooks/shittim-speaker.hook
shittim-speaker-rebuild
echo; echo "끝났어요. 다시 시작한 뒤 소리가 나는지 확인해 주세요."
