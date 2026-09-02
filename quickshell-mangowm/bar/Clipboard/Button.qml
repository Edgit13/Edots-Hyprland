import "root:/"
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: clipButton

    property bool open: false
    property var onToggleRequested: function() {}

    property bool hovered: mouseArea.containsMouse

    implicitWidth: icon.implicitWidth + 14
    implicitHeight: 22
    radius: GameModeState.active ? 0 : 6

    color: (clipButton.open || hovered) ? Colors.bg3 : "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Behavior on radius {
        NumberAnimation { duration: 150 }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "\ue14f" // content_paste
        color: clipButton.open ? Colors.accent : Colors.fg

        font {
            family: "Material Symbols Rounded"
            pixelSize: 14
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: clipButton.onToggleRequested()
    }
}
