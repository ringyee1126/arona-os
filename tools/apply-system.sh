#!/usr/bin/env bash
# 2026-11-19 개선 작업 중 관리자 권한이 필요한 부분.  실행:  sudo bash ~/shittim-os/tools/apply-system.sh
# 1) 스냅샷  2) 패키지 설치  3) 카카오톡 실행 스크립트  4) 부팅·종료 컷씬 (GRUB 메뉴 숨김, 글자 안 보이게)
# 되돌리기: 부팅할 때 Esc → GRUB 메뉴 → 스냅샷 항목에서 "개선 작업 전"을 고른다.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "sudo로 실행해 주세요: sudo bash $0"; exit 1; }
SRC=$(cd "$(dirname "$0")/.." && pwd); R=$SRC/airootfs

echo "== 1/4 스냅샷"
snapper -c root create -d "개선 작업 전 (2026-11-19)"

echo "== 2/4 패키지"
pacman -Syu --needed $(sed 's/#.*//' "$SRC/packages.extra")
systemctl enable --now cups.socket

echo "== 3/4 카카오톡 스크립트, 컷씬 대기 스크립트"
install -m755 "$R/usr/local/bin/kakaotalk" "$R/usr/local/bin/shittim-splash-wait" /usr/local/bin/

echo "== 4/4 부팅·종료 컷씬"
install -m644 "$R/usr/share/plymouth/themes/shittim/shittim.script" /usr/share/plymouth/themes/shittim/shittim.script
for d in plymouth-quit plymouth-poweroff plymouth-reboot; do
  install -Dm644 "$R/etc/systemd/system/$d.service.d/shittim.conf" "/etc/systemd/system/$d.service.d/shittim.conf"
done
systemctl daemon-reload
# GRUB: 메뉴를 숨기고(Esc를 누르면 나옴) 커서·부팅 글자를 끈다
sed -i -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' -e 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' \
       -e 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.udev.log_level=3 systemd.show_status=false vt.global_cursor_default=0"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P          # 스플래시 스크립트가 initramfs 안에 들어 있어서 다시 만든다
bash "$SRC/tools/apply-splash.sh"   # 프라나면 보라색 컷씬
bash "$SRC/tools/fix-bluetooth.sh"    # 블루투스 어댑터 절전 끄기
echo
echo "끝났어요. 다시 시작하면 컷씬이 적용됩니다."
