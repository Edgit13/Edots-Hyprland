import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
    spacing: 6

    Repeater {
        model: 9

        Rectangle {
            id: wsButton
            required property int index

            property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
            property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

            implicitWidth: 24
            implicitHeight: 22
            Layout.alignment: Qt.AlignVCenter
            radius: GameModeState.active ? 0 : 6

            color: isActive ? Colors.bg3 : (ws ? Colors.bg2 : "transparent")

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Behavior on radius {
                NumberAnimation { duration: 150 }
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: wsButton.index + 1
                color: wsButton.isActive ? Colors.accent : Colors.fg

                font {
                    family: "SF Mono"
                    pixelSize: 14
                    weight: 500
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (parent.index + 1) + " })")
            }
        }
    }
}