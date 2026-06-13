import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

PanelWindow {
    id: appDrawer
    exclusiveZone: 0
    implicitWidth: Quickshell.screens[0].width * 0.3 + 300
    color: "transparent"
    visible: false

    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        bottom: true
    }

    margins {
        left: 46
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [appDrawer]
        active: appDrawer.visible
    }

    property bool isOpen: false
    property string searchText: ""
    property var pinnedApps: ["kitty", "zen-browser", "dolphin", "code"]
    property var allApps: []

    // Slide animation
    property real slideOffset: -implicitWidth

    NumberAnimation on slideOffset {
        id: slideIn
        to: 0
        duration: 300
        easing.type: Easing.OutQuart
        running: false
    }

    NumberAnimation on slideOffset {
        id: slideOut
        to: -(Quickshell.screens[0].width * 0.3 + 300)  // tambah ini
        duration: 250
        easing.type: Easing.InQuart
        running: false
        onFinished: appDrawer.visible = false  // hapus imageWindow
    }

    function open() {
        isOpen = true
        slideOffset = -(Quickshell.screens[0].width * 0.3 + 300)
        visible = true
        slideIn.running = true
        Qt.callLater(function() { searchInput.forceActiveFocus() })
    }

    function close() {
        isOpen = false
        slideOut.running = true
    }

    // Load .desktop files
    Process {
    id: appListProc
    command: ["bash", "-c", "for f in /usr/share/applications/*.desktop; do name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2); icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2); exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2 | sed 's/ .*//'); nodisplay=$(grep -m1 '^NoDisplay=' \"$f\" | cut -d= -f2); if [ -n \"$name\" ] && [ -n \"$exec\" ] && [ \"$nodisplay\" != \"true\" ]; then echo \"$name|$icon|$exec\"; fi; done | sort"]
    running: true
    stdout: StdioCollector {
        onStreamFinished: {
            appDrawer.allApps = text.trim().split("\n")
                .filter(a => a.length > 0)
                .map(a => {
                    var parts = a.split("|")
                    return { name: parts[0], icon: parts[1], exec: parts[2] }
                })
            }
        }
    }

    // Main container
    Item {
        id: container
        enabled: appDrawer.visible
        x: appDrawer.slideOffset
        height: parent.height
        width: drawerRect.width + image.width

        // Close kalau klik di luar
        Keys.onEscapePressed: appDrawer.close()

        Rectangle {
            id: drawerRect
            width: Quickshell.screens[0].width * 0.3
            height: parent.height
            color: "#1e1e1e"
            border.color: Colors.panelBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // ─── Search bar ───
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: Qt.rgba(1,1,1,0.08)
                    border.color: searchInput.activeFocus ? Qt.rgba(1,1,1,0.4) : Qt.rgba(1,1,1,0.1)
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        spacing: 8

                        Text {
                            text: "🔍"
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextField {
                            id: searchInput
                            width: parent.parent.width - 50
                            color: Colors.textPrimary
                            font.pixelSize: 12
                            placeholderText: "Search apps..."
                            placeholderTextColor: Qt.rgba(1,1,1,0.3)
                            anchors.verticalCenter: parent.verticalCenter
                            background: null
                            onTextChanged: appDrawer.searchText = text
                        }
                    }
                }

                // ─── Pinned section ───
                Text {
                    text: "Pinned"
                    font.pixelSize: 10
                    font.bold: true
                    color: Colors.textSecondary
                    visible: searchText === ""
                }

                Grid {
                    columns: 4
                    spacing: 8
                    visible: searchText === ""
                    width: parent.width

                    Repeater {
                        model: appDrawer.pinnedApps
                        delegate: AppItem {
                            appName: modelData.name ?? modelData
                            appIcon: modelData.icon ?? modelData
                            appExec: modelData.exec ?? modelData
                            itemWidth: (Quickshell.screens[0].width * 0.3 - 48) / 4
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(1,1,1,0.08)
                    visible: searchText === ""
                }

                // ─── All apps section ───
                Text {
                    text: searchText === "" ? "All Apps" : "Results"
                    font.pixelSize: 10
                    font.bold: true
                    color: Colors.textSecondary
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Grid {
                        columns: 4
                        spacing: 8

                        Repeater {
                            model: appDrawer.allApps.filter(a =>
                                searchText === "" || a.name.toLowerCase().includes(searchText.toLowerCase())
                            )
                            delegate: AppItem {
                                appName: modelData.name
                                appIcon: modelData.icon
                                appExec: modelData.exec
                                itemWidth: (Quickshell.screens[0].width * 0.3 - 48) / 4
                            }
                        }
                    }
                }
            }
        }

        Image {
            id: image
            anchors.left: drawerRect.right
            anchors.leftMargin: -37
            width: 332
            height: parent.height
            fillMode: Image.PreserveAspectCrop
            source: "file:///home/silence-suzuka/Downloads/shower-suzuka.png"
        }
    }
}