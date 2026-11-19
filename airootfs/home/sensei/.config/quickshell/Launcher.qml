import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// "아로나 검색": apps / files / web in one list with a preview pane. Tab switches to asking Arona.
PanelWindow {
    id: ln
    readonly property real s: screen ? screen.height / 1200 : 1
    visible: Ui.launcherOpen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shittim-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property string query: ""
    property string mode: "search"     // "search" | "ask"
    property string tab: "all"         // all | app | file | web
    property int sel: 0
    property var files: []
    property var preview: []
    property real enter: 0
    property string asked: ""          // last thing sent to Arona in ask mode

    onVisibleChanged: if (visible) {
        input.text = ""; mode = "search"; tab = "all"; sel = 0; files = []; preview = []
        enterAnim.restart(); input.forceActiveFocus()
    }
    NumberAnimation { id: enterAnim; target: ln; property: "enter"; from: 0; to: 1; duration: 420; easing.type: Easing.OutBack }

    // ---------- helpers ----------
    function human(n) {
        return n < 1024 ? n + "B" : n < 1048576 ? Math.round(n / 1024) + "KB"
             : n < 1073741824 ? (n / 1048576).toFixed(1) + "MB" : (n / 1073741824).toFixed(1) + "GB"
    }
    function ago(t) {
        const m = (Date.now() / 1000 - t) / 60
        return m < 2 ? "방금" : m < 60 ? Math.floor(m) + "분 전" : m < 1440 ? Math.floor(m / 60) + "시간 전"
             : m < 2880 ? "어제" : Math.floor(m / 1440) + "일 전"
    }
    function folderOf(p) {
        const home = Quickshell.env("HOME"), d = p.substring(0, p.lastIndexOf("/"))
        return d === home ? "홈" : d.replace(home + "/", "").replace(/\//g, " › ")
    }
    function kindOf(f) {
        if (f.type === "d") return "dir"
        if (/\.(zip|7z|rar|tar|gz|tgz|xz|bz2|zst|alz|egg)$/i.test(f.name)) return "zip"
        if (/\.pdf$/i.test(f.name)) return "pdf"
        if (/\.(png|jpe?g|gif|webp|bmp)$/i.test(f.name)) return "img"
        return "doc"
    }
    readonly property var tileColor: ({ zip: Theme.halo, pdf: "#FBE3E6", dir: Theme.sky, img: "#FFD6E2", doc: "#E6EEF4", web: "#E9F4EA", ask: Theme.momo, app: "white" })
    readonly property var tileText: ({ zip: "ZIP", pdf: "PDF", dir: "▤", img: "IMG", doc: "DOC", web: "G", ask: "A" })
    readonly property var tileInk: ({ zip: "#6B5200", pdf: "#D2384D", dir: "white", img: "#B0405E", doc: "#5A7A94", web: "#2E8B57", ask: "white" })

    // ---------- results ----------
    readonly property string q: query.trim()
    readonly property var appResults: {
        const k = q.toLowerCase()
        if (!k) return []
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && [e.name, e.genericName, e.comment].concat(e.keywords || []).join(" ").toLowerCase().includes(k))
            .slice(0, 5)
            .map(e => ({ kind: "app", group: "앱", title: e.name, sub: e.genericName || e.comment || "앱", entry: e }))
    }
    readonly property var fileResults: files.map(f => ({
        kind: kindOf(f), group: "파일", title: f.name, file: f,
        sub: folderOf(f.path) + (f.type === "d" ? " · 폴더" : " · " + human(f.size)) + " · " + ago(f.mtime)
    }))
    readonly property var moreResults: q ? [
        { kind: "web", group: "더 찾기", title: "크롬에서 '" + q + "' 검색", sub: "google.com" },
        { kind: "ask", group: "더 찾기", title: "아로나에게 '" + q + "' 부탁하기", sub: "정리, 요약, 파일 옮기기 등" }
    ] : []
    readonly property int found: fileResults.length + appResults.length
    readonly property var results: tab === "app" ? appResults : tab === "file" ? fileResults : tab === "web" ? moreResults.slice(0, 1)
                                  : fileResults.slice(0, 4).concat(appResults.slice(0, 3), moreResults)
    readonly property int selIdx: Math.max(0, Math.min(sel, results.length - 1))
    readonly property var current: results.length ? results[selIdx] : null
    readonly property var rows: {   // results with a small header in front of each group
        const out = []
        let last = ""
        results.forEach((r, i) => {
            if (r.group !== last) { out.push({ header: true, title: r.group }); last = r.group }
            out.push(Object.assign({ idx: i }, r))
        })
        return out
    }

    // ---------- file search: find under $HOME (no hidden dirs), newest first ----------
    onQueryChanged: { sel = 0; finderDelay.restart() }
    Timer {
        id: finderDelay
        interval: 180
        onTriggered: {
            finder.running = false
            ln.files = []
            if (ln.q.length < 2) return
            finder.command = ["sh", "-c", "find \"$HOME\" -mindepth 1 -maxdepth 5 -not -path '*/.*' -iname \"*$1*\" -printf '%y\\t%s\\t%T@\\t%p\\n' 2>/dev/null | head -n 40", "sh", ln.q]
            finder.running = true
        }
    }
    // Results are collected per run and published once on exit, so a cancelled run can't leak lines into the next.
    Process {
        id: finder
        property var buf: []
        onRunningChanged: if (running) buf = []
        stdout: SplitParser {
            onRead: line => {
                const p = line.split("\t")
                if (p.length < 4) return
                const path = p.slice(3).join("\t")
                finder.buf.push({ type: p[0], size: Number(p[1]), mtime: Number(p[2]), path: path, name: path.split("/").pop() })
            }
        }
        onExited: ln.files = buf.slice().sort((a, b) => b.mtime - a.mtime).slice(0, 12)
    }

    // ---------- archive preview: list what's inside (only when the selected archive changes) ----------
    readonly property string zipPath: current && current.kind === "zip" && !/\.(alz|egg)$/i.test(current.title) ? current.file.path : ""
    onZipPathChanged: {
        preview = []
        lister.running = false
        if (!zipPath) return
        lister.command = ["bsdtar", "-tf", zipPath]
        lister.running = true
    }
    Process {
        id: lister
        property var buf: []
        onRunningChanged: if (running) buf = []
        stdout: SplitParser { onRead: l => { if (!l.endsWith("/")) lister.buf.push(l) } }
        onExited: ln.preview = buf.slice(0, 8)
    }

    // ---------- actions ----------
    function activate(r) {
        if (!r) return
        if (r.kind === "ask") { mode = "ask"; return }
        if (r.kind === "app") r.entry.execute()
        else if (r.kind === "web") Quickshell.execDetached(["chromium", "https://www.google.com/search?q=" + encodeURIComponent(q)])
        else Quickshell.execDetached(["gio", "open", r.file.path])   // gio: goes by file name (.md), xdg-open only looks at the content
        Ui.launcherOpen = false
    }
    function extract(f) {
        // into a folder named after the archive, next to it, so nothing gets scattered; the notification lands in MomoTalk
        Quickshell.execDetached(["sh", "-c", "d=\"${1%.*}\"; mkdir -p \"$d\" && bsdtar -xf \"$1\" -C \"$d\" && notify-send -a 아로나 '압축을 풀었어요!' \"$d\"", "sh", f.path])
        Ui.launcherOpen = false
    }

    // ---------- dim backdrop: click outside to close ----------
    Rectangle {
        anchors.fill: parent
        color: "#990A1E34"
        opacity: Math.min(1, ln.enter)
        MouseArea { anchors.fill: parent; onClicked: Ui.launcherOpen = false }
    }

    // ---------- Arona leaning in ----------
    AronaSprite {
        id: arona
        visible: ln.visible
        mood: ln.mode === "ask" ? (Arona.replying ? "thinking" : Arona.replyMood) : "curious"
        height: 1200 * ln.s; width: height * 640 / 1300
        anchors.right: parent.right; anchors.rightMargin: 70 * ln.s - (1 - ln.enter) * 120 * ln.s
        y: parent.height - height + 150 * ln.s
        opacity: Math.min(1, ln.enter)
    }
    Rectangle {
        id: bubble
        anchors.right: arona.left; anchors.rightMargin: -200 * ln.s
        y: 190 * ln.s
        width: bubbleText.width + 48 * ln.s; height: bubbleText.implicitHeight + 40 * ln.s
        radius: 18 * ln.s; color: "white"
        opacity: Math.min(1, ln.enter)
        Rectangle { width: 24 * ln.s; height: width; rotation: 45; color: "white"; anchors.verticalCenter: parent.verticalCenter; x: parent.width - width / 2 }
        Text {
            id: bubbleText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 320 * ln.s)
            wrapMode: Text.WordWrap
            color: Theme.ink; font.family: Theme.font; font.pixelSize: 20 * ln.s; lineHeight: 1.3
            text: ln.mode === "ask" ? (Arona.replying ? "음… 잠깐만요!" : "선생님의 부탁이라면\n뭐든지 해 볼게요!")
                : !ln.q ? "무엇을 찾아드릴까요, 선생님?"
                : ln.found ? "'" + ln.q + "'로 찾은 게 " + ln.found + "개예요!"
                : finder.running ? "찾고 있어요…" : "'" + ln.q + "'(으)로는 못 찾았어요…"
        }
    }

    // ---------- panel ----------
    Rectangle {
        id: panel
        x: 150 * ln.s; y: (120 - (1 - ln.enter) * 20) * ln.s
        width: 940 * ln.s; height: col.implicitHeight
        radius: 18 * ln.s; color: "#F7FFFFFF"; clip: true
        opacity: Math.min(1, ln.enter)
        MouseArea { anchors.fill: parent }   // clicks inside don't close the launcher

        Column {
            id: col
            width: parent.width

            // header
            Rectangle {
                width: parent.width; height: 56 * ln.s; color: Theme.ink
                SkewRect { x: 26 * ln.s; anchors.verticalCenter: parent.verticalCenter; width: 7 * ln.s; height: 22 * ln.s; color: Theme.sky }
                Text { x: 46 * ln.s; anchors.verticalCenter: parent.verticalCenter; text: ln.mode === "ask" ? "아로나에게 부탁" : "아로나 검색"; color: "white"; font.family: Theme.font; font.pixelSize: 21 * ln.s; font.weight: Font.ExtraBold }
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 26 * ln.s; anchors.verticalCenter: parent.verticalCenter
                    width: capText.implicitWidth + 20 * ln.s; height: 28 * ln.s; radius: 6 * ln.s; color: "#26FFFFFF"
                    Text { id: capText; anchors.centerIn: parent; text: ln.mode === "ask" ? "Tab" : "Super + Space"; color: "white"; font.family: Theme.font; font.pixelSize: 14 * ln.s; font.weight: Font.Bold }
                }
            }

            // search box
            Item {
                width: parent.width; height: 116 * ln.s
                Rectangle {
                    anchors { fill: parent; leftMargin: 26 * ln.s; rightMargin: 26 * ln.s; topMargin: 22 * ln.s; bottomMargin: 22 * ln.s }
                    radius: 12 * ln.s; color: "#F7FBFE"; border.color: Theme.sky; border.width: 3 * ln.s
                    Image {
                        id: glass
                        x: 22 * ln.s; anchors.verticalCenter: parent.verticalCenter
                        width: 32 * ln.s; height: width
                        source: Theme.assets + "icons/" + (ln.mode === "ask" ? "arona" : "search") + ".svg"
                        sourceSize.width: width * 2; sourceSize.height: height * 2
                    }
                    TextInput {
                        id: input
                        anchors { left: glass.right; leftMargin: 16 * ln.s; right: chip.left; rightMargin: 12 * ln.s; verticalCenter: parent.verticalCenter }
                        clip: true
                        color: Theme.ink; font.family: Theme.font; font.pixelSize: (ln.mode === "ask" ? 24 : 30) * ln.s; font.weight: Font.Bold
                        selectionColor: Theme.sky
                        onTextChanged: ln.query = text
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Escape) { if (ln.mode === "ask") ln.mode = "search"; else Ui.launcherOpen = false }
                            else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) ln.mode = ln.mode === "ask" ? "search" : "ask"
                            else if (e.key === Qt.Key_Down) ln.sel = Math.min(ln.selIdx + 1, ln.results.length - 1)
                            else if (e.key === Qt.Key_Up) ln.sel = Math.max(ln.selIdx - 1, 0)
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                if (ln.mode === "search") ln.activate(ln.current)
                                else if (ln.q !== "" && !Arona.replying) { ln.asked = ln.q; Arona.ask(ln.q); input.text = "" }
                            }
                            else return
                            e.accepted = true
                        }
                    }
                    Text {
                        visible: !input.text
                        anchors { left: input.left; verticalCenter: parent.verticalCenter }
                        text: ln.mode === "ask" ? "아로나에게 부탁할 일을 적어 주세요" : "앱, 파일, 하고 싶은 일을 입력하세요"
                        color: "#9AB0C2"; font.family: Theme.font; font.pixelSize: 24 * ln.s
                    }
                    Rectangle {
                        id: chip
                        visible: ln.mode === "ask"
                        anchors.right: parent.right; anchors.rightMargin: 18 * ln.s; anchors.verticalCenter: parent.verticalCenter
                        width: visible ? chipText.implicitWidth + 28 * ln.s : 0; height: 32 * ln.s; radius: 16 * ln.s; color: Theme.momo
                        Text { id: chipText; anchors.centerIn: parent; text: "MomoTalk"; color: "white"; font.family: Theme.font; font.pixelSize: 15 * ln.s; font.weight: Font.ExtraBold }
                    }
                }
            }

            // filter tabs
            Row {
                visible: ln.mode === "search"
                x: 26 * ln.s; spacing: 10 * ln.s
                height: visible ? 52 * ln.s : 0
                Repeater {
                    model: [
                        { id: "all", name: "전체", n: ln.found },
                        { id: "app", name: "앱", n: ln.appResults.length },
                        { id: "file", name: "파일", n: ln.fileResults.length },
                        { id: "web", name: "웹", n: -1 }
                    ]
                    delegate: Item {
                        id: tabItem
                        required property var modelData
                        readonly property bool on: ln.tab === modelData.id
                        width: tabLabel.implicitWidth + 44 * ln.s; height: 40 * ln.s
                        SkewRect { anchors.fill: parent; radius: 7 * ln.s; color: tabItem.on ? Theme.sky : "#E6EEF4" }
                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: tabItem.modelData.name + (tabItem.modelData.n >= 0 && ln.q ? "  " + tabItem.modelData.n : "")
                            color: tabItem.on ? "white" : Theme.inkDim
                            font.family: Theme.font; font.pixelSize: 17 * ln.s; font.weight: Font.ExtraBold
                        }
                        MouseArea { onPressedChanged: if (pressed) Sfx.tap(); anchors.fill: parent; onClicked: { ln.tab = tabItem.modelData.id; ln.sel = 0; input.forceActiveFocus() } }
                    }
                }
            }

            // results + preview
            Item {
                visible: ln.mode === "search" && ln.q !== ""
                width: parent.width
                height: visible ? Math.max(list.implicitHeight, prev.visible ? 440 * ln.s : 0) + 16 * ln.s : 0
                Rectangle { width: parent.width; height: 1; color: "#E3EDF4" }

                Column {
                    id: list
                    x: 14 * ln.s; y: 8 * ln.s
                    width: parent.width - 28 * ln.s - (prev.visible ? 300 * ln.s : 0)
                    Repeater {
                        model: ln.rows
                        delegate: Item {
                            id: row
                            required property var modelData
                            readonly property bool isSel: !modelData.header && modelData.idx === ln.selIdx
                            width: list.width; height: modelData.header ? 36 * ln.s : 68 * ln.s

                            Text {
                                visible: row.modelData.header === true
                                x: 12 * ln.s; anchors.bottom: parent.bottom; anchors.bottomMargin: 6 * ln.s
                                text: row.modelData.title; color: "#8AA3B8"
                                font.family: Theme.font; font.pixelSize: 14 * ln.s; font.weight: Font.ExtraBold; font.letterSpacing: 1
                            }
                            Rectangle {
                                visible: row.isSel
                                anchors.fill: parent; radius: 10 * ln.s; color: Theme.skySoft
                                Rectangle { width: 4 * ln.s; height: parent.height; color: Theme.sky }
                            }
                            Item {
                                visible: !row.modelData.header
                                anchors.fill: parent
                                Rectangle {
                                    x: 14 * ln.s; anchors.verticalCenter: parent.verticalCenter
                                    width: 46 * ln.s; height: width; radius: 11 * ln.s
                                    color: ln.tileColor[row.modelData.kind] || "#E6EEF4"
                                    border.color: row.modelData.kind === "app" ? "#B7DCF1" : "transparent"; border.width: 2 * ln.s
                                    Image {
                                        visible: row.modelData.kind === "app"
                                        anchors.centerIn: parent
                                        width: 30 * ln.s; height: width
                                        source: row.modelData.kind === "app" ? Quickshell.iconPath(row.modelData.entry.icon, "application-x-executable") : ""
                                        sourceSize.width: width * 2; sourceSize.height: height * 2
                                    }
                                    Text {
                                        visible: row.modelData.kind !== "app"
                                        anchors.centerIn: parent
                                        text: ln.tileText[row.modelData.kind] || ""
                                        color: ln.tileInk[row.modelData.kind] || Theme.ink
                                        font.family: Theme.font; font.pixelSize: 14 * ln.s; font.weight: Font.Black
                                    }
                                }
                                Column {
                                    x: 76 * ln.s; anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 180 * ln.s
                                    Text { width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText; text: row.modelData.title || ""; color: Theme.ink; font.family: Theme.font; font.pixelSize: 18 * ln.s; font.weight: Font.Bold }
                                    Text { width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText; text: row.modelData.sub || ""; color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 14 * ln.s }
                                }
                                Text {
                                    visible: row.isSel || row.modelData.kind === "ask"
                                    anchors.right: parent.right; anchors.rightMargin: 14 * ln.s; anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData.kind === "ask" ? "Tab" : "Enter 열기"
                                    color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 13 * ln.s; font.weight: Font.Bold
                                }
                                MouseArea {
                                    onPressedChanged: if (pressed) Sfx.tap()
                                    anchors.fill: parent; hoverEnabled: true
                                    onEntered: ln.sel = row.modelData.idx
                                    onClicked: ln.activate(row.modelData)
                                }
                            }
                        }
                    }
                }

                // preview pane for files and folders
                Rectangle {
                    id: prev
                    visible: ln.current !== null && ln.current.file !== undefined
                    anchors.right: parent.right; y: 1
                    width: 300 * ln.s; height: parent.height - 1
                    color: "#F3F9FD"
                    Column {
                        x: 20 * ln.s; y: 20 * ln.s; width: parent.width - 40 * ln.s
                        spacing: 8 * ln.s
                        Rectangle {
                            width: parent.width; height: 120 * ln.s; radius: 12 * ln.s
                            color: ln.current ? (ln.tileColor[ln.current.kind] || "#E6EEF4") : "#E6EEF4"
                            Text {
                                anchors.centerIn: parent
                                text: ln.current ? (ln.tileText[ln.current.kind] || "") : ""
                                color: ln.current ? (ln.tileInk[ln.current.kind] || Theme.ink) : Theme.ink
                                font.family: Theme.font; font.pixelSize: 30 * ln.s; font.weight: Font.Black
                            }
                        }
                        Text { width: parent.width; wrapMode: Text.WrapAnywhere; textFormat: Text.PlainText; text: ln.current ? ln.current.title : ""; color: Theme.ink; font.family: Theme.font; font.pixelSize: 18 * ln.s; font.weight: Font.Bold }
                        Text { width: parent.width; wrapMode: Text.WordWrap; text: ln.current && ln.current.file ? ln.current.sub : ""; color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 13 * ln.s }
                        Repeater {
                            model: ln.preview
                            delegate: Text {
                                required property var modelData
                                width: parent.width; elide: Text.ElideMiddle; textFormat: Text.PlainText
                                text: "· " + modelData; color: Theme.ink; font.family: Theme.font; font.pixelSize: 14 * ln.s
                            }
                        }
                        Item { width: 1; height: 6 * ln.s }
                        Row {
                            spacing: 10 * ln.s
                            Btn { visible: ln.current !== null && ln.current.kind === "zip"; s: ln.s; text: "여기에 풀기"; onClicked: ln.extract(ln.current.file) }
                            Btn { s: ln.s; text: "열기"; primary: ln.current !== null && ln.current.kind !== "zip"; onClicked: ln.activate(ln.current) }
                        }
                    }
                }
            }

            // ask mode: MomoTalk-style chat with the ARONA server (Arona.ask / Arona.replyText)
            Item {
                visible: ln.mode === "ask"
                width: parent.width; height: visible ? Math.max(300 * ln.s, aronaRow.y + aronaRow.implicitHeight + 26 * ln.s) : 0
                Rectangle { width: parent.width; height: 1; color: "#E3EDF4" }
                Rectangle {
                    id: meBubble
                    visible: ln.asked !== ""
                    anchors.right: parent.right; anchors.rightMargin: 26 * ln.s; y: 22 * ln.s
                    width: Math.min(meText.implicitWidth, 600 * ln.s) + 36 * ln.s; height: meText.implicitHeight + 24 * ln.s
                    radius: 16 * ln.s; color: Theme.sky
                    Text { id: meText; anchors.centerIn: parent; width: Math.min(implicitWidth, 600 * ln.s); wrapMode: Text.WordWrap; textFormat: Text.PlainText; text: ln.asked; color: "white"; font.family: Theme.font; font.pixelSize: 18 * ln.s; font.weight: Font.DemiBold }
                }
                Row {
                    id: aronaRow
                    x: 26 * ln.s; y: meBubble.visible ? meBubble.y + meBubble.height + 20 * ln.s : 26 * ln.s
                    spacing: 14 * ln.s
                    Avatar { s: ln.s; width: 54 * ln.s; height: width }
                    Column {
                        spacing: 4 * ln.s
                        Text { text: "아로나"; color: Theme.skyDeep; font.family: Theme.font; font.pixelSize: 14 * ln.s; font.weight: Font.ExtraBold }
                        Rectangle {
                            width: sayText.implicitWidth + 36 * ln.s; height: sayText.implicitHeight + 28 * ln.s
                            radius: 16 * ln.s; color: "white"; border.color: "#B7DCF1"; border.width: 2 * ln.s
                            Text {
                                id: sayText
                                anchors.centerIn: parent
                                width: Math.min(implicitWidth, 700 * ln.s)
                                wrapMode: Text.WordWrap; textFormat: Text.PlainText
                                text: Arona.replyError || Arona.replyText
                                      || (Arona.replying ? "음… 생각하고 있어요…"
                                         : Arona.ready ? "무엇이든 부탁해 주세요, 선생님!\n입력하고 Enter를 누르면 대답할게요."
                                         : "먼저 설정 → 아로나에서\nGemini API 키를 넣어 주세요!")
                                color: Theme.ink; font.family: Theme.font; font.pixelSize: 17 * ln.s; lineHeight: 1.35
                            }
                        }
                    }
                }
            }

            // key hints
            Rectangle { width: parent.width; height: 1; color: "#E3EDF4" }
            Row {
                x: 26 * ln.s; height: 50 * ln.s; spacing: 22 * ln.s
                Repeater {
                    model: ln.mode === "ask" ? [["Tab", "검색으로"], ["Esc", "검색으로"]]
                                            : [["↑↓", "이동"], ["Enter", "열기"], ["Tab", "아로나에게 부탁"], ["Esc", "닫기"]]
                    delegate: Row {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7 * ln.s
                        Rectangle {
                            width: keyText.implicitWidth + 16 * ln.s; height: 26 * ln.s; radius: 6 * ln.s; color: "#E6EEF4"
                            Text { id: keyText; anchors.centerIn: parent; text: modelData[0]; color: Theme.ink; font.family: Theme.font; font.pixelSize: 13 * ln.s; font.weight: Font.Bold }
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: Theme.inkDim; font.family: Theme.font; font.pixelSize: 14 * ln.s; font.weight: Font.DemiBold }
                    }
                }
            }
        }
    }
}
