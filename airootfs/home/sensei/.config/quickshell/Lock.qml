import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

// Session lock. It doubles as the login screen: the session logs in automatically and locks right away.
// Passwords go straight to PAM (pam/password.conf) and are never stored.
Scope {
    id: lockRoot
    // Survives a shell reload, so editing the config can never unlock a locked session.
    PersistentProperties { id: persist; reloadableId: "shittimLock"; property bool locked: false }
    property alias locked: persist.locked
    property string mood: "smile"     // smile | surprised | angry | happy -> Arona's expression
    property string line: ""          // what Arona says in the dialogue box
    property bool busy: false
    property int fails: 0
    property string pending: ""
    signal failed()

    function greeting() {
        const h = Theme.hour
        const first = h >= 5 && h < 11 ? "좋은 아침이에요, 선생님! 오늘도 시작해 볼까요?"
                    : h >= 11 && h < 18 ? "선생님, 다시 오셨네요! 기다리고 있었어요."
                    : h >= 18 && h < 23 ? "오늘도 수고 많으셨어요, 선생님."
                    : "이렇게 늦은 시간까지… 무리하지 마세요, 선생님."
        return first + "\n싯딤의 상자에 접속하려면 비밀번호를 알려주세요."
    }
    function lock() {
        mood = "smile"; fails = 0; busy = false; pending = ""
        line = greeting()
        locked = true
    }
    // after a shell reload while locked, the dialogue would be empty
    Component.onCompleted: if (locked && line === "") line = greeting()
    function submit(pw) {
        if (busy || pw === "") return
        pending = pw
        busy = true
        pam.start()
    }

    PamContext {
        id: pam
        configDirectory: Qt.resolvedUrl("pam").toString().replace("file://", "")
        config: "password.conf"
        onResponseRequiredChanged: if (responseRequired) respond(lockRoot.pending)
        onCompleted: result => {
            lockRoot.busy = false
            lockRoot.pending = ""
            if (result === PamResult.Success) {
                lockRoot.mood = "happy"
                lockRoot.line = "확인됐어요! 어서 오세요, 선생님!"
                unlockDelay.start()
                return
            }
            lockRoot.fails++
            lockRoot.mood = lockRoot.fails >= 3 ? "angry" : "surprised"
            lockRoot.line = lockRoot.fails === 1 ? "어라? 비밀번호가 틀렸어요, 선생님!\n다시 한 번 입력해 주세요."
                     : lockRoot.fails === 2 ? "또 틀렸어요…\nCaps Lock이 켜져 있지 않은지 확인해 보세요."
                     : "선생님…! 혹시 선생님이 아니신가요?!\n수상해요! 아로나가 지켜보고 있어요!"
            lockRoot.failed()
        }
        onError: {
            lockRoot.busy = false
            lockRoot.pending = ""
            lockRoot.line = "인증 장치에 문제가 생겼어요…\n잠시 후 다시 시도해 주세요."
        }
    }
    Timer { id: unlockDelay; interval: 900; onTriggered: lockRoot.locked = false }

    WlSessionLock {
        locked: lockRoot.locked
        WlSessionLockSurface {
            id: surface
            color: "#02060C"
            LockView { anchors.fill: parent; ctl: lockRoot; s: surface.screen ? surface.screen.height / 1200 : 1 }
        }
    }
}
