import QtQuick

Item {
    id: root

    property int animPhase: 0
    signal animDone(int nextPhase)

    // ╔══════════════════════════════════════════════════╗
    // ║  TWEAK ZONE (Udah Digedein & Ditinggiin)          ║
    // ╚══════════════════════════════════════════════════╝
    readonly property int gateWidth:    460  // Lebih lebar
    readonly property int pillarWidth:  40   // Tiang lebih tebal & kokoh
    readonly property int pillarHeight: 420  // Jauh lebih tinggi
    readonly property int kasagiH:      75   // Area atap vertikal diperbesar
    // ════════════════════════════════════════════════════

    implicitWidth:  gateWidth + 120 
    implicitHeight: pillarHeight + kasagiH + 50

    // Warna solid flat
    readonly property color toriiRed:   "#ff4e21" 
    readonly property color solidBlack: "#111111" 

    // Ekspos properti penting agar bisa dibaca oleh file utama untuk posisi kontent
    readonly property int innerWidth:   gateWidth - pillarWidth * 2
    readonly property int nukiAbsY:     kasagiH + 115 
    // Hitung titik tengah ruang kosong (antara bawah Nuki dan atas Kanmon)
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

    onAnimPhaseChanged: {
        if      (animPhase === 1) leftAnim.start()
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


    // ── PILLAR LEFT ──────────────────────────────────────────────────────
    Item {
        visible: root.showLeft
        x: 60
        y: (root.kasagiH * 0.8) + root.leftDrop // Posisi y diturunkan pas di bawah Shimagi
        width: root.pillarWidth
        height: root.pillarHeight

        Rectangle {
            anchors.fill: parent
            color: root.toriiRed
        }

        // Daiwa (Cincin atas tiang)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: parent.width + 16
            height: 20
            color: root.toriiRed
        }

        // Kanmon (Kaki Hitam bawah)
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
        y: (root.kasagiH * 0.8) + root.rightDrop // Posisi y diturunkan pas di bawah Shimagi
        width: root.pillarWidth
        height: root.pillarHeight

        Rectangle {
            anchors.fill: parent
            color: root.toriiRed
        }

        // Daiwa (Cincin atas tiang)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: parent.width + 16
            height: 20
            color: root.toriiRed
        }

        // Kanmon (Kaki Hitam bawah)
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
        y: root.kasagiH + 95 + root.nukiDrop // Disesuaikan biar posisinya proporsional di tengah
        width: root.gateWidth + 60
        height: 26

        Rectangle {
            anchors.fill: parent
            color: root.toriiRed
        }

        // Gakuzuka (Balok Vertikal Tengah)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            width: 22
            height: 75 // Lebih tinggi mengikuti skala baru
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

            var W = width
            var H = height
            var cx = W / 2

            // 1. Kasagi (Atap Hitam Melengkung Lancip)
            ctx.beginPath()
            ctx.moveTo(10, H * 0.15) 
            ctx.quadraticCurveTo(cx, H * 0.45, W - 10, H * 0.15) 
            ctx.lineTo(W - 24, H * 0.50) 
            ctx.quadraticCurveTo(cx, H * 0.75, 24, H * 0.50) 
            ctx.closePath()
            ctx.fillStyle = root.solidBlack
            ctx.fill()

            // 2. Shimagi (Balok Merah Bawah Atap)
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
}