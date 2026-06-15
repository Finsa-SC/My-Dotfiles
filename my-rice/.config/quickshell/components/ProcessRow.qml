import QtQuick

// ─────────────────────────────────────────────
//  ProcessRow
//  One line process: [name] [SERVICE/ONESHOT toggle] [RUN/STOP button]
// ─────────────────────────────────────────────
Item {
    id: row

    property string scriptName: ""
    property string stateType: "oneshot"   // "service" | "oneshot"
    property bool   isRunning: false

    signal toggleType()
    signal run()
    signal stop()

    implicitWidth: parent ? parent.width : 380
    implicitHeight: 44

    // ── Background
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: row.isRunning ? "#0a1f10" : "#24273a"
        border.color: row.isRunning ? "#1a4020" : "#363a4f"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }
    }

    // ── Running indicator strip (left)
    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        anchors.leftMargin: 0
        width: 2
        radius: 1
        color: row.isRunning ? "#a6da95" : "transparent"
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // ── Script name
    Row {
        id: nameRow
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        width: 140

        Text {
            id: nameText
            text: row.scriptName.replace(".sh","")
            font.pixelSize: 11
            font.letterSpacing: 0.5
            color: row.isRunning ? "#a6da95" : "#a5adcb"
            elide: Text.ElideRight
            maximumLineCount: 1
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Rectangle {
            id: statusDot
            width: 5; height: 5; radius: 3
            color: "#a6da95"
            visible: row.isRunning
            anchors.verticalCenter: parent.verticalCenter
            opacity: blinkAnim.running ? blinkOpacity : 1

            property real blinkOpacity: 1
            SequentialAnimation on blinkOpacity {
                id: blinkAnim
                running: row.isRunning && row.stateType === "service"
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }
        }
    }

    // ── Type toggle pill: SERVICE / ONESHOT
    Rectangle {
        id: typePill
        anchors.right: runBtn.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 68
        height: 20
        radius: 10
        color: row.stateType === "service" ? "#0f2535" : "#181820"
        border.color: row.stateType === "service" ? "#a5adcb" : "#363a4f"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: row.stateType === "service" ? "SERVICE" : "ONESHOT"
            font.pixelSize: 7
            font.letterSpacing: 1.5
            color: row.stateType === "service" ? "#2a7ab0" : "#304040"

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.toggleType()
        }
    }

    // ── Run / Stop button
    Rectangle {
        id: runBtn
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 52
        height: 26
        radius: 6
        color: {
            if (btnArea.pressed) return row.isRunning ? "#3a1010" : "#0f3020"
            if (btnArea.containsMouse) return row.isRunning ? "#2a1515" : "#0f2a18"
            return row.isRunning ? "#1a0a0a" : "#0a1a10"
        }
        border.color: row.isRunning ? "#ed8796" : "#226633"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        // Drag indicator
        property bool isDragging: false
        property real dragStartX: 0
        readonly property int dragThreshold: 36
        property real dragProgress: 0

        Text {
            anchors.centerIn: parent
            text: row.isRunning ? "STOP" : "RUN"
            font.pixelSize: 8
            font.letterSpacing: 1.5
            color: row.isRunning ? "#ed8796" : "#a6da95"

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Drag-to-confirm overlay
        Rectangle {
            id: dragFill
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: runBtn.dragProgress * parent.width
            radius: parent.radius
            color: row.isRunning ? "#aa222220" : "#22aa5520"
            clip: true
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true

            onPressed: (mouse) => {
                runBtn.isDragging = true
                runBtn.dragStartX = mouse.x
                runBtn.dragProgress = 0
            }

            onPositionChanged: (mouse) => {
                if (!runBtn.isDragging) return
                if (!row.isRunning) {
                    // right drag = confirm run
                    let delta = mouse.x - runBtn.dragStartX
                    runBtn.dragProgress = Math.max(0, Math.min(delta / runBtn.dragThreshold, 1.0))
                } else {
                    // left drag = confirm stop
                    let delta = runBtn.dragStartX - mouse.x
                    runBtn.dragProgress = Math.max(0, Math.min(delta / runBtn.dragThreshold, 1.0))
                }
            }

            onReleased: (mouse) => {
                if (runBtn.dragProgress >= 1.0) {
                    if (!row.isRunning) row.run()
                    else row.stop()
                } else if (!runBtn.isDragging || Math.abs(mouse.x - runBtn.dragStartX) < 4) {
                    if (!row.isRunning) row.run()
                    else row.stop()
                }
                runBtn.isDragging = false
                runBtn.dragProgress = 0
            }

            onCanceled: {
                runBtn.isDragging = false
                runBtn.dragProgress = 0
            }
        }
    }
}
