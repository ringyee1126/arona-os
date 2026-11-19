import QtQuick

// Arona (or Plana) standing, animated with her official in-game idle (Spine "Idle_01" + an expression,
// pre-rendered to looping WebP in assets/<who>/). A missing file falls back step by step, so she keeps moving:
// that mood -> the same character's smile -> Arona's smile -> the still art.
Item {
    id: sp
    property string mood: "smile"     // smile | surprised | angry | happy | curious | thinking
    property string who: Arona.who    // arona | plana
    property int fallback: 0
    // 프라나는 표정 파일 이름이 다르다 (assets/plana/ 에 6개: idle happy surprised displeased sparkling serious)
    readonly property var plana: ({ smile: "idle", angry: "displeased", curious: "sparkling", thinking: "serious" })
    onMoodChanged: fallback = 0
    onWhoChanged: fallback = 0

    AnimatedImage {
        id: anim
        anchors.fill: parent
        source: Theme.assets + (sp.fallback < 2 ? sp.who : "arona") + "/" + (sp.fallback === 0 ? (sp.who === "plana" && sp.plana[sp.mood] || sp.mood) : sp.fallback === 1 && sp.who === "plana" ? "idle" : "smile") + ".webp"
        fillMode: Image.PreserveAspectFit
        cache: false                    // ~100 large frames: decode as we go instead of keeping them all in memory
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
