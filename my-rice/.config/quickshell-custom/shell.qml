import Quickshell
import Quickshell.Io
import QtQuick
import "./components"

ShellRoot {
    id: root

    property string mode: "full"  // default

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

    SideBar {}
    WallpaperPicker { id: wallpaperPicker }
    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            if (wallpaperPicker.visible) wallpaperPicker.close()
            else wallpaperPicker.open()
        }
    }

    // === BASIC + FULL ===
    Loader {
        active: root.mode !== "minimal"
        sourceComponent: Component {
            ExpandPanel { id: expandPanel }
        }
    }
    Loader {
        id: sliderLoader
        active: root.mode !== "minimal"
        sourceComponent: Component {
            SliderPanel { id: sliderPanel }
        }
    }
    Loader {
        active: root.mode !== "minimal"
        sourceComponent: Component {
            HoverZone {
                onTriggered: {
                    var s = sliderLoader.item
                    if (s) { s.isHovered = true; hoverResetTimer.restart() }
                }
            }
        }
    }
    Loader {
        id: expandLoader
        active: root.mode !== "minimal"
        sourceComponent: Component {
            ExpandPanel { id: expandPanel }
        }
    }
    Binding {
        target: sliderLoader.item
        property: "panelExpanded"
        value: expandLoader.item ? expandLoader.item.isExpanded : false
    }
    Timer {
        id: hoverResetTimer
        interval: 2000
        repeat: false
        onTriggered: { var s = sliderLoader.item; if (s) s.isHovered = false }
    }
    Loader {
        active: root.mode !== "minimal"
        sourceComponent: Component {
            NotificationPopup {}
        }
    }
    Loader {
        id: drawerLoader
        active: root.mode !== "minimal"
        sourceComponent: Component {
            AppDrawer {}
        }
    }
    IpcHandler {
        target: "drawer"
        function toggle(): void {
            if (root.mode === "minimal") return
            var d = drawerLoader.item
            if (!d) return
            if (d.visible) d.close()
            else d.open()
        }
    }

    // === FULL ONLY ===
    Loader {
        id: cockpitLoader
        active: root.mode === "full"
        sourceComponent: Component {
            CockpitDash {}
        }
    }
    Loader {
        active: root.mode === "full"
        sourceComponent: Component {
            CockpitTrigger {
                dashOpen: cockpitLoader.item ? cockpitLoader.item._open : false
                dashOffset: cockpitLoader.item && cockpitLoader.item._open
                    ? cockpitLoader.item.panelHeight + cockpitLoader.item.tabHeight : 0
                onOpenRequested: if (cockpitLoader.item) cockpitLoader.item.open()
                onCloseRequested: if (cockpitLoader.item) cockpitLoader.item.close()
            }
        }
    }

    // === IPC ganti mode ===
    IpcHandler {
        target: "mode"
        function set(m: string): void {
            if (m !== "full" && m !== "basic" && m !== "minimal") return
            root.mode = m
            hoverResetTimer.stop()
            var s = sliderLoader.item
            if (s) s.isHovered = false
            saveModeProc.command = ["bash", "-c", "echo '" + m + "' > $HOME/.cache/qs-mode"]
            saveModeProc.running = false
            saveModeProc.running = true
        }
    }

    Process {
        id: saveModeProc
        command: ["bash", "-c", "echo noop"]
        running: false
    }
}