// 설정 as its own process: quickshell -p ~/.config/quickshell/settings-app.qml (started by Ui.settings()).
// Wi-Fi / Bluetooth / sound live only in here, so a crash in them can never take the desktop or Arona with it.
// The process quits when the window closes; settings are shared with the desktop through their files.
import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    Settings {}
    IpcHandler {
        target: "settings"
        function toggle(): void { Ui.settingsOpen = !Ui.settingsOpen }
        function open(page: string): void { Ui.openSettings(page) }
    }
    Connections {
        target: Ui
        function onSettingsOpenChanged() { if (!Ui.settingsOpen) Qt.quit() }
    }
    Component.onCompleted: Ui.openSettings(Quickshell.env("SHITTIM_SETTINGS_PAGE") || "wifi")
}
