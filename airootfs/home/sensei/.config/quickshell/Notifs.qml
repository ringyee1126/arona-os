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
            Arona.say((n.appName ? n.appName + " · " : "") + n.summary)
        }
    }
}
