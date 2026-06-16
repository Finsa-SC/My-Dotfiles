import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

PanelWindow {
    id: sideBar

    anchors {
        top: true
        left: true
        bottom: true
    }

    implicitWidth: 46
    exclusiveZone: 28
    color: "transparent"

    // Datetime interval
    property var now: new Date()

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: sideBar.now = new Date()
    }

    property int batteryLevel: 100
    property bool wsExpanded: false

    // ─── Workspace pill ───
    Rectangle {
        id: wsPill
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }
        anchors.topMargin: 16
        width: 38; height: 38
        radius: 10
        color: Colors.panelBg
        border.color: Colors.panelBorder
        border.width: 1

        Item {
            anchors.centerIn: parent
            width: 26; height: 26
            opacity: sideBar.wsExpanded ? 0 : 1

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 8; height: 8; radius: 2
                color: Colors.wsActive
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: 6; height: 6; radius: 2
                color: {
                    if (!Hyprland.focusedWorkspace) return "transparent"
                    return Hyprland.focusedWorkspace.id > 5 ? Colors.wsBg : "transparent"
                }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 6; height: 6; radius: 2
                color: {
                    if (!Hyprland.focusedWorkspace) return "transparent"
                    return Hyprland.focusedWorkspace.id <= 20 ? Colors.wsBg : "transparent"
                }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: 6; height: 6; radius: 2
                color: {
                    if (!Hyprland.focusedWorkspace) return "transparent"
                    return (Hyprland.focusedWorkspace.id - 1) % 5 !== 0 ? Colors.wsBg : "transparent"
                }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                width: 6; height: 6; radius: 2
                color: {
                    if (!Hyprland.focusedWorkspace) return "transparent"
                    return Hyprland.focusedWorkspace.id % 5 !== 0 ? Colors.wsBg : "transparent"
                }
            }
        }
    }

    Rectangle {
        id: pentestPill
        anchors {
            top: wsPill.bottom
            horizontalCenter: parent.horizontalCenter
        }
        anchors.topMargin: 8
        width: 38; height: 38
        radius: 12
        color: Colors.panelBg
        border.color: Colors.panelBorder
        border.width: 1


        Text {
            anchors.centerIn: parent
            text: "⚘"
            font.pixelSize: 24
            color: modePill.currentMode === "full" ? "#e05c5c" : '#936d6d'
        }
        opacity: modePill.currentMode === "full" ? 1.0 : 0.5
        Behavior on opacity { NumberAnimation { duration: 300 } }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: togglePentest.running = !togglePentest.running
        }

        Process {
            id: togglePentest
            command: ["bash", "-c", "qs ipc call pentest toggle"]
            running: false
        }
    }

    // ─── Clock pill ───
    Rectangle {
        anchors {
            top: pentestPill.bottom
            horizontalCenter: parent.horizontalCenter
        }
        anchors.topMargin: 8
        width: 38; height: 72
        radius: 12
        color: Colors.panelBg
        border.color: Colors.panelBorder
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(sideBar.now, "HH")
                font.pixelSize: 13; font.bold: true
                color: Colors.textPrimary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(sideBar.now, "mm")
                font.pixelSize: 13; font.bold: true
                color: Colors.textPrimary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(sideBar.now, "ddd")
                font.pixelSize: 9
                color: Colors.textSecondary
            }
        }

        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: { }
        }
    }

    // ─── Mode pill ───
    Rectangle {
        id: modePill
        anchors {
            bottom: batteryPill.top
            bottomMargin: 8
            horizontalCenter: parent.horizontalCenter
        }
        anchors.topMargin: 8
        width: 38; height: 38
        radius: 12
        color: Colors.panelBg
        border.color: Colors.panelBorder
        border.width: 1

        property string currentMode: "full"
        property bool simple: modePill.currentMode === "minimal"

        Process {
            id: readModeProc
            command: ["bash", "-c", "cat $HOME/.cache/qs-mode 2>/dev/null || echo full"]
            running: true
            stdout: SplitParser {
                onRead: data => {
                    let m = data.trim()
                    if (m === "full" || m === "basic" || m === "minimal")
                        modePill.currentMode = m
                }
            }
        }

        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                readModeProc.running = false
                readModeProc.running = true
            }
        }

        Text {
            anchors.centerIn: parent
            text: modePill.currentMode === "full" ? "◆"
                : modePill.currentMode === "basic" ? "❖"
                : "◇"
            font.pixelSize: 16
            color: modePill.currentMode === "full" ? "#8aadf4"
                : modePill.currentMode === "basic" ? "#eed49f"
                : "#6e738d"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                var next = modePill.currentMode === "minimal" ? "basic"
                    : modePill.currentMode === "basic" ? "full"
                    : "minimal"
                modeSetProc.command = ["bash", "-c",
                    "qs ipc -p $HOME/.config/quickshell call mode set " + next
                ]
                modeSetProc.running = false
                modeSetProc.running = true
            }
        }

        Process {
            id: modeSetProc
            command: ["bash", "-c", "echo noop"]
            running: false
            onRunningChanged: {
                if (!running) {
                    readModeProc.running = false
                    readModeProc.running = true
                }
            }
        }
    }

    // ─── Battery pill ───
    Rectangle {
        id: batteryPill
        anchors {
            bottom: powerPill.top
            horizontalCenter: parent.horizontalCenter
        }
        anchors.bottomMargin: 8
        width: 38
        height: 100
        radius: 12
        color: Colors.panelBg
        border.color: Colors.panelBorder
        border.width: 1
        layer.enabled: true

        property bool initialLoad: true
        property bool isCharging: false
        property color surgeColor: '#90f4ff'
        property bool simple: modePill.currentMode === "minimal"

        property bool triggerLightning: false
        Timer {
            id: lightningGlitchTimer
            interval: Math.random() * 800 + 200
            running: batteryPill.isCharging
            repeat: true
            onTriggered: {
                batteryPill.triggerLightning = Math.random() > 0.4
                lightningResetTimer.start()
            }
        }

        Timer {
            id: lightningResetTimer
            interval: 80
            onTriggered: {
                batteryPill.triggerLightning = false
                waveCanvas.requestPaint()
            }
        }

        // Charging reader
        FileView {
            id: chargingFile
            path: "/sys/class/power_supply/ADP1/online"
            onLoaded: {
                batteryPill.isCharging = parseInt(chargingFile.text()) === 1
            }
            Component.onCompleted: reload()
        }

        Timer {
            interval: 5000; running: true; repeat: true
            onTriggered: chargingFile.reload()
        }

        // Wave animation
        property real waveOffset: 0
        NumberAnimation on waveOffset {
            running: !batteryPill.simple
            from: 0; to: Math.PI * 2
            duration: 4000
            loops: Animation.Infinite
        }

        property real chargeProgress: 0
        NumberAnimation on chargeProgress {
            from: 0; to: 1.0
            duration: 2500
            loops: Animation.Infinite
            running: batteryPill.isCharging && !batteryPill.simple
        }

        Canvas {
            id: waveCanvas
            anchors.fill: parent

            property real fillHeight: batteryPill.height * (sideBar.batteryLevel / 100)
            property color fillColor: batteryPill.isCharging ? "#8aadf4"
                : sideBar.batteryLevel < 20 ? Colors.batteryLow
                : sideBar.batteryLevel < 50 ? "#eed49f"
                : Colors.batteryOk

                Behavior on fillHeight {
                    enabled: !batteryPill.initialLoad
                    NumberAnimation { duration: 600; easing.type: Easing.OutQuart }
                }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                // Rounded clip
                var r = 12
                ctx.beginPath()
                ctx.moveTo(r, 0)
                ctx.lineTo(width - r, 0)
                ctx.arcTo(width, 0, width, r, r)
                ctx.lineTo(width, height - r)
                ctx.arcTo(width, height, width - r, height, r)
                ctx.lineTo(r, height)
                ctx.arcTo(0, height, 0, height - r, r)
                ctx.lineTo(0, r)
                ctx.arcTo(0, 0, r, 0, r)
                ctx.closePath()
                ctx.clip()

                if (batteryPill.simple) {
                    ctx.fillStyle = Qt.rgba(waveCanvas.fillColor.r, waveCanvas.fillColor.g, waveCanvas.fillColor.b, 0.85)
                    ctx.fillRect(0, height - waveCanvas.fillHeight, width, waveCanvas.fillHeight)
                } else {

                    var y0 = height - fillHeight
                    var amp = 2
                    var freq = 0.4

                    // Wave 1
                    ctx.beginPath()
                    ctx.moveTo(0, height)
                    ctx.lineTo(0, y0 + amp * Math.sin(batteryPill.waveOffset))
                    for (var x = 0; x <= width; x++) {
                        var wx = batteryPill.waveOffset + (x / width) * Math.PI * 2 * freq
                        ctx.lineTo(x, y0 + amp * Math.sin(wx))
                    }
                    ctx.lineTo(width, height)
                    ctx.closePath()
                    ctx.fillStyle = Qt.rgba(fillColor.r, fillColor.g, fillColor.b, 0.85)
                    ctx.fill()

                    // Wave 2
                    ctx.beginPath()
                    ctx.moveTo(0, height)
                    ctx.lineTo(0, y0 + amp * Math.sin(batteryPill.waveOffset + 1))
                    for (var x2 = 0; x2 <= width; x2++) {
                        var wx2 = batteryPill.waveOffset + 1 + (x2 / width) * Math.PI * 2 * freq
                        ctx.lineTo(x2, y0 + amp * Math.sin(wx2))
                    }
                    ctx.lineTo(width, height)
                    ctx.closePath()
                    ctx.fillStyle = Qt.rgba(fillColor.r, fillColor.g, fillColor.b, 0.4)
                    ctx.fill()

                    // Wafe extra: charging surge
                    if (batteryPill.isCharging) {
                        var surgeY = height - (fillHeight * batteryPill.chargeProgress)
                        
                        ctx.beginPath()
                        ctx.moveTo(0, height)
                        ctx.lineTo(0, surgeY + (amp * 1.5) * Math.sin(batteryPill.waveOffset * 2))
                        for (var xs = 0; xs <= width; xs++) {
                            var wxs = (batteryPill.waveOffset * 2) + (xs / width) * Math.PI * 2 * (freq * 1.2)
                            ctx.lineTo(xs, surgeY + (amp * 1.5) * Math.sin(wxs))
                        }
                        ctx.lineTo(width, height)
                        ctx.closePath()
                        
                        var fadeFactor = 0.4 * (1.0 - batteryPill.chargeProgress)
                        ctx.fillStyle = Qt.rgba(batteryPill.surgeColor.r, batteryPill.surgeColor.g, batteryPill.surgeColor.b, fadeFactor)
                        ctx.fill()
                    }

                    if (batteryPill.isCharging && batteryPill.triggerLightning) {
                        ctx.save()
                        
                        var curY = 0
                        var curX = (width / 2) + (Math.random() * 10 - 5)
                        var targetY = height
                        
                        ctx.beginPath()
                        ctx.moveTo(curX, curY)
                        
                        while (curY < targetY) {
                            curY += Math.random() * 12 + 6 // Jarak lompatan vertikal patahan petir
                            if (curY > targetY) curY = targetY
                        
                            var glitchFactor = (Math.random() > 0.85) ? 14 : 5
                            curX += (Math.random() * (glitchFactor * 2) - glitchFactor)
                        
                            if (curX < 4) curX = 4
                            if (curX > width - 4) curX = width - 4
                            
                            ctx.lineTo(curX, curY)
                        }

                        // Render Efek Glow Luar Petir
                        ctx.lineWidth = 3.5
                        ctx.strokeStyle = Qt.rgba(0, 0.9, 1.0, 0.4)
                        ctx.lineJoin = "miter"
                        ctx.stroke()

                        // Render Inti Dalam Petir
                        ctx.lineWidth = 1.2
                        ctx.strokeStyle = "#ffffff"
                        ctx.stroke()
                        
                        ctx.restore()
                    }
                }
            }

            Connections {
                target: batteryPill
                function onWaveOffsetChanged() { waveCanvas.requestPaint() }
                function onChargeProgressChanged() { waveCanvas.requestPaint() }
                function onTriggerLightningChanged() { waveCanvas.requestPaint() }
            }
            Connections {
                target: sideBar
                function onBatteryLevelChanged() { waveCanvas.requestPaint() }
            }
            Connections {
                target: modePill
                function onCurrentModeChanged() { waveCanvas.requestPaint() }
            }
        }

        FileView {
            id: batteryFile
            path: "/sys/class/power_supply/BAT0/capacity"
            onLoaded: {
                var val = parseInt(batteryFile.text())
                if (!isNaN(val) && val >= 0 && val <= 100) {
                    sideBar.batteryLevel = val
                    batteryPill.initialLoad = false
                }
            }
            Component.onCompleted: reload()
        }

        Timer {
            interval: 30000; running: true; repeat: true
            onTriggered: batteryFile.reload()
        }

        // Teks persentase
        Text {
            anchors.centerIn: parent
            text: sideBar.batteryLevel + "%"
            font.pixelSize: 9
            font.bold: true
            color: Colors.textPrimary
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.5)
            z: 10
        }
    }

    // ─── Power pill ───
    Rectangle {
        id: powerPill
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        anchors.bottomMargin: 16
        width: 38; height: 38
        radius: 12
        color: Colors.panelBg
        border.color: Colors.panelBorder
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "⏻"
            font.pixelSize: 16
            color: Colors.textPrimary
        }

        MouseArea {
            anchors.fill: parent
            onClicked: powerMenuPopup.visible = !powerMenuPopup.visible
            cursorShape: Qt.PointingHandCursor
        }
    }

    // ─── Workspace grid popup ───
    PopupWindow {
        id: wsPopup
        anchor.window: sideBar
        anchor.rect.x: 46 + 8
        anchor.rect.y: 16
        implicitWidth: 140
        implicitHeight: 140
        visible: sideBar.wsExpanded
        color: "transparent"

        Connections {
            target: Hyprland
            function onFocusedWorkspaceChanged() {
                sideBar.wsExpanded = true
                collapseTimer.restart()
            }
        }

        Timer {
            id: collapseTimer
            interval: 3000
            onTriggered: sideBar.wsExpanded = false
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

    // Tambah setelah wsPopup
    PowerMenu {
        id: powerMenuPopup
    }
}