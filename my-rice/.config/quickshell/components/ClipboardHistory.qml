import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../theme"

PanelWindow {
    id: clipWin

    exclusiveZone: 0
    color: "transparent"
    visible: false

    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    HyprlandFocusGrab {
        windows: [clipWin]
        active: clipWin.visible
    }

    property var history: []
    property string searchText: ""
    property int selectedIndex: 0

    property var filteredHistory: {
        if (searchText === "") return history
        return history.filter(item =>
            item.toLowerCase().includes(searchText.toLowerCase())
        )
    }

    onFilteredHistoryChanged: selectedIndex = 0

    function open() {
        selectedIndex = 0
        searchInput.text = ""
        visible = true
        loadProc.running = false
        loadProc.running = true
        Qt.callLater(() => searchInput.forceActiveFocus())
    }

    function close() {
        visible = false
        searchInput.text = ""
    }

    function confirmSelection() {
        if (filteredHistory.length === 0) return
        var selected = filteredHistory[selectedIndex]
        
        var tabIdx = selected.indexOf("\t")
        var id = tabIdx !== -1 ? selected.substring(0, tabIdx) : ""
        
        if (id === "") return 
        
        pasteProc.command = ["bash", "-c", "cliphist decode " + id + " | wl-copy"]
        
        pasteProc.running = false
        pasteProc.running = true
        close()
    }
    
    // Load history dari cliphist
    Process {
        id: loadProc
        command: ["bash", "-c", "cliphist list | head -100"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                clipWin.history = text.trim().split("\n").filter(l => l.length > 0)
            }
        }
    }

    // Paste ke clipboard
    Process {
        id: pasteProc
        command: ["bash", "-c", "echo noop"]
        running: false
    }

    // Backdrop — klik di luar buat tutup
    MouseArea {
        anchors.fill: parent
        onClicked: clipWin.close()
    }

    // Panel utama
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 540
        height: Math.min(contentCol.implicitHeight + 24, 520)
        radius: 16
        color: Colors.panelBg
        border.color: Colors.panelBorder
        border.width: 1

        // Stop klik di panel dari nutup window
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            id: contentCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 8

            // Search bar
            Rectangle {
                width: parent.width
                height: 36
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.06)
                border.color: searchInput.activeFocus ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: 120 } }

                Row {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 10
                    }
                    spacing: 8

                    Text {
                        text: "⌕"
                        font.pixelSize: 15
                        color: Colors.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextField {
                        id: searchInput
                        width: panel.width - 64
                        color: Colors.textPrimary
                        font.pixelSize: 13
                        placeholderText: "Search clipboard..."
                        placeholderTextColor: Qt.rgba(1, 1, 1, 0.25)
                        anchors.verticalCenter: parent.verticalCenter
                        background: null
                        onTextChanged: clipWin.searchText = text

                        Keys.onUpPressed: {
                            if (clipWin.selectedIndex > 0)
                                clipWin.selectedIndex--
                            listView.positionViewAtIndex(clipWin.selectedIndex, ListView.Contain)
                        }
                        Keys.onDownPressed: {
                            if (clipWin.selectedIndex < clipWin.filteredHistory.length - 1)
                                clipWin.selectedIndex++
                            listView.positionViewAtIndex(clipWin.selectedIndex, ListView.Contain)
                        }
                        Keys.onReturnPressed: clipWin.confirmSelection()
                        Keys.onEscapePressed: clipWin.close()
                    }
                }
            }

            // Counter
            Text {
                text: clipWin.filteredHistory.length + " item" + (clipWin.filteredHistory.length !== 1 ? "s" : "")
                font.pixelSize: 10
                color: Colors.textSecondary
                leftPadding: 2
            }

            // List
            ListView {
                id: listView
                width: parent.width
                height: Math.min(clipWin.filteredHistory.length * 44, 420)
                clip: true
                model: clipWin.filteredHistory

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    width: listView.width
                    height: 40
                    radius: 8
                    color: index === clipWin.selectedIndex
                        ? Qt.rgba(1, 1, 1, 0.1)
                        : hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent"

                    property bool hovered: false

                    Behavior on color { ColorAnimation { duration: 80 } }

                    Row {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 8

                        // Index number
                        Text {
                            text: (index + 1) + "."
                            font.pixelSize: 10
                            color: Colors.textSecondary
                            width: 20
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Content preview
                        Text {
                            text: {
                                var raw = modelData
                                // cliphist format: "ID\tcontent"
                                var tabIdx = raw.indexOf("\t")
                                if (tabIdx !== -1) raw = raw.substring(tabIdx + 1)
                                return raw.replace(/\n/g, " ").trim()
                            }
                            font.pixelSize: 12
                            color: index === clipWin.selectedIndex ? Colors.textPrimary : Qt.rgba(1, 1, 1, 0.75)
                            elide: Text.ElideRight
                            width: parent.width - 28
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    HoverHandler {
                        onHoveredChanged: parent.hovered = hovered
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            clipWin.selectedIndex = index
                            clipWin.confirmSelection()
                        }
                    }
                }
            }

            // Empty state
            Text {
                visible: clipWin.filteredHistory.length === 0
                text: clipWin.searchText === "" ? "No clipboard history" : "No results for \"" + clipWin.searchText + "\""
                font.pixelSize: 12
                color: Colors.textSecondary
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 12
                bottomPadding: 12
            }
        }
    }
}
