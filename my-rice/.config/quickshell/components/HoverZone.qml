import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: hoverZone

    signal triggered()
    signal left()

    anchors { right: true }
    exclusiveZone: 0
    implicitWidth: 4
    implicitHeight: 220

    margins {
        top: (Quickshell.screens[0].height / 2) - 110
        right: 0
    }

    color: "transparent"

    HoverHandler {
        onHoveredChanged: {
            if (hovered) hoverZone.triggered()
        }
    }
}