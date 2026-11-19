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
    // 타자 소리: 글자를 직접 칠 때만 (포커스가 있을 때), 조합 확정처럼 한 번에 두 번 바뀌는 건 한 번만
    property real lastKey: 0
    function key(field) {
        const now = Date.now()
        if (!field.activeFocus || now - lastKey < 25) return
        lastKey = now; play("key")
    }
}
