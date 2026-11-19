import QtQuick
import QtQuick.Effects

// Round portrait of Arona (or Plana), cropped from her full-body art.
Item {
    id: a
    property real s: 1
    readonly property bool plana: Arona.who === "plana"
    implicitWidth: 76 * s; implicitHeight: implicitWidth

    Item {
        id: face
        anchors.fill: parent
        visible: false; clip: true; layer.enabled: true
        Rectangle { anchors.fill: parent; color: Theme.skySoft }
        Image {   // face centre of arona.png (913x1920) is at ~(428, 414)
            // plana.png (640x1300, idle 첫 프레임): 얼굴 중심 ~(360, 320)
            x: -a.width * (a.plana ? 0.94 : 0.93)
            y: -a.height * (a.plana ? 0.78 : 0.88)
            width: a.width * (a.plana ? 2.56 : 3.04); height: width * (a.plana ? 1300 / 640 : 1920 / 913)
            source: Theme.assets + (a.plana ? "plana.png" : "arona.png"); smooth: true; mipmap: true
        }
    }
    Rectangle { id: mask; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
    MultiEffect { anchors.fill: parent; source: face; maskEnabled: true; maskSource: mask; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0 }
    Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.color: Theme.sky; border.width: 3 * a.s }
}
