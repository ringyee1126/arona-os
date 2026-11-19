pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// 오늘의 업무: ~/.config/shittim/tasks.txt, one task per line, "x " in front = done.
// Shown on the desktop card, edited in 설정 → 오늘의 업무.
Singleton {
    id: tasks
    property var list: []      // [{ done, text }]

    function save(l) {
        list = l
        file.setText(l.map(t => (t.done ? "x " : "") + t.text).join("\n") + (l.length ? "\n" : ""))
    }
    function toggle(i) { if (!list[i].done) Arona.react("task-done"); const l = list.slice(); l[i] = { done: !l[i].done, text: l[i].text }; save(l) }
    function add(text) { if (String(text).trim()) save(list.concat([{ done: false, text: String(text).trim() }])) }
    function remove(i) { const l = list.slice(); l.splice(i, 1); save(l) }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/shittim/tasks.txt"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: tasks.list = text().split("\n").filter(l => l.trim() !== "")
                                     .map(l => ({ done: l.startsWith("x "), text: l.replace(/^x /, "") }))
        onLoadFailed: tasks.list = []
    }
}
