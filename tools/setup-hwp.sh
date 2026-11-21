#!/usr/bin/env bash
# 한글(hwp/hwpx) 문서를 LibreOffice 로 열게 한다: H2Orestart 확장 설치.   bash ~/shittim-os/tools/setup-hwp.sh   (sudo 아님)
# 먼저 Java 가 있어야 한다: sudo pacman -S --needed jre-openjdk-headless  (packages.extra 에 있음 → apply-system.sh 가 설치)
set -euo pipefail
command -v java >/dev/null || { echo "Java 가 없어요. 먼저: sudo pacman -S --needed jre-openjdk-headless"; exit 1; }
f=$(mktemp --suffix=.oxt)
curl -fsSL -o "$f" https://github.com/ebandal/H2Orestart/releases/download/v0.8.1/H2Orestart.oxt
pkill -x soffice.bin || true
unopkg add -f "$f"; rm -f "$f"
echo "끝. hwp 파일을 더블클릭하면 LibreOffice Writer 로 열립니다."
