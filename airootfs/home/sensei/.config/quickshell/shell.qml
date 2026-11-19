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
