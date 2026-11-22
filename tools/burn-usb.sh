#!/usr/bin/env bash
# 설치 USB 굽기 + 다시 읽어 원본과 대조 (조용히 깨지는 USB를 잡아낸다).
#   sudo bash tools/burn-usb.sh [ISO] [장치]     기본: 가장 최근 ~/arona-os-*.iso, 하나뿐인 USB 디스크
set -euo pipefail
[[ $EUID -eq 0 ]] || exec sudo bash "$0" "$@"
H=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)
ISO=${1:-$(ls -t "$H"/arona-os-*.iso 2>/dev/null | head -1)}
[[ -f $ISO ]] || { echo "ISO를 찾지 못했어요."; exit 1; }
DEV=${2:-}
if [[ -z $DEV ]]; then
  mapfile -t usb < <(lsblk -dnpo NAME,TRAN,TYPE | awk '$2=="usb" && $3=="disk"{print $1}')
  [[ ${#usb[@]} -eq 1 ]] || { echo "USB 디스크가 ${#usb[@]}개예요. 장치를 직접 적어 주세요."; exit 1; }
  DEV=${usb[0]}
fi
# 내장 디스크에 굽는 사고 방지: USB로 연결된 디스크만 받는다
[[ $(lsblk -dno TRAN,TYPE "$DEV" | xargs) == "usb disk" ]] || { echo "$DEV 은(는) USB 디스크가 아니에요."; exit 1; }
SIZE=$(stat -c %s "$ISO")
lsblk -o NAME,SIZE,LABEL,MODEL "$DEV"
read -rp "$DEV 의 내용을 모두 지우고 $(basename "$ISO") 를 구울까요? (YES): " ok
[[ $ok == YES ]] || exit 1
for p in $(lsblk -lnpo NAME "$DEV" | tail -n +2); do umount "$p" 2>/dev/null || true; done
dd if="$ISO" of="$DEV" bs=4M oflag=direct conv=fsync status=progress
echo "다시 읽어서 원본과 대조하는 중…"
# iflag=direct: 캐시가 아니라 USB에 실제로 적힌 것을 읽는다
if dd if="$DEV" bs=4M iflag=direct status=none | cmp -n "$SIZE" - "$ISO"; then
  echo "성공: USB와 ISO가 완전히 같아요. 뽑아서 설치에 쓰세요."
else
  echo "실패: USB가 적은 대로 읽히지 않아요. 이 USB는 불량이에요 - 다른 USB를 쓰세요."; exit 1
fi
