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
            // plana.png 은 사용자가 고른 정사각형(500x500) 얼굴 그림이라 그대로 채운다
            x: a.plana ? 0 : -a.width * 0.93
            y: a.plana ? 0 : -a.height * 0.88
            width: a.width * (a.plana ? 1 : 3.04); height: a.plana ? width : width * 1920 / 913
            source: Theme.assets + (a.plana ? "plana.png" : "arona.png"); smooth: true; mipmap: true
        }
    }
    Rectangle { id: mask; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
    MultiEffect { anchors.fill: parent; source: face; maskEnabled: true; maskSource: mask; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0 }
    Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.color: Theme.sky; border.width: 3 * a.s }
}
