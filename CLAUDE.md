# ARONA OS (Shittim OS) — 이 노트북에서 작업할 때 알아둘 것

이 노트북(LG 그램 15, Radeon 840M)에는 사용자가 직접 만든 ARONA OS가 설치돼 있다.
버그 수정·개선은 **이 노트북에서 직접** 한다. USB 재설치는 nvme0n1p3를 통째로 지우므로(홈 포함) 하지 않는다.

## 구성
- 기반: **Arch Linux** (archiso `releng` 프로필 + 자체 파일/패키지, `mkarchiso`로 ISO 빌드). 패키지 관리: pacman.
- 컴포지터: **Hyprland** — 설정 `~/.config/hypr/hyprland.lua`
- 데스크톱 셸: **Quickshell (Qt 6 / QML)** — `~/.config/quickshell/`
  - `shell.qml`(진입점), `TopBar` `Dock` `Desktop` `Launcher`(아로나 검색) `Lock`/`LockView`(잠금화면)
    `Notifs` `Tasks` `Chat`/`Arona`(아로나 대화, Gemini API) `Settings`/`settings-app.qml` `Theme`(색·경로)
  - `AronaSprite.qml`: `assets/arona/<mood>.webp`(Spine idle 루프) 재생, 실패하면 `assets/arona.png`로 대체
- 터미널 kitty, 한글 fcitx5-hangul, 소리 PipeWire, 네트워크 NetworkManager
- 부팅 GRUB(EFI 항목 `ShittimOS`) + Plymouth. Windows 부팅 관리자 항목이 EFI에 남아 있을 수 있음.
- 디스크: nvme0n1p1 EFI(200M, 공유) / **p3 btrfs ShittimOS**(서브볼륨 `@` `@home` `@snapshots` `@log`) /
  p5 13G vfat "DNA"(D 드라이브, 건드리지 말 것)
- 스냅샷: snapper + snap-pac(pacman 전 자동) + grub-btrfs(GRUB 메뉴에서 되돌리기)
- 카카오톡: Wine (`/usr/local/bin/kakaotalk`)
- 자체 스크립트: `/usr/local/bin/shittim-*` (install, dev-setup, dev-sync, hyprbars-rebuild)
- 사용자: `sensei`, sudo는 wheel 그룹(비밀번호 필요)

## 작업 규칙
1. **QML/Hyprland 설정은 저장하면 즉시 다시 로드된다.** 재부팅·재설치 불필요. 오류는 Quickshell 로그로 확인
   (`journalctl --user -b | grep -i quickshell`, 또는 터미널에서 `qs`를 직접 실행해 출력 보기).
2. **위험한 변경 전에 스냅샷**: `sudo snapper -c root create -d "설명"`
3. **원본 소스와 동기화**: 소스는 `~/shittim-os` (구글 드라이브 `ARONA-OS-source.zip`을 받아 여기 풀어 둔다).
   - 노트북 `~/.config/X` ↔ 소스 `airootfs/home/sensei/.config/X`
   - 노트북 `/usr/local/bin/X`, `/etc/X` ↔ 소스 `airootfs/usr/local/bin/X`, `airootfs/etc/X`
   - 새로 설치한 pacman 패키지 → 소스 `packages.extra`에 추가 (주석으로 이유 한 줄)
   - 설정을 고쳤으면 소스에도 반영: `rsync -a ~/.config/quickshell/ ~/shittim-os/airootfs/home/sensei/.config/quickshell/`
   - 소스가 git 저장소면 커밋. **API 키·비밀번호가 담긴 파일은 커밋하지 말 것.**
4. ISO 재빌드(`build.sh`)는 원래 Windows의 WSL Arch에서 돌리도록 돼 있다(경로 `/mnt/c/...` 가정).
   노트북에서 빌드하려면 `archiso` 설치 후 경로를 맞춰야 함. 재설치가 필요한 변경(설치 스크립트, 파티션, 부트로더)만 ISO로.

## 설치 때 생긴 일 (2026-11-18)
- 설치 USB의 squashfs 블록 하나(0xa32e0e)가 깨져 있어 아래 두 파일을 빼고 설치했다. **USB는 재사용 전 다시 구워야 함.**
  - `~/.config/quickshell/assets/arona/curious.webp` 없음 → "호기심" 표정이 정지 그림으로 나옴.
    소스 zip의 같은 파일을 복사하면 해결.
  - 이미지에 들어 있던 Claude Code 바이너리 없음 → `curl -fsSL https://claude.ai/install.sh | bash`로 재설치.
    (`shittim-dev-setup`은 VS Code 확장만 설치하고 Claude Code 본체는 설치하지 않는다.)
- 기존 Windows는 지워졌다. 펌웨어 부팅 순서에 Windows Boot Manager가 남아 0xc000000f가 뜨면
  BIOS(F2)에서 ShittimOS를 첫 번째로 두거나 `sudo efibootmgr`로 Windows 항목 정리.

## 버그·개선 목록
한영키 바로 반영 안됨(한영키 누르면 한영은 안바뀌고 글 전체 선택이 됨 가끔.).
카톡 창 들고 내려놨다가 안되고, 카톡 포함 프로그램의 창 크기 조절 안됨.

창 조절과 관련된 불편함 개선 부탁.(크기 조절, 위치 조정 등등)

스크린샷은 막상 사진이 저장이 안됨.

바탕화면 상호작용 대화창이 캐릭터보다 위쪽에 있는 문제

OS자체 내장으로 있는 블루아카이브 피씨판이 있었으면 좋겠어.
스팀이 필요하면 함께 설치하고 아래 대시보드에 넣어줘.(블루아카이브 바로 실행하기 파일은 여러 방향에서 할 수 있도록해줘. 아래 대시보드에 블루아카이브는 없고, 예를들면 바탕화면에 업무 시작하기 버튼을 아로나 검색 대신 넣어주고 아로나 검색 버튼을 업무 버튼 왼쪽으로 치워버리는 방법도 좋아.)
(설치는 직접할테니 블루아카이브를 설치하기 위한 스팀과 블루아카이브 게임이 돌아갈 수 있는 환경 개선 요구, 블아가 설치 안되어있으면 업무 버튼을 눌러도 작동 안되게)

윈도우키누르면 오른쪽 상단에 있는 삼선(메뉴) 버튼 눌러지도록

설정에 막상 목소리 서버 키는 기능이 없음

블루투스가 장치를 누르면 연결됨이라고 떴다가 몇초뒤에 연결이 끊김. 그런데 막상 블루투스 기기에는 연결되지 않았었음

설정창이 다른 크롬이나 디스코드 창보다 항상 맨앞에 고정되는 문제 해결 바람

설정 성격에서 아로나, 프라나, 커스텀을 제외한 나머지 3개를 지워줘
프라나를 선택하면 아로나 대신 프라나 나오도록 만들어줘.(똑같이 부드러운 모션 필요!)

OS설치하면서 삭제된 아로나의 curious 표정을 다시 만들어줘.

대시보드에 있는 클로드 코드는 그냥 지워줘.

제미나이 키를 연결 확인하고
연결 확인 완료라 떴는데도 대화에서는 대화가 늦어집니다, 구글 서버가 이상합니다 이런 메세지가 떠.

부팅, 종료 시에는 반드시 로딩 화면 컷씬이 부드럽게 처음부터 끝까지 나오도록 만들어줘(4~5초 이상). 그리고 가능하면 시작할 때 나오는 cmd창 같은것과 리눅스 글씨 같은건 안나오고 그 자리에 로딩 화면이 나오도록 할 수 있으면 해줘.

부팅이 끝났을 때, 잠금화면이 등장하기 전 0.n초동안 잠시 바탕화면이 등장하는 문제 해결 바람

바탕화면 왼쪽 상단에 있는 샬레 +n 이거 대신 오늘의 월/일 이 나오도록 해줘
## 2026-11-19 작업 결과 (Claude Code)
소스 zip이 구글 드라이브에 없어서, 이 폴더(`~/shittim-os`)는 노트북의 설정을 그대로 복사해 만든 git 저장소다
(첫 커밋 = 수정 전 상태). 원본 소스 zip을 받으면 이 저장소의 `airootfs/`를 그 위에 덮어 합친다.

- Quickshell 로그는 `quickshell log` 로 본다 (`journalctl --user`에는 아무것도 없다).
- 관리자 권한이 필요한 부분은 `sudo bash ~/shittim-os/tools/apply-system.sh` 한 번으로 적용한다
  (스냅샷 → `packages.extra` 설치 → 카카오톡 스크립트 → 부팅·종료 컷씬/GRUB). **아직 실행 전이면 아래 "루트 필요" 항목은 미적용.**
- 독의 Claude Code 버튼은 지우지 않는다 (사용자가 요청을 취소함).

고친 것
- 창: 모든 창이 떠 있는 창(Windows식). 제목 표시줄 끌기, 테두리로 크기 조절, Super+끌기, Super+←/→ 반쪽, Super+↑ 최대화,
  Alt+Tab, Alt+F4, Super+D. 설정 창이 맨 앞에 고정되던 것도 이것으로 해결 (타일 창은 항상 떠 있는 창 밑이었다).
- 스크린샷: `~/.local/bin/shittim-shot` → `~/사진/스크린샷` 저장 + 클립보드. Print / Super+Shift+S / Super+Print.
- 윈도우 키 단독 = ≡ 메뉴. 소리·밝기·미디어 키. Super+V 클립보드 기록(fuzzel 설치 후).
- 한/영: `kb_options = korean:ralt_hangul` (오른쪽 Alt를 Hangul 키로). **사용자 확인 필요.**
- 말풍선을 얼굴 옆으로. 좌상단 배지 = 요일 + 월/일. 성격은 아로나/프라나/커스텀.
- Gemini: 25초 × 최대 3번 재시도, 예비 모델 `gemini-flash-lite-latest`. 모델 목록은 `-latest` 별칭만 (2.5 계열은 404).
- 효과음 `Sfx.qml` + `assets/sfx/` (`tools/make-sfx.py`), 설정 → 소리 → 버튼 효과음.
- 대화창에 파일 끌어다 놓기(사진·PDF·글·소리·영상, 합쳐 15MB).
- md: `viewer.qml` + `shittim-view`. 기본 앱: `~/.config/mimeapps.list`. 압축 파일 더블클릭 = 그 자리에 풀기.
- 카카오톡(Wine)에서 받은 파일 → `shittim-wine-open` 이 이 OS의 기본 앱으로 연다 (Windows 프로그램 없음 경고 제거).
- 부팅 직후 바탕화면이 잠깐 보이던 것: 셸이 첫 시작 때 스스로 잠근다 (`Lock.qml`, `/run/user/1000/shittim-locked-once`).
- 독: Steam 추가, 큰 버튼 = "업무 시작하기"(`shittim-work`, 블루 아카이브가 Steam에 설치돼 있을 때만 켜짐), 왼쪽에 아로나 검색.
- 타자 소리: 셸의 글 입력 칸(대화, 검색, 설정, 잠금화면)에서 `Sfx.key()` → `assets/sfx/key.wav`. 다른 앱 안에서는 안 난다.
- 크롬 제목 표시줄: 크롬도 hyprbars(□ ✕)를 쓴다. Hyprland는 최대화 상태를 앱에 알려주지 않아 앱이 직접 그린 □ 는 복원이 안 된다.
  그래서 크롬 프로필 `Preferences`의 `browser.custom_chrome_frame=false`(= 설정 → 모양 → "시스템 제목 표시줄 및 테두리 사용")로
  크롬 자체 버튼을 끄고 no_bar 규칙에서 chromium을 뺐다. **새 프로필·재설치 때는 이 크롬 설정을 다시 켜야 한다.** GTK 앱은 ✕ 만.
- 목소리: 음성 서버는 쓰지 않는다 (사용자 결정). 정해진 대사(`Arona.qml`의 `lines` 표: 인사·쓰다듬기·오류)만
  `assets/voice/<arona|plana>/<이름>.wav` 녹음을 튼다 (`Arona.speak()`). 파일이 없으면 조용히 넘어간다. 설정 → 소리 → 아로나 목소리.
  대본은 `assets/voice/README.md` (= `~/문서/아로나-음성-대본.md`). 사용자가 데스크탑에서 음성을 만들어 넣을 예정.
  상황별 대사: `Arona.react("<상황>")` = 이름이 `<상황>` 또는 `<상황>-1,-2…` 인 대사 중 하나를 말풍선+목소리로.
  잠금화면, 쓰다듬기, 방치(창 없이 5분), 업무 시작(3초 뒤 실행), 전원(4초 뒤 실행), 설정·검색·대화 열기, 앱 실행, 알림, 스크린샷,
  할 일 완료, 배터리. 다른 프로세스에서는 `quickshell ipc call arona react <상황>`. **`lines`를 고치면 대본(README)도 고칠 것.**
- Steam: 고장이 아니었다. 첫 실행 때 창 없이 몇 분간 약 700MB를 받는다 (`~/.local/share/Steam/logs/bootstrap_log.txt`).
- 화면 녹화: PrtSc = `shittim-shot menu` (fuzzel 목록: 사진 영역/전체, 녹화 전체/영역 × 컴퓨터 소리 포함/없이). 녹화 중 PrtSc = 녹화 끝.
  wf-recorder → `~/비디오/화면 녹화/*.mp4`. 소리는 기본 출력 장치의 모니터(`pactl get-default-sink`.monitor)를 녹음한다.
- **소리 출력 장치가 없다 (2026-11-19 확인)**: PipeWire에 "Dummy Output"만 있다. 커널이 HDMI 오디오와 acp-pdm-mach(마이크)만 잡고
  내장 스피커 코덱(AMD ACP 1022:15e2 rev 72, LG 15Z95U)은 못 잡는다. 블루투스·HDMI를 연결하지 않으면 효과음·목소리·녹화 소리가 전부 무음.

루트 필요 (apply-system.sh)
- Steam·gamemode 등 패키지, 부팅·종료 컷씬(4.5초 시간 기반 진행 막대, 끝까지 재생, GRUB 메뉴 숨김 - Esc로 표시).

남은 것
- 프라나 모션, 아로나 curious 표정: Spine 원본이 없어 못 만듦. `assets/plana/<표정>.webp`, `assets/arona/curious.webp`를
  넣으면 코드 수정 없이 나온다 (지금은 같은 캐릭터의 smile 모션으로 대체).
- 블루투스(Britz BT4000 ANC) 연결 끊김: 헤드셋이 꺼져 있어 재현 못 함. 켠 상태에서 `journalctl -b -u bluetooth -f` 를 보며 다시 연결해 원인 확인.
