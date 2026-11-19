import QtQuick

// Arona standing, animated with her official in-game idle (Spine "Idle_01" + an expression, pre-rendered
// to looping WebP in assets/arona/). Falls back to the still art if the WebP plugin is missing.
Item {
    id: sp
    property string mood: "smile"     // smile | surprised | angry | happy | curious | thinking

    AnimatedImage {
        id: anim
        anchors.fill: parent
        source: Theme.assets + "arona/" + sp.mood + ".webp"
        fillMode: Image.PreserveAspectFit
        cache: false                    // 100 large frames: decode as we go instead of keeping them all in memory
        playing: sp.visible
        smooth: true
    }
    Image {
        visible: anim.status === AnimatedImage.Error
        anchors.fill: parent
        source: visible ? Theme.assets + "arona.png" : ""
        fillMode: Image.PreserveAspectFit
        smooth: true; mipmap: true
    }
}
