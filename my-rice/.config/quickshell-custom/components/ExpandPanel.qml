import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "../theme"

PanelWindow {
    id: expandPanel

    anchors { top: true; right: true; bottom: true }
    exclusiveZone: 0

    implicitWidth: isExpanded ? Quickshell.screens[0].width * 0.3 : 0
    color: "transparent"

    property bool isExpanded: false
    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property bool playing: false
    property var cavaBars: [0,0,0,0,0,0,0,0,0,0,0,0]

    property var lyricLines: []
    property int playPosition: 0
    property int lyricOffset: 0

    property var eqGains: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    property var eqFreqs: ["22Hz", "28Hz", "35Hz", "43Hz", "53Hz", "66Hz", "82Hz", "102Hz", "126Hz", "156Hz"]

    onTitleChanged: {
        if (title !== "" && artist !== "") {
            lyricsProc.searchQuery = title + " " + artist
            lyricsProc.running = true
            lyricLines = []
            lyricOffset = 0
        }
    }

    function getLyricAt(offset) {
        if (lyricLines.length === 0) return ""
        
        var adjustedPos = playPosition + lyricOffset
        
        var idx = -1
        for (var i = 0; i < lyricLines.length; i++) {
            if (lyricLines[i].time <= adjustedPos) {
                idx = i
            } else {
                break
            }
        }
        
        if (idx === -1) idx = 0

        if (offset === 0) {
            var target = idx
            while (target < lyricLines.length && lyricLines[target].text.trim() === "") {
                target++
            }
            if (target >= lyricLines.length) return ""
            return lyricLines[target].text
        }

        var target = idx + offset
        while (target >= 0 && target < lyricLines.length && lyricLines[target].text.trim() === "") {
            target += offset > 0 ? 1 : -1
        }
        if (target < 0 || target >= lyricLines.length) return ""
        return lyricLines[target].text
    }

    function toggle() {
        isExpanded = !isExpanded
    }

    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
    }

    // ── Processes ──────────────────────────────────────────────────────

    Process {
        id: metadataProc
        command: ["playerctl", "metadata", "--format", "TITLE={{title}}||ARTIST={{artist}}||STATUS={{status}}||ART={{mpris:artUrl}}||URL={{xesam:url}}"]
        running: expandPanel.isExpanded
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim()
                var getValue = function(key) {
                    var match = raw.match(new RegExp(key + "=([^|]*)(?:\\|\\||$)"))
                    return match ? match[1].trim() : ""
                }
                expandPanel.title   = getValue("TITLE")
                expandPanel.artist  = getValue("ARTIST")
                expandPanel.playing = (getValue("STATUS") === "Playing")
                var url = getValue("ART")
                var youtubeUrl = getValue("URL")
                if (url === "") {
                    if (youtubeUrl !== "") {
                        lastfmProc.query = youtubeUrl
                        lastfmProc.running = true
                    }
                } else {
                    expandPanel.artUrl = url
                }
            }
        }
    }

    Process {
        id: lastfmProc
        property string query: ""
        command: ["bash", "-c", "echo '" + query + "' | grep -oP '(?<=v=)[^&]+' | head -1 | xargs -I{} echo 'https://img.youtube.com/vi/{}/maxresdefault.jpg'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var url = text.trim()
                if (url !== "") expandPanel.artUrl = url
            }
        }
    }

    Timer {
        interval: 2000
        running: expandPanel.isExpanded
        repeat: true
        onTriggered: {
            if (!metadataProc.running)
                metadataProc.running = true
        }
    }

    Timer {
        id: metadataRefreshTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (!metadataProc.running)
                metadataProc.running = true
        }
    }

    Process { id: prevProc;  command: ["playerctl", "previous"] }
    Process { id: pauseProc; command: ["playerctl", "play-pause"] }
    Process { id: nextProc;  command: ["playerctl", "next"] }

    Process {
        id: cavaProc
        command: ["cava", "-p", "/home/silence-suzuka/.config/cava/quickshell-config"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var trimmed = line.trim()
                if (trimmed === "") return
                var nums = trimmed.split(" ").filter(x => x !== "" && !isNaN(parseInt(x)))
                if (nums.length >= 12)
                    expandPanel.cavaBars = nums.slice(0, 12).map(x => parseInt(x) / 100.0)
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: lyricsProc
        property string searchQuery: ""
        command: ["/home/silence-suzuka/.local/bin/syncedlyrics", "-o", "lrc", searchQuery]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Raw output dari syncedlyrics: " + text.substring(0, 100)) // Cek 100 karakter pertama
                var lines = text.trim().split("\n")
                var parsed = []
                for (var i = 0; i < lines.length; i++) {
                    var match = lines[i].match(/\[(\d+):(\d+\.?\d*)\]\s*(.*)/)
                    if (match) {
                        var ms = (parseInt(match[1]) * 60 + parseFloat(match[2])) * 1000
                        parsed.push({ time: ms, text: match[3] })
                    }
                }
                expandPanel.lyricLines = parsed
                console.log("Jumlah lirik ditemukan: " + parsed.length)
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) console.log("Error syncedlyrics: " + text)
            }
        }
    }

    Process {
        id: positionProc
        command: ["playerctl", "position"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                expandPanel.playPosition = parseFloat(text.trim()) * 1000
                
                var prev = expandPanel.getLyricAt(-1)
                var curr = expandPanel.getLyricAt(0)
                var next = expandPanel.getLyricAt(1)

                if (lyricPrevText.text !== prev) lyricPrevText.text = prev
                if (lyricCurrentText.text !== curr) lyricCurrentText.text = curr
                if (lyricNextText.text !== next) lyricNextText.text = next
            }
        }
    }

    Timer {
        interval: 300
        running: expandPanel.isExpanded && expandPanel.playing
        repeat: true
        onTriggered: {
            if (!positionProc.running)
                positionProc.running = true
        }
    }

    // Process equilizer
    Process {
        id: eqProc
        property int bandIndex: 0
        property real gainValue: 0.0
        property string builtCommand: ""
        command: ["bash", "-c", builtCommand]
        running: false
    }

    Timer {
        id: eqDebounce
        interval: 300
        repeat: false
        onTriggered: {
            eqProc.builtCommand =
                "python3 -c \"" +
                "import json;" +
                "p='/home/silence-suzuka/.local/share/easyeffects/output/MyPreset.json';" +
                "d=json.load(open(p));" +
                "d['output']['equalizer#0']['left']['band" + eqProc.bandIndex + "']['gain']=" + eqProc.gainValue + ";" +
                "d['output']['equalizer#0']['right']['band" + eqProc.bandIndex + "']['gain']=" + eqProc.gainValue + ";" +
                "json.dump(d,open(p,'w'),indent=4)" +
                "\" && easyeffects -l MyPreset"
            eqProc.running = true
        }
    }

    // ── UI ─────────────────────────────────────────────────────────────

    Rectangle {
        anchors.fill: parent
        color: "#0a0e1a"
        border.color: "#1e2a3a"
        border.width: 1
        visible: expandPanel.isExpanded
        clip: true

        // Background grid
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "rgba(80,160,255,0.05)"
                ctx.lineWidth = 1
                for (var x = 0; x < width; x += 24) {
                    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
                }
                for (var y = 0; y < height; y += 24) {
                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                }
            }
        }

        Column {
            id: mainColumn
            anchors { fill: parent; margins: 16 }
            spacing: 10

            // ── SECTION 1: Disk + CAVA ──────────────────────────────────
            Item {
                width: parent.width
                height: 140

                Row {
                    anchors { right: diskContainer.left; rightMargin: 40; verticalCenter: parent.verticalCenter }
                    spacing: 5
                    Repeater {
                        model: 5
                        delegate: Item {
                            id: leftBarItem
                            width: 8; height: 130
                            property real barValue: expandPanel.cavaBars[index]
                            Column {
                                anchors.bottom: parent.bottom
                                width: parent.width; spacing: 2
                                Repeater {
                                    model: 13
                                    delegate: Rectangle {
                                        required property int index
                                        width: 8; height: 7; radius: 2
                                        property real threshold: (12 - index) / 13.0
                                        color: leftBarItem.barValue >= threshold
                                            ? Qt.rgba(0.3 + leftBarItem.barValue * 0.4, 0.4 + leftBarItem.barValue * 0.2, 1.0, 0.85)
                                            : Qt.rgba(1, 1, 1, 0.05)
                                        Behavior on color { ColorAnimation { duration: 60 } }
                                    }
                                }
                            }
                        }
                    }
                }
                Item {
                    id: diskContainer
                    anchors.centerIn: parent
                    width: 140; height: 140

                    property real drumValue: expandPanel.cavaBars[1] || 0
                    property int currentParticle: 0

                    // TIMER GENERATOR
                    Timer {
                        id: auraGenerator
                        interval: 800
                        running: expandPanel.playing
                        repeat: true
                        onTriggered: {
                            var p = particleRepeater.itemAt(diskContainer.currentParticle)
                            if (p && !p.isAnimating) {
                                p.startX = (Math.random() * 190) - 100
                                p.startY = (Math.random() * 160) - 50
                                p.driftY = -(Math.random() * 30) - 20 
                                p.fire()
                                diskContainer.currentParticle = (diskContainer.currentParticle + 1) % 8
                            }
                        }
                    }
                    // Ring 1 biru
                    Rectangle {
                        anchors.centerIn: parent
                        width: 130 + (expandPanel.playing ? (15 + (diskContainer.drumValue * 60)) : 10)
                        height: width; radius: width / 2
                        color: "transparent"; border.color: "#3050ff"; border.width: 2; opacity: 0.3
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    }
                    // Ring 2 ungu
                    Rectangle {
                        anchors.centerIn: parent
                        width: 130 + (expandPanel.playing ? (25 + (diskContainer.drumValue * 80)) : 20)
                        height: width; radius: width / 2
                        color: "transparent"; border.color: "#8030ff"; border.width: 1; opacity: 0.15
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                    }

                    // 2. PIRINGAN HITAM UTAMA (Di tengah)
                    Rectangle {
                        id: diskBody
                        anchors.centerIn: parent
                        width: 130; height: 130; radius: 65
                        color: "#111"; border.color: "#ff6bb5"; border.width: 2
                        
                        scale: expandPanel.playing ? (1.0 + (diskContainer.drumValue * 0.06)) : 1.0
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        RotationAnimator {
                            target: diskBody; from: 0; to: 360
                            duration: 20000; loops: Animation.Infinite
                            running: expandPanel.playing
                        }
                        Image {
                            id: diskImage
                            anchors.fill: parent
                            source: expandPanel.artUrl
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                        }
                        MultiEffect {
                            source: diskImage; anchors.fill: diskImage
                            maskEnabled: true
                            maskSource: ShaderEffectSource {
                                sourceItem: Rectangle { width: diskBody.width; height: diskBody.height; radius: 65 }
                            }
                        }
                    }

                    // 3. REPEATER PARTIKEL AURA
                    Repeater {
                        id: particleRepeater
                        model: 8
                        delegate: Text {
                            id: musicIcon
                            anchors.centerIn: parent
                            
                            text: index % 3 === 0 ? "♫" : (index % 3 === 1 ? "♬" : "♪")
                            font.pixelSize: 16
                            font.bold: true
                            color: "#3050ff"
                            opacity: 0.0
                            scale: 0.0
                            
                            property real startX: 0
                            property real startY: 0
                            property real driftY: -40
                            property bool isAnimating: false

                            function fire() {
                                ambienAnimation.restart()
                            }

                            transform: Translate {
                                id: trans
                                x: musicIcon.startX
                                y: musicIcon.startY
                            }

                            SequentialAnimation {
                                id: ambienAnimation
                                onStarted: musicIcon.isAnimating = true
                                onFinished: {
                                    musicIcon.isAnimating = false
                                    musicIcon.opacity = 0.0
                                    musicIcon.scale = 0.0
                                }

                                ParallelAnimation {
                                    NumberAnimation { 
                                        target: trans; property: "y"; 
                                        from: musicIcon.startY; to: musicIcon.startY + musicIcon.driftY; 
                                        duration: 2000; easing.type: Easing.OutCubic 
                                    }

                                    SequentialAnimation {
                                        ParallelAnimation {
                                            NumberAnimation { target: musicIcon; property: "scale"; from: 0.0; to: 1.5; duration: 600; easing.type: Easing.OutBack }
                                            NumberAnimation { target: musicIcon; property: "opacity"; from: 0.0; to: 0.8; duration: 500 }
                                        }
                                        
                                        PauseAnimation { duration: 600 }
                                        
                                        ParallelAnimation {
                                            NumberAnimation { target: musicIcon; property: "scale"; to: 0.0; duration: 800; easing.type: Easing.InQuad }
                                            NumberAnimation { target: musicIcon; property: "opacity"; to: 0.0; duration: 800 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    anchors { left: diskContainer.right; leftMargin: 40; verticalCenter: parent.verticalCenter }
                    spacing: 5
                    Repeater {
                        model: 5
                        delegate: Item {
                            id: rightBarItem
                            width: 8; height: 130
                            property real barValue: expandPanel.cavaBars[4 - index]
                            Column {
                                anchors.bottom: parent.bottom
                                width: parent.width; spacing: 2
                                Repeater {
                                    model: 13
                                    delegate: Rectangle {
                                        required property int index
                                        width: 8; height: 7; radius: 2
                                        property real threshold: (12 - index) / 13.0
                                        color: rightBarItem.barValue >= threshold
                                            ? Qt.rgba(0.3 + rightBarItem.barValue * 0.4, 0.4 + rightBarItem.barValue * 0.2, 1.0, 0.85)
                                            : Qt.rgba(1, 1, 1, 0.05)
                                        Behavior on color { ColorAnimation { duration: 60 } }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── SECTION 2: Title ────────────────────────────────────────
            Text {
                width: parent.width
                text: expandPanel.title
                color: "#e0eaff"
                font.pixelSize: 15
                font.weight: Font.SemiBold
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            // ── SECTION 3: Artist ───────────────────────────────────────
            Text {
                width: parent.width
                text: expandPanel.artist
                color: "#6080b0"
                font.pixelSize: 12
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            // ── SECTION 4: Media Controls ───────────────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20
                Repeater {
                    model: [
                        { icon: "⏮", proc: prevProc },
                        { icon: expandPanel.playing ? "⏸" : "▶", proc: pauseProc },
                        { icon: "⏭", proc: nextProc }
                    ]
                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: ctrlMa.containsMouse ? "#1a2a4a" : "#0f1828"
                        border.color: "#1e3a5a"; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.pixelSize: 16
                            color: "#a0c0ff"
                        }
                        MouseArea {
                            id: ctrlMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                modelData.proc.running = true
                                metadataRefreshTimer.restart()
                            }
                        }
                    }
                }
            }

            // ── SECTION 5: GIF (left) + Lyric (right) ──────────────────\
            Item {
                width: parent.width
                height: mainColumn.height - 140 - 15 - 14 - 40 - (10 * 4) - 10 - 180
                clip: true

                // Lyric atau Fallback
                Item {
                    anchors.fill: parent

                    // ── FALLBACK: Jukebox ──────────────────────────────
                    Item {
                        id: jukeboxFallback
                        anchors.fill: parent
                        visible: expandPanel.lyricLines.length === 0

                        Image {
                            anchors.centerIn: parent
                            width: parent.width * 0.4
                            height: width
                            source: "/home/silence-suzuka/Downloads/Jukebox.png"
                            fillMode: Image.PreserveAspectFit
                            opacity: 0.85
                        }

                        Repeater {
                            id: jukeParticleRepeater
                            model: 6
                            delegate: Text {
                                id: jukeIcon
                                anchors.centerIn: parent
                                text: index % 3 === 0 ? "♫" : (index % 3 === 1 ? "♬" : "♪")
                                font.pixelSize: 11
                                color: "#a0c0ff"
                                opacity: 0.0
                                scale: 0.0

                                property real startX: 0
                                property real startY: 0
                                property real driftY: -30
                                property bool isAnimating: false

                                function fire() { jukeAnim.restart() }

                                transform: Translate {
                                    id: jukeTrans
                                    x: jukeIcon.startX
                                    y: jukeIcon.startY
                                }

                                SequentialAnimation {
                                    id: jukeAnim
                                    onStarted: jukeIcon.isAnimating = true
                                    onFinished: {
                                        jukeIcon.isAnimating = false
                                        jukeIcon.opacity = 0.0
                                        jukeIcon.scale = 0.0
                                    }
                                    ParallelAnimation {
                                        NumberAnimation {
                                            target: jukeTrans; property: "y"
                                            from: jukeIcon.startY; to: jukeIcon.startY + jukeIcon.driftY
                                            duration: 1800; easing.type: Easing.OutCubic
                                        }
                                        SequentialAnimation {
                                            ParallelAnimation {
                                                NumberAnimation { target: jukeIcon; property: "scale"; from: 0.0; to: 1.2; duration: 500; easing.type: Easing.OutBack }
                                                NumberAnimation { target: jukeIcon; property: "opacity"; from: 0.0; to: 0.7; duration: 400 }
                                            }
                                            PauseAnimation { duration: 500 }
                                            ParallelAnimation {
                                                NumberAnimation { target: jukeIcon; property: "scale"; to: 0.0; duration: 800; easing.type: Easing.InQuad }
                                                NumberAnimation { target: jukeIcon; property: "opacity"; to: 0.0; duration: 800 }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        QtObject {
                            id: jukeParticle
                            property int current: 0
                        }

                        Timer {
                            interval: 900
                            running: jukeboxFallback.visible && expandPanel.playing
                            repeat: true
                            onTriggered: {
                                var p = jukeParticleRepeater.itemAt(jukeParticle.current)
                                if (p && !p.isAnimating) {
                                    p.startX = (Math.random() * (jukeboxFallback.width * 0.6)) - (jukeboxFallback.width * 0.3)
                                    p.startY = (Math.random() * 60) - 30
                                    p.driftY = -(Math.random() * 25) - 15
                                    p.fire()
                                    jukeParticle.current = (jukeParticle.current + 1) % 6
                                }
                            }
                        }
                    }

                    // ── LYRIC ──────────────────────────────────────────
                    Column {
                        anchors {
                            left: parent.left
                            leftMargin: gifImage.width + 12
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                        }
                        visible: expandPanel.lyricLines.length > 0

                        Row {
                            id: offsetRow
                            anchors { top: parent.top; topMargin: 30; horizontalCenter: parent.horizontalCenter }
                            spacing: 5

                            Rectangle {
                                width: 26; height: 17; radius: 4
                                color: slowMa.containsMouse ? "#1a2a4a" : "#0f1828"
                                border.color: "#1e3a5a"; border.width: 1
                                Text { anchors.centerIn: parent; text: "◀◀"; font.pixelSize: 7; color: "#6080b0" }
                                MouseArea { id: slowMa; anchors.fill: parent; hoverEnabled: true; onClicked: expandPanel.lyricOffset -= 500 }
                            }
                            Rectangle {
                                width: 50; height: 17; radius: 4
                                color: "#080d18"; border.color: "#1a2a3a"; border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: { var s = expandPanel.lyricOffset / 1000; return (s >= 0 ? "+" : "") + s.toFixed(1) + "s" }
                                    font.pixelSize: 8
                                    color: expandPanel.lyricOffset === 0 ? "#4060a0" : "#a0c0ff"
                                }
                            }
                            Rectangle {
                                width: 22; height: 17; radius: 4
                                color: rstMa.containsMouse ? "#1a2a4a" : "#0f1828"
                                border.color: "#1e3a5a"; border.width: 1
                                Text { anchors.centerIn: parent; text: "⟳"; font.pixelSize: 9; color: "#6080b0" }
                                MouseArea { id: rstMa; anchors.fill: parent; hoverEnabled: true; onClicked: expandPanel.lyricOffset = 0 }
                            }
                            Rectangle {
                                width: 26; height: 17; radius: 4
                                color: fastMa.containsMouse ? "#1a2a4a" : "#0f1828"
                                border.color: "#1e3a5a"; border.width: 1
                                Text { anchors.centerIn: parent; text: "▶▶"; font.pixelSize: 7; color: "#6080b0" }
                                MouseArea { id: fastMa; anchors.fill: parent; hoverEnabled: true; onClicked: expandPanel.lyricOffset += 500 }
                            }
                        }
                        
                        // Prev lyric
                        Text {
                            id: lyricPrevText
                            anchors { top: offsetRow.bottom; topMargin: 8; left: parent.left; right: parent.right }
                            horizontalAlignment: Text.AlignHCenter
                            color: "#5070a0"; font.pixelSize: 12; opacity: 0.6
                            wrapMode: Text.WordWrap
                            Behavior on text { NumberAnimation { target: lyricPrevText; property: "opacity"; from: 0; to: 0.6; duration: 300 } }
                        }

                        // Current lyric - di tengah
                        Text {
                            id: lyricCurrentText
                            anchors { top: lyricPrevText.bottom; topMargin: 8; left: parent.left; right: parent.right }
                            horizontalAlignment: Text.AlignHCenter
                            color: "#ffffff"; font.pixelSize: 16; font.weight: Font.Bold
                            wrapMode: Text.WordWrap
                            Behavior on text {
                                SequentialAnimation {
                                    PropertyAction { target: lyricCurrentText; property: "opacity"; value: 0 }
                                    ParallelAnimation {
                                        NumberAnimation { target: lyricCurrentText; property: "opacity"; to: 1; duration: 400 }
                                    }
                                }
                            }
                        }

                        // Next lyric
                        Text {
                            id: lyricNextText
                            anchors { top: lyricCurrentText.bottom; topMargin: 8; left: parent.left; right: parent.right }
                            horizontalAlignment: Text.AlignHCenter
                            color: "#5070a0"; font.pixelSize: 12; opacity: 0.6
                            wrapMode: Text.WordWrap
                            Behavior on text { NumberAnimation { target: lyricNextText; property: "opacity"; from: 0; to: 0.6; duration: 300 } }
                        }
                    }
                }
                
                // GIF
                AnimatedImage {
                    id: gifImage
                    property real targetSize: Quickshell.screens[0].width * 0.10
                    
                    width: targetSize
                    height: targetSize
                    
                    x: expandPanel.lyricLines.length === 0 ? (parent.width * 0.15) : 0
                    anchors.top: parent.top
                    anchors.topMargin: 60
                    
                    Behavior on x {
                        NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
                    }
                    
                    source: expandPanel.playing
                        ? "/home/silence-suzuka/Downloads/oguri-cap.gif"
                        : "/home/silence-suzuka/Downloads/sleepy-oguri.gif"
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: false
                }

            }

            // ── SECTION 6: Equalizer ────────────────────────────────────────
            Item {
                width: parent.width
                height: 160

                // Garis tengah (0dB)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 1
                    color: "#1e2a3a"
                }

                Row {
                    anchors.centerIn: parent
                    spacing: (parent.width - 12 * 24) / 11

                    Repeater {
                        model: 10
                        delegate: Item {
                            id: eqBandItem
                            width: 24
                            height: 160
                            property real gain: expandPanel.eqGains[index]  // -12 to +12

                            // Label frekuensi
                            Text {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: expandPanel.eqFreqs[index]
                                font.pixelSize: 7
                                color: "#4060a0"
                            }

                            // Slider track
                            Rectangle {
                                id: sliderTrack
                                width: 4
                                height: 120
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -8
                                radius: 2
                                color: "#0f1828"
                                border.color: "#1e3a5a"
                                border.width: 1

                                // Fill bar
                                Rectangle {
                                    width: parent.width
                                    radius: 2
                                    color: eqBandItem.gain >= 0
                                        ? Qt.rgba(0.3, 0.5, 1.0, 0.7)
                                        : Qt.rgba(0.8, 0.3, 0.5, 0.7)

                                    height: Math.abs(eqBandItem.gain) / 12.0 * 60
                                    anchors.bottom: eqBandItem.gain >= 0 ? sliderTrack.verticalCenter : undefined
                                    anchors.top: eqBandItem.gain < 0 ? sliderTrack.verticalCenter : undefined

                                    Behavior on height { NumberAnimation { duration: 100 } }
                                }
                            }

                            // Thumb
                            Rectangle {
                                id: sliderThumb
                                width: 14; height: 14; radius: 7
                                color: thumbMa.containsMouse ? "#a0c0ff" : "#5080d0"
                                border.color: "#ffffff"; border.width: 1

                                // posisi: tengah = 0dB, atas = +12dB, bawah = -12dB
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: (sliderTrack.y + sliderTrack.height / 2) - (eqBandItem.gain / 12.0 * 60) - height / 2

                                Behavior on y { NumberAnimation { duration: 100 } }

                                MouseArea {
                                    id: thumbMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    drag.target: sliderThumb
                                    drag.axis: Drag.YAxis
                                    drag.minimumY: sliderTrack.y - 7
                                    drag.maximumY: sliderTrack.y + sliderTrack.height - 7

                                    onPositionChanged: {
                                        if (drag.active) {
                                            var center = sliderTrack.y + sliderTrack.height / 2
                                            var rawGain = -(sliderThumb.y + 7 - center) / 60.0 * 12.0
                                            var clamped = Math.max(-12, Math.min(12, rawGain))
                                            var rounded = Math.round(clamped * 2) / 2  // step 0.5dB

                                            var gains = expandPanel.eqGains.slice()
                                            gains[index] = rounded
                                            expandPanel.eqGains = gains

                                            eqProc.bandIndex = index
                                            eqProc.gainValue = rounded
                                            eqDebounce.restart()
                                        }
                                    }
                                }
                            }

                            // Nilai gain
                            Text {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: (eqBandItem.gain >= 0 ? "+" : "") + eqBandItem.gain.toFixed(1)
                                font.pixelSize: 7
                                color: eqBandItem.gain === 0 ? "#4060a0" : "#a0c0ff"
                            }
                        }
                    }
                }
            }
        }
    }
    Item {
        id: fadeHelper
        Component {
            id: fadeAnimation
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300 }
        }
    }
}
