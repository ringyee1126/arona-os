import QtQuick

// Square top-bar button (notifications, menu) with an optional red count badge.
Item {
    id: b
    property real s: 1
    property string icon: ""
    property int badge: 0
    signal clicked()
    width: 52 * s; height: 52 * s

    Rectangle { anchors.fill: parent; radius: 12 * b.s; color: "#EDFFFFFF" }
    Image {
        anchors.centerIn: parent
        width: 26 * b.s; height: width
        source: Theme.assets + "icons/" + b.icon + ".svg"
        sourceSize.width: width * 2; sourceSize.height: height * 2
    }
    Rectangle {
        visible: b.badge > 0
        width: 22 * b.s; height: width; radius: width / 2
        x: parent.width - width * 0.7; y: -width * 0.3
        color: "#F2506A"; border.color: "white"; border.width: 2 * b.s
        Text { anchors.centerIn: parent; text: b.badge; color: "white"; font.family: Theme.font; font.pixelSize: 12 * b.s; font.weight: Font.Black }
    }
    MouseArea { anchors.fill: parent; onClicked: b.clicked() }
}
