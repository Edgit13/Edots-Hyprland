import "root:/"
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: powerButton

    property bool open: false
    property var onToggleRequested: function() {}

    property bool hovered: mouseArea.containsMouse

    implicitWidth: icon.implicitWidth + 14
    implicitHeight: 22
    radius: GameModeState.active ? 0 : 6

    color: (powerButton.open || hovered) ? Colors.bg3 : "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Behavior on radius {
        NumberAnimation { duration: 150 }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "\uf011"
        color: powerButton.open ? Colors.red : Colors.fg

        font {
            family: "JetBrainsMono Nerd Font Propo"
            pixelSize: 14
        }

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: powerButton.onToggleRequested()
    }
}
