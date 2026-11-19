pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// The desktop's notification daemon. MomoTalk lists these; Arona reads each new one aloud in her bubble.
Singleton {
    readonly property var list: server.trackedNotifications.values

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        onNotification: n => {
            n.tracked = true
            if (n.summary === "스크린샷 저장") return Arona.react("shot")
            Arona.say((n.appName ? n.appName + " · " : "") + n.summary); Arona.speak(Arona.pick("notify"))
        }
    }
}
