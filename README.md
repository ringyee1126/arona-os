# ARONA OS (Shittim OS)

Arch Linux + Hyprland + Quickshell 로 만든 개인용 데스크톱. 이 저장소가 설치 ISO 의 소스(archiso 프로필)다.

## 설치 ISO 받기

ISO 는 3GB 가 넘어 [Releases](../../releases) 에 조각 2개로 올라가 있다. 둘 다 받아 한 폴더에 두고 합친다.

합치는 명령(파일 이름 포함)은 각 릴리스 설명에 적혀 있다. Windows 는 `copy /b 조각1 + 조각2 arona-os.iso`, Linux / macOS 는 `cat 조각1 조각2 > arona-os.iso`.

합친 파일이 맞는지는 릴리스에 적힌 SHA-256 과 비교한다 (Windows: `certutil -hashfile arona-os.iso SHA256`, Linux: `sha256sum arona-os.iso`).

## 설치

1. USB(8GB 이상)에 굽는다. Windows 는 [Rufus](https://rufus.ie) 에서 **DD 이미지 모드**, Linux 는 `sudo bash tools/burn-usb.sh`.
2. USB 로 부팅한다 (UEFI, Secure Boot 끔).
3. 터미널에서 `sudo shittim-install` 을 실행하고 설치할 파티션을 고른다.

**고른 파티션의 내용은 모두 지워진다. 먼저 백업할 것.** 다른 파티션과 EFI 의 다른 부팅 항목은 그대로 둔다.

## 업데이트 (이미 설치한 컴퓨터)

다시 설치하지 않는다. 터미널(Super+Enter)에 아래 한 줄을 붙여 넣는다. 중간에 비밀번호를 한 번 묻고, 끝나면 다시 시작한다.

```
curl -fsSL https://raw.githubusercontent.com/ringyee1126/arona-os/main/tools/update.sh | bash
```

한 번 하고 나면 다음부터는 **아로나 검색 → "ARONA OS 업데이트"** 를 누르면 된다.
**2026-11-22 ISO 로 설치했다면 꼭 한 번 실행할 것** (아래 보안 문제가 그 ISO 에 들어 있다).

- 설정 값·API 키·만든 목소리·음악·직접 깐 프로그램은 그대로 둔다. 바뀌는 파일의 이전 판은 `~/.cache/arona-os-update/` 에 남는다.
- 시작하기 전에 스냅샷을 만든다. 문제가 생기면 부팅할 때 Esc → GRUB 메뉴 → 스냅샷 "ARONA OS 업데이트 전".

### 2026-11-23 업데이트 내용

- **보안: 로그인 방식 변경.** 전에는 비밀번호 없이 자동 로그인한 뒤 잠금화면으로 덮기만 했다. 이제 로그인 관리자(greetd)가
  같은 모양의 로그인 화면을 띄우고, 비밀번호가 맞아야 세션이 시작된다. 로그인 화면이 뜨지 못하면 글자 로그인으로 넘어간다.
- **보안: 원격 접속(SSH) 끔.** 설치 USB 의 설정(비밀번호 로그인·root 로그인 허용)이 설치된 컴퓨터에 그대로 켜져 있었다.
  쓰던 사람은 `sudo systemctl enable --now sshd` 로 다시 켠다 (그 전에 `/etc/ssh/sshd_config` 를 직접 점검할 것).
- 설치 USB 에서 딸려 온 안 쓰는 서비스(cloud-init, systemd-networkd)와 패키지(복구·복제 도구 등 20여 개) 정리.
- 화면 오른쪽 위에 뜨던 "Runtime error in lua" 알림 제거 (오류는 `~/.cache/shittim-lua.log` 에 기록).
- 바탕화면 MomoTalk 의 분홍색 머리를 누르면 알림을 모아 보는 창.
- 설정 → 소리: 목소리 크기(시스템 음량과 따로), 목소리 언어(한국어 / 일본어).

### 일본어 목소리

목소리는 저장소에도 업데이트에도 들어 있지 않다. **일본어 목소리는 자기 컴퓨터에서 명령으로 직접 만들어야 한다.**

1. Steam 에서 블루 아카이브를 설치한다 (그 안의 일본어 음성으로 학습한다).
2. 터미널에서 `shittim-voice-setup ja` (인터넷 필요, 램 14GB 이상, CPU 로 3시간쯤. 한국어 목소리는 `shittim-voice-setup`).
3. 설정 → 소리 → 목소리 언어 → 일본어.

만들기 전에 일본어를 골라 두면 한국어 목소리(있으면)로 말한다. 정해진 대사는 일본어로, 대화 답변은 일본어 목소리가 한국어 글을 읽는다.

## 직접 빌드

Arch Linux 에서 `sudo bash build.sh` (20~40분, 디스크 약 20GB, 인터넷 필요). 커밋된 파일만 ISO 에 들어간다.

## 참고

- 아로나 대화는 Gemini API 키가 필요하다 (설정 창에서 입력). 키는 저장소에 들어 있지 않다.
- 목소리 모델은 들어 있지 않다. 만드는 법은 위 "일본어 목소리", `CLAUDE.md`, `tools/voice-setup.sh`.
- 블루 아카이브의 그림·음악은 각 권리자의 것이다. 개인적으로만 쓸 것.
