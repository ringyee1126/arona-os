import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Bottom strip: app dock (drag / wheel to scroll when it overflows), the Arona search button and the big
// yellow "업무 시작하기" button.
PanelWindow {
    id: dock
    readonly property real s: screen ? screen.height / 1200 : 1
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 210 * s
    exclusiveZone: 190 * s
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shittim-dock"
    mask: Region { item: box; Region { item: bigBtn } Region { item: searchBtn } }

    // "업무 시작하기" = 블루 아카이브 (~/.local/bin/shittim-work). 설치돼 있을 때만 눌린다; 20초마다 다시 확인.
    property bool workReady: false
    Process { id: workCheck; command: ["shittim-work", "check"]; onExited: code => dock.workReady = code === 0 }
    Timer { interval: 20000; running: true; repeat: true; triggeredOnStart: true; onTriggered: workCheck.running = true }

    // name, icon file, command. An empty command means "not ready yet" and Arona says so.
    readonly property var apps: [
        { name: "파일", icon: "files", cmd: ["thunar"] },
        { name: "크롬", icon: "chrome", cmd: ["chromium"] },
        { name: "디스코드", icon: "discord", cmd: ["discord"] },
        { name: "카카오톡", icon: "kakao", cmd: ["kakaotalk"] },
        { name: "VS Code", icon: "code", cmd: ["code"] },
        { name: "Claude", icon: "claude", cmd: ["chromium", "--app=https://claude.ai"] },
        { name: "Claude Code", icon: "claudecode", cmd: ["kitty", "--title", "Claude Code", "-e", "bash", "-lc", "cd ~; claude; exec bash"] },
        { name: "문서", icon: "docs", cmd: ["libreoffice"] },
        { name: "음악", icon: "music", cmd: ["sh", "-c", "thunar \"$(xdg-user-dir MUSIC)\""] },
        { name: "설정", icon: "settings", cmd: ["settings"] },
        { name: "터미널", icon: "terminal", cmd: ["kitty"] },
        { name: "사진", icon: "photos", cmd: ["sh", "-c", "thunar \"$(xdg-user-dir PICTURES)\""] },
        { name: "동영상", icon: "videos", cmd: ["sh", "-c", "thunar \"$(xdg-user-dir VIDEOS)\""] },
        { name: "메모장", icon: "notes", cmd: ["mousepad"] },
        { name: "캡처", icon: "capture", cmd: ["shittim-shot", "region"] },   // ~/사진/스크린샷 + 클립보드
        { name: "Steam", icon: "steam", cmd: ["steam"] },
        { name: "압축", icon: "archive", cmd: ["file-roller"] }
    ]
    function launch(app) {
        if (app.cmd[0] === "settings") Ui.settings("toggle")
        else if (app.cmd.length) Quickshell.execDetached(app.cmd)
        else Arona.say(app.name + " 기능은 아직 준비 중이에요.\n조금만 기다려 주세요!")
    }

    // ---------- dock ----------
    Rectangle {
        id: box
        x: 40 * dock.s
        anchors.bottom: parent.bottom; anchors.bottomMargin: 30 * dock.s
        width: Math.min(dock.width - 80 * dock.s - (330 + 150 + 36) * dock.s, 1000 * dock.s, list.contentWidth + 36 * dock.s)
        height: 152 * dock.s
        radius: 18 * dock.s
        color: "#99FFFFFF"; border.color: "#66FFFFFF"; border.width: 1

        ListView {
            id: list
            anchors { fill: parent; leftMargin: 18 * dock.s; rightMargin: 18 * dock.s; topMargin: 14 * dock.s; bottomMargin: 18 * dock.s }
            orientation: ListView.Horizontal
            spacing: 14 * dock.s
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 2500
            model: dock.apps
            delegate: Item {
                id: cell
                required property var modelData
                width: 96 * dock.s; height: list.height
                Rectangle { x: 10 * dock.s; y: 4 * dock.s; width: 76 * dock.s; height: width; radius: 16 * dock.s; color: "#C7DDEB" }
                Rectangle {
                    x: 10 * dock.s; width: 76 * dock.s; height: width; radius: 16 * dock.s; color: "white"
                    scale: ma.pressed ? 0.94 : 1
                    Behavior on scale { NumberAnimation { duration: 90 } }
                    Image {
                        anchors.centerIn: parent
                        width: 40 * dock.s; height: width
                        source: Theme.assets + "icons/" + cell.modelData.icon + ".svg"
                        sourceSize.width: width * 2; sourceSize.height: height * 2
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter; y: 94 * dock.s
                    text: cell.modelData.name; color: Theme.ink
                    font.family: Theme.font; font.pixelSize: 15 * dock.s; font.weight: Font.Bold
                }
                MouseArea { onPressedChanged: if (pressed) Sfx.tap(); id: ma; anchors.fill: parent; onClicked: dock.launch(cell.modelData) }
            }
            WheelHandler { onWheel: e => list.flick((e.angleDelta.y || e.angleDelta.x) * 12, 0) }
        }

        // edge fades: only on the side that still has apps hidden
        Rectangle {
            visible: !list.atXBeginning
            anchors { left: list.left; top: list.top; bottom: list.bottom }
            width: 60 * dock.s
            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#F2FFFFFF" } GradientStop { position: 1; color: "#00FFFFFF" } }
        }
        Rectangle {
            visible: !list.atXEnd
            anchors { right: list.right; top: list.top; bottom: list.bottom }
            width: 60 * dock.s
            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#00FFFFFF" } GradientStop { position: 1; color: "#F2FFFFFF" } }
        }
        // position bar
        Rectangle {
            visible: list.contentWidth > list.width
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 24 * dock.s; rightMargin: 24 * dock.s; bottomMargin: 8 * dock.s }
            height: 4 * dock.s; radius: 2 * dock.s; color: "#261C86C2"
            Rectangle {
                height: parent.height; radius: parent.radius; color: Theme.sky
                width: parent.width * list.visibleArea.widthRatio
                x: parent.width * list.visibleArea.xPosition
            }
        }
    }

    // ---------- Arona search: small button left of the big one ----------
    Item {
        id: searchBtn
        anchors { right: bigBtn.left; bottom: parent.bottom; rightMargin: 18 * dock.s; bottomMargin: 30 * dock.s }
        width: 150 * dock.s; height: 140 * dock.s
        scale: searchMa.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        SkewRect { anchors.fill: parent; anchors.topMargin: 6 * dock.s; radius: 18 * dock.s; color: "#C7D6E2" }
        SkewRect { anchors.fill: parent; anchors.bottomMargin: 6 * dock.s; radius: 18 * dock.s; color: "#F4F9FC"; border.color: "#A6FFFFFF"; border.width: 3 * dock.s }
        Column {
            anchors.centerIn: parent; anchors.verticalCenterOffset: -3 * dock.s
            spacing: 6 * dock.s
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 46 * dock.s; height: width
                source: Theme.assets + "icons/search.svg"
                sourceSize.width: width * 2; sourceSize.height: height * 2
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "아로나 검색"; color: Theme.ink; font.family: Theme.font; font.pixelSize: 17 * dock.s; font.weight: Font.Black }
        }
        MouseArea { id: searchMa; anchors.fill: parent; onPressedChanged: if (pressed) Sfx.tap(); onClicked: Ui.launcherOpen = true }
    }

    // ---------- big yellow button: 업무 시작하기 (블루 아카이브). Grey and inert until the game is installed ----------
    Item {
        id: bigBtn
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 40 * dock.s; bottomMargin: 30 * dock.s }
        width: 330 * dock.s; height: 140 * dock.s
        scale: bigMa.pressed && dock.workReady ? 0.96 : 1
        opacity: dock.workReady ? 1 : 0.75
        Behavior on scale { NumberAnimation { duration: 90 } }

        SkewRect { anchors.fill: parent; anchors.topMargin: 6 * dock.s; radius: 18 * dock.s; color: dock.workReady ? "#C99400" : "#9FB2C2" }
        SkewRect {
            anchors.fill: parent; anchors.bottomMargin: 6 * dock.s
            radius: 18 * dock.s; border.color: "#A6FFFFFF"; border.width: 3 * dock.s
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: dock.workReady ? "#FFE97A" : "#E6EEF4" }
                GradientStop { position: 0.6; color: dock.workReady ? Theme.halo : "#D5E0E9" }
                GradientStop { position: 1; color: dock.workReady ? "#F0B400" : "#C7D6E2" }
            }
        }
        Column {
            anchors.centerIn: parent; anchors.verticalCenterOffset: -3 * dock.s
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "업무 시작하기"; color: dock.workReady ? Theme.ink : Theme.inkDim; font.family: Theme.font; font.pixelSize: 34 * dock.s; font.weight: Font.Black; font.italic: true }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: dock.workReady ? "블루 아카이브 실행" : "블루 아카이브가 설치되면 열려요"; color: dock.workReady ? "#6B5200" : Theme.inkDim; font.family: Theme.font; font.pixelSize: 16 * dock.s; font.weight: Font.Bold }
        }
        MouseArea {
            id: bigMa; anchors.fill: parent; enabled: dock.workReady
            onPressedChanged: if (pressed) Sfx.tap()
            onClicked: Quickshell.execDetached(["shittim-work"])
        }
    }
}
