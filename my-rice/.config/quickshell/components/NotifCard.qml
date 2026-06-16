import QtQuick
import QtQuick.Effects
import Quickshell.Io
import Qt.labs.platform 1.1

Item {
    id: card
    height: 70

    property string summary: ""
    property string body: ""
    property string appName: ""
    property var urgency: 1

    property string notifType: {
        var u = (typeof urgency === "number") ? urgency : (urgency ? urgency.valueOf() : 1)
        if (u === 2) return "critical"
        if (appName !== "" && appName !== "notify-send" && appName !== "System") return "app"
        return "system"
    }

    signal dismissed()
    
    property color accentColor: {
        if (notifType === "critical") return '#c50014'
        if (notifType === "app") return '#26bf00'
        return '#0041c2'
    }
    property string notifIcon: {
        if (notifType === "critical") return "⚠"
        if (notifType === "app") return "☃"
        return "⚙"
    }

    // 2. TENTUKAN PATH FILE .OGA BERDASARKAN TYPE NOTIFIKASI
    property string soundFile: {
        var baseDir = "/home/silence-suzuka/.config/assets/"
        if (notifType === "critical") return baseDir + "Error-Warning_notify.oga"
        if (notifType === "app") return baseDir + "Appclication_notify.oga"
        return baseDir + "System_notify.oga"
    }

    // 3. PROSES UNTUK MEMUTAR SUARA MENGGUNAKAN PAPLAY
    Process {
        id: soundPlayer
        command: ["paplay", card.soundFile]
        running: false
    }

    Component.onCompleted: {
        opacity = 0
        slideIn.start()
        dismissTimer.restart()
        
        // 4. JALANKAN SUARA SAAT NOTIFIKASI MUNCUL
        soundPlayer.running = true 
    }

    ParallelAnimation {
        id: slideIn
        NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 350; easing.type: Easing.OutQuart }
        NumberAnimation { target: card; property: "scale"; from: 0.92; to: 1.0; duration: 350; easing.type: Easing.OutQuart }
    }

    SequentialAnimation {
        id: slideOut
        ParallelAnimation {
            NumberAnimation { target: card; property: "opacity"; to: 0; duration: 300; easing.type: Easing.InQuart }
            NumberAnimation { target: card; property: "scale"; to: 0.92; duration: 300; easing.type: Easing.InQuart }
        }
        ScriptAction {
            script: card.dismissed()
        }
    }

    function dismiss() {
        dismissTimer.stop()
        slideOut.start()
    }

    Timer {
        id: dismissTimer
        interval: 4000
        repeat: false
        onTriggered: card.dismiss()
    }

    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: 8
        radius: 16
        color: "#0d1220"
        border.color: Qt.rgba(1, 1, 1, 0.07)
        border.width: 1

        Rectangle {
            width: parent.width * 0.75
            height: parent.height
            radius: 16
            opacity: 0.28
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: card.accentColor }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            width: 3
            height: parent.height - 16
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            radius: 2
            color: card.accentColor
        }

        Rectangle {
            id: iconBox
            width: 40; height: 40; radius: 10
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            color: Qt.rgba(card.accentColor.r, card.accentColor.g, card.accentColor.b, 0.25)
            border.color: Qt.rgba(card.accentColor.r, card.accentColor.g, card.accentColor.b, 0.5)
            border.width: 1
            Text {
                anchors.centerIn: parent
                text: card.notifIcon
                font.pixelSize: 18
                color: card.accentColor
            }
        }

        Column {
            anchors {
                left: iconBox.right; leftMargin: 12
                right: closeBtn.left; rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            spacing: 3
            Text {
                width: parent.width
                text: card.summary || card.appName || "Notification"
                color: "#cad3f5"; font.pixelSize: 13; font.weight: Font.SemiBold
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: card.body
                color: "#a5adcb"; font.pixelSize: 11
                elide: Text.ElideRight
                visible: text !== ""
            }
            Text {
                text: card.appName
                color: Qt.rgba(card.accentColor.r, card.accentColor.g, card.accentColor.b, 0.7)
                font.pixelSize: 9
                visible: text !== "" && text !== card.summary
            }
        }

        Rectangle {
            id: closeBtn
            width: 32; height: 32; radius: 12
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            color: closeMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 20; color: "#a5adcb" }
            MouseArea {
                id: closeMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: card.dismiss()
            }
        }
    }
}