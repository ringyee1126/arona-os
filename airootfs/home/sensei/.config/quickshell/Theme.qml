pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Colors carried over from ARONA 1.0 (web/css/shittim.css) and the approved mockups.
Singleton {
    readonly property color sky: "#2FA8E1"
    readonly property color skyDeep: "#1C86C2"
    readonly property color skySoft: "#DDEFF9"
    readonly property color ink: "#1E3A52"
    readonly property color inkDim: "#5A7A94"
    readonly property color halo: "#F7C63C"
    readonly property color momo: "#FF8FAB"
    readonly property string font: "Pretendard Variable"
    readonly property string assets: Qt.resolvedUrl("assets/")
    readonly property real skew: 0.2126          // tan(12deg): the slant on pills and buttons
    // UI scale of the main screen (mockups are drawn at 1920x1200), for windows not tied to one screen
    readonly property real scale: Quickshell.screens.length ? Quickshell.screens[0].height / 1200 : 1

    readonly property date now: clock.date
    readonly property int hour: now.getHours()
    readonly property bool day: hour >= 6 && hour < 18

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // D+N (profile badge, settings): counts from ~/.config/shittim/since, written when the image is built / installed
    FileView { id: since; path: Quickshell.env("HOME") + "/.config/shittim/since"; blockLoading: true; printErrors: false }
    readonly property int dayCount: {
        // "2026-11-18" alone parses as UTC midnight (09:00 here), so read it as local midnight
        const t = Date.parse(since.text().trim() + "T00:00:00")
        return isNaN(t) ? 1 : Math.max(1, Math.floor((now - t) / 86400000) + 1)
    }
}
