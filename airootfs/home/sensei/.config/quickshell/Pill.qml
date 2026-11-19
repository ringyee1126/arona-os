import QtQuick

// Top-right resource pill (Wi-Fi, volume, battery, clock).
Item {
    id: p
    property real s: 1
    property string icon: ""
    property string text: ""
    property bool dark: false
    implicitWidth: row.implicitWidth + 40 * s
    implicitHeight: 46 * s

    SkewRect { anchors.fill: parent; radius: 8 * p.s; color: p.dark ? Theme.ink : "#EDFFFFFF" }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 9 * p.s
        Image {
            visible: p.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: 22 * p.s; height: width
            source: p.icon ? Theme.assets + "icons/" + p.icon + ".svg" : ""
            sourceSize.width: width * 2; sourceSize.height: height * 2
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: p.text
            color: p.dark ? "white" : Theme.ink
            font.family: Theme.font; font.pixelSize: (p.dark ? 22 : 19) * p.s
            font.weight: Font.Bold; font.italic: p.dark
        }
    }
}
