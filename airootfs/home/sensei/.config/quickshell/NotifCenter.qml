import Quickshell
import Quickshell.Wayland
import QtQuick

// 알림 모아 보기: 바탕화면 MomoTalk 카드의 분홍 머리를 누르면 열린다 (Ui.notifsOpen). 쌓인 알림 전부를 본문까지 보여 준다.
PanelWindow {
    id: nc
    readonly property real s: screen ? screen.height / 1200 : 1
    visible: Ui.notifsOpen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "#55000000"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shittim-notifs"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    onVisibleChanged: if (visible) keys.forceActiveFocus()
    MouseArea { anchors.fill: parent; onClicked: Ui.notifsOpen = false }
    Item { id: keys; focus: true; Keys.onEscapePressed: Ui.notifsOpen = false }

    Rectangle {
        anchors.centerIn: parent
        width: 720 * nc.s; height: Math.min(nc.height - 240 * nc.s, 64 * nc.s + Math.max(list.contentHeight, 120 * nc.s))
        radius: 18 * nc.s; color: "#FAFFFFFF"; clip: true
        MouseArea { anchors.fill: parent }   // 카드 안을 눌러도 닫히지 않게
        Rectangle {
            id: head
            width: parent.width; height: 64 * nc.s; color: Theme.momo
            Text { x: 24 * nc.s; anchors.verticalCenter: parent.verticalCenter; text: "MomoTalk · 알림 " + Notifs.list.length; color: "white"; font.family: Theme.font; font.pixelSize: 24 * nc.s; font.weight: Font.Black; font.italic: true }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 16 * nc.s; anchors.verticalCenter: parent.verticalCenter; spacing: 10 * nc.s
                Rectangle {
                    visible: Notifs.list.length > 0
                    width: clr.implicitWidth + 28 * nc.s; height: 36 * nc.s; radius: height / 2; color: clrMa.containsMouse ? "#80FFFFFF" : "#4DFFFFFF"
                    Text { id: clr; anchors.centerIn: parent; text: "모두 지우기"; color: "white"; font.family: Theme.font; font.pixelSize: 15 * nc.s; font.weight: Font.Bold }
                    MouseArea { id: clrMa; anchors.fill: parent; hoverEnabled: true; onPressedChanged: if (pressed) Sfx.tap(); onClicked: Notifs.list.slice().forEach(n => n.dismiss()) }
                }
                Rectangle {
                    width: 36 * nc.s; height: width; radius: width / 2; color: xMa.containsMouse ? "#80FFFFFF" : "#4DFFFFFF"
                    XMark { anchors.centerIn: parent; size: 13 * nc.s; color: "white" }
                    MouseArea { id: xMa; anchors.fill: parent; hoverEnabled: true; onPressedChanged: if (pressed) Sfx.tap(); onClicked: Ui.notifsOpen = false }
                }
            }
        }
        ListView {
            id: list
            anchors { top: head.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
            clip: true; boundsBehavior: Flickable.StopAtBounds
            model: Notifs.list.slice().reverse()     // 새 알림이 위
            delegate: Item {
                id: note
                required property var modelData
                width: list.width; height: body.implicitHeight + 28 * nc.s
                Rectangle {
                    x: 24 * nc.s; y: 14 * nc.s
                    width: 50 * nc.s; height: width; radius: width / 2; color: Theme.sky
                    Text { anchors.centerIn: parent; text: (note.modelData.appName || "?").charAt(0).toUpperCase(); color: "white"; font.family: Theme.font; font.pixelSize: 20 * nc.s; font.weight: Font.Black }
                }
                Column {
                    id: body
                    x: 90 * nc.s; y: 14 * nc.s; width: parent.width - 160 * nc.s; spacing: 3 * nc.s
                    Text { width: parent.width; elide: Text.ElideRight; text: note.modelData.appName; visible: text !== ""; color: Theme.momo; font.family: Theme.font; font.pixelSize: 13 * nc.s; font.weight: Font.Bold }
                    Text { width: parent.width; wrapMode: Text.Wrap; text: note.modelData.summary || note.modelData.appName; color: Theme.ink; font.family: Theme.font; font.pixelSize: 18 * nc.s; font.weight: Font.Bold; textFormat: Text.PlainText }
                    Text { width: parent.width; wrapMode: Text.Wrap; text: note.modelData.body; visible: text !== ""; color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 16 * nc.s; textFormat: Text.PlainText; lineHeight: 1.25 }
                }
                Rectangle {   // 이 알림만 지우기
                    anchors.right: parent.right; anchors.rightMargin: 20 * nc.s; y: 20 * nc.s
                    width: 32 * nc.s; height: width; radius: width / 2; color: dMa.containsMouse ? "#FF6B81" : "#E6EEF4"
                    XMark { anchors.centerIn: parent; size: 11 * nc.s; color: dMa.containsMouse ? "white" : Theme.inkDim }
                    MouseArea { id: dMa; anchors.fill: parent; hoverEnabled: true; onPressedChanged: if (pressed) Sfx.tap(); onClicked: note.modelData.dismiss() }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#F0E4E8" }
            }
            Text { visible: Notifs.list.length === 0; anchors.centerIn: parent; text: "새 알림이 없어요"; color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 18 * nc.s }
        }
    }
}
