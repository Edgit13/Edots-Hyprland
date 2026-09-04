import Quickshell
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 6

    property int workspaceCount: 9
    property int activeWorkspace: 1

    Repeater {
        model: root.workspaceCount

        Rectangle {
            id: wsButton
            required property int index

            property int workspaceId: index + 1
            property bool isActive: root.activeWorkspace === workspaceId

            implicitWidth: 24
            implicitHeight: 22
            Layout.alignment: Qt.AlignVCenter
            radius: GameModeState.active ? 0 : 6
            color: isActive ? Colors.bg3 : Colors.bg2

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Behavior on radius {
                NumberAnimation { duration: 150 }
            }

            Text {
                anchors.centerIn: parent
                text: wsButton.workspaceId
                color: wsButton.isActive ? Colors.accent : Colors.fg

                font {
                    family: "SF Mono"
                    pixelSize: 14
                    weight: 500
                }
            }
        }
    }
}
