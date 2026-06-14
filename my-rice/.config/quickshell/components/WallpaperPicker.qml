import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../theme"

PanelWindow {
    id: wallpaperPicker

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    visible: false
    color: "transparent"

    property var wallpapers: []
    property bool animating: false

    function open() {
        wallpapers = []
        lsProc.running = false
        lsProc.running = true
        visible = true
    }

    function close() {
        visible = false
        wallpapers = []
        animating = false
    }

    function throwAndNext() {
        if (animating) return
        animating = true
        throwAnim.start()
    }

    Process {
        id: lsProc
        command: ["bash", "-c", "find /home/$USER/Pictures/Wallpapers -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim()
                if (trimmed.length === 0) return
                let newList = wallpaperPicker.wallpapers.slice()
                newList.push(trimmed)
                wallpaperPicker.wallpapers = newList
            }
        }
    }

    property string pendingWallpaper: ""

    Process {
        id: swaybgProc
        command: ["bash", "-c", "echo noop"]
        running: false
        onRunningChanged: console.log("proc running:", running)
        stderr: SplitParser {
            onRead: data => console.log("stderr:", data)
        }
    }

    function setWallpaper(path) {
        console.log("Setting wallpaper:", path)
        swaybgProc.running = false
        Qt.callLater(() => {
            swaybgProc.command = ["bash", "-c",
                "echo '" + path + "' > $HOME/.cache/current-wallpaper; " +
                "OLD=$(pgrep swaybg | head -1); " +
                "swaybg -i '" + path + "' -m fill & " +
                "sleep 0.3; " +
                "[ -n \"$OLD\" ] && kill $OLD"
            ]
            swaybgProc.running = true
        })
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: deckArea.top
        anchors.bottomMargin: 24
        text: wallpapers.length > 0
            ? "→ / Enter  set wallpaper    •    Esc  close    •    " + wallpapers.length + " wallpapers"
            : "Loading wallpapers…"
        color: Qt.rgba(1, 1, 1, 0.6)
        font.pixelSize: 13
    }

    Item {
        id: deckArea
        width: 600
        height: 380
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48

        PathView {
            id: cardStack
            anchors.fill: parent
            focus: true
            model: wallpaperPicker.wallpapers

            pathItemCount: 5
            preferredHighlightBegin: 0.0
            preferredHighlightEnd: 0.0
            highlightMoveDuration: 300

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    wallpaperPicker.close()
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    if (wallpapers.length > 0)
                        wallpaperPicker.throwAndNext()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (wallpapers.length > 0) {
                        wallpaperPicker.setWallpaper(wallpapers[cardStack.currentIndex])
                        wallpaperPicker.close()
                    }
                    event.accepted = true
                }
            }

            delegate: Item {
                id: delegateRoot
                width: 320
                height: 200

                property int stackIndex: (index >= cardStack.currentIndex)
                    ? (index - cardStack.currentIndex)
                    : (wallpaperPicker.wallpapers.length - cardStack.currentIndex + index)

                property bool isVisibleStack: stackIndex < 4

                z: isVisibleStack ? (100 - stackIndex) : 0
                visible: isVisibleStack

                Item {
                    anchors.fill: parent

                    transform: [
                        Translate {
                            x: PathView.isCurrentItem ? cardTranslateX.x : (stackIndex * 22)
                            y: PathView.isCurrentItem ? cardTranslateY.y : (stackIndex * -8)
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        },
                        Rotation {
                            origin.x: 160; origin.y: 200
                            angle: PathView.isCurrentItem ? cardRotation.angle : (stackIndex * 5)
                            Behavior on angle { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    ]

                    Rectangle {
                        width: PathView.isCurrentItem ? 360 : 320
                        height: PathView.isCurrentItem ? 225 : 200
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        radius: 16
                        color: Colors.surface
                        border.color: PathView.isCurrentItem ? Colors.accent : Colors.panelBorder
                        border.width: PathView.isCurrentItem ? 2 : 1
                        clip: true

                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                        Image {
                            anchors.fill: parent
                            source: "file://" + modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 32
                            color: "#aa000000"
                            visible: PathView.isCurrentItem
                            Text {
                                anchors.centerIn: parent
                                text: modelData.split("/").pop()
                                color: "#ffffff"
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                                width: parent.width - 16
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            width: counterText.width + 12
                            height: 22
                            radius: 11
                            color: Colors.accentDim
                            visible: PathView.isCurrentItem
                            Text {
                                id: counterText
                                anchors.centerIn: parent
                                text: (index + 1) + " / " + wallpaperPicker.wallpapers.length
                                color: "#ffffff"
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }

            path: Path {
                startX: deckArea.width / 2
                startY: deckArea.height - 60
                PathLine {
                    x: deckArea.width / 2
                    y: deckArea.height - 30
                }
            }
        }

        QtObject { id: cardTranslateX; property real x: 0 }
        QtObject { id: cardTranslateY; property real y: 0 }
        QtObject { id: cardRotation;   property real angle: 0 }

        SequentialAnimation {
            id: throwAnim

            ParallelAnimation {
                NumberAnimation {
                    target: cardTranslateX; property: "x"
                    from: 0; to: 30
                    duration: 320; easing.type: Easing.InBack
                }
                NumberAnimation {
                    target: cardTranslateY; property: "y"
                    from: 0; to: 600        // jatuh ke bawah
                    duration: 320; easing.type: Easing.InQuart
                }
                NumberAnimation {
                    target: cardRotation; property: "angle"
                    from: 0; to: 15
                    duration: 320; easing.type: Easing.InQuart
                }
            }

            ScriptAction {
                script: {
                    cardStack.incrementCurrentIndex()
                    cardTranslateX.x = 0
                    cardTranslateY.y = 0
                    cardRotation.angle = 0
                    wallpaperPicker.animating = false
                    
                    wallpaperPicker.setWallpaper(wallpaperPicker.wallpapers[cardStack.currentIndex])
                }
            }
        }
    }
}