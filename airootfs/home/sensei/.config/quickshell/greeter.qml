// 로그인 화면. greetd 가 greeter 사용자로 띄운다 (/usr/local/bin/shittim-greeter → /etc/greetd/hyprland.lua → 이 파일).
// 잠금화면과 같은 그림(LockView)이지만 여기서는 아직 아무도 로그인하지 않았다: 비밀번호가 맞아야 greetd 가 sensei 의
// 세션을 시작한다. (전에는 비밀번호 없이 자동 로그인한 뒤 잠금화면으로 덮기만 했다.)
// 시험: tools/fake-greetd.py 를 띄우고 GREETD_SOCK=<소켓> quickshell -p greeter.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd
import QtQuick

ShellRoot {
    QtObject {   // LockView 가 Lock.qml 에게 바라는 것과 같은 모양
        id: auth
        property bool locked: true
        property string mood: "smile"
        property string line: Arona.lines[Theme.hour >= 5 && Theme.hour < 11 ? "lock-morning" : Theme.hour >= 11 && Theme.hour < 18 ? "lock-day" : Theme.hour >= 18 && Theme.hour < 23 ? "lock-evening" : "lock-night"]
        property bool busy: false
        property int fails: 0
        property bool talking: false
        onLineChanged: if (talking) Arona.speak(line)   // Lock.qml 과 같게: 대화창이 떠 있으면 바뀐 대사를 말한다
        property string pending: ""
        signal failed()
        function submit(pw) {
            if (busy || pw === "") return
            pending = pw; busy = true
            Greetd.createSession("sensei")
        }
        function done(line, mood) { busy = false; pending = ""; auth.line = line; auth.mood = mood }
    }
    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) { Greetd.respond(responseRequired ? auth.pending : "") }
        function onAuthFailure(message) {
            auth.fails++
            auth.done(Arona.lines[auth.fails >= 3 ? "lock-fail-3" : "lock-fail-" + auth.fails], auth.fails >= 3 ? "angry" : "surprised")
            auth.failed()
        }
        function onError(error) { auth.done(Arona.lines["lock-error"], "surprised") }
        function onReadyToLaunch() {
            // "어서 오세요"는 여기서 말하지 않는다: 0.9초 뒤 이 화면이 끝나면서 끊긴다. 방금 시작한 세션이 말한다 (Lock.qml 의 welcome)
            auth.talking = false; auth.pending = ""; auth.mood = "happy"; auth.line = Arona.lines["lock-ok"]
            launch.start()
        }
    }
    // 로그인 셸로 시작해서 ~/.bash_profile 의 PATH 를 받는다. SHITTIM_GREETED: 방금 비밀번호를 확인했으니 셸이 또 잠그지 않게 (Lock.qml)
    Timer { id: launch; interval: 900; onTriggered: Greetd.launch(["bash", "-lc", "exec start-hyprland"], ["SHITTIM_GREETED=1"], true) }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "#02060C"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shittim-greeter"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            LockView { anchors.fill: parent; ctl: auth; s: win.screen ? win.screen.height / 1200 : 1 }
        }
    }
}
