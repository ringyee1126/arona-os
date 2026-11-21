import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import QtQuick

// Top strip: profile plate (left) and resource pills (right). Windows tile below it.
PanelWindow {
    id: bar
    readonly property real s: screen ? screen.height / 1200 : 1
    anchors { top: true; left: true; right: true }
    implicitHeight: 130 * s
    exclusiveZone: 110 * s
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shittim-bar"
    mask: Region { item: profile; Region { item: pills } }

    // Profile bar = how far through the day (06:00 -> 24:00), a nod to the EXP bar in the game
    readonly property real dayProgress: Math.max(0, Math.min(1, (Theme.hour * 60 + Theme.now.getMinutes() - 360) / 1080))

    // Wi-Fi name from NetworkManager, refreshed every 10 s; a wired link shows as "유선"
    property string ssid: ""
    Process {
        id: nm
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null | awk -F: '$2==\"connected\"{print ($1==\"wifi\" ? $3 : \"유선\"); exit}'"]
        stdout: StdioCollector { onStreamFinished: bar.ssid = text.trim() }
    }
    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: nm.running = true }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var bat: UPower.displayDevice

    // ---------- profile ----------
    Item {
        id: profile
        x: 40 * bar.s; y: 28 * bar.s
        width: plate.x + plate.width; height: badge.height

        Rectangle {
            id: plate
            x: 72 * bar.s
            anchors.verticalCenter: badge.verticalCenter
            width: Math.max(310 * bar.s, plateCol.implicitWidth + 70 * bar.s); height: 84 * bar.s
            radius: 12 * bar.s; color: "#EDFFFFFF"
            Column {
                id: plateCol
                x: 38 * bar.s; anchors.verticalCenter: parent.verticalCenter
                spacing: 3 * bar.s
                Text { text: "선생님"; color: Theme.ink; font.family: Theme.font; font.pixelSize: 24 * bar.s; font.weight: Font.Black }
                Text { text: "싯딤의 상자 · " + Arona.name + " 대기 중"; color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 15 * bar.s; font.weight: Font.DemiBold }
                Rectangle {
                    width: 230 * bar.s; height: 8 * bar.s; radius: 4 * bar.s; color: "#DCE8F0"
                    Rectangle { width: parent.width * bar.dayProgress; height: parent.height; radius: parent.radius; color: Theme.sky }
                }
            }
        }
        Rectangle {
            id: badge
            width: 92 * bar.s; height: width; radius: width / 2
            color: Theme.ink; border.color: "white"; border.width: 4 * bar.s
            Column {
                anchors.centerIn: parent
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "일월화수목금토".charAt(Theme.now.getDay()) + "요일"; color: "#8FD0F2"; font.family: Theme.font; font.pixelSize: 13 * bar.s; font.weight: Font.Bold; font.letterSpacing: 1.3 * bar.s }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(Theme.now, "M/d"); color: "white"; font.family: Theme.font; font.pixelSize: 24 * bar.s; font.weight: Font.Black; font.italic: true }
            }
        }
    }

    // ---------- resource pills ----------
    Row {
        id: pills
        anchors.right: parent.right; anchors.rightMargin: 40 * bar.s
        y: 38 * bar.s
        spacing: 12 * bar.s

        Pill {
            s: bar.s; icon: "wifi"; text: bar.ssid || "연결 안 됨"
            MouseArea { onPressedChanged: if (pressed) Sfx.tap(); anchors.fill: parent; onClicked: Ui.settings("open", "wifi") }
        }
        Pill {
            s: bar.s; icon: "volume"
            text: bar.sink && bar.sink.audio ? Math.round(bar.sink.audio.volume * 100) : "–"
            MouseArea { onPressedChanged: if (pressed) Sfx.tap(); anchors.fill: parent; onClicked: Ui.settings("open", "sound") }
            WheelHandler {
                onWheel: e => {
                    if (!bar.sink || !bar.sink.audio) return
                    bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05)))
                }
            }
        }
        Pill {
            s: bar.s; icon: UPower.onBattery ? "battery" : "battery-charging"; pulse: !UPower.onBattery   // 충전기가 꽂혀 있으면 번개 + 깜빡임
            // percentage is 0..1 in current Quickshell; tolerate 0..100 too
            text: bar.bat && bar.bat.isLaptopBattery ? Math.round(bar.bat.percentage <= 1 ? bar.bat.percentage * 100 : bar.bat.percentage) + "%" : "AC"
        }
        Pill { s: bar.s; dark: true; text: Qt.formatDateTime(Theme.now, "hh:mm") }
        IconButton { s: bar.s; icon: "menu"; onClicked: Ui.menuOpen = !Ui.menuOpen }   // PowerMenu.qml
    }
}
