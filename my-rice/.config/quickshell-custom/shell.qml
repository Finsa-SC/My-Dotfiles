import Quickshell
import Quickshell.Io
import QtQuick
import "./components"

ShellRoot {
    SideBar {}
    AppDrawer { id: drawer }
    ExpandPanel { id: expandPanel }
    SliderPanel { id: sliderPanel }
    NotificationPopup {}
    CockpitDash { id: cockpit }
    CockpitTrigger {
        dashOpen: cockpit._open
        dashOffset: cockpit._open ? cockpit.panelHeight + cockpit.tabHeight : 0
        onOpenRequested: cockpit.open()
        onCloseRequested: cockpit.close()
    }
    HoverZone {
        onTriggered: {
            sliderPanel.isHovered = true
            hoverResetTimer.restart()
        }
    }
    Timer {
        id: hoverResetTimer
        interval: 2000
        repeat: false
        onTriggered: sliderPanel.isHovered = false
    }
    IpcHandler {
        target: "drawer"
        function toggle(): void {
            if (drawer.visible) drawer.close()
            else drawer.open()
        }
    }
    WallpaperPicker { id: wallpaperPicker }
    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            if (wallpaperPicker.visible) wallpaperPicker.close()
            else wallpaperPicker.open()
        }
    }
}