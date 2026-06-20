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
    Canvas {
        id: sakuraCanvas
        x: 65
        y: -160
        width: root.width + 400 * scaleFactor
        height: root.height

        property int seedState: 1337
        function rnd() {
            seedState = (seedState + 0x6D2B79F5) | 0
            var t = seedState
            t = Math.imul(t ^ (t >>> 15), t | 1)
            t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
            return ((t ^ (t >>> 14)) >>> 0) / 4294967296
        }
        function rrange(a, b) { return a + rnd() * (b - a) }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            seedState = 1337

            var sf = root.scaleFactor
            var W = width
            var H = height

            var tiltDeg = -7
            var tiltRad = tiltDeg * Math.PI / 180

            var pivotX = W + 40 * sf
            var pivotY = H * 0.48

            ctx.save()
            ctx.translate(pivotX, pivotY)
            ctx.rotate(tiltRad)
            ctx.translate(-pivotX, -pivotY)

            var petalColors = ["#ED93B1", "#F4C0D1", "#D4537E", "#F0997B"]
            function drawFlower(cx, cy, size, rot, alpha) {
                ctx.save()
                ctx.translate(cx, cy)
                ctx.rotate(rot)
                ctx.globalAlpha = alpha
                ctx.fillStyle = petalColors[Math.floor(rnd() * petalColors.length)]

                var r = size * 0.42
                for (var p = 0; p < 5; p++) {
                    var ang = (Math.PI * 2 / 5) * p - Math.PI / 2
                    ctx.beginPath()
                    ctx.arc(Math.cos(ang) * r, Math.sin(ang) * r, r, 0, Math.PI * 2)
                    ctx.fill()
                }
                ctx.fillStyle = "#993C1D"
                ctx.beginPath()
                ctx.arc(0, 0, size * 0.16, 0, Math.PI * 2)
                ctx.fill()
                ctx.restore()
            }

            function drawFlowerCluster(cx, cy, count, spread, sizeMin, sizeMax) {
                for (var i = 0; i < count; i++) {
                    var ang = rrange(0, Math.PI * 2)
                    var dist = Math.sqrt(rnd()) * spread
                    drawFlower(
                        cx + Math.cos(ang) * dist,
                        cy + Math.sin(ang) * dist,
                        rrange(sizeMin, sizeMax) * sf,
                        rrange(0, Math.PI * 2),
                        rrange(0.75, 1.0)
                    )
                }
            }

            // densityFactor: pengali jumlah bunga (1.0 = normal, 0.3 = sepertiganya, dst)
            function scatterAlongPath(x0, y0, cx1, cy1, cx2, cy2, x1, y1, densityPerLen, sizeMin, sizeMax, spreadAtStart, spreadAtEnd, densityFactorStart, densityFactorEnd) {
                var approxLen = Math.hypot(x1 - x0, y1 - y0) * 1.15
                var baseCount = (approxLen / sf) * densityPerLen

                for (var i = 0; i < baseCount * Math.max(densityFactorStart, densityFactorEnd) + 4; i++) {
                    var t = rrange(0.04, 1.0)

                    var localDensityFactor = densityFactorStart + (densityFactorEnd - densityFactorStart) * t
                    if (rnd() > localDensityFactor) continue

                    var mt = 1 - t
                    var px = mt*mt*mt*x0 + 3*mt*mt*t*cx1 + 3*mt*t*t*cx2 + t*t*t*x1
                    var py = mt*mt*mt*y0 + 3*mt*mt*t*cy1 + 3*mt*t*t*cy2 + t*t*t*y1

                    var dx = 3*mt*mt*(cx1-x0) + 6*mt*t*(cx2-cx1) + 3*t*t*(x1-cx2)
                    var dy = 3*mt*mt*(cy1-y0) + 6*mt*t*(cy2-cy1) + 3*t*t*(y1-cy2)
                    var len = Math.hypot(dx, dy) || 1
                    var nx = -dy / len, ny = dx / len

                    var localSpread = spreadAtStart + (spreadAtEnd - spreadAtStart) * t

                    var side = rnd() < 0.5 ? -1 : 1
                    var off = side * (localSpread * 0.3 + rrange(0, localSpread * 0.7)) * sf

                    var sizeScale = 1.0 - t * 0.25

                    drawFlower(
                        px + nx * off,
                        py + ny * off,
                        rrange(sizeMin, sizeMax) * sf * sizeScale,
                        rrange(0, Math.PI * 2),
                        rrange(0.7, 1.0)
                    )
                }
            }

            function drawBranch(x0, y0, x1, y1, wStart, wEnd, color, wobble, leafDensity, leafMin, leafMax, spreadAtStart, spreadAtEnd, densityFactorStart, densityFactorEnd) {
                var dx = x1 - x0, dy = y1 - y0
                var cx1 = x0 + dx * 0.33 + rrange(-wobble, wobble)
                var cy1 = y0 + dy * 0.33 + rrange(-wobble, wobble)
                var cx2 = x0 + dx * 0.66 + rrange(-wobble, wobble)
                var cy2 = y0 + dy * 0.66 + rrange(-wobble, wobble)

                var steps = 10
                var px = x0, py = y0
                for (var i = 1; i <= steps; i++) {
                    var t = i / steps, mt = 1 - t
                    var nx = mt*mt*mt*x0 + 3*mt*mt*t*cx1 + 3*mt*t*t*cx2 + t*t*t*x1
                    var ny = mt*mt*mt*y0 + 3*mt*mt*t*cy1 + 3*mt*t*t*cy2 + t*t*t*y1

                    ctx.beginPath()
                    ctx.moveTo(px, py)
                    ctx.lineTo(nx, ny)
                    ctx.lineWidth = (wStart + (wEnd - wStart) * t) * sf
                    ctx.strokeStyle = color
                    ctx.lineCap = "round"
                    ctx.stroke()
                    px = nx; py = ny
                }

                if (leafDensity > 0) {
                    scatterAlongPath(x0, y0, cx1, cy1, cx2, cy2, x1, y1, leafDensity, leafMin, leafMax,
                        spreadAtStart, spreadAtEnd, densityFactorStart, densityFactorEnd)
                }

                return { x: x1, y: y1, angle: Math.atan2(y1 - cy2, x1 - cx2) }
            }

            function buildLevel(startY, mainLength, riseAmount, branchColor, twigColor, thicknessMain, isUpper) {
                var startX = W + 40 * sf
                var endX = startX - mainLength
                var endY = startY - riseAmount

                var radiusBase = 95
                var radiusTip  = 22
                function radiusAt(t) { return radiusBase - (radiusBase - radiusTip) * t }

                var densityFull = 1.0
                var densityThin = 0.25
                function densityAt(t) { return densityFull - (densityFull - densityThin) * t }

                var segCount = isUpper ? 4 : 3
                var px = startX, py = startY
                var nodes = []

                // ── batang utama: leafDensity dinaikkan (0.20 -> 0.45) + cluster tambahan di tengah segmen ──
                for (var s = 0; s < segCount; s++) {
                    var t0 = s / segCount, t1 = (s + 1) / segCount
                    var nx = startX + (endX - startX) * t1 + rrange(-18, 18) * sf
                    var ny = startY + (endY - startY) * t1 + rrange(-14, 14) * sf
                    var wS = thicknessMain * (1 - t0 * 0.55)
                    var wE = thicknessMain * (1 - t1 * 0.55)

                    var startSpread = radiusAt(t0)
                    var endSpread   = radiusAt(t1)

                    var res = drawBranch(px, py, nx, ny, wS, wE, branchColor, 22 * sf,
                        0.45, 8, 14, startSpread, endSpread, densityAt(t0), densityAt(t1))
                    nodes.push({ x: nx, y: ny, angle: res.angle, tNorm: t1 })

                    // cluster ekstra di TENGAH segmen ini, biar gak ada celah kosong
                    var midT = (t0 + t1) / 2
                    var midX = px + (nx - px) * 0.5
                    var midY = py + (ny - py) * 0.5
                    var midCount = Math.max(1, Math.round((isUpper ? 5 : 4) * densityAt(midT)))
                    drawFlowerCluster(midX, midY, midCount, radiusAt(midT) * sf * 0.8, 8, 13)

                    px = nx; py = ny
                }

                for (var n = 0; n < nodes.length; n++) {
                    var node = nodes[n]
                    var branchScale = 1.0 - node.tNorm * 0.5
                    var subCount = isUpper ? 2 : 1
                    var baseSpreadHere = radiusAt(node.tNorm)
                    var baseDensityHere = densityAt(node.tNorm)

                    for (var b = 0; b < subCount; b++) {
                        var spreadAngle = rrange(-0.9, -0.25)
                        var subAngle = node.angle + Math.PI + spreadAngle * (b === 0 ? 1 : -0.6)
                        var subLen = rrange(50, 95) * sf * branchScale
                        var sx1 = node.x + Math.cos(subAngle) * subLen
                        var sy1 = node.y + Math.sin(subAngle) * subLen

                        var subStartSpread = baseSpreadHere
                        var subEndSpread = baseSpreadHere * 0.55
                        var subStartDensity = baseDensityHere
                        var subEndDensity = baseDensityHere * 0.6

                        var subRes = drawBranch(node.x, node.y, sx1, sy1,
                            4.5 * sf * branchScale, 1.5 * sf * branchScale, twigColor, 14 * sf,
                            0.26, 8, 14, subStartSpread, subEndSpread, subStartDensity, subEndDensity)

                        for (var w = 0; w < 2; w++) {
                            var twigAngle = subRes.angle + rrange(-0.7, 0.7)
                            var twigLen = rrange(20, 40) * sf * branchScale
                            var tx1 = sx1 + Math.cos(twigAngle) * twigLen
                            var ty1 = sy1 + Math.sin(twigAngle) * twigLen

                            var twigStartSpread = subEndSpread
                            var twigEndSpread = subEndSpread * 0.45
                            var twigStartDensity = subEndDensity
                            var twigEndDensity = subEndDensity * 0.6

                            drawBranch(sx1, sy1, tx1, ty1, 1.8 * sf * branchScale, 0.6 * sf, twigColor, 8 * sf,
                                0.30, 8, 15, twigStartSpread, twigEndSpread, twigStartDensity, twigEndDensity)

                            var tipCount = Math.max(1, Math.round((isUpper ? 6 : 5) * twigEndDensity))
                            drawFlowerCluster(tx1, ty1, tipCount, twigEndSpread * 0.9 * sf, 8, 13)
                        }

                        var nodeCount = Math.max(1, Math.round((isUpper ? 5 : 4) * subStartDensity))
                        var subCount2 = Math.max(1, Math.round((isUpper ? 5 : 4) * subEndDensity))
                        drawFlowerCluster(node.x, node.y, nodeCount, subStartSpread * sf, 9, 14)
                        drawFlowerCluster(sx1, sy1, subCount2, subEndSpread * sf, 8, 13)
                    }
                }

                var c1 = Math.max(1, Math.round((isUpper ? 9 : 7) * densityAt(0.10)))
                var c2 = Math.max(1, Math.round((isUpper ? 8 : 6) * densityAt(0.40)))
                var c3 = Math.max(1, Math.round((isUpper ? 6 : 5) * densityAt(1.0)))

                drawFlowerCluster(startX - mainLength * 0.15, startY - riseAmount * 0.1, c1, radiusAt(0.10) * sf, 10, 16)
                drawFlowerCluster(startX - mainLength * 0.4, startY - riseAmount * 0.4, c2, radiusAt(0.40) * sf, 9, 15)
                drawFlowerCluster(endX, endY, c3, radiusAt(1.0) * sf, 8, 13)
            }

            buildLevel(H * 0.58, W * 0.30, H * 0.10, "#3C1A0E", "#5A2A14", 15, false)
            buildLevel(H * 0.40, W * 0.62, H * 0.30, "#2C140A", "#4A2210", 19, true)

            ctx.restore()
        }

        Component.onCompleted: requestPaint()
    }
}