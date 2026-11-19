import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// 창을 화면 가장자리로 끌 때, 놓으면 창이 갈 자리를 미리 보여 준다. hyprland.lua 가 부른다:
//   quickshell ipc call snap box <x> <y> <w> <h>   ("show"는 quickshell ipc 의 명령어와 겹쳐서 못 쓴다)   /   quickshell ipc call snap hide
PanelWindow {
    id: sp
    property bool on: false
    property rect r: Qt.rect(0, 0, 0, 0)
    visible: on || box.opacity > 0
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shittim-snap"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}      // 마우스는 그대로 통과
    IpcHandler {
        target: "snap"
        function box(x: int, y: int, w: int, h: int): void { sp.r = Qt.rect(x, y, w, h); sp.on = true }
        function hide(): void { sp.on = false }
    }
    Rectangle {
        id: box
        x: sp.r.x; y: sp.r.y; width: sp.r.width; height: sp.r.height
        radius: 14; color: "#552FA8E1"; border.width: 3; border.color: "#CC2FA8E1"
        opacity: sp.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
}
