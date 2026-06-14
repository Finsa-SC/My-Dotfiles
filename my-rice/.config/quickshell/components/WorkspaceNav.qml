import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../theme"

PopupWindow {
    id: navPanel

    anchor.window: SideBar.sideBar
    anchor.rect.x: 46 + 8
    anchor.rect.y: 16

    width: 140
    height: 140
    visible: State.wsExpanded
    color: "transparent"

    Timer {
        id: collapseTimer
        interval: 3000
        onTriggered: State.wsExpanded = false
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            State.wsExpanded = true
            collapseTimer.restart()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Colors.panelBg
        border.color: Colors.panelBorder
        border.width: 1

        GridLayout {
            anchors { fill: parent; margins: 8 }
            columns: 5
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: 25
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 3
                    color: {
                        if (!Hyprland.focusedWorkspace) return Colors.wsBg
                        if (index + 1 === Hyprland.focusedWorkspace.id)
                            return Colors.wsActive
                        return Colors.wsBg
                    }
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
            }
        }
    }
}
