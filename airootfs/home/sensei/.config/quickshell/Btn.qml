import QtQuick

// Game-style slanted button: yellow for the main action, grey otherwise.
Item {
    id: b
    property real s: 1
    property string text: ""
    property bool primary: true
    signal clicked()
    implicitWidth: label.implicitWidth + 44 * s
    implicitHeight: 42 * s
    scale: ma.pressed ? 0.95 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }

    SkewRect { anchors.fill: parent; anchors.topMargin: 3 * b.s; radius: 8 * b.s; color: b.primary ? "#C99400" : "#C7D6E2" }
    SkewRect {
        anchors.fill: parent; anchors.bottomMargin: 3 * b.s; radius: 8 * b.s
        color: b.primary ? Theme.halo : "#E6EEF4"
        border.color: "#99FFFFFF"; border.width: 2 * b.s
    }
    Text {
        id: label
        anchors.centerIn: parent; anchors.verticalCenterOffset: -1.5 * b.s
        text: b.text; color: b.primary ? Theme.ink : Theme.inkDim
        font.family: Theme.font; font.pixelSize: 17 * b.s; font.weight: Font.ExtraBold
    }
    MouseArea { id: ma; anchors.fill: parent; onClicked: b.clicked() }
}
