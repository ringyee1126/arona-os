import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick

// Top-right ≡: lock / sleep / restart / shut down, plus volume and brightness. Restart and shut down take a
// second tap so a stray click can't turn the laptop off.
PanelWindow {
    id: menu
    readonly property real s: screen ? screen.height / 1200 : 1
    visible: Ui.menuOpen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shittim-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property string armed: ""          // power action waiting for its second tap
    Timer { id: disarm; interval: 3000; onTriggered: menu.armed = "" }
    onVisibleChanged: { armed = ""; if (visible) { keys.forceActiveFocus(); brightGet.running = true } }

    readonly property var actions: [
        { key: "lock", name: "잠금", icon: "lock", cmd: ["quickshell", "ipc", "call", "lock", "lock"] },
        { key: "sleep", name: "절전", icon: "moon", cmd: ["sh", "-c", "quickshell ipc call lock lock; sleep 1; systemctl suspend"] },
        { key: "reboot", name: "다시 시작", icon: "restart", cmd: ["systemctl", "reboot"], confirm: true },
        { key: "off", name: "시스템 종료", icon: "power", cmd: ["systemctl", "poweroff"], confirm: true }
    ]
    function run(a) {
        if (a.confirm && armed !== a.key) { armed = a.key; disarm.restart(); Arona.react("power-confirm"); return }
        Ui.menuOpen = false
        if (a.key === "lock") return Quickshell.execDetached(a.cmd)
        Arona.react("power-" + a.key)   // 인사를 끝까지 하고 나서 끈다
        Quickshell.execDetached(["sh", "-c", "sleep 4; exec \"$@\"", "sh"].concat(a.cmd))
    }

    // volume (same default output as the top bar) and backlight (absent on external monitors / the VM)
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    property int bright: -1
    Process {
        id: brightGet
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector { onStreamFinished: { const f = text.trim().split(","); menu.bright = f.length >= 4 ? parseInt(f[3]) : -1 } }
    }
    Timer { id: brightSet; interval: 60; onTriggered: Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.max(1, menu.bright) + "%"]) }

    MouseArea { anchors.fill: parent; onClicked: Ui.menuOpen = false }
    Item { id: keys; focus: true; Keys.onEscapePressed: Ui.menuOpen = false }

    component Txt: Text { color: Theme.ink; font.family: Theme.font; font.pixelSize: 16 * Theme.scale }
    component Slider: Item {
        id: sl
        property string label: ""
        property real value: 0
        signal moved(real v)
        width: parent ? parent.width : 0; height: 44 * Theme.scale
        Txt { anchors.verticalCenter: parent.verticalCenter; text: sl.label; font.weight: Font.ExtraBold; width: 60 * Theme.scale }
        Item {
            id: track
            x: 64 * Theme.scale; anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - 56 * Theme.scale; height: 26 * Theme.scale
            readonly property real v: Math.max(0, Math.min(1, sl.value))
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 8 * Theme.scale; radius: height / 2; color: "#DCE8F0"
                Rectangle { width: parent.width * track.v; height: parent.height; radius: parent.radius; color: Theme.sky }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter; x: (track.width - width) * track.v
                width: 22 * Theme.scale; height: width; radius: width / 2; color: "white"; border.color: Theme.sky; border.width: 3 * Theme.scale
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                function at(mx) { return Math.max(0, Math.min(1, mx / width)) }
                onPressed: m => sl.moved(at(m.x))
                onPositionChanged: m => { if (pressed) sl.moved(at(m.x)) }
            }
            WheelHandler { onWheel: e => sl.moved(Math.max(0, Math.min(1, sl.value + (e.angleDelta.y > 0 ? 0.05 : -0.05)))) }
        }
        Txt { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: Math.round(sl.value * 100) + "%"; font.weight: Font.Bold }
    }

    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 40 * menu.s
        y: 100 * menu.s
        width: 440 * menu.s; height: col.implicitHeight + 18 * menu.s
        radius: 16 * menu.s; color: "#F7FFFFFF"; clip: true
        MouseArea { anchors.fill: parent }      // clicks inside the card don't close it

        Column {
            id: col
            width: parent.width
            Rectangle {
                width: parent.width; height: 54 * menu.s; color: Theme.ink
                SkewRect { x: 22 * menu.s; anchors.verticalCenter: parent.verticalCenter; width: 7 * menu.s; height: 22 * menu.s; color: Theme.sky }
                Txt { x: 42 * menu.s; anchors.verticalCenter: parent.verticalCenter; text: "메뉴"; color: "white"; font.pixelSize: 21 * menu.s; font.weight: Font.ExtraBold }
                Txt {
                    anchors.right: parent.right; anchors.rightMargin: 22 * menu.s; anchors.verticalCenter: parent.verticalCenter
                    text: (Arona.settings.userName || "선생님") + " · D+" + Theme.dayCount; color: "#8FC9EA"; font.pixelSize: 14 * menu.s; font.weight: Font.Bold
                }
            }
            Item { width: 1; height: 18 * menu.s }

            // ---------- power ----------
            Grid {
                id: grid
                x: 18 * menu.s; width: parent.width - 36 * menu.s
                columns: 2; spacing: 12 * menu.s
                Repeater {
                    model: menu.actions
                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        readonly property bool hot: menu.armed === modelData.key
                        width: (grid.width - grid.spacing) / 2; height: 92 * menu.s; radius: 12 * menu.s
                        color: hot ? "#FF6B81" : tileMa.containsMouse ? Theme.skySoft : "#EEF5FA"
                        border.width: 2 * menu.s; border.color: hot ? "#FF6B81" : tileMa.containsMouse ? Theme.sky : "transparent"
                        scale: tileMa.pressed ? 0.96 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Image {
                            visible: !tile.hot
                            anchors.horizontalCenter: parent.horizontalCenter; y: 16 * menu.s
                            width: 30 * menu.s; height: width
                            source: Theme.assets + "icons/" + tile.modelData.icon + ".svg"
                            sourceSize.width: width * 2; sourceSize.height: height * 2
                        }
                        Txt {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: tile.hot ? (parent.height - height) / 2 : 56 * menu.s
                            horizontalAlignment: Text.AlignHCenter
                            text: tile.hot ? "한 번 더 누르면\n" + tile.modelData.name : tile.modelData.name
                            color: tile.hot ? "white" : Theme.ink; font.weight: Font.Bold
                        }
                        MouseArea { onPressedChanged: if (pressed) Sfx.tap(); id: tileMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: menu.run(tile.modelData) }
                    }
                }
            }
            Item { width: 1; height: 16 * menu.s }
            Rectangle { x: 18 * menu.s; width: parent.width - 36 * menu.s; height: 1; color: "#E3EDF4" }
            Item { width: 1; height: 8 * menu.s }

            // ---------- quick controls ----------
            Column {
                x: 22 * menu.s; width: parent.width - 44 * menu.s
                Slider {
                    label: "음량"
                    value: menu.sink && menu.sink.audio ? menu.sink.audio.volume : 0
                    onMoved: v => { if (menu.sink && menu.sink.audio) { menu.sink.audio.volume = v; menu.sink.audio.muted = false } }
                }
                Slider {
                    visible: menu.bright >= 0
                    label: "밝기"
                    value: menu.bright / 100
                    onMoved: v => { menu.bright = Math.max(1, Math.round(v * 100)); brightSet.restart() }
                }
            }
            Item { width: 1; height: 8 * menu.s }
            Item {
                x: 18 * menu.s; width: parent.width - 36 * menu.s; height: setBtn.height
                Btn {
                    id: setBtn
                    anchors.right: parent.right; s: menu.s; primary: false; text: "설정 열기"
                    onClicked: { Ui.menuOpen = false; Ui.settings("open", "wifi") }
                }
            }
        }
    }
}
