pragma Singleton
import Quickshell
import QtQuick

// Shared UI state between windows (the dock button and the Super+Space shortcut both open the launcher).
Singleton {
    property bool launcherOpen: false
    property bool settingsOpen: false
    property string settingsPage: "wifi"     // wifi | bluetooth | sound | display | arona | tasks | about
    property bool chatOpen: false            // MomoTalk with the desktop Arona
    property bool menuOpen: false            // top-right ≡: power + quick controls (PowerMenu.qml)

    function openSettings(page) { settingsPage = page || settingsPage; settingsOpen = true }

    // 설정 runs as its own Quickshell process (settings-app.qml): if Wi-Fi / Bluetooth handling ever crashes, only
    // that window closes - the desktop, Arona and the lock screen stay. call = "toggle" | "open"; page optional.
    readonly property string settingsApp: Quickshell.shellDir + "/settings-app.qml"
    function settings(call, page) {
        Quickshell.execDetached(["sh", "-c",
            'quickshell ipc -p "$0" call settings "$1" $2 >/dev/null 2>&1 || SHITTIM_SETTINGS_PAGE="$2" exec quickshell -n -p "$0"',
            settingsApp, call, page || ""])
    }
}
