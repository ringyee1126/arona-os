// Shittim OS desktop shell. One desktop, top bar and dock per screen; one launcher.
import Quickshell
import Quickshell.Io
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
    // Super+I (설정) / Super+A (아로나와 대화); "settings open bluetooth" opens a given page.
    // 설정 itself runs in its own process (settings-app.qml), see Ui.settings().
    IpcHandler {
        target: "settings"
        function toggle(): void { Ui.settings("toggle") }
        function open(page: string): void { Ui.settings("open", page) }
    }
    IpcHandler {   // 윈도우 키만 눌렀다 떼면 (hyprland.lua)
        target: "menu"
        function toggle(): void { Ui.menuOpen = !Ui.menuOpen }
    }
    Connections {
        target: Ui
        function onLauncherOpenChanged() { Sfx.play(Ui.launcherOpen ? "open" : "close") }
        function onChatOpenChanged() { Sfx.play(Ui.chatOpen ? "open" : "close") }
        function onMenuOpenChanged() { Sfx.play(Ui.menuOpen ? "open" : "close") }
    }
    Connections {
        target: Arona
        function onReplyTextChanged() { if (Arona.replyText) { Sfx.play("receive"); Arona.speak(Arona.replyText) } }
        function onReplyErrorChanged() { if (Arona.replyError) Sfx.play("error") }
    }
    IpcHandler {
        target: "chat"
        function toggle(): void { Ui.chatOpen = !Ui.chatOpen }
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
        }
    }
}
