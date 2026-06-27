import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Io

PanelWindow {
    id: splash

    // path dinamis, baca $HOME langsung dari environment
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string assetsDir: homeDir + "/.config/assets"

    // --- layer-shell setup: full screen, paling atas, exclusive ---
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: -1
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    visible: true

    // blok semua klik/scroll selagi splash tampil
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
    }

    // ====== layer 1: overlay hitam transparan ======
    Rectangle {
        id: dim
        anchors.fill: parent
        color: "black"
        opacity: 0.0
    }

    // ====== layer 2: gif ======
    AnimatedImage {
        id: gif
        source: "file://" + splash.assetsDir + "/hello_oguri.gif"
        anchors.centerIn: parent
        opacity: 0.0
        playing: false
        cache: false

        // biar gif gak ke-stretch aneh kalau ukuran beda monitor
        fillMode: Image.PreserveAspectFit
    }

    // ====== audio: spawn lewat paplay, biar gak gantung QtMultimedia ======
    Process {
        id: audioProc
        command: ["paplay", splash.assetsDir + "/hello.mp3"]
        running: false
        onExited: (code, status) => {
            // begitu audio selesai atau gagal, lanjut ke fade out
            fadeOutSequence.start()
        }
    }

    // ---- animasi fade-in dim ----
    NumberAnimation {
        id: fadeInDim
        target: dim
        property: "opacity"
        from: 0.0
        to: 0.6
        duration: 500
        easing.type: Easing.OutCubic
        onStopped: pauseBeforeGif.start()
    }

    // ---- delay 600ms sebelum gif muncul ----
    Timer {
        id: pauseBeforeGif
        interval: 400
        repeat: false
        onTriggered: {
            gif.playing = true
            fadeInGif.start()
        }
    }

    // ---- fade-in gif + mulai audio bareng ----
    NumberAnimation {
        id: fadeInGif
        target: gif
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: 400
        easing.type: Easing.OutCubic
        onStopped: {
            audioProc.running = true
        }
    }

    // ---- fade-out gif lalu dim, dijalankan setelah audio selesai ----
    SequentialAnimation {
        id: fadeOutSequence

        NumberAnimation {
            target: gif
            property: "opacity"
            from: 0.6
            to: 0.0
            duration: 400
            easing.type: Easing.InCubic
        }

        ScriptAction { script: gif.playing = false }

        NumberAnimation {
            target: dim
            property: "opacity"
            from: 0.6
            to: 0.0
            duration: 400
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: {
                splash.visible = false
                splash.destroyLater()
            }
        }
    }

    Component.onCompleted: {
        fadeInDim.start()
    }
}