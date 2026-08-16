import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "root:/"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    property bool open: false
    signal requestClose()

    visible: open

    anchors {
        top: true
        right: true
    }

    margins {
        top: 32
        right: 14
    }

    width: contentLayout.implicitWidth + 24
    height: contentLayout.implicitHeight + 24
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.95)
        border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.15)
        border.width: 1
        radius: 12

        RowLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: 6

            Text {
                visible: SystemTray.items.count === 0
                text: "Немає активних треїв"
                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.5)
                font.pixelSize: 12
                Layout.margins: 8
            }

            Repeater {
                model: SystemTray.items

                Rectangle {
                    id: trayItem
                    required property var modelData

                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: itemMouseArea.containsMouse ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1) : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 18
                        asynchronous: true
                        source: trayItem.modelData.icon
                    }

                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        // Підказка з назвою застосунку (bluetooth/wifi/тощо)
                        ToolTip.visible: containsMouse && trayItem.modelData.tooltipTitle.length > 0
                        ToolTip.text: trayItem.modelData.tooltipTitle
                        ToolTip.delay: 400

                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu) {
                                trayItem.modelData.display(root, mouse.x, mouse.y)
                            } else if (trayItem.modelData.onlyMenu && trayItem.modelData.hasMenu) {
                                trayItem.modelData.display(root, mouse.x, mouse.y)
                            } else {
                                trayItem.modelData.activate()
                            }
                        }
                    }
                }
            }
        }
    }
}
