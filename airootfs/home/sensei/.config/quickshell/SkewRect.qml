import QtQuick

// A rectangle slanted like the game's buttons and resource pills.
// Put text next to it, not inside it, so the text stays upright.
Rectangle {
    id: r
    transform: Matrix4x4 {
        matrix: Qt.matrix4x4(1, -Theme.skew, 0, Theme.skew * r.height / 2,
                             0, 1, 0, 0,
                             0, 0, 1, 0,
                             0, 0, 0, 1)
    }
}
