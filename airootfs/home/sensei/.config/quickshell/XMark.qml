import QtQuick

// A crisp ✕ drawn from two bars (the font glyph renders thin and blurry at small sizes).
Item {
    id: mark
    property color color: "white"
    property real size: 12
    property real thickness: 2.4
    width: size; height: size
    Repeater {
        model: [45, -45]
        Rectangle {
            required property var modelData
            anchors.centerIn: parent
            width: mark.size * 1.3; height: mark.thickness; radius: height / 2
            color: mark.color; rotation: modelData; antialiasing: true
        }
    }
}
