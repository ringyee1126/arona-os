#!/usr/bin/env bash
# 이미 설치한 ARONA OS 에 업데이트의 관리자 권한 부분을 적용한다. tools/update.sh 가 sudo 로 부른다.
#   sudo bash tools/apply-update.sh
# 되돌리기: 부팅할 때 Esc → GRUB 메뉴 → 스냅샷에서 "ARONA OS 업데이트 전"을 고른다.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "sudo로 실행해 주세요: sudo bash $0"; exit 1; }
[[ ! -d /run/archiso ]] || { echo "설치 USB(라이브)에서는 실행하지 않아요. 설치한 뒤에 실행해 주세요."; exit 1; }
R=$(cd "$(dirname "$0")/.." && pwd)/airootfs

echo "== 1/4 스냅샷"
snapper -c root create -d "ARONA OS 업데이트 전 ($(date +%F))" || echo "(스냅샷을 만들지 못했어요 - 계속합니다)"

echo "== 2/4 패키지 (greetd: 로그인 화면)"
# shortcut: 전체 업그레이드(-Syu)는 하지 않는다 - Hyprland 등이 같이 올라가면 이 업데이트와 상관없는 문제가 날 수 있다.
# 패키지 목록이 낡아서 못 받으면 목록만 새로 받아(-Sy) 다시 해 본다. 그래도 안 되면 로그인 화면만 예전 방식으로 남는다.
pacman -S --needed --noconfirm greetd || pacman -Sy --needed --noconfirm greetd || echo "(greetd 를 설치하지 못했어요)"

echo "== 3/4 시스템 파일"
install -m755 "$R"/usr/local/bin/shittim-{greeter,greeter-sync,postinstall,splash-who} /usr/local/bin/
install -Dm644 "$R/etc/greetd/hyprland.lua" /etc/greetd/hyprland.lua
install -Dm644 "$R/etc/greetd/config.toml" /etc/greetd/config.toml

echo "== 4/4 로그인 화면 · 원격 접속 끄기 · 안 쓰는 것 정리"
/usr/local/bin/shittim-postinstall
echo
echo "끝났어요. 다시 시작하면 적용됩니다."
