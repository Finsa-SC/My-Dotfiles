import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Services.Notifications

PanelWindow {
    id: notifWindow
    anchors { top: true; left: true; right: true }
    exclusiveZone: 0
    implicitHeight: activeModel.count > 0 ? (topMarginVal + activeModel.count * cardHeight + 20) : 0
    color: "transparent"

    readonly property int cardHeight: 80
    readonly property int topMarginVal: 20

    NotificationServer {
        id: notifServer
        actionIconsSupported: true
        actionsSupported: true
        bodySupported: true
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        persistenceSupported: false
        onNotification: (notif) => {
            var d = {
                summary: notif.summary || "",
                body: notif.body || "",
                appName: notif.appName || "",
                urgency: notif.urgency ? parseInt(notif.urgency) : 1,
                id: notif.id || 0
            }
            if (activeModel.count < 3) {
                activeModel.append(d)
            } else {
                pendingQueue.push(d)
            }
        }
    }

    ListModel { id: activeModel }

    QtObject {
        id: pendingQueue
        property var items: []
        property int length: items.length
        function push(d) {
            items.push(d)
            length = items.length
        }
        function shift() {
            if (items.length > 0) {
                let item = items.shift()
                length = items.length
                return item
            }
            return null
        }
    }

    function onNotifDismissed() {
        if (pendingQueue.length > 0 && activeModel.count < 3) {
            activeModel.append(pendingQueue.shift())
        }
    }

    Item {
        anchors {
            top: parent.top
            topMargin: notifWindow.topMarginVal
            horizontalCenter: parent.horizontalCenter
        }
        width: 420
        height: activeModel.count * notifWindow.cardHeight

        Repeater {
            model: activeModel
            delegate: NotifCard {
                id: cardDelegate
                width: 420
                height: 80
                y: index * 80
                summary: model.summary
                body: model.body
                appName: model.appName
                urgency: model.urgency

                onDismissed: {
                    var i = index
                    if (i >= 0 && i < activeModel.count) {
                        activeModel.remove(i)
                        if (typeof notifWindow !== "undefined") {
                            notifWindow.onNotifDismissed()
                        }
                    }
                }
            }
        }
    }
}