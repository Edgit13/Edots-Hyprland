import "root:/"
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: wallButton

    property bool open: false
    property var onToggleRequested: function() {}

    property bool hovered: mouseArea.containsMouse

    implicitWidth: icon.implicitWidth + 14
    implicitHeight: 22
    radius: GameModeState.active ? 0 : 6

    color: (wallButton.open || hovered) ? "#1d3631" : "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Behavior on radius {
        NumberAnimation { duration: 150 }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "\uF03E"
        color: wallButton.open ? "#3dd1b0" : "#f5e2c5"

        font {
            family: "JetBrainsMono Nerd Font Propo"
            pixelSize: 14
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: wallButton.onToggleRequested()
    }
}
