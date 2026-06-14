import Quickshell.Io
import QtQuick

Process {
    property string scriptName: ""
    property string processDir: ""
    command: ["bash", processDir + "/" + scriptName]
    running: true
    signal finished()
    onExited: finished()
}