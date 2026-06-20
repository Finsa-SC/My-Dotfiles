import QtQuick
import QtQuick.Window 

Item {
    id: root

    property int animPhase: 0
    signal animDone(int nextPhase)

    readonly property real scaleFactor: Screen.height / 1080.0

    readonly property int gateWidth:    680 * scaleFactor
    readonly property int pillarWidth:  58  * scaleFactor
    readonly property int pillarHeight: 740 * scaleFactor
    readonly property int kasagiH:      105 * scaleFactor
    // ════════════════════════════════════════════════════

    implicitWidth:  gateWidth + 120 
    implicitHeight: pillarHeight + kasagiH + 50

    // Warna solid flat
    readonly property color toriiRed:   "#ff4e21" 
    readonly property color solidBlack: "#111111" 

    // Ekspos properti penting agar bisa dibaca oleh file utama untuk posisi kontent
    readonly property int innerWidth:   gateWidth - pillarWidth * 2
    readonly property int nukiAbsY:     kasagiH + 115 
    readonly property int visualBottom: (kasagiH * 0.8) + pillarHeight - 65
    readonly property int contentCenterY: (nukiAbsY + visualBottom) / 2

    property real leftDrop:   -(pillarHeight + kasagiH)
    property real rightDrop:  -(pillarHeight + kasagiH)
    property real kasagiDrop: -(pillarHeight + kasagiH)
    property real nukiDrop:   -20

    property bool showLeft:   false
    property bool showRight:  false
    property bool showKasagi: false
    property bool showNuki:   false
    property bool showMoon:   false

    onAnimPhaseChanged: {
        if (animPhase === 1) {
            root.showMoon = true
            leftAnim.start()
        }
        else if (animPhase === 2) rightAnim.start()
        else if (animPhase === 3) gapTimer.start()
        else if (animPhase === 4) kasagiAnim.start()
        else if (animPhase === 5) nukiAnim.start()
        else if (animPhase === 6) waitTimer.start()
    }

    SequentialAnimation {
        id: leftAnim
        ScriptAction { script: { root.showLeft = true } }
        NumberAnimation {
            target: root; property: "leftDrop"
            to: 0; duration: 1000
            easing.type: Easing.OutBounce
            easing.amplitude: 1.0; easing.period: 0.28
        }
        ScriptAction { script: root.animDone(2) }
    }

    SequentialAnimation {
        id: rightAnim
        ScriptAction { script: { root.showRight = true } }
        NumberAnimation {
            target: root; property: "rightDrop"
            to: 0; duration: 1000
            easing.type: Easing.OutBounce
            easing.amplitude: 1.0; easing.period: 0.28
        }
        ScriptAction { script: root.animDone(3) }
    }

    Timer { id: gapTimer; interval: 280; onTriggered: root.animDone(4) }

    SequentialAnimation {
        id: kasagiAnim
        ScriptAction { script: { root.showKasagi = true } }
        NumberAnimation {
            target: root; property: "kasagiDrop"
            to: 0; duration: 900
            easing.type: Easing.OutBounce
            easing.amplitude: 0.7; easing.period: 0.32
        }
        ScriptAction { script: root.animDone(5) }
    }

    SequentialAnimation {
        id: nukiAnim
        ScriptAction { script: { root.showNuki = true } }
        NumberAnimation {
            target: root; property: "nukiDrop"
            from: -20; to: 0; duration: 480
            easing.type: Easing.OutQuart
        }
        ScriptAction { script: root.animDone(6) }
    }

    Timer { id: waitTimer; interval: 700; onTriggered: root.animDone(7) }

    // ── WATER REFLECTION (Air acak tanpa background + Refleksi Bulan Distorsi) ──
    Canvas {
        id: waterCanvas
        
        width: Screen.width
        height: Screen.height * 0.4 
        
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        property real waveProgress: 0
        property var ripples: []

        Component.onCompleted: {
            var temp = []
            for (var i = 0; i < 4; i++) {
                temp.push({
                    x: Math.random(),               
                    y: Math.random(),               
                    phase: Math.random(),           
                    size: 0.3 + Math.random() * 1.0 
                })
            }
            ripples = temp
            requestPaint()
        }

        NumberAnimation on waveProgress {
            from: 0
            to: 1
            duration: 6000
            loops: Animation.Infinite
            running: root.showLeft 
        }

        onWaveProgressChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var sf = root.scaleFactor
            
            // Waktu untuk putaran penuh, menjamin loop sempurna tanpa snap
            var timeOffset = waveProgress * Math.PI * 2

            // 1. GAMBAR REFLEKSI BULAN
            if (root.showMoon) {
                ctx.save()
                
                var moonCenterWaterX = (width / 2) - (root.width / 2) - (270 * sf)
                var moonCenterWaterY = height * 0.25 
                
                // Goyangan kanan-kiri keseluruhan (pakai bilangan bulat biar ga nge-snap)
                var globalSwayX = Math.sin(timeOffset) * (6 * sf)
                ctx.translate(moonCenterWaterX + globalSwayX, moonCenterWaterY)
                
                ctx.fillStyle = "rgba(245, 246, 250, 0.4)" // Warnanya digabung, transparan soft
                ctx.beginPath()
                
                // Menggambar lingkaran custom yang pinggirannya berdistorsi riak
                var segments = 40
                for (var k = 0; k <= segments; k++) {
                    var angle = (k / segments) * Math.PI * 2
                    
                    // Hitung efek "meleot" (wobble) pakai perpaduan sin/cos
                    var wobble = Math.sin(angle * 3 + timeOffset) * (5 * sf) + Math.cos(angle * 2 - timeOffset) * (3 * sf)
                    
                    // Bentuk dasar oval (gepeng) ditambah efek wobble di kelilingnya
                    var rx = (70 * sf) + wobble
                    var ry = (12 * sf) + (wobble * 0.2)
                    
                    var dx = Math.cos(angle) * rx
                    var dy = Math.sin(angle) * ry
                    
                    if (k === 0) ctx.moveTo(dx, dy)
                    else ctx.lineTo(dx, dy)
                }
                ctx.closePath()
                ctx.fill()
                
                ctx.restore()
            }

            // 2. GAMBAR RIAK AIR ACAK
            ctx.lineWidth = 2 * sf 

            for (var i = 0; i < ripples.length; i++) {
                var rip = ripples[i]
                var p = (waveProgress + rip.phase) % 1.0
                
                var alpha = Math.sin(p * Math.PI) * 0.6 
                
                var maxRadius = (width * 0.12) * rip.size
                var r = maxRadius * p
                
                ctx.save()
                ctx.translate(rip.x * width, rip.y * height)
                ctx.scale(1, 0.12) 
                
                ctx.strokeStyle = "rgba(255, 255, 255, " + alpha + ")"
                ctx.beginPath()
                ctx.arc(0, 0, r, 0, Math.PI * 2)
                ctx.stroke()
                
                ctx.restore()
            }
        }

        opacity: root.showLeft ? 1 : 0
        Behavior on opacity { 
            NumberAnimation { duration: 1500; easing.type: Easing.InOutQuad } 
        }
    }

    // ── PILLAR LEFT ──────────────────────────────────────────────────────
    Item {
        visible: root.showLeft
        x: 60
        y: (root.kasagiH * 0.8) + root.leftDrop 
        width: root.pillarWidth
        height: root.pillarHeight

        Rectangle { anchors.fill: parent; color: root.toriiRed }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: parent.width + 16
            height: 20
            color: root.toriiRed
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: parent.width + 4
            height: 55
            color: root.solidBlack
        }
    }

    // ── PILLAR RIGHT ─────────────────────────────────────────────────────
    Item {
        visible: root.showRight
        x: root.gateWidth - root.pillarWidth + 60
        y: (root.kasagiH * 0.8) + root.rightDrop 
        width: root.pillarWidth
        height: root.pillarHeight

        Rectangle { anchors.fill: parent; color: root.toriiRed }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: parent.width + 16
            height: 20
            color: root.toriiRed
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: parent.width + 4
            height: 55
            color: root.solidBlack
        }
    }

    // ── NUKI (Palang Tengah Menembus Tiang) ──────────────────────────────
    Item {
        visible: root.showNuki
        x: 30
        y: root.kasagiH + 95 + root.nukiDrop 
        width: root.gateWidth + 60
        height: 26

        Rectangle { anchors.fill: parent; color: root.toriiRed }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            width: 22
            height: 75 
            color: root.toriiRed
        }
    }

    // ── KASAGI & SHIMAGI (Atap Lancip 2 Lapis) ───────────────────────────
    Canvas {
        id: roofCanvas
        visible: root.showKasagi
        x: 0
        y: root.kasagiDrop
        width:  root.gateWidth + 120 
        height: root.kasagiH + 30

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var W = width; var H = height; var cx = W / 2

            ctx.beginPath()
            ctx.moveTo(10, H * 0.15) 
            ctx.quadraticCurveTo(cx, H * 0.45, W - 10, H * 0.15) 
            ctx.lineTo(W - 24, H * 0.50) 
            ctx.quadraticCurveTo(cx, H * 0.75, 24, H * 0.50) 
            ctx.closePath()
            ctx.fillStyle = root.solidBlack
            ctx.fill()

            ctx.beginPath()
            ctx.moveTo(25, H * 0.50) 
            ctx.quadraticCurveTo(cx, H * 0.75, W - 25, H * 0.50) 
            ctx.lineTo(W - 35, H * 0.85) 
            ctx.quadraticCurveTo(cx, H * 1.0, 35, H * 0.85) 
            ctx.closePath()
            ctx.fillStyle = root.toriiRed
            ctx.fill()
        }

        Connections {
            target: root
            function onKasagiDropChanged() { roofCanvas.requestPaint() }
        }

        Component.onCompleted: requestPaint()
    }

    // ── MOON ─────────────────────────────────────────────────────────────
    Canvas {
        id: moonCanvas
        visible: root.showMoon
        x: -360 * scaleFactor              
        y: -80 * scaleFactor               
        width: 180 * scaleFactor          
        height: 180 * scaleFactor

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var sf = scaleFactor; var cx = width / 2; var cy = height / 2; var r = width * 0.4 

            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.fillStyle = "#f5f6fa"
            ctx.fill()

            ctx.save()
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.clip()

            ctx.fillStyle = "#e1e4ed" 
            ctx.beginPath()
            ctx.arc(cx + (20 * sf), cy + (20 * sf), r * 0.8, 0, Math.PI * 2)
            ctx.fill()

            ctx.beginPath()
            ctx.arc(cx - (15 * sf), cy - (10 * sf), r * 0.3, 0, Math.PI * 2)
            ctx.fill()

            ctx.beginPath()
            ctx.arc(cx - (10 * sf), cy + (15 * sf), r * 0.25, 0, Math.PI * 2)
            ctx.fill()
            ctx.restore()

            ctx.fillStyle = "rgba(255, 255, 255, 0.25)"
            ctx.beginPath()
            ctx.roundRect(cx - r - (10 * sf), cy - (5 * sf), r * 1.5, 6 * sf, 3 * sf)
            ctx.roundRect(cx - (10 * sf), cy + (15 * sf), r * 1.2, 5 * sf, 2.5 * sf)
            ctx.fill()
        }

        Component.onCompleted: moonCanvas.requestPaint()
    }
}