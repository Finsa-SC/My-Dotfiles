import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root
    anchors { bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    implicitHeight: (_open || slidingContainer.y < panelHeight) ? panelHeight + tabHeight : 0
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property bool everOpened: false

    readonly property int panelHeight: 260
    readonly property int tabHeight:   44
    property bool _open: false

    function open()   { everOpened = true; _open = true  }
    function close()  { _open = false }
    function toggle() { _open ? close() : open() }

    visible: everOpened

    // ── data (bind ke IPC / proc / sensors) ─────────────────────────────
    property int    gpuPct:     0
    property int    cpuPct:     0
    property int    tmpCpu:     0
    property int    tmpGpu:     0
    property var    coreData:   []
    property int    ramPct:     0
    property int    ramUsedGb:  0
    property int    ramTotalGb: 0
    property int    diskPct:    0
    property int    swapPct:    0
    property real   loadAvg:    0.0
    property string uptime:     "..."
    property int    procs:      0
    property string kernelVer:  "..."
    property int    netUp:      0
    property int    netDown:    0
    property int    activeTcp:  0
    property string pubIp:      "..."
    property bool   vpnActive:  false
    property string iface:      "..."
    property bool   wifiOn:     false
    property bool   btOn:       false
    property bool   nightMode:  false
    property bool   notifOn:    true
    property int batPct: 0
    property string batStatus: "..."
    property int diskRead:  0
    property int diskWrite: 0
    Behavior on cpuPct    { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on ramPct    { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on diskPct   { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on swapPct   { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on gpuPct    { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on tmpCpu    { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on tmpGpu    { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on loadAvg   { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on batPct    { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
    

    Process {
        id: ipProc
        command: ["bash", "-c", "curl -s --max-time 5 ifconfig.me 2>/dev/null || echo '?.?.?.?'"]
        stdout: SplitParser {
            onRead: data => {
                var ip = data.trim()
                if (!ip) return
                if (ip.indexOf(":") !== -1) {
                    // IPv6 — mask 4 group terakhir
                    var p = ip.split(":")
                    root.pubIp = p.slice(0, 4).join(":") + ":x:x:x:x"
                } else {
                    // IPv4 — mask 2 oktet terakhir
                    var p = ip.split(".")
                    root.pubIp = p.length === 4 ? p[0] + "." + p[1] + ".x.x" : ip
                }
            }
        }
    }

    // Fetch IP sekali saat startup
    Component.onCompleted: ipProc.running = true

    // Re-fetch hanya ketika vpnActive berubah
    onVpnActiveChanged: {
        ipProc.running = false
        ipProc.running = true
    }

    // ── Live data via Process ────────────────────────────────────────────
    Process {
        id: dataProc
        command: ["bash", "-c", "while true; do
            grep -m1 '^cpu ' /proc/stat | awk '{printf \"CPU %s %s\\n\",$2+$4,$2+$3+$4+$5}'
            grep '^cpu[0-9]' /proc/stat | awk '{printf \"CORE %s %s\\n\",$2+$4,$2+$3+$4+$5}'
            awk '/nvme0n1 /{printf \"DISKIO %s %s\\n\",$6,$10}' /proc/diskstats
            printf 'TCPU %.0f\n' $(( $(cat /sys/class/hwmon/hwmon4/temp1_input) / 1000 ))
            printf 'TGPU %.0f\n' $(( $(cat /sys/class/hwmon/hwmon3/temp1_input) / 1000 ))
            cat /sys/class/power_supply/BAT0/capacity 2>/dev/null | awk '{printf \"BAT %s\\n\",$1}'
            cat /sys/class/power_supply/BAT0/status 2>/dev/null | awk '{printf \"BSTAT %s\\n\",$1}'
            cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null | awk '{printf \"GPU %s\\n\",$1}'
            ss -t state established 2>/dev/null | tail -n +2 | wc -l | awk '{printf \"TCP %s\\n\",$1}'
            free -b | awk '/^Mem/{printf \"MEM %s %s\\n\",$2,$3} /^Swap/{printf \"SWAP %s\\n\",$3}'
            df / | awk 'NR==2{printf \"DISK %s\\n\",$5}' | tr -d '%'
            cat /proc/loadavg | awk '{printf \"LOAD %s\\n\",$1}{printf \"PROCS %s\\n\",$4}'
            uptime -p | sed 's/up /UPTIME /'
            uname -r | awk '{printf \"KERN %s\\n\",$1}'
            cat /proc/net/dev | awk 'NR>2 && !/lo:/{printf \"NET %s %s %s\\n\",$1,$2,$10}'
            echo TICK
            ip link show tun0 2>/dev/null | grep -q UP && echo 'VPN 1' || ip link show wg0 2>/dev/null | grep -q UP && echo 'VPN 1' || echo 'VPN 0'
            sleep 2
        done"]
        running: true

        property real cpuPrevU: 0; property real cpuPrevT: 0
        property var  corePrevU: []; property var corePrevT: []
        property real netPrevDown: 0; property real netPrevUp: 0
        property var  pendingCores: []
        property real pendingNetDown: 0; property real pendingNetUp: 0
        property string pendingIface: ""
        property real diskPrevR: 0
        property real diskPrevW: 0

        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (!line) return
                var parts = line.split(" ")
                var key = parts[0]

                if (key === "CPU") {
                    var u = parseFloat(parts[1]), t = parseFloat(parts[2])
                    var du = u - dataProc.cpuPrevU, dt = t - dataProc.cpuPrevT
                    if (dt > 0) root.cpuPct = Math.round(du / dt * 100)
                    dataProc.cpuPrevU = u; dataProc.cpuPrevT = t

                } else if (key === "CORE") {
                    dataProc.pendingCores.push([parseFloat(parts[1]), parseFloat(parts[2])])

                } else if (key === "MEM") {
                    var total = parseFloat(parts[1]), used = parseFloat(parts[2])
                    root.ramPct     = Math.round(used / total * 100)
                    root.ramUsedGb  = Math.round(used / 1073741824 * 10) / 10
                    root.ramTotalGb = Math.round(total / 1073741824)

                } else if (key === "SWAP") {
                    if (root.ramTotalGb > 0)
                        root.swapPct = Math.min(100, Math.round(parseFloat(parts[1]) / (root.ramTotalGb * 1073741824) * 100))

                } else if (key === "BAT") {
                    root.batPct = parseInt(parts[1]) || 0
                    root.batStatus = parts[2] || "..."
                
                } else if (key === "DISK") {
                    root.diskPct = parseInt(parts[1]) || 0

                } else if (key === "LOAD") {
                    root.loadAvg = parseFloat(parts[1])

                } else if (key === "DISKIO") {
                    var dr = parseFloat(parts[1]), dw = parseFloat(parts[2])
                    root.diskRead  = Math.round((dr - dataProc.diskPrevR) * 512 / 1024 / 2)
                    root.diskWrite = Math.round((dw - dataProc.diskPrevW) * 512 / 1024 / 2)
                    dataProc.diskPrevR = dr
                    dataProc.diskPrevW = dw
                
                } else if (key === "PROCS") {
                    root.procs = parseInt(parts[1])

                } else if (key === "UPTIME") {
                    root.uptime = line.replace("UPTIME ", "")
                        .replace("hours", "h").replace("hour", "h")
                        .replace("minutes", "m").replace("minute", "m")

                } else if (key === "KERN") {
                    root.kernelVer = parts[1]

                } else if (key === "TCPU") {
                    root.tmpCpu = Math.round(parseFloat(parts[1]))

                } else if (key === "TGPU") {
                    root.tmpGpu = Math.round(parseFloat(parts[1]))

                } else if (key === "GPU") {
                    root.gpuPct = parseInt(parts[1]) || 0

                } else if (key === "NET") {
                    dataProc.pendingNetDown += parseFloat(parts[2])
                    dataProc.pendingNetUp   += parseFloat(parts[3])
                    if (dataProc.pendingIface === "") dataProc.pendingIface = parts[1].replace(":", "")

                } else if (key === "VPN") {
                    root.vpnActive = parts[1] === "1"
                
                } else if (key === "TCP") {
                    root.activeTcp = parseInt(parts[1]) || 0
                
                } else if (key === "TICK") {
                    var newCores = []
                    for (var c = 0; c < dataProc.pendingCores.length; c++) {
                        var pu = dataProc.corePrevU[c] || 0, pt = dataProc.corePrevT[c] || 0
                        var dcu = dataProc.pendingCores[c][0] - pu
                        var dct = dataProc.pendingCores[c][1] - pt
                        newCores.push(dct > 0 ? Math.round(dcu / dct * 100) : 0)
                        dataProc.corePrevU[c] = dataProc.pendingCores[c][0]
                        dataProc.corePrevT[c] = dataProc.pendingCores[c][1]
                    }
                    root.coreData = newCores
                    dataProc.pendingCores = []

                    root.netDown = Math.round((dataProc.pendingNetDown - dataProc.netPrevDown) / 1024)
                    root.netUp   = Math.round((dataProc.pendingNetUp   - dataProc.netPrevUp)   / 1024)
                    dataProc.netPrevDown = dataProc.pendingNetDown
                    dataProc.netPrevUp   = dataProc.pendingNetUp
                    root.iface = dataProc.pendingIface
                    dataProc.pendingNetDown = 0; dataProc.pendingNetUp = 0; dataProc.pendingIface = ""
                }
            }
        }
    }
    
    Item {
        id: slidingContainer
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.panelHeight + root.tabHeight
        y: root._open ? 0 : root.panelHeight

        Behavior on y {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        // ══════════════════════════════════════════════════════════════════
        // JAMBUL / MOHAWK TAB — paling atas dari container, ikut slide
        // Shape:   _______/------\_______
        // ══════════════════════════════════════════════════════════════════
        Item {
            id: pullTab
            width: 280
            height: root.tabHeight
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var W = width, H = height
                    // Jambul shape: flat di ujung kiri-kanan,
                    // naik ke atas di tengah dengan sudut tajam (angular, bukan curve)
                    var rampW = 36   // lebar miring kiri/kanan
                    var topH  = H    // tinggi total

                    ctx.beginPath()
                    ctx.moveTo(0, H)                        // bawah kiri
                    ctx.lineTo(0, H)
                    ctx.lineTo(rampW, 0)                    // miring naik kiri
                    ctx.lineTo(W - rampW, 0)                // flat atas
                    ctx.lineTo(W, H)                        // miring turun kanan
                    ctx.closePath()
                    ctx.fillStyle = "#24273a"
                    ctx.fill()

                    // Garis tepi atas (silhouette jambul)
                    ctx.beginPath()
                    ctx.moveTo(0, H)
                    ctx.lineTo(rampW, 0)
                    ctx.lineTo(W - rampW, 0)
                    ctx.lineTo(W, H)
                    ctx.strokeStyle = "#363a4f"
                    ctx.lineWidth = 1.5
                    ctx.stroke()

                    // Garis accent dalam (panel line paralel)
                    ctx.beginPath()
                    ctx.moveTo(rampW + 6, 4)
                    ctx.lineTo(W - rampW - 6, 4)
                    ctx.strokeStyle = "#0f2a44"
                    ctx.lineWidth = 1
                    ctx.stroke()

                    // Corner brackets kiri
                    ctx.beginPath()
                    ctx.moveTo(rampW + 2, 2)
                    ctx.lineTo(rampW + 12, 2)
                    ctx.moveTo(rampW + 2, 2)
                    ctx.lineTo(rampW + 2, 10)
                    ctx.strokeStyle = "#2a6aaa"
                    ctx.lineWidth = 1
                    ctx.stroke()

                    // Corner brackets kanan
                    ctx.beginPath()
                    ctx.moveTo(W - rampW - 2, 2)
                    ctx.lineTo(W - rampW - 12, 2)
                    ctx.moveTo(W - rampW - 2, 2)
                    ctx.lineTo(W - rampW - 2, 10)
                    ctx.strokeStyle = "#2a6aaa"
                    ctx.lineWidth = 1
                    ctx.stroke()
                }
            }

            // Label + indicator
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 4
                spacing: 10

                // Blinking status dot
                Rectangle {
                    width: 5; height: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.vpnActive ? "#a6da95" : "#ed8796"
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 600 }
                        NumberAnimation { to: 1.0; duration: 600 }
                    }
                }

                Text {
                    text: "SYS.DASH"
                    font.pixelSize: 11
                    color: "#1e5a8a"
                    font.letterSpacing: 4
                    font.family: "monospace"
                    font.weight: Font.Bold
                }

                // CPU quick readout
                Text {
                    text: root.batPct + "%"
                    font.pixelSize: 10
                    color: "#2a7acc"
                    font.family: "monospace"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 5; height: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.vpnActive ? "#a6da95" : "#ed8796"
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 800 }
                        NumberAnimation { to: 1.0; duration: 800 }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.toggle()
                cursorShape: Qt.PointingHandCursor
            }
        }

        Item {
            id: mainPanel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: pullTab.bottom
            anchors.bottom: parent.bottom
            clip: true

            // Angular top bevel — sudut tajam kiri kanan
            Canvas {
                id: topBevel
                anchors.top: parent.top
                width: parent.width
                height: 22
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var bev = 22
                    ctx.beginPath()
                    ctx.moveTo(0, height)
                    ctx.lineTo(bev, 0)
                    ctx.lineTo(width - bev, 0)
                    ctx.lineTo(width, height)
                    ctx.closePath()
                    ctx.fillStyle = "#24273a"
                    ctx.fill()

                    // Top line
                    ctx.beginPath()
                    ctx.moveTo(bev, 0)
                    ctx.lineTo(width - bev, 0)
                    ctx.strokeStyle = "#363a4f"
                    ctx.lineWidth = 1.5
                    ctx.stroke()

                    // Miring kiri
                    ctx.beginPath()
                    ctx.moveTo(0, height)
                    ctx.lineTo(bev, 0)
                    ctx.strokeStyle = "#363a4f"
                    ctx.lineWidth = 1
                    ctx.stroke()

                    // Miring kanan
                    ctx.beginPath()
                    ctx.moveTo(width - bev, 0)
                    ctx.lineTo(width, height)
                    ctx.strokeStyle = "#363a4f"
                    ctx.lineWidth = 1
                    ctx.stroke()
                }
            }

            // Main body — full width panel
            Rectangle {
                anchors.top: topBevel.bottom
                anchors.topMargin: -1
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: "#24273a"
                border.color: "#363a4f"
                border.width: 1

                // Thin accent line top
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left; anchors.right: parent.right
                    height: 1; color: "#a5adcb"; opacity: 0.5
                }
                Row {
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.topMargin: 10
                    spacing: 0

                    // ════════════════════════════════════════════════
                    // KIRI — Wifi / Bluetooth / quick toggles 
                    // ════════════════════════════════════════════════
                    Column {
                        width: 130
                        height: parent.height
                        spacing: 10

                        // WIFI button — gede, angular
                        Rectangle {
                            id: wifiBtn
                            width: parent.width
                            height: 62
                            color: root.wifiOn ? "#071a0e" : "#070d1a"
                            border.color: root.wifiOn ? "#a6da95" : "#363a4f"
                            border.width: 1

                            // Angular cut sudut kanan atas
                            Canvas {
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.beginPath()
                                    ctx.moveTo(width - 10, 0)
                                    ctx.lineTo(width, 10)
                                    ctx.strokeStyle = root.wifiOn ? "#a6da95" : "#363a4f"
                                    ctx.lineWidth = 1
                                    ctx.stroke()
                                    // Fill corner cut
                                    ctx.beginPath()
                                    ctx.moveTo(width - 10, 0)
                                    ctx.lineTo(width, 0)
                                    ctx.lineTo(width, 10)
                                    ctx.closePath()
                                    ctx.fillStyle = "#24273a"
                                    ctx.fill()
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                // Wifi arc indicator
                                Canvas {
                                    width: 36; height: 28
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        var cx = width / 2, cy = height - 2
                                        var active = root.wifiOn
                                        var arcs = [
                                            { r: 6,  sw: 2.5, col: active ? "#a6da95" : "#1a3a2a" },
                                            { r: 13, sw: 2,   col: active ? "#1aaa55" : "#112918" },
                                            { r: 20, sw: 1.5, col: active ? "#118844" : "#0a1e12" }
                                        ]
                                        arcs.forEach(function(a) {
                                            ctx.beginPath()
                                            ctx.arc(cx, cy, a.r, Math.PI * 1.15, Math.PI * 1.85)
                                            ctx.strokeStyle = a.col
                                            ctx.lineWidth = a.sw
                                            ctx.lineCap = "butt"
                                            ctx.stroke()
                                        })
                                        // dot
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, 2.5, 0, Math.PI * 2)
                                        ctx.fillStyle = active ? "#22ff88" : "#1a4a2a"
                                        ctx.fill()
                                    }
                                }

                                Text {
                                    text: root.wifiOn ? "CONNECTED" : "WIFI OFF"
                                    font.pixelSize: 9
                                    color: root.wifiOn ? "#a6da95" : "#2a4a3a"
                                    font.family: "monospace"
                                    font.letterSpacing: 1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.wifiOn = !root.wifiOn
                                cursorShape: Qt.PointingHandCursor
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                property real pressY: 0
                                property bool dragging: false

                                onPressed: (mouse) => {
                                    pressY = mouse.y
                                    dragging = false
                                }

                                onPositionChanged: (mouse) => {
                                    if (mouse.y - pressY > 10) dragging = true
                                }

                                onReleased: (mouse) => {
                                    if (dragging && mouse.y - pressY > 30) {
                                        root.close()
                                    } else if (!dragging) {
                                        root.toggle()
                                    }
                                    dragging = false
                                }
                            }
                        }

                        // BLUETOOTH button — gede, angular
                        Rectangle {
                            id: btBtn
                            width: parent.width
                            height: 62
                            color: root.btOn ? "#0a071e" : "#070d1a"
                            border.color: root.btOn ? "#c6a0f6" : "#363a4f"
                            border.width: 1

                            Canvas {
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.beginPath()
                                    ctx.moveTo(width - 10, 0)
                                    ctx.lineTo(width, 10)
                                    ctx.strokeStyle = root.btOn ? "#c6a0f6" : "#363a4f"
                                    ctx.lineWidth = 1
                                    ctx.stroke()
                                    ctx.beginPath()
                                    ctx.moveTo(width - 10, 0)
                                    ctx.lineTo(width, 0)
                                    ctx.lineTo(width, 10)
                                    ctx.closePath()
                                    ctx.fillStyle = "#24273a"
                                    ctx.fill()
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                // Bluetooth symbol (manual path)
                                Canvas {
                                    width: 20; height: 32
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        var col = root.btOn ? "#c6a0f6" : "#2a2040"
                                        ctx.strokeStyle = col
                                        ctx.lineWidth = 2
                                        ctx.lineCap = "round"
                                        // vertical spine
                                        ctx.beginPath()
                                        ctx.moveTo(10, 2); ctx.lineTo(10, 30); ctx.stroke()
                                        // top right diagonal
                                        ctx.beginPath()
                                        ctx.moveTo(10, 2); ctx.lineTo(18, 10); ctx.lineTo(10, 16); ctx.stroke()
                                        // bottom right diagonal
                                        ctx.beginPath()
                                        ctx.moveTo(10, 30); ctx.lineTo(18, 22); ctx.lineTo(10, 16); ctx.stroke()
                                        // top left
                                        ctx.beginPath()
                                        ctx.moveTo(10, 2); ctx.lineTo(2, 10); ctx.stroke()
                                        // bottom left
                                        ctx.beginPath()
                                        ctx.moveTo(10, 30); ctx.lineTo(2, 22); ctx.stroke()
                                    }
                                }

                                Text {
                                    text: root.btOn ? "BT ON" : "BT OFF"
                                    font.pixelSize: 9
                                    color: root.btOn ? "#c6a0f6" : "#2a2040"
                                    font.family: "monospace"
                                    font.letterSpacing: 1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.btOn = !root.btOn
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        // Night mode + notif — compact row di bawah
                        Row {
                            spacing: 6
                            width: parent.width

                            Repeater {
                                model: [
                                    { lbl: "NIGHT", prop: "nightMode", col: "#c6a0f6" },
                                    { lbl: "NOTIF", prop: "notifOn",   col: "#8aadf4" }
                                ]
                                Rectangle {
                                    width: (parent.parent.width - 6) / 2
                                    height: 28
                                    property bool isOn: index === 0 ? root.nightMode : root.notifOn
                                    color: isOn ? "#0a0718" : "#070d1a"
                                    border.color: isOn ? modelData.col : "#363a4f"
                                    border.width: 1
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Rectangle {
                                            width: 14; height: 6
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: isOn ? Qt.rgba(
                                                parseInt(modelData.col.slice(1,3),16)/255,
                                                parseInt(modelData.col.slice(3,5),16)/255,
                                                parseInt(modelData.col.slice(5,7),16)/255, 0.25) : "#070d1a"
                                            border.color: isOn ? modelData.col : "#363a4f"
                                            border.width: 1
                                            Rectangle {
                                                x: isOn ? 7 : 1
                                                width: 4; height: 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: isOn ? modelData.col : "#2a3a4a"
                                                Behavior on x { NumberAnimation { duration: 100 } }
                                            }
                                        }
                                        Text {
                                            text: modelData.lbl
                                            font.pixelSize: 7; color: isOn ? modelData.col : "#363a4f"
                                            font.family: "monospace"; font.letterSpacing: 1
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (index === 0) root.nightMode = !root.nightMode
                                            else root.notifOn = !root.notifOn
                                        }
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }
                    }

                    // Separator
                    Item {
                        width: 20; height: parent.height
                        Rectangle {
                            anchors.centerIn: parent
                            width: 1; height: parent.height - 16
                            color: "#24273a"
                        }
                    }

                    // ════════════════════════════════════════════════
                    // TENGAH-KIRI — CPU cores + speedometer CPU gede
                    // ════════════════════════════════════════════════
                    Column {
                        width: 220
                        height: parent.height
                        spacing: 8

                        // Big CPU speedometer
                        Item {
                            width: parent.width
                            height: 90
                            anchors.horizontalCenter: parent.horizontalCenter

                            Canvas {
                                anchors.fill: parent
                                property real pct: root.cpuPct / 100
                                onPctChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    var cx = width / 2, cy = height - 14, r = 70

                                    // Outer ring track
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, r, Math.PI, 2 * Math.PI)
                                    ctx.strokeStyle = "#363a4f"
                                    ctx.lineWidth = 10
                                    ctx.lineCap = "butt"
                                    ctx.stroke()

                                    // Segmented fill (mecha look — bukan satu arc mulus)
                                    var segments = 24
                                    var startA = Math.PI
                                    var totalA = Math.PI
                                    var gap = 0.04
                                    for (var i = 0; i < segments; i++) {
                                        var segStart = startA + (i / segments) * totalA + gap / 2
                                        var segEnd   = startA + ((i + 1) / segments) * totalA - gap / 2
                                        var filled = (i / segments) < pct
                                        if (filled) {
                                            var heat = i / segments
                                            var r2 = Math.round(26 + heat * 180)
                                            var g2 = Math.round(100 - heat * 80)
                                            var b2 = Math.round(204 - heat * 180)
                                            ctx.beginPath()
                                            ctx.arc(cx, cy, r, segStart, segEnd)
                                            ctx.strokeStyle = "rgb(" + r2 + "," + g2 + "," + b2 + ")"
                                            ctx.lineWidth = 10
                                            ctx.lineCap = "butt"
                                            ctx.stroke()
                                        }
                                    }

                                    // Tick marks
                                    for (var t = 0; t <= 10; t++) {
                                        var tA = Math.PI + (t / 10) * Math.PI
                                        var inner = t % 5 === 0 ? r - 14 : r - 9
                                        ctx.beginPath()
                                        ctx.moveTo(cx + (r + 2) * Math.cos(tA), cy + (r + 2) * Math.sin(tA))
                                        ctx.lineTo(cx + inner * Math.cos(tA), cy + inner * Math.sin(tA))
                                        ctx.strokeStyle = "#363a4f"
                                        ctx.lineWidth = t % 5 === 0 ? 1.5 : 0.8
                                        ctx.stroke()
                                    }

                                    // Center fill
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, r - 16, 0, 2 * Math.PI)
                                    ctx.fillStyle = "#1e2030"
                                    ctx.fill()

                                    // Needle
                                    var nA = Math.PI + pct * Math.PI
                                    var nLen = r - 20
                                    ctx.beginPath()
                                    ctx.moveTo(cx, cy)
                                    ctx.lineTo(cx + nLen * Math.cos(nA), cy + nLen * Math.sin(nA))
                                    ctx.strokeStyle = "#ed8796"
                                    ctx.lineWidth = 2
                                    ctx.lineCap = "round"
                                    ctx.stroke()
                                    // Needle pivot
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, 5, 0, Math.PI * 2)
                                    ctx.fillStyle = "#ed8796"
                                    ctx.fill()
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, 2, 0, Math.PI * 2)
                                    ctx.fillStyle = "#24273a"
                                    ctx.fill()
                                }
                            }

                            // Center text
                            Column {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 18
                                spacing: 0
                                Text {
                                    text: root.cpuPct + "%"
                                    font.pixelSize: 22; color: "#cad3f5"
                                    font.family: "monospace"; font.weight: Font.Bold
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: "CPU"
                                    font.pixelSize: 9; color: "#a5adcb"
                                    font.family: "monospace"; font.letterSpacing: 3
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // Per-core bars
                        Grid {
                            width: parent.width
                            columns: root.coreData.length > 8 ? 2 : 1
                            spacing: 3
                            Repeater {
                                model: root.coreData.length
                                Row {
                                    spacing: 4
                                    width: root.coreData.length > 8 ? (parent.width / 2) - 2 : parent.width
                                    property int coreVal: (root.coreData && index < root.coreData.length) ? (root.coreData[index] || 0) : 0
                                    Text {
                                        text: "C" + index
                                        font.pixelSize: 8; color: "#a5adcb"
                                        width: root.coreData.length > 8 ? 18 : 16
                                        font.family: "monospace"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Item {
                                        width: parent.width - (root.coreData.length > 8 ? 18 : 16) - 30 - 8; height: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        Rectangle { anchors.fill: parent; color: "#1e2030"; border.color: "#363a4f"; border.width: 1 }
                                        Rectangle {
                                            width: parent.width * parent.parent.coreVal / 100
                                            height: parent.height
                                            color: parent.parent.coreVal > 80 ? "#ed8796" : parent.parent.coreVal > 50 ? "#eed49f" : "#8aadf4"
                                        }
                                    }
                                    Rectangle {
                                        width: parent.width * parent.parent.coreVal / 100
                                        height: parent.height
                                        color: parent.parent.coreVal > 80 ? "#ed8796" : parent.parent.coreVal > 50 ? "#eed49f" : "#8aadf4"
                                        Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
                                    }
                                    Text {
                                        text: parent.coreVal + "%"
                                        font.pixelSize: 8; color: "#a5adcb"; width: 28
                                        horizontalAlignment: Text.AlignRight
                                        font.family: "monospace"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }

                    // Separator
                    Item {
                        width: 20; height: parent.height
                        Rectangle {
                            anchors.centerIn: parent
                            width: 1; height: parent.height - 16
                            color: "#24273a"
                        }
                    }

                    // ════════════════════════════════════════════════
                    // TENGAH — RAM gauge + temps acak campur
                    // ════════════════════════════════════════════════
                    Column {
                        width: 160
                        height: parent.height
                        spacing: 8

                        // RAM arc gauge
                        Item {
                            width: parent.width; height: 100
                            Canvas {
                                anchors.fill: parent
                                property real pct: root.ramPct / 100
                                onPctChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    var cx = width / 2, cy = height / 2 + 10, r = 44

                                    // Track
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, r, Math.PI * 0.7, Math.PI * 2.3)
                                    ctx.strokeStyle = "#363a4f"; ctx.lineWidth = 8; ctx.lineCap = "butt"; ctx.stroke()

                                    // Fill — segmented
                                    var segs = 18, sA = Math.PI * 0.7, tA = Math.PI * 1.6
                                    for (var i = 0; i < segs; i++) {
                                        if ((i / segs) >= pct) continue
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, r, sA + (i/segs)*tA + 0.04, sA + ((i+1)/segs)*tA - 0.04)
                                        ctx.strokeStyle = pct > 0.85 ? "#cc2244" : "#a6da95"
                                        ctx.lineWidth = 8; ctx.lineCap = "butt"; ctx.stroke()
                                    }

                                    // Inner
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, r - 12, 0, Math.PI * 2)
                                    ctx.fillStyle = "#1e2030"; ctx.fill()
                                }
                            }
                            Column {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: 10
                                spacing: 1
                                Text {
                                    text: root.ramPct + "%"
                                    font.pixelSize: 18; color: "#cad3f5"
                                    font.family: "monospace"; font.weight: Font.Bold
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: root.ramUsedGb + "/" + root.ramTotalGb + "GB"
                                    font.pixelSize: 8; color: "#a5adcb"
                                    font.family: "monospace"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: "MEM"
                                    font.pixelSize: 8; color: "#a5adcb"
                                    font.family: "monospace"; font.letterSpacing: 2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // Temps + disk acak campur
                        Column {
                            width: parent.width; spacing: 4

                            // CPU temp + GPU temp side by side gede
                            Row {
                                spacing: 6; width: parent.width
                                Repeater {
                                    model: [
                                        { lbl: "CPU", val: root.tmpCpu, danger: 85 },
                                        { lbl: "GPU", val: root.tmpGpu, danger: 90 }
                                    ]
                                    Rectangle {
                                        width: (parent.parent.width - 6) / 2; height: 44
                                        color: "#1e2030"
                                        border.color: modelData.val > modelData.danger ? "#ed8796" : "#363a4f"
                                        border.width: 1
                                        Column {
                                            anchors.centerIn: parent; spacing: 2
                                            Text {
                                                text: modelData.val + "°"
                                                font.pixelSize: 18; color: modelData.val > modelData.danger ? "#ed8796" : "#cc7722"
                                                font.family: "monospace"; font.weight: Font.Bold
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }
                                            Text {
                                                text: modelData.lbl + ".TMP"
                                                font.pixelSize: 7; color: "#a5adcb"
                                                font.family: "monospace"; font.letterSpacing: 1
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }
                                        }
                                    }
                                }
                            }

                            // DISK bar
                            Column {
                                width: parent.width; spacing: 2
                                Row {
                                    spacing: 4
                                    Text { text: "DISK"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace"; font.letterSpacing: 2 }
                                    Text { text: root.diskPct + "%"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                    Text { text: "   SWAP"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace"; font.letterSpacing: 2 }
                                    Text { text: root.swapPct + "%"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                }
                                Item {
                                    width: parent.width; height: 8
                                    Rectangle { anchors.fill: parent; color: "#1e2030"; border.color: "#363a4f"; border.width: 1 }
                                    Rectangle {
                                        width: parent.width * root.diskPct / 100; height: parent.height
                                        color: "#eed49f"
                                    }
                                }
                            }

                            Row {
                                spacing: 4
                                Text { text: "R"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                Text { text: root.diskRead + " KB/s"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                Text { text: "W"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                Text { text: root.diskWrite + " KB/s"; font.pixelSize: 8; color: "#eed49f"; font.family: "monospace" }
                            }

                            // Load avg + uptime inline
                            Row {
                                spacing: 8
                                Text { text: "LOAD"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                Text { text: root.loadAvg.toFixed(2); font.pixelSize: 9; color: "#8aadf4"; font.family: "monospace" }
                                Text { text: "UP"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                Text { text: root.uptime; font.pixelSize: 9; color: "#a6da95"; font.family: "monospace" }
                            }

                            Row {
                                spacing: 8
                                Text { text: "PROCS"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                Text { text: root.procs + ""; font.pixelSize: 9; color: "#8aadf4"; font.family: "monospace" }
                                Text { text: "KRN"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                Text { text: root.kernelVer; font.pixelSize: 8; color: "#8aadf4"; font.family: "monospace" }
                            }
                        }
                    }

                    // Separator
                    Item {
                        width: 20; height: parent.height
                        Rectangle {
                            anchors.centerIn: parent
                            width: 1; height: parent.height - 16
                            color: "#24273a"
                        }
                    }

                    // ════════════════════════════════════════════════
                    // RIGHT — Network traffic + Connection + VPN status
                    // ════════════════════════════════════════════════
                    Column {
                        width: parent.width - 130 - 170 - 160 - 20*3 - 20
                        height: parent.height
                        spacing: 6

                        // ── NET GRAPH ─────────────────────────────────────────────
                        Item {
                            width: parent.width
                            height: 100

                            // Rolling history
                            property var downHistory: []
                            property var upHistory:   []
                            property real peakVal:    1

                            onWidthChanged: canvas.requestPaint()

                            Component.onCompleted: {
                                for (var i = 0; i < 40; i++) {
                                    downHistory.push(0)
                                    upHistory.push(0)
                                }
                            }

                            Connections {
                                target: root
                                function onNetDownChanged() {
                                    var h = netGraph.downHistory
                                    h.push(root.netDown)
                                    if (h.length > 40) h.shift()
                                    netGraph.downHistory = h

                                    var peak = 1
                                    for (var i = 0; i < h.length; i++) peak = Math.max(peak, h[i])
                                    for (var j = 0; j < netGraph.upHistory.length; j++) peak = Math.max(peak, netGraph.upHistory[j])
                                    netGraph.peakVal = peak
                                    canvas.requestPaint()
                                }
                                function onNetUpChanged() {
                                    var h = netGraph.upHistory
                                    h.push(root.netUp)
                                    if (h.length > 40) h.shift()
                                    netGraph.upHistory = h
                                    canvas.requestPaint()
                                }
                            }

                            id: netGraph

                            Canvas {
                                id: canvas
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    var half = width / 2 - 2
                                    var peak = netGraph.peakVal

                                    // Grid lines
                                    for (var g = 1; g <= 4; g++) {
                                        var gy = height - (g / 4) * height
                                        ctx.beginPath()
                                        ctx.moveTo(0, gy); ctx.lineTo(width, gy)
                                        ctx.strokeStyle = "#1e2030"
                                        ctx.lineWidth = 1
                                        ctx.stroke()
                                    }

                                    // Separator tengah
                                    ctx.beginPath()
                                    ctx.moveTo(width/2, 0); ctx.lineTo(width/2, height)
                                    ctx.strokeStyle = "#24273a"
                                    ctx.lineWidth = 1
                                    ctx.stroke()

                                    var dh = netGraph.downHistory
                                    var uh = netGraph.upHistory
                                    var barW = half / 40

                                    // DOWNLOAD — kiri
                                    for (var i = 0; i < dh.length; i++) {
                                        var bh = dh[i] > 0 ? Math.max(1, (dh[i] / peak) * height) : 0
                                        var x = i * barW
                                        ctx.fillStyle = Qt.rgba(0.13, 0.4, 0.8, 0.25 + (dh[i]/peak) * 0.65)
                                        ctx.fillRect(x, height - bh, Math.max(1, barW - 1), bh)
                                    }

                                    // UPLOAD — kanan
                                    for (var j = 0; j < uh.length; j++) {
                                        var bhu = uh[j] > 0 ? Math.max(1, (uh[j] / peak) * height) : 0
                                        var xu = width/2 + 2 + j * barW
                                        ctx.fillStyle = Qt.rgba(0.8, 0.27, 0.13, 0.25 + (uh[j]/peak) * 0.65)
                                        ctx.fillRect(xu, height - bhu, Math.max(1, barW - 1), bhu)
                                    }

                                    // Labels
                                    ctx.font = "9px monospace"
                                    ctx.fillStyle = "#8aadf4"
                                    ctx.fillText("▼ " + (root.netDown >= 1024 ? (root.netDown/1024).toFixed(1)+"MB/s" : root.netDown+"KB/s"), 2, 11)

                                    ctx.fillStyle = "#cc4422"
                                    var upTxt = "▲ " + (root.netUp >= 1024 ? (root.netUp/1024).toFixed(1)+"MB/s" : root.netUp+"KB/s")
                                    ctx.fillText(upTxt, width/2 + 4, 11)

                                    // Peak
                                    var pkTxt = peak >= 1024 ? (peak/1024).toFixed(1)+"MB/s" : peak+"KB/s"
                                    ctx.fillStyle = "#363a4f"
                                    ctx.font = "8px monospace"
                                    ctx.fillText("pk:"+pkTxt, 2, height - 2)
                                }
                            }
                        }

                        // ── INFO BAWAH ────────────────────────────────────────────
                        Row {
                            spacing: 10; width: parent.width

                            Rectangle {
                                width: 64; height: 52
                                color: "#1e2030"
                                border.color: "#363a4f"; border.width: 1
                                Canvas {
                                    anchors.fill: parent
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0,0,width,height)
                                        ctx.beginPath()
                                        ctx.moveTo(width-8,0); ctx.lineTo(width,8)
                                        ctx.strokeStyle="#363a4f"; ctx.lineWidth=1; ctx.stroke()
                                        ctx.beginPath()
                                        ctx.moveTo(width-8,0); ctx.lineTo(width,0); ctx.lineTo(width,8)
                                        ctx.closePath(); ctx.fillStyle="#24273a"; ctx.fill()
                                    }
                                }
                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        text: root.activeTcp + ""
                                        font.pixelSize: 20; color: "#8aadf4"
                                        font.family: "monospace"; font.weight: Font.Bold
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "CONNS"
                                        font.pixelSize: 7; color: "#363a4f"
                                        font.family: "monospace"; font.letterSpacing: 2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }

                            Column {
                                spacing: 5; anchors.verticalCenter: parent.verticalCenter
                                Row {
                                    spacing: 5
                                    Text { text: "IFACE"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                    Text { text: root.iface; font.pixelSize: 9; color: "#a5adcb"; font.family: "monospace" }
                                }
                                Row {
                                    spacing: 5
                                    Text { text: "PUB.IP"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                    Text {
                                        text: root.pubIp
                                        font.pixelSize: 9
                                        color: root.vpnActive ? "#a6da95" : "#ed8796"
                                        font.family: "monospace"
                                    }
                                }
                                Row {
                                    spacing: 5
                                    Text { text: "BAT"; font.pixelSize: 8; color: "#a5adcb"; font.family: "monospace" }
                                    Text {
                                        text: root.batPct + "%"
                                        font.pixelSize: 9
                                        color: root.batPct < 20 ? "#ed8796" : "#a5adcb"
                                        font.family: "monospace"
                                    }
                                }
                            }
                        }

                        // VPN status
                        Rectangle {
                            width: parent.width; height: 22
                            color: root.vpnActive ? "#060f08" : "#0f0606"
                            border.color: root.vpnActive ? "#0d3018" : "#3a0e0e"; border.width: 1
                            Row {
                                anchors.centerIn: parent; spacing: 8
                                Rectangle {
                                    width: 6; height: 6; anchors.verticalCenter: parent.verticalCenter
                                    color: root.vpnActive ? "#a6da95" : "#ed8796"
                                    SequentialAnimation on opacity {
                                        running: !root.vpnActive
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.1; duration: 350 }
                                        NumberAnimation { to: 1.0; duration: 350 }
                                    }
                                }
                                Text {
                                    text: root.vpnActive ? "VPN ACTIVE — IDENTITY MASKED" : "!! WARN: REAL IP EXPOSED"
                                    font.pixelSize: 9
                                    color: root.vpnActive ? "#a6da95" : "#ed8796"
                                    font.family: "monospace"; font.letterSpacing: 1
                                }
                            }
                        }

                        // Badge VPN/TOR
                        Row {
                            spacing: 6
                            Repeater {
                                model: [
                                    { lbl: "VPN", on: root.vpnActive, col: "#a6da95" },
                                    { lbl: "TOR", on: false,           col: "#c6a0f6" }
                                ]
                                Rectangle {
                                    height: 18
                                    width: badgeTxt.implicitWidth + 18
                                    color: modelData.on ? Qt.rgba(
                                        parseInt(modelData.col.slice(1,3),16)/255,
                                        parseInt(modelData.col.slice(3,5),16)/255,
                                        parseInt(modelData.col.slice(5,7),16)/255, 0.15) : "#1e2030"
                                    border.color: modelData.on ? modelData.col : "#363a4f"; border.width: 1
                                    Text {
                                        id: badgeTxt
                                        anchors.centerIn: parent
                                        text: modelData.lbl
                                        font.pixelSize: 8; color: modelData.on ? modelData.col : "#363a4f"
                                        font.family: "monospace"; font.letterSpacing: 2
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
