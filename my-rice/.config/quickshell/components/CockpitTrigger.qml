import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: triggerZone
    anchors { bottom: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    implicitWidth: 160
    implicitHeight: visible ? 48 : 0

    property bool dashOpen: false
    property int  dashOffset: 0

    margins.left: (Quickshell.screens[0].width / 2) - 80
    margins.bottom: dashOffset

    Behavior on margins.bottom {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    signal openRequested()
    signal closeRequested()

    property bool isHovered: false
    property bool isDragging: false
    property real dragStartY: 0
    readonly property int dragThreshold: 40

    HoverHandler {
        onHoveredChanged: {
            triggerZone.isHovered = hovered
        }
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
                // drag ke atas → open
                var deltaUp = triggerZone.dragStartY - mouse.y
                dragIndicator.dragProgress = Math.max(0, Math.min(deltaUp / triggerZone.dragThreshold, 1.0))
            } else {
                // drag ke bawah → close
                var deltaDown = mouse.y - triggerZone.dragStartY
                dragIndicator.dragProgress = Math.max(0, Math.min(deltaDown / triggerZone.dragThreshold, 1.0)) * -1
            }
        }

        onReleased: (mouse) => {
            if (!triggerZone.dashOpen) {
                var deltaUp = triggerZone.dragStartY - mouse.y
                if (deltaUp >= triggerZone.dragThreshold) {
                    triggerZone.openRequested()
                }
            } else {
                var deltaDown = mouse.y - triggerZone.dragStartY
                if (deltaDown >= triggerZone.dragThreshold) {
                    triggerZone.closeRequested()
                }
            }
            dragIndicator.dragProgress = 0
            triggerZone.isDragging = false
        }
    }

    Item {
        id: dragIndicator
        anchors.fill: parent
        property real dragProgress: 0  // positif = drag up, negatif = drag down

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            spacing: 2
            visible: triggerZone.isHovered || triggerZone.isDragging

            Repeater {
                model: 3
                Text {
                    text: triggerZone.dashOpen ? "▼" : "▲"
                    font.pixelSize: 10
                    color: dragIndicator.dragProgress !== 0 ? "#c6a0f6" : "#a5adcb"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            text: {
                if (triggerZone.dashOpen) {
                    return dragIndicator.dragProgress < -0.5 ? "RELEASE" : "DASH"
                } else {
                    return dragIndicator.dragProgress > 0.5 ? "RELEASE" : "DASH"
                }
            }
            font.pixelSize: 7
            color: dragIndicator.dragProgress !== 0 ? "#c6a0f6" : "#363a4f"
            font.letterSpacing: 2
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}