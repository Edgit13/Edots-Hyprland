import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Wrap in a MouseArea so the whole pill is clickable, same pattern as Network.qml
MouseArea {
    id: root
    implicitWidth: mainLayout.implicitWidth + (GameModeState.active ? 16 : 0)
    implicitHeight: mainLayout.implicitHeight
    cursorShape: Qt.PointingHandCursor

    onClicked: toggleProc.running = true

    Process {
        id: toggleProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/gamemode.sh"]
        running: false
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        // Squared off while game mode is on, pill-shaped otherwise
        radius: GameModeState.active ? 0 : height / 2
        color: Colors.accent
        opacity: GameModeState.active ? 0.15 : 0
        border.color: Colors.accent
        border.width: GameModeState.active ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Behavior on radius {
            NumberAnimation { duration: 150 }
        }
    }

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 6

        Text {
            text: String.fromCodePoint(0xea28) // sports_esports
            color: GameModeState.active ? Colors.accent : Colors.grey1

            font {
                family: "Material Symbols Rounded"
                pixelSize: 13
            }
        }

        Text {
            text: GameModeState.active ? "Game Mode" : ""
            visible: GameModeState.active
            color: Colors.accent

            font {
                family: "SF Pro Display"
                weight: 500
            }
        }
    }
}
