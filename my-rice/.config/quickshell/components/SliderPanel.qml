import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

PanelWindow {
    id: sliderPanel

    anchors { right: true }
    exclusiveZone: 0

    property bool isWide: false

    implicitWidth: isWide ? 234 : 96
    implicitHeight: isFullHeight ? Quickshell.screens[0].height : 220


    margins {
        top: isFullHeight ? 0 : (Quickshell.screens[0].height / 2) - 110
        right: {
            if (sliderPanel.panelExpanded) return Quickshell.screens[0].width * 0.3 + 8
            if (sliderPanel.isHovered) return 8
            return -96
        }
        bottom: 0
    }

    color: "transparent"

    property bool isRotated: false
    property bool isFullHeight: false
    property bool isHovered: false
    property real volume: 0.5
    property real brightness: 0.5
    property bool panelExpanded: false
    property bool expandEnabled: true
    signal expandRequested()
    signal collapseRequested()

    Process {
        id: setVolumeProc
        property string targetVol: "50%"
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", targetVol]
    }

    Process {
        id: setBrightnessProc
        property string targetBright: "50%"
        command: ["brightnessctl", "set", targetBright]
    }

    function setVolume(val) {
        volume = val
        setVolumeProc.targetVol = String(Math.round(val * 100)) + "%"
        setVolumeProc.running = true
    }

    function setBrightness(val) {
        brightness = val
        setBrightnessProc.targetBright = String(Math.round(val * 100)) + "%"
        setBrightnessProc.running = true
    }

    Process {
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                sliderPanel.volume = parseFloat(text.trim()) || 0.5
            }
        }
    }

    Process {
        command: ["bash", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                sliderPanel.brightness = (parseFloat(text.trim()) || 50) / 100
            }
        }
    }

    Item {
        anchors.right: parent.right
        y: (sliderPanel.height - 220) / 2
        width: 96
        height: 220
        transformOrigin: Item.BottomRight
        rotation: isRotated ? -110 : 0

        Behavior on rotation {
            NumberAnimation {
                duration: 700
                easing.type: Easing.OutBounce
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "#24273a"
            border.color: "#363a4f"
            border.width: 1

            HoverHandler {
                onHoveredChanged: sliderPanel.isHovered = hovered
            }

            DragHandler {
                onTranslationChanged: {
                    if (translation.x < -30 && !sliderPanel.panelExpanded && sliderPanel.expandEnabled) {
                        sliderPanel.isFullHeight = true
                        sliderPanel.expandRequested()
                        rotateTimer.start()
                    } else if (translation.x > 30 && sliderPanel.panelExpanded && sliderPanel.isRotated) {
                        sliderPanel.isRotated = false
                        collapseTimer.start()
                    }
                }
            }

            Timer {
                id: collapseTimer
                interval: 900
                repeat: false
                onTriggered: {
                    sliderPanel.collapseRequested()
                    sliderPanel.isWide = false
                    shrinkTimer.start()
                }
            }
            Timer {
                id: shrinkTimer
                interval: 50
                repeat: false
                onTriggered: sliderPanel.isFullHeight = false
            }
            Timer {
                id: rotateTimer
                interval: 300
                repeat: false
                onTriggered: {
                    sliderPanel.isRotated = true
                    sliderPanel.isWide = true
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 16

                Item {
                    width: 36; height: 160

                    Text {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: -18 }
                        text: "🧪"; font.pixelSize: 11
                    }

                    Rectangle {
                        id: volBottle
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
                        width: 28; height: 140
                        radius: 8
                        color: "#1e2030"
                        border.color: "#363a4f"
                        border.width: 1
                        clip: true

                        Rectangle {
                            id: volLiquid
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: parent.height * sliderPanel.volume
                            color: "transparent"
                            clip: true

                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(0.2, 0.5, 1.0, 0.7)
                            }

                            Repeater {
                                model: 5
                                Item {
                                    id: bubble
                                    x: 4 + index * 4 + Math.random() * 8
                                    width: 4 + index % 3 * 2
                                    height: width
                                    property real startY: volLiquid.height * (0.1 + Math.random() * 0.8)

                                    SequentialAnimation on y {
                                        loops: Animation.Infinite
                                        running: true
                                        NumberAnimation {
                                            from: bubble.startY
                                            to: -bubble.height
                                            duration: 1500 + index * 400
                                            easing.type: Easing.InQuad
                                        }
                                        PauseAnimation { duration: 200 + index * 300 }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: Qt.rgba(0.6, 0.8, 1.0, 0.5)
                                        border.color: Qt.rgba(1,1,1,0.3)
                                        border.width: 1
                                    }
                                }
                            }

                            Canvas {
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: 8
                                property real phase: 0
                                NumberAnimation on phase {
                                    from: 0; to: Math.PI * 2
                                    duration: 1500; loops: Animation.Infinite
                                }
                                onPhaseChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.fillStyle = "rgba(100,180,255,0.4)"
                                    ctx.beginPath()
                                    ctx.moveTo(0, height)
                                    for (var x = 0; x <= width; x++) {
                                        ctx.lineTo(x, Math.sin(x * 0.4 + phase) * 2 + 4)
                                    }
                                    ctx.lineTo(width, height)
                                    ctx.closePath()
                                    ctx.fill()
                                }
                            }
                        }

                        Repeater {
                            model: 4
                            Rectangle {
                                x: parent.width - 8
                                y: parent.height * (1 - (index + 1) * 0.25)
                                width: 6; height: 1
                                color: Qt.rgba(1,1,1,0.2)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: 20
                            preventStealing: true
                            onPressed: (mouse) => sliderPanel.setVolume(Math.max(0, Math.min(1, 1 - mouse.y / height)))
                            onPositionChanged: (mouse) => sliderPanel.setVolume(Math.max(0, Math.min(1, 1 - mouse.y / height)))
                        }
                    }

                    Rectangle {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: volBottle.top }
                        width: 14; height: 16
                        color: "#1e2030"
                        border.color: "#363a4f"
                        border.width: 1
                        radius: 3
                    }
                }

                Item {
                    width: 36; height: 160

                    Text {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: -18 }
                        text: "⚗️"; font.pixelSize: 11
                    }

                    Rectangle {
                        id: brightBottle
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
                        width: 28; height: 140
                        radius: 8
                        color: "#1e2030"
                        border.color: "#2a1a3a"
                        border.width: 1
                        clip: true

                        Rectangle {
                            id: brightLiquid
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: parent.height * sliderPanel.brightness
                            color: "transparent"
                            clip: true

                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(0.8, 0.5, 1.0, 0.7)
                            }

                            Repeater {
                                model: 5
                                Item {
                                    id: brightBubble
                                    x: 4 + index * 4 + Math.random() * 8
                                    width: 4 + index % 3 * 2
                                    height: width
                                    property real startY: brightLiquid.height * (0.1 + Math.random() * 0.8)

                                    SequentialAnimation on y {
                                        loops: Animation.Infinite
                                        running: true
                                        NumberAnimation {
                                            from: brightBubble.startY
                                            to: -brightBubble.height
                                            duration: 1500 + index * 400
                                            easing.type: Easing.InQuad
                                        }
                                        PauseAnimation { duration: 200 + index * 300 }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: Qt.rgba(0.9, 0.7, 1.0, 0.5)
                                        border.color: Qt.rgba(1,1,1,0.3)
                                        border.width: 1
                                    }
                                }
                            }

                            Canvas {
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: 8
                                property real phase: 0
                                NumberAnimation on phase {
                                    from: 0; to: Math.PI * 2
                                    duration: 1200; loops: Animation.Infinite
                                }
                                onPhaseChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.fillStyle = "rgba(180,120,255,0.4)"
                                    ctx.beginPath()
                                    ctx.moveTo(0, height)
                                    for (var x = 0; x <= width; x++) {
                                        ctx.lineTo(x, Math.sin(x * 0.4 + phase) * 2 + 4)
                                    }
                                    ctx.lineTo(width, height)
                                    ctx.closePath()
                                    ctx.fill()
                                }
                            }
                        }

                        Repeater {
                            model: 4
                            Rectangle {
                                x: parent.width - 8
                                y: parent.height * (1 - (index + 1) * 0.25)
                                width: 6; height: 1
                                color: Qt.rgba(1,1,1,0.2)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: 20
                            preventStealing: true
                            onPressed: (mouse) => sliderPanel.setBrightness(Math.max(0, Math.min(1, 1 - mouse.y / height)))
                            onPositionChanged: (mouse) => sliderPanel.setBrightness(Math.max(0, Math.min(1, 1 - mouse.y / height)))
                        }
                    }

                    Rectangle {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: brightBottle.top }
                        width: 14; height: 16
                        color: "#1e2030"
                        border.color: "#2a1a3a"
                        border.width: 1
                        radius: 3
                    }
                }
            }
        }
    }
}
