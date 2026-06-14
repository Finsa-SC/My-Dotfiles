import Quickshell
import QtQuick
import "../theme"

Item {
    id: appItem
    property string appName: ""
    property string appIcon: ""
    property string appExec: ""
    property real itemWidth: 60

    width: itemWidth
    height: itemWidth + 24

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: hoverArea.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Image {
            id: iconImg
            anchors.horizontalCenter: parent.horizontalCenter
            width: 36; height: 36
            source: "file:///usr/share/icons/Papirus/48x48/apps/" + appIcon + ".svg"
            fillMode: Image.PreserveAspectFit

            onStatusChanged: {
                if (status === Image.Error) {
                    source = "file:///usr/share/icons/Papirus/48x48/apps/" + appIcon + ".png"
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 36; height: 36
            radius: 8
            color: Qt.rgba(1,1,1,0.1)
            visible: iconImg.status === Image.Error

            Text {
                anchors.centerIn: parent
                text: appName.charAt(0).toUpperCase()
                font.pixelSize: 16
                font.bold: true
                color: Colors.textPrimary
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: appName
            font.pixelSize: 9
            color: Colors.textPrimary
            elide: Text.ElideRight
            width: appItem.itemWidth - 4
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["sh", "-c", appExec])
            appDrawer.close()
        }
    }
}
