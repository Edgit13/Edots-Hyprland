import "root:/"
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: menuButton

    property bool open: false
    property var onToggleRequested: function() {}

    property bool hovered: mouseArea.containsMouse

    implicitWidth: icon.implicitWidth + 14
    implicitHeight: 22
    radius: GameModeState.active ? 0 : 6

    color: (menuButton.open || hovered) ? Colors.bg3 : "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Behavior on radius {
        NumberAnimation { duration: 150 }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "\ue5c3" // apps (Material Symbols не має лого Arch Linux)
        color: menuButton.open ? Colors.accent : Colors.fg

        font {
            family: "Material Symbols Rounded"
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
        onClicked: menuButton.onToggleRequested()
    }
}
