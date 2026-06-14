import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: triggerZone

    anchors { top: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    implicitWidth: 160
    implicitHeight: visible ? 48 : 0

    property bool dashOpen: false
    property int  dashOffset: 0

    margins.left: (Quickshell.screens[0].width / 2) - 80
    margins.top: dashOffset

    Behavior on margins.top {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    signal openRequested()
    signal closeRequested()

    property bool isHovered: false
    property bool isDragging: false
    property real dragStartY: 0
    readonly property int dragThreshold: 40

    HoverHandler {
        onHoveredChanged: triggerZone.isHovered = hovered
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true

        onPressed: (mouse) => {
            triggerZone.isDragging = true
            triggerZone.dragStartY = mouse.y
            dragIndicator.dragProgress = 0
        }

        onPositionChanged: (mouse) => {
            if (!triggerZone.isDragging) return
            if (!triggerZone.dashOpen) {
                var deltaDown = mouse.y - triggerZone.dragStartY
                dragIndicator.dragProgress = Math.max(0, Math.min(deltaDown / triggerZone.dragThreshold, 1.0))
            } else {
                var deltaUp = triggerZone.dragStartY - mouse.y
                dragIndicator.dragProgress = Math.max(0, Math.min(deltaUp / triggerZone.dragThreshold, 1.0)) * -1
            }
        }

        onReleased: (mouse) => {
            if (!triggerZone.dashOpen) {
                var deltaDown = mouse.y - triggerZone.dragStartY
                if (deltaDown >= triggerZone.dragThreshold)
                    triggerZone.openRequested()
            } else {
                var deltaUp = triggerZone.dragStartY - mouse.y
                if (deltaUp >= triggerZone.dragThreshold)
                    triggerZone.closeRequested()
            }
            dragIndicator.dragProgress = 0
            triggerZone.isDragging = false
        }
    }

    // Pill background
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 4
        width: 90
        height: 28
        radius: 14
        color: triggerZone.isHovered || triggerZone.isDragging ? "#1a2a3a" : "#0d1821"
        border.color: dragIndicator.dragProgress !== 0 ? "#4488ff" : "#1e3a5a"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Item {
            id: dragIndicator
            anchors.fill: parent
            property real dragProgress: 0

            // Arrow icons
            Row {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -18
                spacing: 2
                visible: triggerZone.isHovered || triggerZone.isDragging

                Repeater {
                    model: 1
                    Text {
                        text: triggerZone.dashOpen ? "▲" : "▼"
                        font.pixelSize: 7
                        color: dragIndicator.dragProgress !== 0 ? "#4488ff" : "#2a5080"
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: (triggerZone.isHovered || triggerZone.isDragging) ? 8 : 0
                text: {
                    if (triggerZone.dashOpen)
                        return dragIndicator.dragProgress < -0.5 ? "RELEASE" : "PROC"
                    else
                        return dragIndicator.dragProgress > 0.5 ? "RELEASE" : "PROC"
                }
                font.pixelSize: 7
                color: dragIndicator.dragProgress !== 0 ? "#4488ff" : "#1e3a5a"
                font.letterSpacing: 2

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on anchors.horizontalCenterOffset { NumberAnimation { duration: 150 } }
            }
        }
    }
}
