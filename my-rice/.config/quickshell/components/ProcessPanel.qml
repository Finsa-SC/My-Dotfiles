import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

PanelWindow {
    id: processPanel

    anchors { top: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    implicitWidth: 420
    implicitHeight: panelContent.implicitHeight + 24

    property bool _open: false
    readonly property int panelHeight: panelContent.implicitHeight + 24

    margins.left: (Quickshell.screens[0].width / 2) - 210
    margins.top: _open ? 0 : -(panelHeight + 10)

    Behavior on margins.top {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }

    function open()  { _open = true  }
    function close() { _open = false }

    property string processDir: Quickshell.shellDir + "/processes"
    property var processState: ({})
    property var serviceProcesses: ({})

    signal stateChanged()

    // ── Notify
    function notify(title, body) {
        Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["notify-send", "-a", "Quickshell", "-t", "2000", "` + title + `", "` + body + `"]
                running: true
                onExited: destroy()
            }
        `, processPanel, "Notif")
    }

    // ── Auto-start services saat boot
    function autoStartServices() {
        for (let k in processState) {
            let entry = processState[k]
            if (entry.type === "service" && entry.running) {
                let s = Object.assign({}, processState)
                s[k].running = false
                processPanel.processState = s
                runScript(k)
            }
        }
    }

    // ── Model
    ListModel { id: scriptModel }

    // ── Scan
    Process {
        id: scanProc
        command: ["bash", "-c",
            "mkdir -p " + processPanel.processDir +
            " && find " + processPanel.processDir +
            " -maxdepth 1 -name '*.sh' | sort | while read f; do basename \"$f\"; done"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let name = data.trim()
                if (name.length === 0) return
                scriptModel.append({ name: name })
                if (!processPanel.processState[name]) {
                    let s = processPanel.processState
                    s[name] = { type: "oneshot", running: false }
                    processPanel.processState = s
                }
            }
        }
        onExited: loadConfig.running = true
    }

    // ── Load config
    Process {
        id: loadConfig
        command: ["bash", "-c", "cat " + Quickshell.shellDir + "/qs-processes.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    let saved = JSON.parse(data.trim())
                    let s = processPanel.processState
                    for (let k in saved) {
                        if (s[k]) {
                            s[k].type = saved[k].type || "oneshot"
                            s[k].running = saved[k].running || false
                        }
                    }
                    processPanel.processState = Object.assign({}, s)
                    stateChanged()
                    autoStartServices()
                } catch(e) { console.log("loadConfig error: " + e) }
            }
        }
    }

    // ── Save config
    function saveConfig() {
        let out = {}
        for (let k in processState) {
            out[k] = {
                type: processState[k].type,
                running: processState[k].type === "service" ? processState[k].running : false
            }
        }
        let json = JSON.stringify(out)
        saveProc.command = ["bash", "-c", "echo '" + json + "' > " + Quickshell.shellDir + "/qs-processes.json"]
        saveProc.running = false
        saveProc.running = true
    }
    Process { id: saveProc; command: ["bash", "-c", "echo noop"]; running: false }

    // ── Toggle type
    function toggleType(name) {
        let s = processState
        if (!s[name]) return
        if (s[name].running) stopScript(name)
        s[name].type = s[name].type === "service" ? "oneshot" : "service"
        processPanel.processState = Object.assign({}, s)
        stateChanged()
        saveConfig()
        notify("⚙ " + name.replace(".sh",""),
            processState[name].type === "service" ? "Set to SERVICE" : "Set to ONESHOT")
    }

    // ── Run script — cek password dulu
    function runScript(name) {
        doRunScript(name)
    }

    // ── Core run logic
    function doRunScript(name) {
        let s = processState
        if (!s[name]) return

        if (s[name].type === "oneshot") {
            let comp = Qt.createComponent("OneshotRunner.qml")
            if (comp.status === Component.Ready) {
                let obj = comp.createObject(processPanel, {
                    scriptName: name,
                    processDir: processPanel.processDir
                })
                notify("▶ " + name.replace(".sh",""), "Running...")
                obj.finished.connect(() => {
                    let ss = Object.assign({}, processPanel.processState)
                    if (ss[name]) ss[name].running = false
                    processPanel.processState = ss
                    processPanel.stateChanged()
                    processPanel.saveConfig()
                    processPanel.notify("✓ " + name.replace(".sh",""), "Finished")
                    obj.destroy()
                })
            }
        } else {
            let comp = Qt.createComponent("ServiceRunner.qml")
            if (comp.status === Component.Ready) {
                let obj = comp.createObject(processPanel, {
                    scriptName: name,
                    processDir: processPanel.processDir
                })
                let sp = Object.assign({}, serviceProcesses)
                sp[name] = obj
                serviceProcesses = sp
                notify("▶ " + name.replace(".sh",""), "Service started")
            } else {
                console.log("ServiceRunner error: " + comp.errorString())
                return
            }
        }

        s[name].running = true
        processPanel.processState = Object.assign({}, s)
        stateChanged()
        saveConfig()
    }

    // ── Stop script
    function stopScript(name) {
        let s = processState
        if (!s[name]) return

        let sp = serviceProcesses
        if (sp[name]) {
            sp[name].shouldRun = false
            sp[name].restartTimer.stop()
            sp[name].proc.running = false
            sp[name].destroy()
            let sp2 = Object.assign({}, sp)
            delete sp2[name]
            serviceProcesses = sp2
            notify("■ " + name.replace(".sh",""), "Service stopped")
        } else {
            Qt.createQmlObject(`
                import Quickshell.Io
                Process {
                    command: ["pkill", "-f", "` + name + `"]
                    running: true
                    onExited: destroy()
                }
            `, processPanel, "KillProc_" + name)
            notify("■ " + name.replace(".sh",""), "Stopped")
        }

        s[name].running = false
        processPanel.processState = Object.assign({}, s)
        stateChanged()
        saveConfig()
    }

    // ── UI
    Rectangle {
        id: panelContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: headerRow.height + listCol.implicitHeight + 32
        color: "#24273a"

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1; color: "#363a4f"
        }
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 1; color: "#363a4f"
        }
        Rectangle {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: 1; color: "#363a4f"
        }

        Row {
            id: headerRow
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors.topMargin: 12
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 28

            Text {
                text: "PROCESSES"
                font.pixelSize: 9
                font.letterSpacing: 3
                color: "#2a6090"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: scriptModel.count + " scripts"
                font.pixelSize: 8
                color: "#363a4f"
                font.letterSpacing: 1
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right }
            anchors.top: headerRow.bottom
            anchors.topMargin: 4
            height: 1; color: "#1e2030"
        }

        Column {
            id: listCol
            anchors {
                top: headerRow.bottom
                left: parent.left; right: parent.right
                topMargin: 12; leftMargin: 12
                rightMargin: 12; bottomMargin: 12
            }
            spacing: 6

            property int _tick: 0
            Connections {
                target: processPanel
                function onStateChanged() { listCol._tick++ }
            }

            Repeater {
                model: scriptModel
                delegate: ProcessRow {
                    required property var model
                    scriptName: model.name
                    stateType: {
                        listCol._tick
                        return processPanel.processState[model.name]?.type ?? "oneshot"
                    }
                    isRunning: {
                        listCol._tick
                        return processPanel.processState[model.name]?.running ?? false
                    }
                    onToggleType: processPanel.toggleType(model.name)
                    onRun: processPanel.runScript(model.name)
                    onStop: processPanel.stopScript(model.name)
                }
            }

            Text {
                visible: scriptModel.count === 0
                text: "No scripts found in " + processPanel.processDir
                font.pixelSize: 10
                color: "#363a4f"
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 12
                bottomPadding: 12
            }
        }
    }
}