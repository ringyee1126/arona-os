import QtQuick
import QtQuick.Effects

// Round portrait of Arona, cropped from her full-body art.
Item {
    id: a
    property real s: 1
    implicitWidth: 76 * s; implicitHeight: implicitWidth

    Item {
        id: face
        anchors.fill: parent
        visible: false; clip: true; layer.enabled: true
        Rectangle { anchors.fill: parent; color: Theme.skySoft }
        Image {   // face centre of arona.png (913x1920) is at ~(428, 414)
            x: -a.width * 0.93
            y: -a.height * 0.88
            width: a.width * 3.04; height: width * 1920 / 913
            source: Theme.assets + "arona.png"; smooth: true; mipmap: true
        }
    }
    Rectangle { id: mask; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
    MultiEffect { anchors.fill: parent; source: face; maskEnabled: true; maskSource: mask; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0 }
    Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.color: Theme.sky; border.width: 3 * a.s }
}
