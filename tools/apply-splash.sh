#!/usr/bin/env bash
# 프라나일 때 보라색 부팅·종료 컷씬.  실행:  sudo bash ~/shittim-os/tools/apply-splash.sh   (apply-system.sh 도 이것을 부른다)
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "sudo로 실행해 주세요: sudo bash $0"; exit 1; }
R=$(cd "$(dirname "$0")/.." && pwd)/airootfs; T=/usr/share/plymouth/themes/shittim
for w in arona plana; do install -d $T/$w; install -m644 "$R$T/$w/"*.png $T/$w/; done
install -m755 "$R/usr/local/bin/shittim-splash-who" /usr/local/bin/
install -m644 "$R"/etc/systemd/system/shittim-splash-who.{service,path} /etc/systemd/system/
systemctl daemon-reload
systemctl enable shittim-splash-who.service
systemctl enable --now shittim-splash-who.path
rm -f $T/who                         # 그림이 바뀌었을 수 있으니 같은 캐릭터여도 다시 깔고 initramfs를 다시 만든다
/usr/local/bin/shittim-splash-who      # 지금 캐릭터에 맞춘다 (프라나면 여기서 initramfs를 다시 만든다)
echo "컷씬 색: $(cat $T/who)"
