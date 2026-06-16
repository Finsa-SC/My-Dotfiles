import QtQuick

Item {
    implicitHeight: 20
    property string text: ""

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: parent.text
        font.pixelSize: 8
        font.letterSpacing: 1.5
        color: "#6e738d"
    }
}
