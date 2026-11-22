import Quickshell
import Quickshell.Io
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
        return Arona.lines[h >= 5 && h < 11 ? "lock-morning" : h >= 11 && h < 18 ? "lock-day" : h >= 18 && h < 23 ? "lock-evening" : "lock-night"]
    }
    property bool talking: false      // 대화창이 떠 있을 때만 말한다 (LockView: 키를 눌러 대화창을 열면 켠다). 잠기자마자 혼자 말하지 않게
    onLineChanged: if (talking) Arona.speak(line)
    function lock() {
        mood = "smile"; fails = 0; busy = false; pending = ""; talking = false
        line = greeting()
        locked = true
    }
    // First start after login: lock at once, before the desktop is ever drawn. (hyprland.lua's "ipc call lock lock"
    // only arrives about a second later, which let the desktop flash before the lock screen.) The mark lives in
    // /run/user/<uid>, so it is gone after a logout or reboot but survives shell reloads.
    FileView { id: bootMark; path: Quickshell.env("XDG_RUNTIME_DIR") + "/shittim-locked-once"; blockLoading: true; printErrors: false }
    Component.onCompleted: {
        // SHITTIM_GREETED: greetd 로그인 화면(greeter.qml)에서 방금 비밀번호를 확인하고 들어온 세션이면 또 잠그지 않는다.
        // (예전 방식 = 자동 로그인인 컴퓨터와 설치 USB 에서는 이 값이 없어서 지금처럼 바로 잠근다.)
        if (!locked && bootMark.text() === "") { bootMark.setText("1"); if (!Quickshell.env("SHITTIM_GREETED")) lock() }
        // after a shell reload while locked, the dialogue would be empty
        if (locked && line === "") line = greeting()
    }
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
                lockRoot.line = Arona.lines["lock-ok"]
                unlockDelay.start()
                return
            }
            lockRoot.fails++
            lockRoot.mood = lockRoot.fails >= 3 ? "angry" : "surprised"
            lockRoot.line = lockRoot.fails === 1 ? Arona.lines["lock-fail-1"]
                     : lockRoot.fails === 2 ? Arona.lines["lock-fail-2"]
                     : Arona.lines["lock-fail-3"]
            lockRoot.failed()
        }
        onError: {
            lockRoot.busy = false
            lockRoot.pending = ""
            lockRoot.line = Arona.lines["lock-error"]
        }
    }
    Timer { id: unlockDelay; interval: 900; onTriggered: lockRoot.locked = false }

    WlSessionLock {
        locked: lockRoot.locked
        WlSessionLockSurface {
            id: surface
            color: "#02060C"
            LockView { anchors.fill: parent; ctl: lockRoot; s: surface.screen ? surface.screen.height / 1200 : 1 }
            Rectangle { anchors.fill: parent; color: "#02070f"; visible: Ui.sleeping }   // 절전 컷씬 뒤 잠들 때까지 잠금화면을 가린다
        }
    }
}
