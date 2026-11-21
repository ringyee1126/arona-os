# ARONA OS (Shittim OS)

Arch Linux + Hyprland + Quickshell 로 만든 개인용 데스크톱. 이 저장소가 설치 ISO 의 소스(archiso 프로필)다.

## 설치 ISO 받기

ISO 는 3GB 가 넘어 [Releases](../../releases) 에 조각 2개로 올라가 있다. 둘 다 받아 한 폴더에 두고 합친다.

- Windows (명령 프롬프트): `copy /b arona-os-*.iso.part1 + arona-os-*.iso.part2 arona-os.iso`
- Linux / macOS: `cat arona-os-*.iso.part1 arona-os-*.iso.part2 > arona-os.iso`

합친 파일이 맞는지는 릴리스에 적힌 SHA-256 과 비교한다 (Windows: `certutil -hashfile arona-os.iso SHA256`, Linux: `sha256sum arona-os.iso`).

## 설치

1. USB(8GB 이상)에 굽는다. Windows 는 [Rufus](https://rufus.ie) 에서 **DD 이미지 모드**, Linux 는 `sudo bash tools/burn-usb.sh`.
2. USB 로 부팅한다 (UEFI, Secure Boot 끔).
3. 터미널에서 `sudo shittim-install` 을 실행하고 설치할 파티션을 고른다.

**고른 파티션의 내용은 모두 지워진다. 먼저 백업할 것.** 다른 파티션과 EFI 의 다른 부팅 항목은 그대로 둔다.

## 직접 빌드

Arch Linux 에서 `sudo bash build.sh` (20~40분, 디스크 약 20GB, 인터넷 필요). 커밋된 파일만 ISO 에 들어간다.

## 참고

- 아로나 대화는 Gemini API 키가 필요하다 (설정 창에서 입력). 키는 저장소에 들어 있지 않다.
- 목소리 모델은 들어 있지 않다. 만드는 법은 `CLAUDE.md` 와 `tools/voice-setup.sh`.
- 블루 아카이브의 그림·음악은 각 권리자의 것이다. 개인적으로만 쓸 것.
