// Shittim OS desktop shell. One desktop, top bar and dock per screen; one launcher.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick

ShellRoot {
    // Hyprland's Super+Space runs: quickshell ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void { Ui.launcherOpen = !Ui.launcherOpen }
    }
    Launcher { screen: Quickshell.screens[0] }
    Chat { screen: Quickshell.screens[0] }
    PowerMenu { screen: Quickshell.screens[0] }
    Switcher { screen: Quickshell.screens[0] }
    Music { screen: Quickshell.screens[0] }
    Capture { screen: Quickshell.screens[0] }
    SnapPreview { screen: Quickshell.screens[0] }
    // Super+I (설정) / Super+A (아로나와 대화); "settings open bluetooth" opens a given page.
    // 설정 itself runs in its own process (settings-app.qml), see Ui.settings().
    IpcHandler {
        target: "settings"
        function toggle(): void { Ui.settings("toggle") }
        function open(page: string): void { Ui.settings("open", page) }
    }
    IpcHandler {   // 윈도우 키만 눌렀다 떼면 (hyprland.lua)
        target: "menu"
        function toggle(): void { if (!lockScreen.locked) Ui.menuOpen = !Ui.menuOpen }
    }
    Connections {
        target: Ui
        function onLauncherOpenChanged() { Sfx.play(Ui.launcherOpen ? "open" : "close"); if (Ui.launcherOpen) Arona.react("search") }
        function onChatOpenChanged() { Sfx.play(Ui.chatOpen ? "open" : "close"); if (Ui.chatOpen) Arona.react("chat") }
        function onMenuOpenChanged() { Sfx.play(Ui.menuOpen ? "open" : "close") }
    }
    Connections {
        target: Arona
        function onReplyTextChanged() { if (Arona.replyText) Sfx.play("receive") }
        function onReplyErrorChanged() { if (Arona.replyError) Sfx.play("error") }
        function onSwitchingChanged() { if (!Arona.switching) Arona.react("hello") }   // 교체가 끝나면 새 캐릭터가 인사
    }
    IpcHandler {   // 음악 대시보드: quickshell ipc call music toggle
        target: "music"
        function toggle(): void { Ui.musicOpen = !Ui.musicOpen }
    }
    IpcHandler {
        target: "chat"
        function toggle(): void { Ui.chatOpen = !Ui.chatOpen }
    }

    // 다른 프로세스(설정 창, 스크립트)가 아로나에게 한마디 시킨다: quickshell ipc call arona react <상황>
    IpcHandler {
        target: "arona"
        function react(ev: string): void { Arona.react(ev) }
        function ask(text: string): void { Arona.ask(text) }
        function see(path: string): void { seeProc.command = ["base64", "-w0", path]; seeProc.running = true }   // 화면 물어보기 (shittim-see)
    }
    // 화면 물어보기: Super+Shift+A 로 고른 화면 조각(png)을 Gemini 에 보여 주고 답을 대화창·목소리로 듣는다
    Process {
        id: seeProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                Ui.chatOpen = true
                Arona.ask("(화면을 보여 줬어요)", [{ inlineData: { mimeType: "image/png", data: text } },
                    { text: "내 화면의 이 부분을 보여 줄게. 무엇인지 짧게 설명해 줘. 글이 있으면 핵심만 요약하고, 오류나 질문이 보이면 해결 방법이나 답을 알려 줘." }])
            }
        }   // 시험용: quickshell ipc call arona ask "…" (답이 대화창·목소리로 나온다)
    }
    // 창이 하나도 없는 바탕화면을 5분 보고 있으면 말을 건다. 자리를 비웠을 때 계속 떠들지 않게 연속 3번까지만.
    property int idleSaid: 0
    readonly property int windows: ToplevelManager.toplevels.values.length
    onWindowsChanged: idleSaid = 0
    Timer {
        interval: 300000; repeat: true
        running: windows === 0 && !lockScreen.locked && !Ui.chatOpen && !Ui.launcherOpen && idleSaid < 3
        onTriggered: { idleSaid++; Arona.react("idle") }
    }
    // 배터리 20% 아래로 내려가면 한 번, 충전기를 꽂으면 한 번
    property bool lowSaid: false
    readonly property real battery: UPower.displayDevice.percentage <= 1 ? UPower.displayDevice.percentage * 100 : UPower.displayDevice.percentage
    onBatteryChanged: if (UPower.onBattery && battery < 20 && !lowSaid) { lowSaid = true; Arona.react("battery-low") }
    Connections {
        target: UPower
        function onOnBatteryChanged() { if (!UPower.onBattery) { lowSaid = false; Arona.react("battery-charging") } }
    }

    // Hyprland's Super+L (and the lock right after login) runs: quickshell ipc call lock lock
    IpcHandler {
        target: "lock"
        function lock(): void { lockScreen.lock() }
    }
    Lock { id: lockScreen }

    Variants {
        model: Quickshell.screens
        Scope {
            id: scope
            required property ShellScreen modelData
            Desktop { screen: scope.modelData }
            TopBar { screen: scope.modelData }
            Dock { screen: scope.modelData }
            Loading { screen: scope.modelData }
        }
    }
}
