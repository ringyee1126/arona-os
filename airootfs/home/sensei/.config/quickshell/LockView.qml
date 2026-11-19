import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import QtQuick

// What the lock screen shows on one monitor: "PRESS ANY KEY" first, then the login card
// with Arona talking in a story-style dialogue box.
Item {
    id: v
    required property var ctl
    property real s: 1
    property bool login: false
    property bool powerOpen: false
    property int shown: 0          // typewriter: how many characters of ctl.line are visible

    focus: true
    Keys.onPressed: e => { if (!v.login) { v.openLogin(); e.accepted = true } }
    function openLogin() { login = true; field.forceActiveFocus() }
    function closeLogin() { login = false; powerOpen = false; field.text = ""; v.forceActiveFocus() }

    Connections {
        target: v.ctl
        function onFailed() { shake.restart(); field.text = "" }
        function onLineChanged() { v.shown = 0 }
        function onMoodChanged() { hop.restart() }
        function onLockedChanged() { if (v.ctl.locked) v.closeLogin() }
    }
    Timer { interval: 30000; running: v.login && field.text === "" && !v.ctl.busy; onTriggered: v.closeLogin() }
    Timer { interval: 28; repeat: true; running: v.shown < v.ctl.line.length; onTriggered: v.shown++ }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var bat: UPower.displayDevice

    // ---------- background ----------
    Image {
        property real drift: 0
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: drift
        width: parent.width * 1.08; height: parent.height * 1.08
        fillMode: Image.PreserveAspectCrop
        source: Theme.assets + (Theme.day ? "BG_AronaRoom.jpg" : "BG_AronaRoom_Night.jpg")
        SequentialAnimation on drift {
            loops: Animation.Infinite
            NumberAnimation { from: -14 * v.s; to: 14 * v.s; duration: 40000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 14 * v.s; to: -14 * v.s; duration: 40000; easing.type: Easing.InOutSine }
        }
    }
    Repeater {   // twinkling stars at night
        model: Theme.day ? 0 : 60
        delegate: Rectangle {
            x: (0.3 + Math.random() * 0.7) * v.width; y: Math.random() * 0.3 * v.height
            width: (2 + Math.random() * 2) * v.s; height: width; radius: width / 2; color: "white"
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 1; duration: 1200 + Math.random() * 1800 }
                NumberAnimation { to: 0.15; duration: 1200 + Math.random() * 1800 }
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#C7040E1E" }
            GradientStop { position: 0.42; color: "#59040E1E" }
            GradientStop { position: 0.65; color: "#00040E1E" }
        }
    }
    MouseArea { onPressedChanged: if (pressed) Sfx.tap(); anchors.fill: parent; onClicked: if (!v.login) v.openLogin() }

    // ---------- Arona: expression follows ctl.mood, hops when it changes ----------
    Item {
        id: arona
        property real breathe: 0
        property real hopY: 0
        height: 1560 * v.s; width: height * 640 / 1300
        anchors.right: parent.right; anchors.rightMargin: 150 * v.s
        y: parent.height - height + 440 * v.s + breathe + hopY   // breathing itself comes from her Spine idle
        SequentialAnimation {
            id: hop
            NumberAnimation { target: arona; property: "hopY"; to: -26 * v.s; duration: 120; easing.type: Easing.OutQuad }
            NumberAnimation { target: arona; property: "hopY"; to: 0; duration: 220; easing.type: Easing.OutBounce }
        }
        AronaSprite { anchors.fill: parent; mood: v.ctl.mood }
    }

    // ---------- top: tag + status pills ----------
    Row {
        x: 70 * v.s; y: 52 * v.s; spacing: 16 * v.s
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 30 * v.s; height: width; radius: width / 2; color: "transparent"
            border.color: Theme.sky; border.width: 4 * v.s
        }
        Text { anchors.verticalCenter: parent.verticalCenter; text: "SHITTIM CHEST"; color: "white"; font.family: Theme.font; font.pixelSize: 22 * v.s; font.weight: Font.Black; font.letterSpacing: 3 * v.s }
        Text { anchors.verticalCenter: parent.verticalCenter; text: "싯딤의 상자"; color: "#9FD8F5"; font.family: Theme.font; font.pixelSize: 16 * v.s; font.weight: Font.DemiBold }
    }
    Row {
        anchors.right: parent.right; anchors.rightMargin: 70 * v.s
        y: 46 * v.s; spacing: 14 * v.s
        Pill { s: v.s; icon: "wifi"; text: "Wi-Fi" }
        Pill { s: v.s; icon: "volume"; text: v.sink && v.sink.audio ? Math.round(v.sink.audio.volume * 100) : "–" }
        Pill { s: v.s; icon: "battery"; text: v.bat && v.bat.isLaptopBattery ? Math.round(v.bat.percentage <= 1 ? v.bat.percentage * 100 : v.bat.percentage) + "%" : "AC" }
    }

    // ---------- big clock ----------
    Column {
        x: 130 * v.s; y: 250 * v.s
        Item {
            width: clockText.implicitWidth; height: clockText.implicitHeight
            Text { x: 0; y: 6 * v.s; text: clockText.text; color: "#8C1C86C2"; font: clockText.font }   // offset shadow, like the game's numbers
            Text {
                id: clockText
                text: Qt.formatDateTime(Theme.now, "hh:mm")
                color: "white"; font.family: Theme.font; font.pixelSize: 200 * v.s; font.weight: Font.Black; font.italic: true
            }
        }
        Row {
            topPadding: 26 * v.s; spacing: 18 * v.s
            SkewRect { anchors.verticalCenter: parent.verticalCenter; width: 10 * v.s; height: 40 * v.s; color: Theme.halo }
            Text {
                text: (Theme.now.getMonth() + 1) + "월 " + Theme.now.getDate() + "일 " + "일월화수목금토"[Theme.now.getDay()] + "요일"
                color: "white"; font.family: Theme.font; font.pixelSize: 38 * v.s; font.weight: Font.Bold
            }
        }
    }

    // ---------- idle: PRESS ANY KEY ----------
    Column {
        visible: !v.login
        x: 136 * v.s; anchors.bottom: parent.bottom; anchors.bottomMargin: 140 * v.s
        spacing: 12 * v.s
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.25; duration: 1100; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 1100; easing.type: Easing.InOutSine }
        }
        Text { text: "PRESS ANY KEY"; color: "white"; font.family: Theme.font; font.pixelSize: 34 * v.s; font.weight: Font.Black; font.italic: true; font.letterSpacing: 10 * v.s }
        Text { text: "아무 키나 눌러 싯딤의 상자에 접속"; color: "#BFE6FA"; font.family: Theme.font; font.pixelSize: 18 * v.s; font.weight: Font.DemiBold; font.letterSpacing: 1.5 * v.s }
    }

    // ---------- login card ----------
    Rectangle {
        id: card
        property real shakeX: 0
        visible: v.login
        x: 130 * v.s + shakeX; y: 610 * v.s
        width: 620 * v.s; height: cardCol.implicitHeight
        radius: 14 * v.s; color: "#F5FFFFFF"; clip: true
        SequentialAnimation {
            id: shake
            NumberAnimation { target: card; property: "shakeX"; to: -18 * v.s; duration: 45 }
            NumberAnimation { target: card; property: "shakeX"; to: 16 * v.s; duration: 70 }
            NumberAnimation { target: card; property: "shakeX"; to: -10 * v.s; duration: 60 }
            NumberAnimation { target: card; property: "shakeX"; to: 6 * v.s; duration: 50 }
            NumberAnimation { target: card; property: "shakeX"; to: 0; duration: 40 }
        }
        Column {
            id: cardCol
            width: parent.width
            Rectangle {
                width: parent.width; height: 64 * v.s; color: Theme.ink
                SkewRect { x: 30 * v.s; anchors.verticalCenter: parent.verticalCenter; width: 8 * v.s; height: 26 * v.s; color: Theme.sky }
                Text { x: 52 * v.s; anchors.verticalCenter: parent.verticalCenter; text: "선생님 인증"; color: "white"; font.family: Theme.font; font.pixelSize: 24 * v.s; font.weight: Font.ExtraBold }
            }
            Row {
                leftPadding: 30 * v.s; topPadding: 30 * v.s; bottomPadding: 24 * v.s
                spacing: 18 * v.s
                Avatar { s: v.s; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    spacing: 8 * v.s
                    Text { text: "sensei · 비밀번호"; color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 17 * v.s; font.weight: Font.Bold }
                    Rectangle {
                        width: 450 * v.s; height: 58 * v.s; radius: 8 * v.s
                        color: "#F3F9FD"; border.color: v.ctl.fails > 0 && field.text === "" ? "#E0485A" : Theme.sky; border.width: 2 * v.s
                        TextInput {
                            id: field
                            onTextChanged: Sfx.key(field); onPreeditTextChanged: Sfx.key(field)
                            anchors { left: parent.left; right: parent.right; leftMargin: 18 * v.s; rightMargin: 18 * v.s; verticalCenter: parent.verticalCenter }
                            echoMode: TextInput.Password; passwordCharacter: "●"
                            color: Theme.ink; font.family: Theme.font; font.pixelSize: 28 * v.s; font.letterSpacing: 6 * v.s
                            clip: true
                            enabled: !v.ctl.busy
                            onAccepted: v.ctl.submit(text)          // Enter
                            Keys.onEscapePressed: v.closeLogin()                        }
                        Text {
                            visible: field.text === ""
                            anchors { left: parent.left; leftMargin: 18 * v.s; verticalCenter: parent.verticalCenter }
                            text: v.ctl.busy ? "확인하는 중…" : "비밀번호 입력 후 Enter"
                            color: "#9AB0C2"; font.family: Theme.font; font.pixelSize: 19 * v.s
                        }
                    }
                }
            }
            Row {
                visible: v.powerOpen
                leftPadding: 30 * v.s; bottomPadding: 16 * v.s; spacing: 12 * v.s
                Btn { s: v.s; primary: false; text: "절전"; onClicked: Quickshell.execDetached(["systemctl", "suspend"]) }
                Btn { s: v.s; primary: false; text: "다시 시작"; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                Btn { s: v.s; primary: false; text: "전원 끄기"; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
            }
            Item {
                width: parent.width; height: 74 * v.s
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 30 * v.s; anchors.top: parent.top
                    spacing: 14 * v.s
                    Btn { s: v.s; primary: false; text: "전원"; onClicked: { v.powerOpen = !v.powerOpen; field.forceActiveFocus() } }
                    Btn { s: v.s; text: v.ctl.busy ? "확인 중" : "접속"; onClicked: v.ctl.submit(field.text) }
                }
            }
        }
    }

    // ---------- story-style dialogue box ----------
    Item {
        visible: v.login
        anchors.bottom: parent.bottom
        width: parent.width; height: 270 * v.s
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "#0006101E" }
                GradientStop { position: 0.38; color: "#D106101E" }
                GradientStop { position: 1; color: "#EB06101E" }
            }
        }
        Row {
            x: 160 * v.s; y: 66 * v.s; spacing: 16 * v.s
            Text { id: speaker; text: Arona.name; color: "white"; font.family: Theme.font; font.pixelSize: 38 * v.s; font.weight: Font.ExtraBold }
            Text { anchors.baseline: speaker.baseline; text: "싯딤의 상자"; color: "#6FC8F2"; font.family: Theme.font; font.pixelSize: 24 * v.s; font.weight: Font.Bold }
        }
        Rectangle {
            x: 160 * v.s; y: 116 * v.s; width: parent.width - 1060 * v.s; height: 2 * v.s
            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#99FFFFFF" } GradientStop { position: 1; color: "#00FFFFFF" } }
        }
        Text {
            x: 160 * v.s; y: 138 * v.s; width: parent.width - 980 * v.s
            text: v.ctl.line.substring(0, v.shown)
            wrapMode: Text.WordWrap; textFormat: Text.PlainText
            color: "white"; font.family: Theme.font; font.pixelSize: 31 * v.s; font.weight: Font.Medium; lineHeight: 1.4
        }
        Text {
            visible: v.shown >= v.ctl.line.length
            x: parent.width - 840 * v.s; y: parent.height - 56 * v.s
            text: "▼"; color: "white"; font.pixelSize: 20 * v.s
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: (270 - 50) * v.s; duration: 500; easing.type: Easing.InOutSine }
                NumberAnimation { to: (270 - 56) * v.s; duration: 500; easing.type: Easing.InOutSine }
            }
        }
    }
}
