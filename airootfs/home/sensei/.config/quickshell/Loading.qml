import Quickshell
import Quickshell.Wayland
import QtQuick

// 아로나 ↔ 프라나 교체 중 2초 동안 화면을 덮는 싯딤 로딩 화면. 부팅 컷씬(Plymouth 테마)의 그림을 그대로 쓴다.
// 캐릭터는 이 화면에 가려진 1초째에 바뀐다 (Arona.qml의 swap 타이머).
PanelWindow {
    id: w
    readonly property real s: screen ? screen.height / 1200 : 1
    readonly property string art: "file:///usr/share/plymouth/themes/shittim/"
    visible: Arona.switching || fade.opacity > 0
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shittim-loading"

    Rectangle {
        id: fade
        anchors.fill: parent
        color: "#02070f"
        opacity: Arona.switching ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        MouseArea { anchors.fill: parent }   // 가려진 동안 뒤의 창이 눌리지 않게

        Image { anchors.fill: parent; source: w.art + "bg.png" }
        Image {
            x: (parent.width - width) / 2; y: 400 * w.s - height / 2; width: 300 * w.s; height: width
            source: w.art + "ring_out.png"
            RotationAnimation on rotation { from: 0; to: 360; duration: 6000; loops: Animation.Infinite; running: w.visible }
        }
        Image {
            x: (parent.width - width) / 2; y: 400 * w.s - height / 2; width: 300 * w.s; height: width
            source: w.art + "ring_in.png"
        }
        Image {
            x: (parent.width - width) / 2; y: 665 * w.s - height / 2; width: 900 * w.s; height: 150 * w.s
            source: w.art + "title.png"
        }
        Image {
            id: barBg
            x: (parent.width - width) / 2; y: 797 * w.s - height / 2; width: 600 * w.s; height: 30 * w.s
            source: w.art + "bar_bg.png"
            Item {   // 2초 동안 차오르는 막대
                height: parent.height; clip: true
                width: Arona.switching ? parent.width : 0
                Behavior on width { enabled: Arona.switching; NumberAnimation { duration: 2000 } }
                Image { width: barBg.width; height: barBg.height; source: w.art + "bar_fill.png" }
            }
        }
    }
}
