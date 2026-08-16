import "root:/"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

Rectangle {
    id: trayButton

    property bool open: false
    property var onToggleRequested: function() {}

    property bool hovered: mouseArea.containsMouse

    implicitWidth: icon.implicitWidth + 14
    implicitHeight: 22
    radius: GameModeState.active ? 0 : 6
    visible: SystemTray.items.count > 0

    color: (trayButton.open || hovered) ? Colors.bg3 : "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Behavior on radius {
        NumberAnimation { duration: 150 }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "\uf141"
        color: trayButton.open ? Colors.accent : Colors.fg

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
        onClicked: trayButton.onToggleRequested()
    }
}
