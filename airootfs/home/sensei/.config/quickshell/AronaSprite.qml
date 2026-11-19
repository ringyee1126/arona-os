import QtQuick

// Arona (or Plana) standing, animated with her official in-game idle (Spine "Idle_01" + an expression,
// pre-rendered to looping WebP in assets/<who>/). A missing file falls back step by step, so she keeps moving:
// that mood -> the same character's smile -> Arona's smile -> the still art.
Item {
    id: sp
    property string mood: "smile"     // smile | surprised | angry | happy | curious | thinking
    property string who: Arona.who    // arona | plana
    property int fallback: 0
    onMoodChanged: fallback = 0
    onWhoChanged: fallback = 0

    AnimatedImage {
        id: anim
        anchors.fill: parent
        source: Theme.assets + (sp.fallback < 2 ? sp.who : "arona") + "/" + (sp.fallback === 0 ? sp.mood : "smile") + ".webp"
        fillMode: Image.PreserveAspectFit
        cache: false                    // 100 large frames: decode as we go instead of keeping them all in memory
        playing: sp.visible
        smooth: true
        onStatusChanged: if (status === AnimatedImage.Error && sp.fallback < 2) sp.fallback++
    }
    Image {
        visible: anim.status === AnimatedImage.Error
        anchors.fill: parent
        source: visible ? Theme.assets + "arona.png" : ""
        fillMode: Image.PreserveAspectFit
        smooth: true; mipmap: true
    }
}
