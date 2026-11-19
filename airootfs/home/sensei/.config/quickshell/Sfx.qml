pragma Singleton
import Quickshell
import QtQuick

// 버튼 효과음 (assets/sfx/*.wav, tools/make-sfx.py 로 만든 것). 설정 → 소리 → 효과음으로 끈다.
// shortcut: 소리마다 pw-play 프로세스를 하나 띄운다. 지연이 거슬리면 qt6-multimedia의 SoundEffect로 바꾼다.
Singleton {
    readonly property string dir: Qt.resolvedUrl("assets/sfx/").toString().replace("file://", "")
    function play(name) {
        if (Arona.settings.sounds) Quickshell.execDetached(["pw-play", "--volume", "0.7", dir + name + ".wav"])
    }
    function tap() { play("tap") }
}
