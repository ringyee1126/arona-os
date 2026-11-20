#!/usr/bin/env bash
# 블루투스 연결이 잘 안 되던 것: 어댑터의 USB 절전을 끈다.  실행:  sudo bash ~/shittim-os/tools/fix-bluetooth.sh
# 되돌리기: /etc/modprobe.d/shittim-bluetooth.conf 를 지우고 다시 시작.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "sudo로 실행해 주세요: sudo bash $0"; exit 1; }
SRC=$(cd "$(dirname "$0")/.." && pwd)
install -Dm644 "$SRC/airootfs/etc/modprobe.d/shittim-bluetooth.conf" /etc/modprobe.d/shittim-bluetooth.conf
# 다시 시작하지 않아도 지금 바로: 블루투스 클래스(e0)의 USB 장치를 깨워 둔다
for i in /sys/bus/usb/devices/*/bInterfaceClass; do
  [[ $(cat "$i") == e0 ]] && echo on > "$(dirname "$i")/../power/control"
done
systemctl restart bluetooth
echo "끝났어요. 블루투스 기기를 다시 연결해 보세요."
