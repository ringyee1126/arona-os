#!/usr/bin/env bash
# ARONA OS 설치 ISO를 만든다.  터미널(kitty)에서:  sudo bash ~/shittim-os/build.sh   → ~/arona-os-<날짜>-x86_64.iso
# 20~40분, 디스크 약 20GB(/var/tmp, 끝나면 지움), 인터넷 필요.
# git에 커밋된 파일만 들어간다: 커밋하지 않은 개인 파일(API 키 등)이 ISO에 섞이지 않게 하려는 것.
set -euo pipefail
[[ $EUID -eq 0 && -n ${SUDO_USER:-} ]] || { echo "sudo로 실행해 주세요: sudo bash $0"; exit 1; }
SRC=$(cd "$(dirname "$0")" && pwd); OUT=${1:-$(dirname "$SRC")}; W=/var/tmp/shittim-iso-build; P=$W/profile
u() { sudo -u "$SUDO_USER" "$@"; }     # 저장소는 사용자 것이라 git은 사용자로 돌린다
[[ -z $(u git -C "$SRC" status --porcelain) ]] || echo "주의: 커밋하지 않은 변경은 ISO에 들어가지 않아요."
command -v mkarchiso >/dev/null || pacman -S --needed --noconfirm archiso
rm -rf "$W"; mkdir -p "$P"
u git -C "$SRC" archive HEAD | tar -x -C "$P"
sed 's/#.*//' "$SRC/packages.extra" | xargs -n1 >> "$P/packages.x86_64"
# hyprbars(제목 표시줄): pacman 훅(shittim-hyprbars.hook)이 이미지 안에서 빌드하는데 거기에는 인터넷이 없어 소스를 미리 넣어 둔다
git clone -q https://github.com/hyprwm/hyprland-plugins.git "$P/airootfs/usr/local/src/hyprland-plugins"
mkarchiso -v -w "$W/work" -o "$OUT" "$P"
[[ -f $W/work/x86_64/airootfs/usr/lib/hyprland-plugins/hyprbars.so ]] \
  || { echo "실패: 이미지에 hyprbars.so 가 없어요 (창 제목 표시줄이 안 나옴). 위 로그에서 'hyprbars'를 찾아보세요. 작업 폴더: $W"; exit 1; }
chown "$SUDO_USER": "$OUT"/arona-os-*.iso
rm -rf "$W"
ls -lh "$OUT"/arona-os-*.iso
