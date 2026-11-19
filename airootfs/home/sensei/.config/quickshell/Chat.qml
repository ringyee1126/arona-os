import Quickshell
import Quickshell.Wayland
import QtQuick

// MomoTalk with the desktop Arona (approved mockup: mockups/windows.html ③). Clicking her opens it next to her;
// it talks through Arona.ask (Gemini), and her face on the desktop follows Arona.replyMood.
PanelWindow {
    id: chat
    readonly property real s: screen ? screen.height / 1200 : 1
    visible: Ui.chatOpen
    anchors { top: true; right: true }
    margins { top: 190 * s; right: 640 * s }
    implicitWidth: 560 * s
    implicitHeight: 680 * s
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shittim-chat"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property string me: Arona.settings.userName.trim() || "선생님"
    property string pending: ""          // sent, but not in Arona.history yet (waiting, or it failed)
    readonly property var msgs: {
        const m = [{ me: false, text: "어서 오세요, " + me + "! 오늘은 무엇을 도와드릴까요?" }]
        for (const h of Arona.history)
            m.push({ me: h.role === "user", text: h.role === "user" ? h.text : h.text.replace(/\[\[표정:[^\]]*\]\]/g, "").trim() })
        if (pending) m.push({ me: true, text: pending })
        if (Arona.replying) m.push({ me: false, typing: true, text: "" })
        else if (pending && Arona.replyError) m.push({ me: false, error: true, text: Arona.replyError })
        return m
    }
    onMsgsChanged: Qt.callLater(list.positionViewAtEnd)
    Connections { target: Arona; function onHistoryChanged() { chat.pending = "" } }
    onVisibleChanged: if (visible) input.forceActiveFocus()

    function send() {
        const t = input.text.trim()
        if (!t || Arona.replying) return
        pending = t
        input.text = ""
        Arona.ask(t)
    }

    Rectangle {
        anchors.fill: parent
        radius: 18 * chat.s; color: "#F3F8FB"; clip: true
        border.color: "#33FFFFFF"; border.width: 1

        // ---------- header ----------
        Rectangle {
            id: head
            width: parent.width; height: 64 * chat.s
            topLeftRadius: 18 * chat.s; topRightRadius: 18 * chat.s
            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#FF8FAB" } GradientStop { position: 1; color: "#FFA9BF" } }
            Avatar { id: headAva; s: 42 / 76 * chat.s; x: 18 * chat.s; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.left: headAva.right; anchors.leftMargin: 12 * chat.s; anchors.verticalCenter: parent.verticalCenter
                Text { text: "아로나"; color: "white"; font.family: Theme.font; font.pixelSize: 19 * chat.s; font.weight: Font.Black }
                Text { text: Arona.replying ? "입력 중…" : "MomoTalk · 싯딤의 상자"; color: "#F2FFFFFF"; font.family: Theme.font; font.pixelSize: 13 * chat.s }
            }
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 18 * chat.s; anchors.verticalCenter: parent.verticalCenter
                width: 32 * chat.s; height: width; radius: width / 2
                color: closeMa.containsMouse ? "#66FFFFFF" : "#4DFFFFFF"
                XMark { anchors.centerIn: parent; size: 11 * chat.s; thickness: 2.6 * chat.s }
                MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.chatOpen = false }
            }
        }

        // ---------- messages ----------
        ListView {
            id: list
            anchors { top: head.bottom; bottom: bar.top; left: parent.left; right: parent.right }
            topMargin: 20 * chat.s; bottomMargin: 20 * chat.s
            leftMargin: 18 * chat.s; rightMargin: 18 * chat.s
            spacing: 14 * chat.s
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: chat.msgs
            delegate: Item {
                id: msg
                required property var modelData
                readonly property real maxW: list.width - list.leftMargin - list.rightMargin - 70 * chat.s
                width: list.width - list.leftMargin - list.rightMargin
                height: modelData.me ? mine.height : theirs.height

                // ---- mine: sky bubble on the right
                Rectangle {
                    id: mine
                    visible: msg.modelData.me
                    anchors.right: parent.right
                    width: Math.min(measure.implicitWidth, msg.maxW) + 32 * chat.s
                    height: mineText.contentHeight + 22 * chat.s
                    radius: 14 * chat.s; color: Theme.sky
                    Rectangle { anchors.right: parent.right; anchors.bottom: parent.bottom; width: 14 * chat.s; height: width; color: Theme.sky; radius: 4 * chat.s }
                    TextEdit {
                        id: mineText
                        x: 16 * chat.s; y: 11 * chat.s; width: parent.width - 32 * chat.s
                        text: msg.modelData.text; readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap
                        color: "white"; selectionColor: Theme.skyDeep
                        font.family: Theme.font; font.pixelSize: 17 * chat.s; font.weight: Font.DemiBold
                    }
                }

                // ---- Arona: avatar + name + white bubble on the left
                Item {
                    id: theirs
                    visible: !msg.modelData.me
                    width: parent.width
                    height: Math.max(40 * chat.s, nameTag.height + 4 * chat.s + bubble.height)
                    Avatar { s: 40 / 76 * chat.s }
                    Text {
                        id: nameTag
                        x: 50 * chat.s
                        text: "아로나"; color: Theme.skyDeep
                        font.family: Theme.font; font.pixelSize: 13 * chat.s; font.weight: Font.ExtraBold
                    }
                    Rectangle {
                        id: bubble
                        x: 50 * chat.s; y: nameTag.height + 4 * chat.s
                        width: msg.modelData.typing ? 70 * chat.s : Math.min(measure.implicitWidth, msg.maxW) + 32 * chat.s
                        height: msg.modelData.typing ? 40 * chat.s : theirText.contentHeight + 22 * chat.s
                        radius: 14 * chat.s
                        color: msg.modelData.error ? "#FFF1F4" : "white"
                        border.width: 2 * chat.s; border.color: msg.modelData.error ? "#FFC2CF" : "#CBE4F3"
                        TextEdit {
                            id: theirText
                            visible: !msg.modelData.typing
                            x: 16 * chat.s; y: 11 * chat.s; width: parent.width - 32 * chat.s
                            text: msg.modelData.text; readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap
                            color: msg.modelData.error ? "#C2334D" : Theme.ink; selectionColor: Theme.sky; selectedTextColor: "white"
                            font.family: Theme.font; font.pixelSize: 17 * chat.s
                        }
                        Row {   // typing dots
                            visible: msg.modelData.typing === true
                            anchors.centerIn: parent; spacing: 5 * chat.s
                            Repeater {
                                model: 3
                                Rectangle {
                                    required property int index
                                    width: 8 * chat.s; height: width; radius: width / 2; color: Theme.sky
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite; running: msg.modelData.typing === true
                                        PauseAnimation { duration: index * 160 }
                                        NumberAnimation { from: 0.3; to: 1; duration: 320 }
                                        NumberAnimation { from: 1; to: 0.3; duration: 320 }
                                        PauseAnimation { duration: (2 - index) * 160 }
                                    }
                                }
                            }
                        }
                    }
                }
                // natural (unwrapped) width of the text, to size the bubble
                Text { id: measure; visible: false; text: msg.modelData.text; font: mineText.font }
            }
        }

        // ---------- input ----------
        Rectangle {
            id: bar
            anchors.bottom: parent.bottom
            width: parent.width; height: 76 * chat.s; color: "white"
            bottomLeftRadius: 18 * chat.s; bottomRightRadius: 18 * chat.s
            Rectangle { width: parent.width; height: 1; color: "#CBE4F3" }
            Rectangle {
                x: 14 * chat.s; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 28 * chat.s - sendBtn.width - 10 * chat.s; height: 48 * chat.s
                radius: 10 * chat.s; color: "#F7FBFE"
                border.width: 2 * chat.s; border.color: input.activeFocus ? Theme.sky : "#CBE4F3"
                TextInput {
                    id: input
                    anchors { fill: parent; leftMargin: 16 * chat.s; rightMargin: 16 * chat.s }
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: Theme.ink; selectionColor: Theme.sky; selectedTextColor: "white"
                    font.family: Theme.font; font.pixelSize: 16 * chat.s
                    onAccepted: chat.send()
                    Keys.onEscapePressed: Ui.chatOpen = false
                }
                Text {
                    x: 16 * chat.s; anchors.verticalCenter: parent.verticalCenter
                    visible: !input.text && !input.preeditText
                    text: Arona.ready ? "아로나에게 말 걸기…" : "설정 → 아로나에서 API 키를 넣어 주세요"
                    color: "#9AB0C2"; font.family: Theme.font; font.pixelSize: 16 * chat.s
                }
            }
            Rectangle {
                id: sendBtn
                anchors.right: parent.right; anchors.rightMargin: 14 * chat.s; anchors.verticalCenter: parent.verticalCenter
                width: 48 * chat.s; height: width; radius: 12 * chat.s
                color: Arona.replying ? "#9FD3EE" : sendMa.pressed ? Theme.skyDeep : Theme.sky
                Image {
                    anchors.centerIn: parent; width: 22 * chat.s; height: width
                    source: Theme.assets + "icons/send.svg"; sourceSize.width: width * 2; sourceSize.height: height * 2
                }
                MouseArea { id: sendMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: chat.send() }
            }
        }
    }
}
