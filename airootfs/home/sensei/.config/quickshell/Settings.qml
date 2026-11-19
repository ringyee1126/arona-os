import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import QtQuick

// 설정 · 싯딤의 상자 (approved mockup: mockups/windows.html ①②). One window for Wi-Fi, Bluetooth, sound,
// brightness, Arona, today's tasks and system info. Draws its own Shittim title bar
// (hyprland.lua floats it and keeps the title-bar plugin off it).
FloatingWindow {
    id: win
    readonly property real s: Theme.scale
    title: "설정 · 싯딤의 상자"
    implicitWidth: 1180 * s
    implicitHeight: 860 * s
    color: "#F6FAFD"
    visible: false
    onVisibleChanged: Ui.settingsOpen = visible
    Connections { target: Ui; function onSettingsOpenChanged() { win.visible = Ui.settingsOpen } }

    readonly property var pages: [
        { key: "wifi", name: "Wi-Fi", icon: "wifi" },
        { key: "bluetooth", name: "블루투스", icon: "bluetooth" },
        { key: "sound", name: "소리", icon: "volume" },
        { key: "display", name: "화면 · 밝기", icon: "sun" },
        { key: "arona", name: "아로나", icon: "halo" },
        { key: "tasks", name: "오늘의 업무", icon: "tasks" },
        { key: "about", name: "시스템 정보", icon: "info" }
    ]

    // ---------- small helpers ----------
    function deviceOf(type) { return Networking.devices.values.find(d => d.type === type) || null }
    function level(v) { return v > 1 ? v / 100 : v }       // signal strength, 0..1
    function secure(n) { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe }
    function failText(r) {
        if (r === ConnectionFailReason.NoSecrets || r === ConnectionFailReason.WifiClientFailed || r === ConnectionFailReason.WifiAuthTimeout)
            return "비밀번호가 맞지 않는 것 같아요. 다시 넣어 주세요."
        if (r === ConnectionFailReason.WifiNetworkLost) return "신호가 끊겼어요. 공유기 가까이에서 다시 시도해 주세요."
        return "연결하지 못했어요. 다시 시도해 주세요."
    }
    function nodeName(n) { return n.description || n.nickname || n.name }

    component T: Text {
        color: Theme.ink
        font.family: Theme.font; font.pixelSize: 17 * Theme.scale
    }
    component Head: Item {
        property string title: ""
        property string desc: ""
        width: parent ? parent.width : 0; height: 56 * Theme.scale
        SkewRect { anchors.verticalCenter: parent.verticalCenter; x: 4 * Theme.scale; width: 9 * Theme.scale; height: 32 * Theme.scale; radius: 2 * Theme.scale; color: Theme.sky }
        T { x: 26 * Theme.scale; anchors.verticalCenter: parent.verticalCenter; text: parent.title; font.pixelSize: 32 * Theme.scale; font.weight: Font.Black; font.italic: true }
        T { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: parent.desc; color: Theme.inkDim; font.pixelSize: 15 * Theme.scale }
    }
    component Card: Rectangle {
        default property alias content: body.data
        width: parent ? parent.width : 0
        implicitHeight: body.implicitHeight + 32 * Theme.scale
        radius: 14 * Theme.scale; color: "white"; border.color: "#CBE4F3"; border.width: 1
        Column { id: body; x: 22 * Theme.scale; y: 16 * Theme.scale; width: parent.width - 44 * Theme.scale; spacing: 10 * Theme.scale }
    }
    component Label: T {
        width: 150 * Theme.scale
        font.weight: Font.ExtraBold
    }
    component Sub: T {
        color: Theme.inkDim; font.pixelSize: 14 * Theme.scale
    }
    component Line: Rectangle { width: parent ? parent.width : 0; height: 1; color: "#EDF4F9" }
    component Toggle: Rectangle {
        id: tg
        property bool on: false
        signal toggled()
        width: 54 * Theme.scale; height: 30 * Theme.scale; radius: height / 2
        color: on ? Theme.sky : "#C9D9E5"
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle {
            width: 22 * Theme.scale; height: width; radius: width / 2; color: "white"
            anchors.verticalCenter: parent.verticalCenter
            x: tg.on ? tg.width - width - 4 * Theme.scale : 4 * Theme.scale
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        MouseArea { onPressedChanged: if (pressed) Sfx.tap(); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tg.toggled() }
    }
    component Field: Rectangle {
        id: fd
        property alias text: ti.text
        property alias input: ti
        property string placeholder: ""
        property bool secret: false
        signal accepted()
        implicitWidth: 300 * Theme.scale; implicitHeight: 46 * Theme.scale
        radius: 10 * Theme.scale; color: "#F7FBFE"
        border.width: 2 * Theme.scale; border.color: ti.activeFocus ? Theme.sky : "#CBE4F3"
        TextInput {
            id: ti
            onTextChanged: Sfx.key(ti); onPreeditTextChanged: Sfx.key(ti)
            anchors { fill: parent; leftMargin: 16 * Theme.scale; rightMargin: 16 * Theme.scale }
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            echoMode: fd.secret ? TextInput.Password : TextInput.Normal
            color: Theme.ink; selectionColor: Theme.sky; selectedTextColor: "white"
            font.family: Theme.font; font.pixelSize: 17 * Theme.scale
            onAccepted: fd.accepted()
        }
        T {
            x: 16 * Theme.scale; anchors.verticalCenter: parent.verticalCenter
            visible: !ti.text && !ti.preeditText
            text: fd.placeholder; color: "#9AB0C2"
        }
    }
    component Area: Rectangle {
        property alias text: te.text
        property string placeholder: ""
        implicitHeight: Math.max(84 * Theme.scale, te.contentHeight + 24 * Theme.scale)
        radius: 10 * Theme.scale; color: "#F7FBFE"
        border.width: 2 * Theme.scale; border.color: te.activeFocus ? Theme.sky : "#CBE4F3"
        TextEdit {
            id: te
            onTextChanged: Sfx.key(te); onPreeditTextChanged: Sfx.key(te)
            x: 16 * Theme.scale; y: 12 * Theme.scale; width: parent.width - 32 * Theme.scale
            wrapMode: TextEdit.Wrap
            color: Theme.ink; selectionColor: Theme.sky; selectedTextColor: "white"
            font.family: Theme.font; font.pixelSize: 16 * Theme.scale
        }
        T {
            x: 16 * Theme.scale; y: 12 * Theme.scale; width: parent.width - 32 * Theme.scale
            visible: !te.text && !te.preeditText
            text: parent.placeholder; color: "#9AB0C2"; font.pixelSize: 16 * Theme.scale; wrapMode: Text.Wrap
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onPressed: m => { te.forceActiveFocus(); m.accepted = false } }
    }
    component Slider: Item {
        id: sl
        property real value: 0      // 0..1
        signal moved(real v)
        implicitHeight: 30 * Theme.scale
        readonly property real v: Math.max(0, Math.min(1, value))
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 8 * Theme.scale; radius: height / 2; color: "#DCE8F0"
            Rectangle { width: parent.width * sl.v; height: parent.height; radius: parent.radius; color: Theme.sky }
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: (sl.width - width) * sl.v
            width: 24 * Theme.scale; height: width; radius: width / 2
            color: "white"; border.color: Theme.sky; border.width: 3 * Theme.scale
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            function at(mx) { return Math.max(0, Math.min(1, mx / width)) }
            onPressed: m => sl.moved(at(m.x))
            onPositionChanged: m => { if (pressed) sl.moved(at(m.x)) }
        }
        WheelHandler { onWheel: e => sl.moved(Math.max(0, Math.min(1, sl.value + (e.angleDelta.y > 0 ? 0.05 : -0.05)))) }
    }
    component Bars: Row {
        property real level: 0     // 0..1
        spacing: 3 * Theme.scale
        height: 22 * Theme.scale
        Repeater {
            model: 4
            Rectangle {
                required property int index
                width: 5 * Theme.scale; height: (6 + index * 5.3) * Theme.scale; radius: 2 * Theme.scale
                y: parent.height - height
                color: index < Math.max(1, Math.round(parent.level * 4)) ? Theme.sky : "#CFE0EC"
            }
        }
    }
    component Chip: Rectangle {
        property alias text: chipText.text
        width: chipText.implicitWidth + 28 * Theme.scale; height: 30 * Theme.scale; radius: height / 2
        color: Theme.skySoft
        T { id: chipText; anchors.centerIn: parent; color: Theme.skyDeep; font.pixelSize: 14 * Theme.scale; font.weight: Font.ExtraBold }
    }
    component Dot: Rectangle { width: 10 * Theme.scale; height: width; radius: width / 2; color: "#4CC38A" }

    // ---------- title bar ----------
    Rectangle {
        id: titleBar
        width: parent.width; height: 44 * win.s; color: Theme.ink
        MouseArea { anchors.fill: parent; onPressed: win.startSystemMove() }
        SkewRect { x: 20 * win.s; anchors.verticalCenter: parent.verticalCenter; width: 6 * win.s; height: 20 * win.s; radius: 2 * win.s; color: Theme.sky }
        Row {
            x: 38 * win.s; anchors.verticalCenter: parent.verticalCenter; spacing: 8 * win.s
            T { text: "설정"; color: "white"; font.pixelSize: 16 * win.s; font.weight: Font.ExtraBold }
            T { anchors.baseline: parent.children[0].baseline; text: "싯딤의 상자"; color: "#8FC9EA"; font.pixelSize: 14 * win.s; font.weight: Font.DemiBold }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 10 * win.s; anchors.verticalCenter: parent.verticalCenter
            spacing: 8 * win.s
            Repeater {
                model: [{ c: "#3D5A74", a: "hide" }, { c: Theme.sky, a: "max" }, { c: "#FF6B81", a: "close" }]
                delegate: Rectangle {
                    id: tb
                    required property var modelData
                    width: 30 * win.s; height: width; radius: width / 2; color: modelData.c
                    border.width: tbMa.containsMouse ? 3 * win.s : 0; border.color: Qt.lighter(modelData.c, 1.35)
                    // – □ ✕ drawn as shapes
                    Rectangle { visible: tb.modelData.a === "hide"; anchors.centerIn: parent; width: 12 * win.s; height: 2.6 * win.s; radius: height / 2; color: "white" }
                    Rectangle { visible: tb.modelData.a === "max"; anchors.centerIn: parent; width: 11 * win.s; height: width; radius: 2 * win.s; color: "transparent"; border.color: "white"; border.width: 2.2 * win.s }
                    XMark { visible: tb.modelData.a === "close"; anchors.centerIn: parent; size: 10 * win.s; thickness: 2.6 * win.s }
                    MouseArea {
                        onPressedChanged: if (pressed) Sfx.tap()
                        id: tbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: tb.modelData.a === "max" ? (win.maximized = !win.maximized) : (Ui.settingsOpen = false)
                    }
                }
            }
        }
    }

    // ---------- side nav + page ----------
    Item {
        anchors { fill: parent; topMargin: titleBar.height }
        Keys.onEscapePressed: Ui.settingsOpen = false

        Rectangle {
            id: side
            width: 270 * win.s; height: parent.height
            gradient: Gradient { GradientStop { position: 0; color: "#EAF5FC" } GradientStop { position: 1; color: "#DDEFF9" } }
            Column {
                x: 14 * win.s; y: 22 * win.s; width: parent.width - 28 * win.s; spacing: 4 * win.s
                Item {
                    width: parent.width; height: 80 * win.s
                    Rectangle {
                        id: lv
                        x: 10 * win.s; y: 4 * win.s; width: 52 * win.s; height: width; radius: width / 2
                        color: Theme.ink; border.color: "white"; border.width: 3 * win.s
                        T { anchors.centerIn: parent; text: "D+" + Theme.dayCount; color: "white"; font.pixelSize: 16 * win.s; font.weight: Font.Black; font.italic: true }
                    }
                    Column {
                        anchors.left: lv.right; anchors.leftMargin: 12 * win.s; anchors.verticalCenter: lv.verticalCenter
                        T { text: Arona.settings.userName || "선생님"; font.pixelSize: 18 * win.s; font.weight: Font.Bold }
                        Sub { text: "shittim · ARONA OS"; font.pixelSize: 13 * win.s }
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#CBE4F3" }
                }
                Item { width: 1; height: 8 * win.s }
                Repeater {
                    model: win.pages
                    delegate: Item {
                        id: nav
                        required property var modelData
                        readonly property bool on: Ui.settingsPage === modelData.key
                        width: parent.width; height: 52 * win.s
                        Rectangle { anchors.fill: parent; radius: 10 * win.s; color: nav.on ? "white" : navMa.containsMouse ? "#99FFFFFF" : "transparent" }
                        SkewRect { visible: nav.on; x: -2 * win.s; y: 12 * win.s; width: 6 * win.s; height: 28 * win.s; radius: 2 * win.s; color: Theme.sky }
                        Image {
                            x: 18 * win.s; anchors.verticalCenter: parent.verticalCenter
                            width: 22 * win.s; height: width
                            source: Theme.assets + "icons/" + nav.modelData.icon + ".svg"
                            sourceSize.width: width * 2; sourceSize.height: height * 2
                        }
                        T {
                            x: 54 * win.s; anchors.verticalCenter: parent.verticalCenter
                            text: nav.modelData.name; color: nav.on ? Theme.ink : Theme.inkDim; font.weight: Font.Bold
                        }
                        MouseArea { onPressedChanged: if (pressed) Sfx.tap(); id: navMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.settingsPage = nav.modelData.key }
                    }
                }
            }
        }

        Flickable {
            id: flick
            anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom }
            clip: true
            contentHeight: page.height + 60 * win.s
            boundsBehavior: Flickable.StopAtBounds
            Loader {
                id: page
                x: 40 * win.s; y: 28 * win.s; width: flick.width - 80 * win.s
                active: win.visible
                sourceComponent: ({ wifi: wifiPage, bluetooth: btPage, sound: soundPage, display: displayPage,
                                    arona: aronaPage, tasks: tasksPage, about: aboutPage })[Ui.settingsPage] || wifiPage
                onLoaded: flick.contentY = 0
            }
        }
    }

    // =====================================================================================
    // Wi-Fi (Quickshell.Networking -> NetworkManager over D-Bus; passwords never touch a command line)
    Component {
        id: wifiPage
        Column {
            id: wp
            spacing: 16 * win.s
            readonly property var dev: win.deviceOf(DeviceType.Wifi)
            readonly property var wired: win.deviceOf(DeviceType.Wired)
            property var current: null     // connected network
            property var others: []        // the rest, strongest first
            property string netsKey: ""
            property string open: ""       // the network whose password row is showing
            property string error: ""

            // The list is only ever changed here, from a timer or Qt.callLater - never inside a network's own signal
            // (rebuilding rows while NetworkManager is mid-update crashed the shell on real Wi-Fi). It only
            // re-sorts when networks come or go, and not while a password is being typed.
            function refresh() {
                if (open !== "") return
                const l = dev ? dev.networks.values.filter(n => n && n.name).sort((a, b) => b.signalStrength - a.signalStrength) : []
                const cur = l.find(n => n.connected) || null
                const rest = l.filter(n => !n.connected)
                const k = (cur ? cur.name : "") + "|" + rest.map(n => n.name).join("|")
                if (k !== netsKey) { netsKey = k; current = cur; others = rest }
            }
            Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: wp.refresh() }
            ScriptModel { id: othersModel; values: wp.others }
            Binding { when: wp.dev !== null; target: wp.dev; property: "scannerEnabled"; value: true }

            Head { title: "Wi-Fi"; desc: "무선 네트워크에 연결합니다" }
            Card {
                visible: wp.dev === null
                T { text: "Wi-Fi 장치를 찾지 못했어요."; font.weight: Font.Bold }
                Sub { text: wp.wired && wp.wired.connected ? "지금은 유선 네트워크로 연결돼 있어요." : "무선 랜 장치가 꺼져 있거나 없는 것 같아요." }
            }
            Card {
                visible: wp.dev !== null
                Item {
                    width: parent.width; height: 40 * win.s
                    T { anchors.verticalCenter: parent.verticalCenter; text: "Wi-Fi 사용"; font.pixelSize: 18 * win.s; font.weight: Font.Bold }
                    Toggle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; on: Networking.wifiEnabled; onToggled: Networking.wifiEnabled = !Networking.wifiEnabled }
                }
                Sub { visible: !Networking.wifiHardwareEnabled; text: "노트북의 무선 스위치(비행기 모드)가 꺼져 있어요." }
            }
            Card {
                visible: wp.current !== null
                border.color: Theme.sky
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#E6F5FD" } GradientStop { position: 1; color: "white" } }
                Item {
                    width: parent.width; height: 60 * win.s
                    Bars { anchors.verticalCenter: parent.verticalCenter; level: wp.current ? win.level(wp.current.signalStrength) : 0 }
                    Column {
                        x: 40 * win.s; anchors.verticalCenter: parent.verticalCenter
                        T { text: wp.current ? wp.current.name : ""; font.pixelSize: 18 * win.s; font.weight: Font.Bold }
                        Row {
                            spacing: 6 * win.s
                            Dot { anchors.verticalCenter: parent.verticalCenter }
                            Sub { text: "연결됨 · " + (wp.current && win.secure(wp.current) ? "보안" : "공개 네트워크") }
                        }
                    }
                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 12 * win.s
                        Chip { anchors.verticalCenter: parent.verticalCenter; text: "자동 연결" }
                        Btn { s: win.s; primary: false; text: "연결 끊기"; onClicked: wp.current.disconnect() }
                    }
                }
            }
            T {
                visible: wp.dev !== null && Networking.wifiEnabled
                text: "사용 가능한 네트워크"; color: Theme.inkDim; font.pixelSize: 15 * win.s; font.weight: Font.ExtraBold
            }
            Card {
                visible: wp.dev !== null && Networking.wifiEnabled
                Sub { visible: wp.others.length === 0; text: "주변 네트워크를 찾고 있어요…"; topPadding: 6 * win.s; bottomPadding: 6 * win.s }
                Repeater {
                    model: othersModel
                    delegate: Column {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property var net: modelData
                        readonly property bool busy: net.stateChanging || net.state === ConnectionState.Connecting
                        readonly property bool asking: wp.open === net.name
                        width: parent.width
                        spacing: 10 * win.s
                        function join() { if (pw.text) { wp.error = ""; row.net.connectWithPsk(pw.text) } }
                        Connections {
                            target: row.net
                            function onConnectionFailed(reason) { wp.error = win.failText(reason); wp.open = row.net.name; pw.input.forceActiveFocus() }
                            function onConnectedChanged() { if (row.net.connected) { wp.open = ""; wp.error = "" } Qt.callLater(wp.refresh) }
                        }

                        Line { visible: row.index > 0 }
                        Item {
                            width: parent.width; height: 50 * win.s
                            Bars { anchors.verticalCenter: parent.verticalCenter; level: win.level(row.net.signalStrength) }
                            Column {
                                x: 40 * win.s; anchors.verticalCenter: parent.verticalCenter
                                T { text: row.net.name; font.weight: Font.Bold }
                                Sub {
                                    text: row.busy ? "연결하는 중…"
                                        : (row.net.known ? "저장됨 · " : "") + (win.secure(row.net) ? (row.asking ? "보안 · 비밀번호를 넣어 주세요" : "보안") : "공개 네트워크")
                                }
                            }
                            Image {
                                visible: win.secure(row.net)
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                width: 20 * win.s; height: width; opacity: 0.7
                                source: Theme.assets + "icons/lock.svg"; sourceSize.width: width * 2; sourceSize.height: height * 2
                            }
                            MouseArea {
                                onPressedChanged: if (pressed) Sfx.tap()
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    wp.error = ""
                                    if (!win.secure(row.net) || row.net.known) row.net.connect()
                                    else { wp.open = row.asking ? "" : row.net.name; if (wp.open) pw.input.forceActiveFocus() }
                                }
                            }
                        }
                        Item {
                            visible: row.asking
                            width: parent.width; height: 46 * win.s
                            Field { id: pw; x: 40 * win.s; width: parent.width - x - joinBtn.width - 14 * win.s; height: 46 * win.s; secret: true; placeholder: "비밀번호"; onAccepted: row.join() }
                            Btn { id: joinBtn; anchors.right: parent.right; s: win.s; text: "연결"; onClicked: row.join(); anchors.verticalCenter: pw.verticalCenter }
                        }
                        T { visible: row.asking && wp.error !== ""; x: 40 * win.s; text: wp.error; color: "#E0475F"; font.pixelSize: 14 * win.s }
                        Item { visible: row.asking; width: 1; height: 2 * win.s }
                    }
                }
            }
        }
    }

    // =====================================================================================
    // Bluetooth (Quickshell.Bluetooth -> BlueZ)
    Component {
        id: btPage
        Column {
            id: bp
            spacing: 16 * win.s
            readonly property var ad: Bluetooth.defaultAdapter
            property var devs: []
            property string devsKey: ""
            function refresh() {
                const l = ad ? ad.devices.values.filter(d => d.paired || d.connected || d.deviceName)
                                 .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)) : []
                const k = l.map(d => d.address + d.connected + d.paired).join("|")
                if (k !== devsKey) { devsKey = k; devs = l }
            }
            Timer { interval: 1500; running: true; repeat: true; triggeredOnStart: true; onTriggered: bp.refresh() }
            ScriptModel { id: devsModel; values: bp.devs }
            Component.onDestruction: if (ad && ad.discovering) ad.discovering = false

            Head { title: "블루투스"; desc: "이어폰 · 마우스 · 키보드를 연결합니다" }
            Card {
                visible: bp.ad === null
                T { text: "블루투스 장치를 찾지 못했어요."; font.weight: Font.Bold }
                Sub { text: "이 컴퓨터에 블루투스가 없거나 꺼져 있는 것 같아요." }
            }
            Card {
                visible: bp.ad !== null
                Item {
                    width: parent.width; height: 40 * win.s
                    T { anchors.verticalCenter: parent.verticalCenter; text: "블루투스 사용"; font.pixelSize: 18 * win.s; font.weight: Font.Bold }
                    Toggle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; on: bp.ad ? bp.ad.enabled : false; onToggled: bp.ad.enabled = !bp.ad.enabled }
                }
            }
            Item {
                visible: bp.ad !== null && bp.ad.enabled
                width: parent.width; height: findBtn.height
                T { anchors.verticalCenter: parent.verticalCenter; text: "기기"; color: Theme.inkDim; font.pixelSize: 15 * win.s; font.weight: Font.ExtraBold }
                Btn {
                    id: findBtn
                    anchors.right: parent.right; s: win.s
                    primary: !(bp.ad && bp.ad.discovering)
                    text: bp.ad && bp.ad.discovering ? "찾는 중… (멈추기)" : "기기 찾기"
                    onClicked: bp.ad.discovering = !bp.ad.discovering
                }
            }
            Card {
                visible: bp.ad !== null && bp.ad.enabled
                Sub { visible: bp.devs.length === 0; text: "‘기기 찾기’를 누르고, 이어폰이나 마우스를 연결 대기 상태로 만들어 주세요."; topPadding: 6 * win.s; bottomPadding: 6 * win.s }
                Repeater {
                    model: devsModel
                    delegate: Column {
                        id: bd
                        required property var modelData
                        required property int index
                        readonly property var d: modelData
                        readonly property bool busy: d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting
                        width: parent.width
                        Connections { target: bd.d; function onPairedChanged() { if (bd.d.paired && !bd.d.connected) bd.d.connect() } }
                        Line { visible: bd.index > 0 }
                        Item {
                            width: parent.width; height: 62 * win.s
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                T { text: bd.d.name; font.weight: Font.Bold }
                                Row {
                                    spacing: 6 * win.s
                                    Dot { visible: bd.d.connected; anchors.verticalCenter: parent.verticalCenter }
                                    Sub {
                                        text: bd.d.pairing ? "페어링하는 중…" : bd.busy ? "연결하는 중…"
                                            : bd.d.connected ? "연결됨" + (bd.d.batteryAvailable ? " · 배터리 " + Math.round(bd.d.battery > 1 ? bd.d.battery : bd.d.battery * 100) + "%" : "")
                                            : bd.d.paired ? "저장된 기기" : "새 기기"
                                    }
                                }
                            }
                            Row {
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 14 * win.s
                                T {
                                    visible: bd.d.paired && !bd.d.connected
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "삭제"; color: Theme.inkDim; font.pixelSize: 14 * win.s; font.underline: forgetMa.containsMouse
                                    MouseArea { onPressedChanged: if (pressed) Sfx.tap(); id: forgetMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bd.d.forget() }
                                }
                                Btn {
                                    s: win.s
                                    primary: !bd.d.connected
                                    text: bd.d.connected ? "연결 끊기" : "연결"
                                    onClicked: {
                                        if (bd.busy) return
                                        if (bd.d.connected) bd.d.disconnect()
                                        else if (bd.d.paired) bd.d.connect()
                                        else { bd.d.trusted = true; bd.d.pair() }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Item {
                visible: bp.ad !== null
                width: parent.width; height: moreBtn.height
                Sub { anchors.verticalCenter: parent.verticalCenter; text: "PIN 번호를 입력해야 하는 기기는 고급 설정에서 연결해 주세요." }
                Btn { id: moreBtn; anchors.right: parent.right; s: win.s; primary: false; text: "고급 설정"; onClicked: Quickshell.execDetached(["blueman-manager"]) }
            }
        }
    }

    // =====================================================================================
    // Sound (Quickshell.Services.Pipewire)
    Component {
        id: soundPage
        Column {
            id: sp
            spacing: 16 * win.s
            readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
            readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)
            PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

            Head { title: "소리"; desc: "스피커 · 마이크와 음량을 고릅니다" }
            Repeater {
                model: [
                    { name: "스피커", node: Pipewire.defaultAudioSink, list: sp.sinks, out: true },
                    { name: "마이크", node: Pipewire.defaultAudioSource, list: sp.sources, out: false }
                ]
                delegate: Card {
                    id: dev
                    required property var modelData
                    readonly property var node: modelData.node
                    readonly property bool ok: node !== null && node.audio !== null
                    Item {
                        width: parent.width; height: 48 * win.s
                        Label { anchors.verticalCenter: parent.verticalCenter; width: 110 * win.s; text: dev.modelData.name; font.pixelSize: 18 * win.s }
                        Slider {
                            x: 120 * win.s; anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - x - 200 * win.s
                            enabled: dev.ok
                            value: dev.ok ? dev.node.audio.volume : 0
                            onMoved: v => { dev.node.audio.volume = v; if (v > 0) dev.node.audio.muted = false }
                        }
                        T {
                            anchors.right: muteRow.left; anchors.rightMargin: 18 * win.s; anchors.verticalCenter: parent.verticalCenter
                            text: dev.ok ? Math.round(dev.node.audio.volume * 100) + "%" : "–"; font.weight: Font.Bold
                        }
                        Row {
                            id: muteRow
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 8 * win.s
                            Sub { anchors.verticalCenter: parent.verticalCenter; text: "켜기" }
                            Toggle { on: dev.ok && !dev.node.audio.muted; onToggled: if (dev.ok) dev.node.audio.muted = !dev.node.audio.muted }
                        }
                    }
                    Sub { visible: !dev.ok; text: dev.modelData.out ? "소리를 낼 장치가 없어요." : "마이크가 없어요." }
                    Repeater {
                        model: dev.modelData.list.length > 1 ? dev.modelData.list : []
                        delegate: Item {
                            id: opt
                            required property var modelData
                            readonly property bool on: dev.node === modelData
                            width: parent.width; height: 44 * win.s
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20 * win.s; height: width; radius: width / 2
                                color: "white"; border.color: opt.on ? Theme.sky : "#CBE4F3"; border.width: 2 * win.s
                                Rectangle { anchors.centerIn: parent; visible: opt.on; width: 10 * win.s; height: width; radius: width / 2; color: Theme.sky }
                            }
                            T { x: 34 * win.s; anchors.verticalCenter: parent.verticalCenter; width: parent.width - x; elide: Text.ElideRight; text: win.nodeName(opt.modelData); font.weight: opt.on ? Font.Bold : Font.Normal }
                            MouseArea {
                                onPressedChanged: if (pressed) Sfx.tap()
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: dev.modelData.out ? (Pipewire.preferredDefaultAudioSink = opt.modelData) : (Pipewire.preferredDefaultAudioSource = opt.modelData)
                            }
                        }
                    }
                    Sub { visible: dev.ok && dev.modelData.list.length <= 1; text: dev.ok ? win.nodeName(dev.node) : "" }
                }
            }
            Card {
                Item {
                    width: parent.width; height: 40 * win.s
                    T { anchors.verticalCenter: parent.verticalCenter; text: "버튼 효과음"; font.pixelSize: 18 * win.s; font.weight: Font.Bold }
                    Toggle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; on: Arona.settings.sounds; onToggled: Arona.settings.sounds = !Arona.settings.sounds }
                }
            }
            Card {
                Item {
                    width: parent.width; height: 40 * win.s
                    T { anchors.verticalCenter: parent.verticalCenter; text: "아로나 목소리"; font.pixelSize: 18 * win.s; font.weight: Font.Bold }
                    Toggle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; on: Arona.settings.voice; onToggled: Arona.settings.voice = !Arona.settings.voice }
                }
                Sub { text: "인사, 쓰다듬기처럼 정해진 대사를 녹음된 목소리로 들려줘요." }
            }
            Item {
                width: parent.width; height: mixBtn.height
                Sub { anchors.verticalCenter: parent.verticalCenter; text: "앱마다 음량을 따로 맞추려면 앱별 음량을 여세요." }
                Btn { id: mixBtn; anchors.right: parent.right; s: win.s; primary: false; text: "앱별 음량"; onClicked: Quickshell.execDetached(["pavucontrol"]) }
            }
        }
    }

    // =====================================================================================
    // Display: backlight via brightnessctl (works through logind, no root needed)
    Component {
        id: displayPage
        Column {
            id: dp
            spacing: 16 * win.s
            property int pct: -1        // -1 = no backlight (external monitor, VM)
            Process {
                running: true
                command: ["brightnessctl", "-m", "-c", "backlight"]
                stdout: StdioCollector { onStreamFinished: { const f = text.trim().split(","); dp.pct = f.length >= 4 ? parseInt(f[3]) : -1 } }
            }
            Timer { id: apply; interval: 60; onTriggered: Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.max(1, dp.pct) + "%"]) }

            Head { title: "화면 · 밝기"; desc: "화면 밝기와 정보를 봅니다" }
            Card {
                Item {
                    width: parent.width; height: 48 * win.s
                    Label { anchors.verticalCenter: parent.verticalCenter; width: 110 * win.s; text: "밝기"; font.pixelSize: 18 * win.s }
                    Slider {
                        visible: dp.pct >= 0
                        x: 120 * win.s; anchors.verticalCenter: parent.verticalCenter; width: parent.width - x - 90 * win.s
                        value: dp.pct / 100
                        onMoved: v => { dp.pct = Math.max(1, Math.round(v * 100)); apply.restart() }
                    }
                    T { visible: dp.pct >= 0; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: dp.pct + "%"; font.weight: Font.Bold }
                    Sub { visible: dp.pct < 0; x: 120 * win.s; anchors.verticalCenter: parent.verticalCenter; text: "이 화면은 밝기 조절을 지원하지 않아요." }
                }
            }
            Card {
                Label { text: "화면"; font.pixelSize: 18 * win.s }
                Repeater {
                    model: Quickshell.screens
                    delegate: Row {
                        required property var modelData
                        spacing: 10 * win.s
                        T { text: modelData.name; font.weight: Font.Bold }
                        Sub { anchors.verticalCenter: parent.verticalCenter; text: (modelData.model ? modelData.model + " · " : "") + modelData.width + " × " + modelData.height }
                    }
                }
            }
            Card {
                Label { text: "배경"; font.pixelSize: 18 * win.s }
                Sub { text: "시간에 따라 아로나의 방이 낮 · 밤으로 바뀌어요. (지금은 " + (Theme.day ? "낮" : "밤") + ")" }
            }
        }
    }

    // =====================================================================================
    // Arona (ARONA 1.0's settings, saved by Arona.qml in ~/.config/shittim/arona.json)
    Component {
        id: aronaPage
        Column {
            id: ap
            spacing: 16 * win.s
            property string model: Arona.settings.model
            property string persona: Arona.settings.persona
            property bool picking: false
            property string chk: ""          // "" | "busy" | "ok" | error message
            property string toast: ""
            readonly property var models: [
                // "-latest" 별칭만 쓴다: 번호가 붙은 모델(2.5 등)은 구글이 종료하면 404가 난다
                { id: "gemini-flash-latest", label: "Gemini Flash Latest — 최신 Flash 자동 추적 (추천)" },
                { id: "gemini-flash-lite-latest", label: "Gemini Flash-Lite Latest — 더 가볍고 빠름, 덜 붐빔" },
                { id: "gemini-pro-latest", label: "Gemini Pro Latest — 더 똑똑하지만 느리고 무료 한도가 적음" }
            ]
            function modelLabel(id) { const m = models.find(x => x.id === id); return m ? m.label : id }
            function say(t) { toast = t; toastTimer.restart() }
            function save() {
                Arona.settings.apiKey = keyField.text.trim()
                Arona.settings.model = model
                Arona.settings.userName = nameField.text.trim() || "선생님"
                Arona.settings.persona = persona
                Arona.settings.customPersona = customArea.text
                Arona.settings.memoryNotes = notesArea.text
                say("저장했어요!")
            }
            Timer { id: toastTimer; interval: 2500; onTriggered: ap.toast = "" }

            Head { title: "아로나"; desc: "바탕화면 아로나와의 대화 설정" }
            Card {
                border.color: Theme.sky
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#E6F5FD" } GradientStop { position: 1; color: "white" } }
                Item {
                    width: parent.width; height: 80 * win.s
                    Avatar { id: ava; s: win.s * 0.95; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.left: ava.right; anchors.leftMargin: 18 * win.s; anchors.verticalCenter: parent.verticalCenter
                        spacing: 4 * win.s
                        T {
                            text: "아로나 · " + (ap.chk === "ok" ? "연결됨" : !Arona.ready ? "API 키가 필요해요" : "대기 중")
                            font.pixelSize: 20 * win.s; font.weight: Font.Bold
                        }
                        Row {
                            spacing: 6 * win.s
                            Dot {
                                anchors.verticalCenter: parent.verticalCenter
                                color: ap.chk === "ok" ? "#4CC38A" : ap.chk && ap.chk !== "busy" ? "#E0475F" : Theme.halo
                            }
                            Sub {
                                font.pixelSize: 15 * win.s
                                text: ap.chk === "busy" ? "연결을 확인하는 중…"
                                    : ap.chk === "ok" ? "Gemini 연결 확인 완료 · " + ap.model
                                    : ap.chk ? ap.chk.split("\n")[0]
                                    : Arona.ready ? "키가 저장돼 있어요 · " + Arona.settings.model
                                    : "아래에 Gemini API 키를 넣으면 대화할 수 있어요."
                            }
                        }
                    }
                }
            }
            Card {
                Item {
                    width: parent.width; height: 52 * win.s
                    Label { anchors.verticalCenter: parent.verticalCenter; text: "Gemini API 키" }
                    Field {
                        id: keyField
                        x: 166 * win.s; anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x - checkBtn.width - 14 * win.s
                        secret: true; placeholder: "AIza…"; text: Arona.settings.apiKey
                    }
                    Btn {
                        id: checkBtn
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        s: win.s; primary: false; text: "연결 확인"
                        onClicked: {
                            if (!keyField.text.trim()) { ap.chk = "API 키를 먼저 넣어 주세요."; return }
                            ap.chk = "busy"
                            Arona.check(keyField.text.trim(), ap.model, (ok, msg) => ap.chk = ok ? "ok" : msg)
                        }
                    }
                }
                Sub { x: 166 * win.s; text: "aistudio.google.com 에서 무료로 받을 수 있어요. 이 컴퓨터 안에만 저장돼요." }
                Item { width: 1; height: 2 * win.s }
                Item {
                    width: parent.width; height: 52 * win.s
                    Label { anchors.verticalCenter: parent.verticalCenter; text: "모델" }
                    Rectangle {
                        x: 166 * win.s; anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x; height: 46 * win.s; radius: 10 * win.s
                        color: "#F7FBFE"; border.width: 2 * win.s; border.color: ap.picking ? Theme.sky : "#CBE4F3"
                        T { x: 16 * win.s; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60 * win.s; elide: Text.ElideRight; text: ap.modelLabel(ap.model) }
                        T { anchors.right: parent.right; anchors.rightMargin: 16 * win.s; anchors.verticalCenter: parent.verticalCenter; text: ap.picking ? "▴" : "▾"; color: Theme.sky }
                        MouseArea { onPressedChanged: if (pressed) Sfx.tap(); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ap.picking = !ap.picking }
                    }
                }
                Column {
                    visible: ap.picking
                    x: 166 * win.s; width: parent.width - x
                    Repeater {
                        model: ap.models
                        delegate: Rectangle {
                            id: mo
                            required property var modelData
                            width: parent.width; height: 42 * win.s; radius: 8 * win.s
                            color: moMa.containsMouse ? Theme.skySoft : "transparent"
                            T {
                                x: 16 * win.s; anchors.verticalCenter: parent.verticalCenter
                                text: mo.modelData.label; font.pixelSize: 16 * win.s
                                font.weight: ap.model === mo.modelData.id ? Font.Bold : Font.Normal
                                color: ap.model === mo.modelData.id ? Theme.skyDeep : Theme.ink
                            }
                            MouseArea { onPressedChanged: if (pressed) Sfx.tap(); id: moMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { ap.model = mo.modelData.id; ap.picking = false; ap.chk = "" } }
                        }
                    }
                }
                Item {
                    width: parent.width; height: 52 * win.s
                    Label { anchors.verticalCenter: parent.verticalCenter; text: "나를 부르는 호칭" }
                    Field { id: nameField; x: 166 * win.s; anchors.verticalCenter: parent.verticalCenter; width: 260 * win.s; placeholder: "선생님"; text: Arona.settings.userName }
                }
            }
            Card {
                Label { text: "성격"; bottomPadding: 4 * win.s }
                Grid {
                    id: grid
                    width: parent.width; columns: 3; spacing: 12 * win.s
                    Repeater {
                        model: Arona.personaKeys
                        delegate: Rectangle {
                            id: pc
                            required property string modelData
                            readonly property bool on: ap.persona === modelData
                            width: (grid.width - 24 * win.s) / 3; height: 72 * win.s; radius: 12 * win.s
                            color: on ? "#EEF8FE" : "white"; border.width: 2 * win.s; border.color: on ? Theme.sky : "#CBE4F3"
                            Column {
                                x: 16 * win.s; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 32 * win.s
                                T { text: Arona.personas[pc.modelData].label; font.weight: Font.Bold }
                                Sub { width: parent.width; elide: Text.ElideRight; text: Arona.personas[pc.modelData].desc; font.pixelSize: 13 * win.s }
                            }
                            MouseArea { onPressedChanged: if (pressed) Sfx.tap(); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ap.persona = pc.modelData }
                        }
                    }
                }
                Item { width: 1; height: 6 * win.s }
                Item {
                    visible: ap.persona === "custom"
                    width: parent.width; height: customArea.height
                    Label { y: 12 * win.s; text: "커스텀 성격" }
                    Area {
                        id: customArea
                        x: 166 * win.s; width: parent.width - x
                        placeholder: "아로나가 어떤 성격으로 말할지 직접 적어 주세요. 적은 내용이 그대로 시스템 프롬프트가 돼요."
                        text: Arona.settings.customPersona
                    }
                }
                Item {
                    width: parent.width; height: notesArea.height
                    Label { y: 12 * win.s; text: "기억할 것" }
                    Area {
                        id: notesArea
                        x: 166 * win.s; width: parent.width - x
                        placeholder: "예: C#이랑 C++ 공부 중. 단 걸 좋아함. 밤 12시 넘으면 자라고 말해 줘."
                        text: Arona.settings.memoryNotes
                    }
                }
                Item {
                    width: parent.width; height: saveBtn.height + 8 * win.s
                    Sub { anchors.verticalCenter: btnRow.verticalCenter; text: ap.toast; color: Theme.skyDeep; font.weight: Font.Bold }
                    Row {
                        id: btnRow
                        anchors.right: parent.right; anchors.bottom: parent.bottom; spacing: 12 * win.s
                        Btn { s: win.s; primary: false; text: "대화 기록 지우기"; onClicked: { Arona.clearChat(); ap.say("대화 기록을 지웠어요.") } }
                        Btn { id: saveBtn; s: win.s; text: "저장"; onClicked: ap.save() }
                    }
                }
            }
        }
    }

    // =====================================================================================
    // Today's tasks (Tasks.qml, shown on the desktop card)
    Component {
        id: tasksPage
        Column {
            id: tp
            spacing: 16 * win.s
            Head { title: "오늘의 업무"; desc: "바탕화면의 할 일 목록을 고칩니다" }
            Card {
                Sub { visible: Tasks.list.length === 0; text: "아직 할 일이 없어요. 아래에서 추가해 보세요!"; topPadding: 6 * win.s; bottomPadding: 6 * win.s }
                Repeater {
                    model: Tasks.list
                    delegate: Column {
                        id: task
                        required property var modelData
                        required property int index
                        width: parent.width
                        Line { visible: task.index > 0 }
                        Item {
                            width: parent.width; height: 50 * win.s
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24 * win.s; height: width; radius: 6 * win.s
                                color: task.modelData.done ? Theme.sky : "transparent"
                                border.color: Theme.sky; border.width: 2 * win.s
                                T { anchors.centerIn: parent; visible: task.modelData.done; text: "✓"; color: "white"; font.pixelSize: 15 * win.s; font.weight: Font.Black }
                            }
                            T {
                                x: 40 * win.s; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 90 * win.s; elide: Text.ElideRight
                                text: task.modelData.text; font.strikeout: task.modelData.done
                                color: task.modelData.done ? "#9AB0C2" : Theme.ink; font.weight: Font.DemiBold
                            }
                            MouseArea { onPressedChanged: if (pressed) Sfx.tap(); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Tasks.toggle(task.index) }
                            Rectangle {
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                width: 30 * win.s; height: width; radius: width / 2
                                color: delMa.containsMouse ? "#FFE3E8" : "transparent"
                                XMark { anchors.centerIn: parent; size: 10 * win.s; thickness: 2.2 * win.s; color: delMa.containsMouse ? "#E0475F" : "#9AB0C2" }
                                MouseArea { onPressedChanged: if (pressed) Sfx.tap(); id: delMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Tasks.remove(task.index) }
                            }
                        }
                    }
                }
            }
            Item {
                width: parent.width; height: addBtn.height
                Field {
                    id: newTask
                    anchors.verticalCenter: addBtn.verticalCenter
                    width: parent.width - addBtn.width - 14 * win.s; height: 46 * win.s
                    placeholder: "새 할 일 (Enter로 추가)"
                    onAccepted: { Tasks.add(text); text = "" }
                }
                Btn { id: addBtn; anchors.right: parent.right; s: win.s; text: "추가"; onClicked: { Tasks.add(newTask.text); newTask.text = "" } }
            }
        }
    }

    // =====================================================================================
    // System info
    Component {
        id: aboutPage
        Column {
            id: ab
            spacing: 16 * win.s
            property var info: ({})
            Process {
                running: true
                command: ["sh", "-c", [
                    ". /etc/os-release 2>/dev/null; echo \"os=$PRETTY_NAME\"",
                    "echo \"host=$(cat /proc/sys/kernel/hostname)\"",
                    "echo \"kernel=$(uname -r)\"",
                    "echo \"cpu=$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -n1)\"",
                    "echo \"mem=$(awk '/^MemTotal/{printf \"%.1f GB\", $2/1048576}' /proc/meminfo)\"",
                    "echo \"disk=$(df -h --output=used,size / | awk 'NR==2{print $1 \" / \" $2}')\"",
                    "echo \"up=$(cut -d. -f1 /proc/uptime)\""
                ].join("\n")]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const o = {}
                        text.split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) })
                        ab.info = o
                    }
                }
            }
            function uptime(sec) {
                const m = Math.floor(sec / 60), h = Math.floor(m / 60), d = Math.floor(h / 24)
                return d > 0 ? d + "일 " + (h % 24) + "시간" : h > 0 ? h + "시간 " + (m % 60) + "분" : m + "분"
            }

            Head { title: "시스템 정보"; desc: "이 컴퓨터에 대해" }
            Card {
                border.color: Theme.sky
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#E6F5FD" } GradientStop { position: 1; color: "white" } }
                Item {
                    width: parent.width; height: 74 * win.s
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        T { text: "SHITTIM CHEST"; color: Theme.skyDeep; font.pixelSize: 26 * win.s; font.weight: Font.Black; font.italic: true }
                        Sub { text: "싯딤의 상자 · ARONA OS" + (ab.info.os ? "  (" + ab.info.os + ")" : "") }
                    }
                    Column {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        T { anchors.right: parent.right; text: "D+" + Theme.dayCount; color: Theme.ink; font.pixelSize: 26 * win.s; font.weight: Font.Black; font.italic: true }
                        Sub { anchors.right: parent.right; text: "선생님과 함께한 날" }
                    }
                }
            }
            Card {
                Repeater {
                    model: [
                        ["컴퓨터 이름", ab.info.host], ["프로세서", ab.info.cpu], ["메모리", ab.info.mem],
                        ["저장 공간 (사용 / 전체)", ab.info.disk], ["커널", ab.info.kernel],
                        ["켜진 지", ab.info.up ? ab.uptime(parseInt(ab.info.up)) : ""]
                    ]
                    delegate: Column {
                        id: inf
                        required property var modelData
                        required property int index
                        width: parent.width
                        Line { visible: inf.index > 0 }
                        Item {
                            width: parent.width; height: 46 * win.s
                            Label { anchors.verticalCenter: parent.verticalCenter; width: 220 * win.s; text: inf.modelData[0] }
                            T { x: 230 * win.s; anchors.verticalCenter: parent.verticalCenter; width: parent.width - x; elide: Text.ElideRight; text: inf.modelData[1] || "…"; color: Theme.inkDim }
                        }
                    }
                }
            }
        }
    }
}
