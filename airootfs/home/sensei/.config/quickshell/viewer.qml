// 문서 보기: 마크다운(.md)을 서식 있게 보여 주는 작은 창. ~/.local/bin/shittim-view <파일> 이 띄운다
// (quickshell -n -p viewer.qml, 설정 창처럼 자기 프로세스). 창 테두리와 제목 표시줄은 hyprbars가 그린다.
import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    FloatingWindow {
        id: win
        readonly property string file: Quickshell.env("SHITTIM_VIEW_FILE") || ""
        readonly property bool md: /\.(md|markdown)$/i.test(file)
        readonly property real s: Theme.scale
        title: file.split("/").pop() + " · 문서 보기"
        implicitWidth: 920 * s; implicitHeight: 800 * s
        color: "white"
        onVisibleChanged: if (!visible) Qt.quit()

        FileView { id: doc; path: win.file; blockLoading: true; watchChanges: true; onFileChanged: reload() }

        Flickable {
            id: flick
            anchors { fill: parent; bottomMargin: bar.height }
            contentHeight: body.height + 72 * win.s
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            focus: true
            Keys.onEscapePressed: Qt.quit()
            Keys.onPressed: e => {
                const page = e.key === Qt.Key_PageDown || e.key === Qt.Key_Space ? 1 : e.key === Qt.Key_PageUp ? -1 : 0
                const d = page ? page * height * 0.9 : e.key === Qt.Key_Down ? 60 : e.key === Qt.Key_Up ? -60 : 0
                if (d) contentY = Math.max(0, Math.min(Math.max(0, contentHeight - height), contentY + d))
            }
            TextEdit {
                id: body
                x: 44 * win.s; y: 36 * win.s; width: flick.width - 88 * win.s
                readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap
                textFormat: win.md ? TextEdit.MarkdownText : TextEdit.PlainText
                text: doc.text()
                color: Theme.ink; selectionColor: Theme.sky; selectedTextColor: "white"
                font.family: Theme.font; font.pixelSize: 17 * win.s
                onLinkActivated: l => Qt.openUrlExternally(l)
                HoverHandler { cursorShape: body.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor }
            }
        }
        Rectangle {   // scroll position
            visible: flick.contentHeight > flick.height
            anchors.right: parent.right; anchors.rightMargin: 4 * win.s
            width: 6 * win.s; radius: 3 * win.s; color: "#662FA8E1"
            y: flick.visibleArea.yPosition * flick.height
            height: Math.max(30 * win.s, flick.visibleArea.heightRatio * flick.height)
        }
        Rectangle {
            id: bar
            anchors.bottom: parent.bottom
            width: parent.width; height: 62 * win.s; color: "#F3F8FB"
            Rectangle { width: parent.width; height: 1; color: "#CBE4F3" }
            Text {
                x: 22 * win.s; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - editBtn.width - 60 * win.s; elide: Text.ElideMiddle
                text: win.file; color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 14 * win.s
            }
            Btn {
                id: editBtn
                anchors.right: parent.right; anchors.rightMargin: 16 * win.s; anchors.verticalCenter: parent.verticalCenter
                s: win.s * 0.85; primary: false; text: "메모장으로 편집"
                onClicked: Quickshell.execDetached(["mousepad", win.file])
            }
        }
    }
}
