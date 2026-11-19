import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

// Alt+Tab 창 목록 (Windows식). hyprland.lua: Alt+Tab = next, Alt+Shift+Tab = prev, Alt를 떼면 commit.
// 목록은 가장 최근에 쓴 창 순서(hyprctl의 focusHistoryID)라서, Alt+Tab을 한 번 톡 누르면 바로 전에 쓰던 창으로 간다.
PanelWindow {
    id: sw
    readonly property real s: screen ? screen.height / 1200 : 1
    property bool open: false
    property var wins: []          // [{ address, class, title }]
    property int idx: 0
    property int steps: 0          // 목록을 읽는 동안 들어온 Tab 횟수 (+next / -prev)
    property bool wantCommit: false   // 목록이 뜨기 전에 Alt를 뗐다

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shittim-switcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}                // 마우스는 그대로 아래 창으로

    function step(d) {
        if (open) { idx = (idx + d + wins.length) % wins.length; return }
        steps += d
        if (!list.running) { wantCommit = false; list.running = true }
    }
    function commit() {
        if (list.running) { wantCommit = true; return }
        if (!open) return
        open = false
        const w = wins[idx]
        if (w && idx !== 0) Quickshell.execDetached(["sh", "-c",
            // 목록 창이 사라질 때 Hyprland가 마우스 밑의 창으로 포커스를 되돌리므로, 그 뒤에 옮긴다
            "sleep 0.12; hyprctl dispatch \"hl.dsp.focus({ window = 'address:$1' })\"; hyprctl dispatch 'hl.dsp.window.bring_to_top()'", "sh", w.address])
    }
    function thumb(address) {      // 같은 창의 Wayland 핸들 (미리보기용). 못 찾으면 글자만 보인다
        const a = String(address).replace(/^0x/, "")
        const t = Hyprland.toplevels.values.find(t => String(t.address).replace(/^0x/, "") === a)
        return t ? t.wayland : null
    }
    Process {
        id: list
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let l = []
                try { l = JSON.parse(text) } catch (e) {}
                sw.wins = l.filter(c => c.mapped && !c.hidden && c.title !== "" && c.focusHistoryID >= 0)
                           .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                const n = sw.wins.length, d = sw.steps
                sw.steps = 0
                if (n < 2) { sw.wantCommit = false; return }
                sw.idx = ((d % n) + n) % n
                sw.open = true
                if (sw.wantCommit) { sw.wantCommit = false; sw.commit() }
            }
        }
    }
    IpcHandler {
        target: "switcher"
        function next(): void { sw.step(1) }
        function prev(): void { sw.step(-1) }
        function commit(): void { sw.commit() }
    }

    Rectangle {
        anchors.centerIn: parent
        width: row.width + 48 * sw.s; height: row.height + 48 * sw.s
        radius: 24 * sw.s; color: "#E61E3A52"; border.width: 2 * sw.s; border.color: "#66FFFFFF"
        Row {
            id: row
            anchors.centerIn: parent; spacing: 16 * sw.s
            Repeater {
                model: sw.wins.slice(0, 7)   // shortcut: 7개까지만 그린다. 창이 더 많으면 줄바꿈(Flow)으로 바꾼다
                Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === sw.idx
                    width: 220 * sw.s; height: 190 * sw.s; radius: 14 * sw.s
                    color: sel ? Theme.sky : "#33FFFFFF"
                    border.width: sel ? 3 * sw.s : 0; border.color: "white"
                    Rectangle {
                        x: 10 * sw.s; y: 10 * sw.s; width: parent.width - 20 * sw.s; height: 124 * sw.s
                        radius: 8 * sw.s; color: "#55000000"; clip: true
                        Text {   // 미리보기가 없을 때 보이는 글자
                            anchors.centerIn: parent; text: (tile.modelData.class || "?").charAt(0).toUpperCase()
                            color: "#99FFFFFF"; font.family: Theme.font; font.pixelSize: 54 * sw.s; font.weight: Font.Black
                        }
                        ScreencopyView {
                            anchors.fill: parent
                            captureSource: sw.open ? sw.thumb(tile.modelData.address) : null
                            live: false
                        }
                    }
                    Text {
                        x: 12 * sw.s; width: parent.width - 24 * sw.s; y: 144 * sw.s
                        text: tile.modelData.title; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                        color: "white"; font.family: Theme.font; font.pixelSize: 17 * sw.s; font.weight: tile.sel ? Font.ExtraBold : Font.Medium
                    }
                }
            }
        }
    }
}
