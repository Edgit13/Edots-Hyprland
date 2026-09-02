import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: confirm
    required property var modelData
    screen: modelData

    property bool open: false
    signal requestClose()
    signal confirmed()

    anchors {
        top: true
        right: true
    }

    margins.top: 30
    margins.right: 44
    implicitWidth: confirm.open ? 200 : 0
    implicitHeight: 70
    exclusiveZone: 0
    color: "transparent"

    Behavior on implicitWidth {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        onExited: {
            confirm.confirmed()
            confirm.requestClose()
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        radius: 12
        color: Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.92)
        border.color: Colors.red
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Text {
                text: "Clear all history?"
                color: Colors.fg
                font.pixelSize: 12
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    radius: 6
                    color: cancelHover.containsMouse ? Colors.bg3 : Colors.bg2

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Colors.fg
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: cancelHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: confirm.requestClose()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    radius: 6
                    color: confirmHover.containsMouse ? Colors.red : Colors.bg2

                    Text {
                        anchors.centerIn: parent
                        text: "Clear"
                        color: confirmHover.containsMouse ? Colors.bg0 : Colors.red
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: confirmHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wipeProc.running = true
                    }
                }
            }
        }
    }
}
