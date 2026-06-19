import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../theme"

PopupWindow {
    id: powerMenu

    anchor.window: sideBar
    anchor.rect.x: (Quickshell.screens[0].width / 2) - (implicitWidth / 2)
    anchor.rect.y: (Quickshell.screens[0].height / 2) - (implicitHeight / 2)

    implicitWidth: 420
    implicitHeight: 120
    visible: false
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Colors.panelBg
        border.color: Colors.panelBorder
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "What do you want to do?"
                font.pixelSize: 11
                color: Colors.textSecondary
            }

            Row {
                spacing: 8

                // Power off
                Rectangle {
                    width: 64; height: 64
                    radius: 14
                    color: powerOffHover.containsMouse ? Colors.batteryLow : Qt.rgba(1,1,1,0.05)
                    border.color: powerOffHover.containsMouse ? Colors.batteryLow : Colors.panelBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "⏻"
                            font.pixelSize: 22
                            color: powerOffHover.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Power Off"
                            font.pixelSize: 9
                            color: powerOffHover.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: powerOffHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenu.visible = false
                            Quickshell.execDetached(["systemctl", "poweroff"])
                        }
                    }
                }

                // Reboot
                Rectangle {
                    width: 64; height: 64
                    radius: 14
                    color: rebootHover.containsMouse ? Qt.rgba(1,0.6,0.2,0.4) : Qt.rgba(1,1,1,0.05)
                    border.color: rebootHover.containsMouse ? Qt.rgba(1,0.6,0.2,0.8) : Colors.panelBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "↺"
                            font.pixelSize: 22
                            color: rebootHover.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Reboot"
                            font.pixelSize: 9
                            color: rebootHover.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: rebootHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenu.visible = false
                            Quickshell.execDetached(["systemctl", "reboot"])
                        }
                    }
                }

                // Suspend
                Rectangle {
                    width: 64; height: 64
                    radius: 14
                    color: suspendHover.containsMouse ? Qt.rgba(0.3,0.6,1,0.4) : Qt.rgba(1,1,1,0.05)
                    border.color: suspendHover.containsMouse ? Qt.rgba(0.3,0.6,1,0.8) : Colors.panelBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "⏾"
                            font.pixelSize: 22
                            color: suspendHover.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Suspend"
                            font.pixelSize: 9
                            color: suspendHover.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: suspendHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenu.visible = false
                            Quickshell.execDetached(["systemctl", "suspend"])
                        }
                    }
                }

                // Logout
                Rectangle {
                    width: 64; height: 64
                    radius: 14
                    color: logoutHover.containsMouse ? Qt.rgba(0.5,1,0.5,0.3) : Qt.rgba(1,1,1,0.05)
                    border.color: logoutHover.containsMouse ? Qt.rgba(0.5,1,0.5,0.8) : Colors.panelBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "⎋"
                            font.pixelSize: 22
                            color: logoutHover.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Logout"
                            font.pixelSize: 9
                            color: logoutHover.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: logoutHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenu.visible = false
                            Quickshell.execDetached(["loginctl", "terminate-session", Quickshell.env("XDG_SESSION_ID")])
                        }
                    }
                }
                // Lock
                Rectangle {
                    width: 64; height: 64
                    radius: 14
                    color: lockHover.containsMouse ? Qt.rgba(0.8,0.5,1,0.4) : Qt.rgba(1,1,1,0.05)
                    border.color: lockHover.containsMouse ? Qt.rgba(0.8,0.5,1,0.8) : Colors.panelBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "🔒"
                            font.pixelSize: 22
                            color: lockHover.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Lock"
                            font.pixelSize: 9
                            color: lockHover.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: lockHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenu.visible = false
                            Quickshell.execDetached(["hyprlock"])
                        }
                    }
                }
            }
        }
    }
}