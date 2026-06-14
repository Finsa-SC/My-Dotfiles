import Quickshell.Io
import QtQuick

QtObject {
    property string scriptName: ""
    property string processDir: ""
    property bool shouldRun: true

    property var proc: Process {
        command: ["bash", processDir + "/" + scriptName]
        running: true
        onExited: {
            if (shouldRun) restartTimer.restart()
        }
    }

    property var restartTimer: Timer {
        interval: 2000
        repeat: false
        onTriggered: {
            proc.running = false
            proc.running = true
        }
    }
}