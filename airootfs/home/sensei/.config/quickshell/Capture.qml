import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// PrtSc 캡처 메뉴 + 녹화 중 표시. 실제 일은 ~/.local/bin/shittim-shot 이 한다.
//   quickshell ipc call capture open           → 메뉴
//   quickshell ipc call capture state rec|paused|off   (shittim-shot 이 알려 준다)
Scope {
    id: cap
    required property ShellScreen screen
    property bool open: false
    property string state: "off"       // off | rec | paused
    property int secs: 0
    readonly property real s: screen ? screen.height / 1200 : 1
    function run(args) { open = false; Quickshell.execDetached(["shittim-shot"].concat(args)) }
    onStateChanged: if (state === "off") secs = 0
    Timer { interval: 1000; repeat: true; running: cap.state === "rec"; onTriggered: cap.secs++ }

    IpcHandler {
        target: "capture"
        function open(): void { cap.open = true }
        function close(): void { cap.open = false }
        function state(s: string): void { cap.state = s }
    }

    // ---------- 메뉴 ----------
    PanelWindow {
        screen: cap.screen
        visible: cap.open
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "#55000000"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shittim-capture"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        onVisibleChanged: if (visible) keys.forceActiveFocus()
        MouseArea { anchors.fill: parent; onClicked: cap.open = false }
        Item { id: keys; focus: true; Keys.onEscapePressed: cap.open = false }

        Rectangle {
            anchors.centerIn: parent
            width: col.width + 56 * cap.s; height: col.height + 52 * cap.s
            radius: 22 * cap.s; color: "white"
            MouseArea { anchors.fill: parent }   // 카드 안을 눌러도 닫히지 않게
            Column {
                id: col
                anchors.centerIn: parent; spacing: 14 * cap.s
                Item {
                    width: grid.width; height: 40 * cap.s
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "캡처"; color: Theme.ink; font.family: Theme.font; font.pixelSize: 26 * cap.s; font.weight: Font.Black }
                    Rectangle {   // ✕
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 36 * cap.s; height: width; radius: width / 2; color: xMa.containsMouse ? "#FF6B81" : "#E6EEF4"
                        XMark { anchors.centerIn: parent; size: 13 * cap.s; color: xMa.containsMouse ? "white" : Theme.inkDim }
                        MouseArea { id: xMa; anchors.fill: parent; hoverEnabled: true; onPressedChanged: if (pressed) Sfx.tap(); onClicked: cap.open = false }
                    }
                }
                Text { text: "녹화 끝내기: PrtSc 키. 전체 화면 녹화는 마우스를 화면 맨 위 가운데에 대면 조작 막대가 나와요."; width: grid.width; wrapMode: Text.WordWrap; color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 14 * cap.s; font.weight: Font.Bold }
                Grid {
                    id: grid
                    columns: 2; spacing: 12 * cap.s
                    Repeater {
                        model: [
                            { t: "사진", d: "영역 선택", a: ["region"] },
                            { t: "사진", d: "전체 화면", a: ["full"] },
                            { t: "녹화", d: "전체 화면 + 컴퓨터 소리", a: ["rec", "full", "audio"] },
                            { t: "녹화", d: "전체 화면 (소리 없이)", a: ["rec", "full", "mute"] },
                            { t: "녹화", d: "영역 선택 + 컴퓨터 소리", a: ["rec", "region", "audio"] },
                            { t: "녹화", d: "영역 선택 (소리 없이)", a: ["rec", "region", "mute"] }
                        ]
                        Rectangle {
                            id: opt
                            required property var modelData
                            width: 300 * cap.s; height: 76 * cap.s; radius: 12 * cap.s
                            color: oMa.containsMouse ? Theme.skySoft : "#F7FBFE"
                            border.width: 2 * cap.s; border.color: oMa.containsMouse ? Theme.sky : "#CBE4F3"
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; x: 18 * cap.s; spacing: 2 * cap.s
                                Text { text: opt.modelData.t; color: opt.modelData.t === "녹화" ? "#E0384F" : Theme.skyDeep; font.family: Theme.font; font.pixelSize: 15 * cap.s; font.weight: Font.Black }
                                Text { text: opt.modelData.d; color: Theme.ink; font.family: Theme.font; font.pixelSize: 19 * cap.s; font.weight: Font.Bold }
                            }
                            MouseArea { id: oMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onPressedChanged: if (pressed) Sfx.tap(); onClicked: cap.run(opt.modelData.a) }
                        }
                    }
                }
            }
        }
    }

    // ---------- 녹화 중: 빨간 테두리 + 조작 막대 ----------
    // Hyprland에는 "화면에는 보이고 녹화에는 안 찍히는" 레이어가 없다 (no_screen_share 는 그 자리를 검게 칠한다).
    // 그래서 shittim-shot 이 화면 가장자리 4px 안쪽만 녹화하고, 테두리는 그 바깥 4px에 그린다 → 보이지만 안 찍힌다.
    // 조작 막대도 영상에 찍히면 안 된다 (사용자 요청): 녹화 영역 위나 아래에 자리가 있으면 그 바깥에 늘 보이고,
    // 전체 화면처럼 자리가 없으면 숨어 있다가 마우스를 화면 맨 위 가운데에 대면 나온다 (그동안만 영상에 찍힌다).
    property rect frame: Qt.rect(4, 4, 100, 100)     // 녹화 영역 (shittim-shot 이 알려 준다)
    readonly property int t: 4                        // 테두리 두께 = 녹화 영역 바깥 여백
    IpcHandler {
        target: "capframe"
        function set(x: int, y: int, w: int, h: int): void { cap.frame = Qt.rect(x, y, w, h) }
    }
    PanelWindow {
        id: rec
        screen: cap.screen
        visible: cap.state !== "off"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shittim-rec"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region { item: hot }           // 막대(와 위쪽 테두리)만 눌리고 나머지는 아래 창으로
        readonly property color line: cap.state === "paused" ? "#F7C63C" : "#FF2D4A"
        readonly property bool above: cap.frame.y - cap.t >= pill.height + 12       // 영역 위에 막대 놓을 자리가 있다
        readonly property bool below: !above && cap.frame.y + cap.frame.height + cap.t + pill.height + 12 <= cap.screen.height
        readonly property bool outside: above || below
        readonly property bool shown: outside || hover.hovered || pillHover.hovered
        Rectangle {
            x: cap.frame.x - cap.t; y: cap.frame.y - cap.t; width: cap.frame.width + cap.t * 2; height: cap.frame.height + cap.t * 2
            color: "transparent"; border.width: cap.t; border.color: rec.line
        }
        Item {
            id: hot      // 마우스를 받는 곳: 막대가 숨어 있을 때는 위쪽 테두리 가운데만
            x: pill.x; width: pill.width
            y: rec.outside ? pill.y : cap.frame.y - cap.t
            height: rec.outside ? pill.height : rec.shown ? pill.height + 14 : cap.t + 6
            HoverHandler { id: hover }
        }
        Rectangle {
            id: pill
            visible: rec.shown
            x: Math.max(8, Math.min(parent.width - width - 8, cap.frame.x + (cap.frame.width - width) / 2))
            y: rec.above ? cap.frame.y - cap.t - height - 6 : rec.below ? cap.frame.y + cap.frame.height + cap.t + 6 : cap.frame.y + 6
            width: bar.width + 36 * cap.s; height: 52 * cap.s; radius: height / 2
            color: "#F21E3A52"; border.width: 2 * cap.s; border.color: rec.line
            HoverHandler { id: pillHover }      // 막대 위에서는 아래 hot 의 hover 가 끊긴다: 버튼으로 가는 동안 숨지 않게
            Row {
                id: bar
                anchors.centerIn: parent; spacing: 14 * cap.s
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter; width: 14 * cap.s; height: width; radius: width / 2; color: rec.line
                    SequentialAnimation on opacity { running: cap.state === "rec"; loops: Animation.Infinite; alwaysRunToEnd: true
                        NumberAnimation { to: 0.25; duration: 600 } NumberAnimation { to: 1; duration: 600 } }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (cap.state === "paused" ? "일시정지 " : "녹화 중 ") + Math.floor(cap.secs / 60) + ":" + String(cap.secs % 60).padStart(2, "0")
                    color: "white"; font.family: Theme.font; font.pixelSize: 18 * cap.s; font.weight: Font.ExtraBold
                }
                Repeater {
                    model: [{ t: cap.state === "paused" ? "▶ 계속" : "❙❙ 일시정지", a: "pause", c: "#3D5A74" }, { t: "■ 끝내기", a: "stop", c: "#E0384F" }]
                    Rectangle {
                        id: rb
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: rt.width + 26 * cap.s; height: 34 * cap.s; radius: height / 2; color: rMa.containsMouse ? Qt.lighter(modelData.c, 1.25) : modelData.c
                        Text { id: rt; anchors.centerIn: parent; text: rb.modelData.t; color: "white"; font.family: Theme.font; font.pixelSize: 15 * cap.s; font.weight: Font.ExtraBold }
                        MouseArea { id: rMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["shittim-shot", rb.modelData.a]) }
                    }
                }
            }
        }
    }
}
