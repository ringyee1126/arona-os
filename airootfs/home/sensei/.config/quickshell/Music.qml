import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// 왼쪽 아래(독 위)의 음악 대시보드. 독의 "음악" 버튼이 켜고 끈다 (Ui.musicOpen).
// ~/음악/재생목록 안의 곡을 이름 순서로 재생한다: mpv 하나를 띄우고 JSON IPC 소켓으로 조종한다.
PanelWindow {
    id: music
    readonly property real s: screen ? screen.height / 1200 : 1
    visible: Ui.musicOpen
    anchors { bottom: true; left: true }
    margins { left: 40 * s; bottom: 12 * s }
    implicitWidth: 440 * s; implicitHeight: 104 * s
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shittim-music"

    readonly property string sockPath: Quickshell.env("XDG_RUNTIME_DIR") + "/shittim-mpv.sock"
    readonly property string dirCmd: 'd="$(xdg-user-dir MUSIC)/재생목록"; mkdir -p "$d"; '
    property string title: ""
    property bool paused: false
    property int pos: 0
    property int count: 0
    readonly property bool playing: mpv.running && sock.connected && !paused && count > 0

    function send(cmd, id) { sock.write(JSON.stringify(id ? { command: cmd, request_id: id } : { command: cmd }) + "\n"); sock.flush() }
    function go(d) { if (count > 0) send(["set_property", "playlist-pos", (pos + d + count) % count]) }   // 끝에서 처음으로, 처음에서 끝으로
    function toggle() { if (mpv.running) send(["cycle", "pause"]); else mpv.running = true }   // 곡을 넣은 뒤 다시 누르면 시작

    Process {
        id: mpv
        running: Ui.musicOpen
        command: ["sh", "-c", music.dirCmd + 'exec mpv --no-video --no-terminal --no-config --loop-playlist=inf --input-ipc-server="$0" "$d"', music.sockPath]
        onRunningChanged: if (!running) { sock.connected = false; music.count = 0; music.title = "" }
    }
    Timer { interval: 200; repeat: true; running: mpv.running && !sock.connected; onTriggered: sock.connected = true }   // 소켓이 생길 때까지
    Socket {
        id: sock
        path: music.sockPath
        onConnectedChanged: if (connected) {
            const props = ["media-title", "pause", "playlist-pos", "playlist-count"]
            for (let i = 0; i < props.length; i++) music.send(["observe_property", i + 1, props[i]])
        }
        parser: SplitParser {
            onRead: line => {
                let m; try { m = JSON.parse(line) } catch (e) { return }
                if (m.request_id === 9) {   // ⏮: 시작한 지 3초 안이면(= 연달아 두 번 누름 포함) 이전 곡, 아니면 처음부터
                    if (m.data < 3) music.go(-1); else music.send(["seek", 0, "absolute"])
                } else if (m.event === "property-change") {
                    if (m.name === "media-title") music.title = (m.data || "").replace(/\.(mp3|flac|ogg|opus|m4a|aac|wav|wma|webm|mp4|mkv)$/i, "")
                    else if (m.name === "pause") music.paused = !!m.data
                    else if (m.name === "playlist-pos") music.pos = m.data
                    else if (m.name === "playlist-count") music.count = m.data
                }
            }
        }
    }

    component Ico: Canvas {   // prev | next | play | pause
        id: ico
        property string kind: "play"
        signal clicked()
        width: 34 * music.s; height: width
        opacity: icoMa.containsMouse ? 1 : 0.85
        scale: icoMa.pressed ? 0.88 : 1
        onKindChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"), w = width, u = w / 10
            c.reset(); c.fillStyle = "white"
            const tri = (x0, x1) => { c.beginPath(); c.moveTo(x0, 2.5 * u); c.lineTo(x1, 5 * u); c.lineTo(x0, 7.5 * u); c.closePath(); c.fill() }
            if (kind === "play") tri(3 * u, 8 * u)
            else if (kind === "pause") { c.fillRect(2.8 * u, 2.5 * u, 1.5 * u, 5 * u); c.fillRect(5.7 * u, 2.5 * u, 1.5 * u, 5 * u) }
            else if (kind === "next") { tri(2.5 * u, 6.5 * u); c.fillRect(6.5 * u, 2.5 * u, 1.2 * u, 5 * u) }
            else { tri(7.5 * u, 3.5 * u); c.fillRect(2.3 * u, 2.5 * u, 1.2 * u, 5 * u) }
        }
        MouseArea { id: icoMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onPressedChanged: if (pressed) Sfx.tap(); onClicked: ico.clicked() }
    }

    Rectangle {
        anchors.fill: parent
        radius: 10 * music.s
        border.width: 1; border.color: "#55FFFFFF"
        gradient: Gradient {   // 낮 = 밝은 하늘색, 밤 = 남색
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.day ? "#E65BB8EC" : "#E6182A5C" }
            GradientStop { position: 1; color: Theme.day ? "#E68AD4F7" : "#E62B3F86" }
        }

        // 곡 이름: 길면 처음부터 끝까지 천천히 흘러갔다가 처음으로. 누르면 재생목록 폴더가 열린다.
        Item {
            id: nameBox
            x: 20 * music.s; y: 14 * music.s; height: 40 * music.s
            width: ctl.x - x - 14 * music.s
            clip: true
            Text {
                id: name
                anchors.verticalCenter: parent.verticalCenter
                text: music.title || (mpv.running ? "불러오는 중…" : "재생목록 폴더에 곡을 넣어 주세요")
                color: "white"; font.family: Theme.font; font.pixelSize: 21 * music.s; font.weight: Font.Bold
                readonly property real over: Math.max(0, width - nameBox.width)
                onTextChanged: x = 0
                SequentialAnimation on x {
                    running: name.over > 0 && music.visible; loops: Animation.Infinite
                    PauseAnimation { duration: 1500 }
                    NumberAnimation { from: 0; to: -name.over; duration: name.over * 25 }
                    PauseAnimation { duration: 1500 }
                    PropertyAction { value: 0 }
                }
                onOverChanged: if (over === 0) x = 0
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["sh", "-c", music.dirCmd + 'exec thunar "$d"'])
            }
        }
        Row {
            id: ctl
            anchors.right: parent.right; anchors.rightMargin: 16 * music.s
            anchors.verticalCenter: nameBox.verticalCenter
            spacing: 6 * music.s
            Ico { kind: "prev"; onClicked: music.send(["get_property", "time-pos"], 9) }
            Ico { kind: music.playing ? "pause" : "play"; onClicked: music.toggle() }
            Ico { kind: "next"; onClicked: music.go(1) }
        }

        // 재생 중에만 움직이는 막대 (실제 음량과는 무관)
        Row {
            id: bars
            x: 20 * music.s; width: parent.width - 2 * x
            anchors.bottom: parent.bottom; anchors.bottomMargin: 12 * music.s
            height: 30 * music.s
            spacing: 3 * music.s
            Repeater {
                model: 40
                Item {
                    width: (bars.width - 39 * bars.spacing) / 40; height: bars.height
                    Rectangle {
                        id: bar
                        anchors.bottom: parent.bottom; width: parent.width; radius: width / 2
                        color: "#E6FFFFFF"
                        height: 2 * music.s
                        Behavior on height { NumberAnimation { duration: 160 } }
                        Timer {
                            interval: 160; repeat: true; running: music.visible
                            onTriggered: bar.height = music.playing ? (0.15 + 0.85 * Math.random()) * bars.height : 2 * music.s
                        }
                    }
                }
            }
        }
    }
}
