import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Desktop layer (under all windows): moving background, resident Arona with her speech bubble,
// MomoTalk notifications and today's tasks.
PanelWindow {
    id: desk
    readonly property real s: screen ? screen.height / 1200 : 1
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "shittim-desktop"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "#0B1A2A"

    // ---------- background: Arona's room, day or night by the clock, slowly drifting ----------
    Image {
        id: wall
        property real drift: 0
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: drift
        width: parent.width * 1.08; height: parent.height * 1.08
        fillMode: Image.PreserveAspectCrop
        source: Theme.assets + (Theme.day ? "BG_AronaRoom.jpg" : "BG_AronaRoom_Night.jpg")
        smooth: true
        SequentialAnimation on drift {
            loops: Animation.Infinite
            NumberAnimation { from: -16 * desk.s; to: 16 * desk.s; duration: 45000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 16 * desk.s; to: -16 * desk.s; duration: 45000; easing.type: Easing.InOutSine }
        }
    }

    // ---------- Arona ----------
    Item {
        id: arona
        property real breathe: 0
        property bool patted: false
        height: 1300 * desk.s
        width: height * 640 / 1300
        anchors.right: parent.right; anchors.rightMargin: 120 * desk.s
        y: parent.height - height + 380 * desk.s + breathe
        // while chatting her face follows the answer's [[표정:…]] tag (thinking while she waits for Gemini)
        AronaSprite { anchors.fill: parent; mood: arona.patted ? "happy" : Ui.chatOpen ? Arona.replyMood : "smile" }
        Timer { id: patTimer; interval: 2500; onTriggered: arona.patted = false }
        MouseArea {   // click her: MomoTalk chat opens next to her (Chat.qml)
            onPressedChanged: if (pressed) Sfx.tap()
            x: parent.width * 0.2; y: parent.height * 0.28; width: parent.width * 0.6; height: parent.height * 0.42
            cursorShape: Qt.PointingHandCursor
            onClicked: Ui.chatOpen = !Ui.chatOpen
        }
        MouseArea {   // pat her head: she beams for a moment
            onPressedChanged: if (pressed) Sfx.tap()
            x: parent.width * 0.25; y: parent.height * 0.1; width: parent.width * 0.5; height: parent.height * 0.18
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                arona.patted = true; patTimer.restart()
                Arona.say(Arona.patLines[Math.floor(Math.random() * Arona.patLines.length)])
            }
        }
    }

    // ---------- speech bubble ----------
    Rectangle {
        id: bubble
        property string text: Arona.greeting()
        property bool shown: true
        anchors.right: arona.left; anchors.rightMargin: -185 * desk.s
        // 얼굴 높이(스프라이트 위에서 22%)에 맞춘다. arona.y 대신 식을 써서 숨쉬기 움직임을 따라가지 않게 한다
        y: parent.height - arona.height + 380 * desk.s + arona.height * 0.22 - height / 2
        width: label.width + 52 * desk.s
        height: label.implicitHeight + 44 * desk.s
        radius: 18 * desk.s; color: "white"
        transformOrigin: Item.Right
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.7
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }

        Rectangle {   // tail pointing at Arona
            width: 24 * desk.s; height: width; rotation: 45; color: "white"
            anchors.verticalCenter: parent.verticalCenter; x: parent.width - width / 2
        }
        Text {
            id: label
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 360 * desk.s)
            text: bubble.text
            wrapMode: Text.WordWrap
            color: Theme.ink; font.family: Theme.font; font.pixelSize: 21 * desk.s; lineHeight: 1.3
        }
        MouseArea { onPressedChanged: if (pressed) Sfx.tap(); anchors.fill: parent; onClicked: bubble.shown = false }

        Timer { id: hideTimer; interval: 15000; onTriggered: bubble.shown = false }
        Timer { interval: 3600000; running: true; repeat: true; onTriggered: Arona.say(Arona.greeting()) }
        Connections {
            target: Arona
            function onSay(t) { if (!Ui.chatOpen) { bubble.text = t; bubble.shown = true; hideTimer.restart() } }
        }
        Connections {   // the chat window sits where the bubble is
            target: Ui
            function onChatOpenChanged() { if (Ui.chatOpen) bubble.shown = false }
        }
        Component.onCompleted: hideTimer.restart()
    }

    // ---------- MomoTalk: latest notifications ----------
    Rectangle {
        id: momo
        x: 40 * desk.s; y: 170 * desk.s
        width: 430 * desk.s; height: momoCol.implicitHeight
        radius: 16 * desk.s; color: "#F2FFFFFF"; clip: true
        Column {
            id: momoCol
            width: parent.width
            Rectangle {
                width: parent.width; height: 54 * desk.s; color: Theme.momo
                Text { x: 20 * desk.s; anchors.verticalCenter: parent.verticalCenter; text: "MomoTalk"; color: "white"; font.family: Theme.font; font.pixelSize: 23 * desk.s; font.weight: Font.Black; font.italic: true }
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 16 * desk.s; anchors.verticalCenter: parent.verticalCenter
                    width: cnt.implicitWidth + 20 * desk.s; height: 26 * desk.s; radius: 13 * desk.s; color: "#4DFFFFFF"
                    Text { id: cnt; anchors.centerIn: parent; text: "알림 " + Notifs.list.length; color: "white"; font.family: Theme.font; font.pixelSize: 15 * desk.s; font.weight: Font.Bold }
                }
            }
            Repeater {
                model: Notifs.list.slice(-4).reverse()
                delegate: Item {
                    id: note
                    required property var modelData
                    width: momoCol.width; height: 78 * desk.s
                    Rectangle {
                        x: 20 * desk.s; anchors.verticalCenter: parent.verticalCenter
                        width: 50 * desk.s; height: width; radius: width / 2; color: Theme.sky
                        Text { anchors.centerIn: parent; text: (note.modelData.appName || "?").charAt(0).toUpperCase(); color: "white"; font.family: Theme.font; font.pixelSize: 20 * desk.s; font.weight: Font.Black }
                    }
                    Column {
                        x: 84 * desk.s; anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 110 * desk.s
                        Text { width: parent.width; elide: Text.ElideRight; text: note.modelData.summary || note.modelData.appName; color: Theme.ink; font.family: Theme.font; font.pixelSize: 17 * desk.s; font.weight: Font.Bold }
                        Text { width: parent.width; elide: Text.ElideRight; text: note.modelData.body || note.modelData.appName; color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 15 * desk.s; textFormat: Text.PlainText }
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#F0E4E8" }
                    MouseArea { onPressedChanged: if (pressed) Sfx.tap(); anchors.fill: parent; onClicked: note.modelData.dismiss() }
                }
            }
            Item {
                visible: Notifs.list.length === 0
                width: momoCol.width; height: 70 * desk.s
                Text { anchors.centerIn: parent; text: "새 알림이 없어요"; color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 16 * desk.s }
            }
        }
    }

    // ---------- today's tasks (Tasks.qml; edited in 설정 → 오늘의 업무) ----------
    Rectangle {
        id: tasksCard
        x: 40 * desk.s; y: momo.y + momo.height + 22 * desk.s
        width: 430 * desk.s; height: taskCol.implicitHeight + 10 * desk.s
        radius: 16 * desk.s; color: "#EDFFFFFF"; clip: true
        Column {
            id: taskCol
            width: parent.width
            Rectangle {
                width: parent.width; height: 52 * desk.s; color: Theme.ink
                SkewRect { x: 20 * desk.s; anchors.verticalCenter: parent.verticalCenter; width: 7 * desk.s; height: 22 * desk.s; color: Theme.sky }
                Text { x: 40 * desk.s; anchors.verticalCenter: parent.verticalCenter; text: "오늘의 업무"; color: "white"; font.family: Theme.font; font.pixelSize: 20 * desk.s; font.weight: Font.ExtraBold }
            }
            Repeater {
                model: Tasks.list
                delegate: Item {
                    id: task
                    required property var modelData
                    required property int index
                    width: taskCol.width; height: 46 * desk.s
                    Rectangle {
                        x: 22 * desk.s; anchors.verticalCenter: parent.verticalCenter
                        width: 22 * desk.s; height: width; radius: 6 * desk.s
                        color: task.modelData.done ? Theme.sky : "transparent"
                        border.color: Theme.sky; border.width: 2 * desk.s
                    }
                    Text {
                        x: 56 * desk.s; anchors.verticalCenter: parent.verticalCenter
                        text: task.modelData.text; font.strikeout: task.modelData.done
                        color: task.modelData.done ? "#9AB0C2" : Theme.ink
                        font.family: Theme.font; font.pixelSize: 17 * desk.s; font.weight: Font.DemiBold
                    }
                    MouseArea { onPressedChanged: if (pressed) Sfx.tap(); anchors.fill: parent; onClicked: Tasks.toggle(task.index) }
                }
            }
        }
    }
}
