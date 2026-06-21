import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: root
    exclusionMode: ExclusionMode.Ignore
    margins { left: 0; right: 0; top: 0; bottom: 0 }

    // ╔══════════════════════════════════════════════════════════════════╗
    // ║  CONFIG                                                          ║
    // ╚══════════════════════════════════════════════════════════════════╝
    readonly property string username:         "SilenceSuzuka"
    readonly property string avatarPath:       Quickshell.env("HOME") + "/.config/assets/silence-suzuka.png"
    readonly property string screenshotPath:   "/tmp/qs-lockscreen-bg.png"

    readonly property string passwordFilePath: Quickshell.env("HOME") + "/.config/qs-lock/lockscreen.conf"

    // ╔══════════════════════════════════════════════════════════════════╗
    // ║  LAYOUT                                                          ║
    // ╚══════════════════════════════════════════════════════════════════╝
    readonly property real scaleFactor: Screen.height / 1080.0
    readonly property int avatarSize:        158 * scaleFactor
    readonly property int clockSize:         48 * scaleFactor
    readonly property int dateSize:          30 * scaleFactor
    readonly property int usernameSize:      30 * scaleFactor
    readonly property int pwFieldWidth:      312 * scaleFactor
    readonly property int pwFieldHeight:     49 * scaleFactor
    readonly property int pwFontSize:        16 * scaleFactor
    // ════════════════════════════════════════════════════════════════════

    property int animPhase: 0
    property string correctPassword: ""
    property int wrongAttempts: 0

    anchors { left: true; right: true; top: true; bottom: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    Image {
        id: bgImage
        anchors.fill: parent
        source: "file://" + root.screenshotPath
        fillMode: Image.Stretch
        smooth: true
    }

    Item {
        id: blurLayer
        anchors.fill: parent
        opacity: animPhase >= 7 ? 1 : 0
        visible: true

        Behavior on opacity {
            NumberAnimation { duration: 1400; easing.type: Easing.InOutQuad }
        }

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                source: bgImage
                blurEnabled: true
                blur: 1.0
                blurMax: 48
                blurMultiplier: 1.5
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#99060610"
        }
    }

    ToriiGate {
        id: toriiGate
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.toriiBottomMargin
        animPhase: root.animPhase
        onAnimDone: phase => { root.animPhase = phase }
    }

    Item {
        id: loginContainer
        anchors.horizontalCenter: toriiGate.horizontalCenter

        anchors.verticalCenter: toriiGate.top
        anchors.verticalCenterOffset: toriiGate.contentCenterY

        width: toriiGate.innerWidth
        height: loginContent.implicitHeight

        opacity: animPhase >= 8 ? 1 : 0
        visible: animPhase >= 7

        Behavior on opacity {
            NumberAnimation { duration: 900; easing.type: Easing.OutCubic }
        }

        Column {
            id: loginContent
            anchors.centerIn: parent
            spacing: root.contentSpacing

            Text {
                id: clockText
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: root.clockSize
                font.weight: Font.Light
                color: "#ffffff"
                text: Qt.formatTime(new Date(), "hh:mm")
                Timer {
                    interval: 10000; repeat: true; running: true
                    onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: root.dateSize
                color: "#70ffffff"
                text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
                font.letterSpacing: 0.8
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.avatarSize; height: root.avatarSize
                radius: root.avatarSize / 2
                color: "#1a1a1a"
                border.color: "#35ffffff"; border.width: 2
                clip: true
                Image {
                    anchors.fill: parent
                    source: "file://" + root.avatarPath
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    text: root.username.substring(0,2).toUpperCase()
                    font.pixelSize: root.avatarSize * 0.35
                    font.weight: Font.Medium
                    color: "#ccffffff"
                    visible: parent.children[0].status !== Image.Ready
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.username
                font.pixelSize: root.usernameSize
                font.weight: Font.Medium
                color: "#ffffff"; font.letterSpacing: 0.5
            }

            Rectangle {
                id: pwFieldRect
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.pwFieldWidth
                height: root.pwFieldHeight
                radius: 9
                color: "#12ffffff"
                border.color: pwInput.activeFocus ? "#55ffffff" : "#22ffffff"
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "🔒"; font.pixelSize: 12; color: "#45ffffff"
                    }

                    TextInput {
                        id: pwInput
                        width: root.pwFieldWidth - 48
                        height: root.pwFieldHeight - 16
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        color: "#ffffff"
                        font.pixelSize: root.pwFontSize
                        focus: animPhase >= 8
                        cursorVisible: activeFocus
                        clip: true

                        onFocusChanged: if (focus) forceActiveFocus()

                        Keys.onReturnPressed: {
                            console.log("ENTER PRESSED. animPhase:", root.animPhase, "| typed:", pwInput.text, "| correct:", root.correctPassword, "| activeFocus:", pwInput.activeFocus)

                            if (root.correctPassword !== "" && pwInput.text === root.correctPassword) {
                                feedbackText.text = "Unlocking..."
                                feedbackText.color = "#80ffffff"
                                handoffTimer.restart()
                            } else {
                                feedbackText.text = "Incorrect password"
                                feedbackText.color = "#ff6b6b"
                                root.wrongAttempts++
                                pwInput.text = ""
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Password..."
                            font.pixelSize: root.pwFontSize
                            color: "#38ffffff"
                            visible: pwInput.text.length === 0 && !pwInput.activeFocus
                        }
                    }
                }
            }

            Text {
                id: feedbackText
                anchors.horizontalCenter: parent.horizontalCenter
                text: ""; font.pixelSize: 11; color: "#60ffffff"
            }
        }
    }

    Timer {
        id: blurDoneTimer
        interval: 1500
        onTriggered: animPhase = 8
    }
    onAnimPhaseChanged: {
        if (animPhase === 7) blurDoneTimer.start()
        if (animPhase === 8) pwInput.forceActiveFocus()
    }

    Timer {
        id: handoffTimer
        interval: 350
        onTriggered: Qt.quit()
    }

    FileView {
        id: passwordFile
        path: root.passwordFilePath
        onLoaded: {
            console.log("FileView loaded, path:", root.passwordFilePath)
            console.log("Raw content:", text())
            var lines = text().split("\n")
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.indexOf("password=") === 0) {
                    root.correctPassword = line.substring("password=".length)
                    console.log("Password loaded, length:", root.correctPassword.length)
                    break
                }
            }
        }
        onLoadFailed: function(error) {
            console.log("FileView FAILED to load:", error)
        }
    }

    Component.onCompleted: animPhase = 1
}