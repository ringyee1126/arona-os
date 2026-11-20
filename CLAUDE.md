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
4. ISO 빌드: 터미널에서 `sudo bash ~/shittim-os/build.sh` → `~/arona-os-<날짜>-x86_64.iso`. **커밋된 파일만 들어간다.**
   이 저장소가 곧 archiso 프로필이다 (`profiledef.sh`, `packages.x86_64` + `packages.extra`, `pacman.conf`, `efiboot/` `syslinux/` `grub/`).
   원본 소스 zip은 찾지 못해서, 2026-11-20에 archiso v92 `releng` 프로필 + 설치 USB(11-17 빌드) 이미지에서 꺼낸 파일로 다시 만들었다
   (`packages.x86_64` = 그 이미지에서 직접 고른 패키지 194개). 이미지에 있던 Claude Code 바이너리는 넣지 않았다.
   재설치가 필요한 변경(설치 스크립트, 파티션, 부트로더)만 ISO로.

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
- 윈도우 키 단독 = ≡ 메뉴 (hyprland.lua의 20ms 타이머가 `hl.is_key_down("Super_L")`을 본다. release 단축키 `SUPER + Super_L`은 가상 키보드(uinput)로는 되는데
  노트북 키보드에서는 불리지 않았다 - 원인 미확인. 시험: /dev/uinput 은 sensei가 쓸 수 있어 가상 키 입력이 가능). 소리·밝기·미디어 키. Super+V 클립보드 기록(fuzzel 설치 후).
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
- 캡처: PrtSc = `shittim-shot menu` → `Capture.qml` 메뉴(사진 영역/전체, 녹화 전체/영역 × 컴퓨터 소리 포함/없이, ✕·Esc로 닫기).
  녹화 중 PrtSc = 녹화 끝. wf-recorder → `~/비디오/화면 녹화/*.mp4`, 소리는 기본 출력 장치의 모니터.
  일시정지(`shittim-shot pause`)는 wf-recorder에 없어서 조각(`$XDG_RUNTIME_DIR/shittim-rec/seg-N.mp4`)으로 찍고 끝에 ffmpeg concat.
  녹화 중 표시: Hyprland의 `no_screen_share` 레이어 규칙은 그 자리를 **검게 칠해서** 못 쓴다. 대신 전체 화면도 가장자리 4px 안쪽만
  녹화하고(1912x1072) 빨간 테두리를 그 바깥에 그린다. 조작 막대는 늘 보인다(사용자 요청): 영역 위에 자리가 있으면 바깥(안 찍힘),
  전체 화면이면 안쪽 위(영상에 찍힘).
- 창 스냅 (hyprland.lua "창 붙이기"): 창을 끌다 마우스를 화면 끝에서 놓으면 왼쪽/오른쪽 = 반쪽, 위 = 최대화, 모서리(60px) = 1/4.
  끄는 동안 `SnapPreview.qml`이 갈 자리를 미리 보여 주고(`ipc call snap box x y w h` / `hide`), 붙인 창을 다시 끌어내면 원래 크기로.
  끌기 시작/끝 이벤트가 없어서 `mouse:272` 누름/뗌 non_consuming 단축키 + 50ms 타이머로 "누른 뒤 창 위치가 바뀜"을 본다.
  시험: `hyprctl dispatch "hl.dsp.exec_cmd((function() shittim_snap('tl') return 'true' end)())"`.
  주의: IpcHandler 함수 이름으로 `show`는 못 쓴다 (`quickshell ipc show`와 겹침). QML 파일만 고쳐서 IPC가 안 바뀌면 `touch shell.qml`.
- **내장 스피커가 안 잡힌다 (2026-11-19)**: PipeWire에 "Dummy Output"만 있다. 스피커 칩은 SoundWire의 Realtek RT722
  (ACPI `\_SB.PCI0.GPPA.ACP.SDWC.SW21`, _ADR 0x000030025d072201, 커널 표 `acp70_rt722_only`에 있음). 그런데 BIOS에
  `acp-audio-config-flag`가 없어 `snd_amd_acp_find_config()`가 "마이크 전용"을 돌려주고 snd_pci_ps(SoundWire) 대신 snd_acp_pci가 붙는다.
  고치는 법 = `acp70_acpi_flag_override_table`에 이 기종 추가. `sudo bash tools/fix-speaker.sh` 가 그 한 항목을 넣은
  `snd-acp-config.ko`를 빌드해 `/usr/lib/modules/<커널>/updates/`에 넣는다 (`shittim-speaker-rebuild`, 커널 업데이트 때는 pacman 훅).
  빌드까지는 확인했고 **재부팅 후 실제로 소리가 나는지는 미확인.** 되돌리기: updates의 그 파일을 지우고 `depmod -a`.
- 카카오톡: 창을 옮길 수 있게 Wine 창(`*.exe`)도 hyprbars 제목 표시줄을 쓴다. Wine 트레이 창(explorer.exe 160x20)은
  레지스트리 `HKCU\Software\Wine\X11 Driver\ShowSystray=N` 으로 껐다 (기존 프리픽스에 적용함, 새 설치는 kakaotalk 스크립트).
- 카카오톡 한글 안 됨(영어만 됨): 카톡 창이 활성이어도 X 입력 포커스가 없어(`XGetInputFocus` = None) fcitx5의 XIM 입력
  컨텍스트가 `focus:0` 이었다. 레지스트리 `HKCU\Software\Wine\X11 Driver\UseTakeFocus=N` 으로 고침 (기존 프리픽스에 적용함, 새 설치는
  kakaotalk 스크립트). 확인: `dbus-send --print-reply --dest=org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1.DebugInfo`
  에서 카톡이 활성일 때 `wine-preloader frontend:xim ... focus:1` 이어야 한다. 사용자가 한글 입력 확인함 (2026-11-19).
- Alt+Tab: `Switcher.qml` 창 목록(미리보기, 최근 사용 순). Alt+Tab/Alt+Shift+Tab = `ipc call switcher next/prev`, 마우스로 고르기, Alt+Esc·바깥 클릭 = 취소.
  Alt를 뗀 것은 hyprland.lua의 타이머(`hl.is_key_down("Alt_L")`, 40ms)가 보고 `commit` 한다. release 단축키는 그 사이에 다른
  단축키(Alt+Tab)가 눌리면 Hyprland가 실행하지 않아서 쓸 수 없다. 시험: `hyprctl dispatch 'hl.dsp.exec_cmd((function() shittim_switcher("next")() return "true" end)())'`
- Wine 트레이 창(explorer.exe, 제목 없음, 160x20)은 창 규칙 `wine-tray`로 `special:winetray`에 보낸다. Proton 게임(블루 아카이브의 넥슨)은
  트레이 창 class가 `steam_app_<id>`라서 `window.open` 핸들러가 제목 없음 + 160x20을 보고 같은 곳으로 옮긴다. 규칙은 새로 뜨는 창에만 먹는다.
- pacman "키링을 쓸 수 없음": 설치 USB의 `/etc/systemd/system/etc-pacman.d-gnupg.mount`(tmpfs)가 설치된 시스템에 남아
  다시 시작할 때마다 열쇠고리가 비워졌다. `tools/fix-speaker.sh`가 그 유닛을 지우고 `pacman-key --init/--populate` 한다
  (설치 스크립트 `shittim-install`에도 반영).

루트 필요 (apply-system.sh)
- Steam·gamemode 등 패키지, 부팅·종료 컷씬(4.5초 시간 기반 진행 막대, 끝까지 재생, GRUB 메뉴 숨김 - Esc로 표시).

남은 것
- 아로나 curious 표정: Spine 원본이 없어 못 만듦. `assets/arona/curious.webp`를 넣으면 코드 수정 없이 나온다 (지금은 smile로 대체).

## 프라나 (2026-11-19)
- 모션: 사용자가 준 `expressions.zip`(720x1280 투명 VP9 webm 23개, 30fps 200프레임)을 `assets/plana/<표정>.webp`(640x1300, 발 위치를 아로나에 맞춤)로 변환.
  `ffmpeg -c:v libvpx-vp9 -i X.webm -vf "crop=640:1280:39:0,pad=640:1300:0:13:color=0x00000000" -c:v libwebp_anim -quality 75 -loop 0 X.webp`
  (`-c:v libvpx-vp9` 를 입력 앞에 꼭 줄 것: 기본 vp9 디코더는 투명도를 버린다.)
  **한 바퀴만 잘라 쓴다 (`-frames:v N` 추가)**: 원본은 200프레임이지만 동작 한 바퀴는 Idle = 109프레임, 나머지 표정 = 100프레임이다.
  Idle을 200프레임 그대로 돌리면 1.83바퀴에서 끊겨 처음으로 돌아갈 때 튄다. 새 표정을 변환할 때는 첫 프레임과 가장 닮은 프레임 번호를 N으로.
- 표정 연결(`AronaSprite.qml`의 `plana` 표): smile→idle, angry→displeased, curious→sparkling, thinking→serious, happy·surprised는 같은 이름.
  쓰지 않는 나머지 17개는 지웠다 (사용자 결정). 다시 필요하면 원본 zip에서 위 명령으로 변환한다.
- 대사: `Arona.qml`의 `aronaLines` / `planaLines` (같은 키 63개), `Arona.lines`가 지금 캐릭터의 표. 표 밖의 문장은 `Arona.v(아로나, 프라나)`.
- 교체: 설정 → 아로나 → 성격 저장 → `Arona.switching` 2초 동안 `Loading.qml`(Plymouth 테마 그림 재사용)이 덮고 1초째에 `Arona.who`가 바뀐다.
  끝나면 `hello` 대사. 대화 기록은 교체 때 비운다.
- 블루투스(Britz BT4000 ANC) 연결 끊김: 헤드셋이 꺼져 있어 재현 못 함. 켠 상태에서 `journalctl -b -u bluetooth -f` 를 보며 다시 연결해 원인 확인.

## 프라나 컷씬 색·잠금화면·창 위치 (2026-11-20)
- 보라색 컷씬: Plymouth 테마에 그림 세트 두 벌 `themes/shittim/arona/`(파랑, 원본) · `plana/`(보라). 테마 폴더 맨 위의 png가 실제로 쓰이는 것.
  보라 세트는 원본을 색상만 돌린 것: `ffmpeg -i arona/X.png -vf "format=yuva444p10le,hue=h=60,format=rgba" plana/X.png` (원본 그림을 바꾸면 다시 만들 것).
  `shittim-splash-who`(루트, `shittim-splash-who.path`가 `~/.config/shittim` 변경을 보고 실행 + 부팅 때 한 번)가 성격이 바뀐 때에만
  세트를 맨 위로 복사하고 `mkinitcpio -P` 한다 (부팅 컷씬은 initramfs 안의 그림을 쓴다). 지금 색은 `themes/shittim/who`.
  종료 컷씬은 바로, 부팅 컷씬은 initramfs가 다 만들어진 뒤(10~20초)부터 바뀐다. 설치: `sudo bash tools/apply-splash.sh`.
  ISO로 새로 설치할 때는 두 유닛을 enable 해야 한다 (apply-system.sh가 apply-splash.sh를 부른다).
- 교체 화면(`Loading.qml`)도 바뀔 캐릭터의 세트를 쓴다.
- 잠금화면에 아로나가 잠깐 나오던 것: `arona.json`은 FileView가 뒤에서 읽어서 `Arona.who`가 "arona"로 시작했고, 읽힌 뒤의 교체(1초)가
  잠금화면 밑에서 돌았다. `Arona.qml`의 onCompleted에서 `cfgFile.waitForJob()`으로 다 읽은 뒤 who를 정한다.
- 새 창이 화면 위로 잘려 뜨던 것: hyprland.lua `keep_top` (window.open + 0.4초 뒤 한 번 더). 뜬 뒤에 사용자가 올리는 것은 그대로 둔다.

## 절전 컷씬·음악 대시보드 (2026-11-20)
- **보라색 컷씬이 안 나오면 `sudo bash ~/shittim-os/tools/apply-splash.sh` 가 아직 안 돌아간 것이다** (`/usr/share/plymouth/themes/shittim/plana/` 가 없으면 미설치).
  교체·절전 컷씬(`Loading.qml`)도 그 폴더의 그림을 쓴다.
- 절전: 대사(4초) → `Ui.sleeping` 으로 `Loading.qml` 컷씬(1.5초) → 잠금 + `systemctl suspend` (`PowerMenu.qml`의 sleepCut/sleepGo/wake 타이머).
  잠들기 전 잠금화면이 안 보이게 `Lock.qml`이 `Ui.sleeping` 동안 어둡게 덮고, 벽시계가 건너뛰면(깨어남) 걷는다.
- 음악: 독의 "음악" = `Ui.musicOpen` 켜고 끄기 (`quickshell ipc call music toggle`). `Music.qml`이 `mpv --input-ipc-server`
  (`$XDG_RUNTIME_DIR/shittim-mpv.sock`)로 `~/음악/재생목록` 을 이름 순서로 반복 재생한다. 끄면 mpv도 끝난다.
  곡 이름 클릭 = 그 폴더 열기. ⏮ = 3초 안이면 이전 곡, 아니면 처음부터. 막대는 무작위(실제 음량 아님).

## 큰 창 위의 작은 창이 안 눌리던 것 (2026-11-21)
- 원인: 모든 창이 떠 있는 창인데, Hyprland의 최대화/전체 화면 상태인 창은 누르면 클릭 순서로는 맨 위로 올라오면서 화면에는
  그 위에 뜬 창이 계속 그려진다. 그래서 큰 창을 한 번 누른 뒤에는 그 위에 보이는 작은 창을 눌러도 큰 창이 받았다.
- 최대화: Hyprland 최대화 상태를 쓰지 않는다. `shittim_snap("max")` = 화면 가득한 크기·자리로 옮기기, 한 번 더 = 원래대로
  (□ 버튼, 제목 표시줄 두 번 누르기, Super+↑, 위로 끌어 붙이기, 설정 창의 □ 모두 이것). 앱이 청하는 최대화는 `suppress_event = "maximize"`로 무시.
  그래서 최대화된 창을 누르면 Windows처럼 그 창이 앞으로 오고 작은 창은 뒤로 간다.
  `hl.dsp.window.fullscreen({ mode = "maximized" })` 를 다시 쓰지 말 것. (최대화 이벤트를 받아 바로 풀고 크기를 바꾸는 방식은 가끔 크기가 안 바뀌었다.)
- 전체 화면(게임): 활성이 되거나 눌릴 때마다 `alter_zorder bottom` 으로 맨 밑에 둔다 (hyprland.lua `sink`).
- 시험: /dev/uinput 가상 마우스로 클릭 + `kitty`에서 `printf '\033[?1000h'` 로 어느 창이 클릭을 받았는지 확인. 실제 게임(블루 아카이브) 위에서 설정 창이 눌리는 것은 사용자가 확인함 (2026-11-21).

## 블루투스 연결이 잘 안 됨 (2026-11-21)
- 어댑터: MediaTek MT7922 (USB 13d3:3576, btusb). 기록에 남은 실패는 전부 `br-connection-page-timeout`(기기가 응답 없음,
  bluetoothd 로그에는 "Unable to get Hands-Free ... Host is down"). 시험할 때 기기가 켜져 있었는지는 모른다 → **원인 미확정.**
- 한 것 1: 설정 → 블루투스의 "연결"이 다섯 번까지 알아서 다시 건다(붙자마자 끊겨도), 다 실패하면 안내 문구 (`Settings.qml` btPage의 `go()`/`tries`).
- 한 것 2 (루트, **사용자가 실행해야 적용**): `sudo bash tools/fix-bluetooth.sh` = btusb USB 절전 끄기 (`/etc/modprobe.d/shittim-bluetooth.conf`).
- 그래도 안 되면: 기기를 켠 채 `journalctl -b -u bluetooth -f` 를 보며 연결. "붙었다가 바로 끊김"이 인증 실패(키 불일치)면 설정에서 삭제 후 다시 페어링.
- 2026-11-21 00:56 실측 (IB-IX7 켠 상태, 절전 끄기 스크립트 실행 전): page timeout 4번(약 9초 간격) 뒤 5번째에 연결, 이후 1분 넘게 유지·소리 출력 잡힘.
  기기가 켜져 있어도 호출을 놓친다 = 노트북 쪽 문제일 가능성이 높다. 재시도를 5번으로 늘림. `fix-bluetooth.sh` 실행 뒤 한 번에 붙는지 확인할 것.
- 결론 (사용자 확인, 2026-11-21): 헤드셋이 휴대폰에 연결돼 있어서 노트북의 호출에 응답하지 않았던 것. 노트북 쪽 문제 아님.
  위의 "노트북 쪽 문제일 가능성"은 틀렸다. `fix-bluetooth.sh`(절전 끄기)는 꼭 필요하지 않다 - 실행 안 해도 된다.
