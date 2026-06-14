import Quickshell
import Quickshell.Io
import QtQuick
import "./components"

ShellRoot {
    id: root
    property string mode: "full"
    property bool panelExpanded: false

    Process {
        id: readMode
        command: ["bash", "-c", "cat $HOME/.cache/qs-mode 2>/dev/null || echo full"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let m = data.trim()
                if (m === "full" || m === "basic" || m === "minimal")
                    root.mode = m
            }
        }
    }

    IpcHandler {
        target: "mode"
        function set(m: string): void {
            if (m !== "full" && m !== "basic" && m !== "minimal") return
            root.mode = m
            root.panelExpanded = false
            sliderPanel.isHovered = false
            hoverResetTimer.stop()
            saveModeProc.command = ["bash", "-c", "echo '" + m + "' > $HOME/.cache/qs-mode"]
            saveModeProc.running = false
            saveModeProc.running = true
        }
    }

    Process { id: saveModeProc; command: ["bash", "-c", "echo noop"]; running: false }

    SideBar {}
    WallpaperPicker { id: wallpaperPicker }
    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            if (wallpaperPicker.visible) wallpaperPicker.close()
            else wallpaperPicker.open()
        }
    }

    SliderPanel {
        id: sliderPanel
        panelExpanded: root.panelExpanded
        expandEnabled: root.mode !== "minimal"
        onExpandRequested: {
            root.panelExpanded = true
            if (expandLoader.item) expandLoader.item.isExpanded = true
        }
        onCollapseRequested: {
            root.panelExpanded = false
            if (expandLoader.item) expandLoader.item.isExpanded = false
        }
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

    AppDrawer { id: drawer }
    NotificationPopup { visible: root.mode !== "minimal" }
    Loader {
        id: expandLoader
        active: root.mode !== "minimal"
        sourceComponent: Component {
            ExpandPanel { id: expandPanel }
        }
    }

    IpcHandler {
        target: "drawer"
        function toggle(): void {
            if (root.mode === "minimal") return
            if (drawer.isOpen) drawer.close()
            else drawer.open()
        }
    }
    Loader {
        id: cockpitLoader
        active: root.mode === "full"
        sourceComponent: Component {
            CockpitDash { id: cockpit }
        }
    }

    CockpitTrigger {
        visible: root.mode === "full"
        dashOpen: cockpitLoader.item ? cockpitLoader.item._open : false
        dashOffset: cockpitLoader.item && cockpitLoader.item._open
            ? cockpitLoader.item.panelHeight + cockpitLoader.item.tabHeight : 0
        onOpenRequested: if (cockpitLoader.item) cockpitLoader.item.open()
        onCloseRequested: if (cockpitLoader.item) cockpitLoader.item.close()
    }

    Loader {
        id: processPanelLoader
        active: root.mode !== "minimal"
        sourceComponent: Component {
            ProcessPanel { id: processPanel }
        }
    }

    ProcessTrigger {
        visible: root.mode !== "minimal"
        dashOpen: processPanelLoader.item ? processPanelLoader.item._open : false
        dashOffset: processPanelLoader.item && processPanelLoader.item._open
            ? processPanelLoader.item.panelHeight : 0
        onOpenRequested:  if (processPanelLoader.item) processPanelLoader.item.open()
        onCloseRequested: if (processPanelLoader.item) processPanelLoader.item.close()
    }

    IpcHandler {
        target: "processes"
        function toggle(): void {
            if (root.mode === "minimal") return
            if (!processPanelLoader.item) return
            if (processPanelLoader.item._open) processPanelLoader.item.close()
            else processPanelLoader.item.open()
        }
    }
}