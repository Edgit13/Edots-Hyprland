import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    property bool open: false
    signal requestClose()

    visible: open

    // Розміщення на найвищому шарі (Overlay), щоб панель відкривалася поверх усіх програм
    WlrLayershell.layer: WlrLayer.Overlay
    // Не резервувати місця на екрані
    exclusiveZone: 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: 40
        right: 4
    }

    width: 240
    height: contentLayout.implicitHeight + 24
    color: "transparent"

    // Процес для виконання команд живлення
    Process {
        id: powerProc
    }

    function run(cmd) {
        powerProc.command = cmd
        powerProc.running = true
        root.requestClose()
    }

    // Головний акриловий контейнер
    Rectangle {
        anchors.fill: parent
        // Акрилова напівпрозорість
        color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.72)
        border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.20)
        border.width: 1
        radius: 14

        // Внутрішня легка світлова облямівка для підсилення ефекту скла
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            radius: 13
        }

        ColumnLayout {
            id: contentLayout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 4

            Text {
                text: "ЖИВЛЕННЯ"
                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.5)
                font.bold: true
                font.pixelSize: 11
                Layout.leftMargin: 8
                Layout.topMargin: 4
                Layout.bottomMargin: 6
            }

            MenuItem {
                text: "Заблокувати"
                icon: "\ue899" // lock
                onClicked: root.run(["hyprlock", "-c", Quickshell.env("HOME") + "/.config/hypr/hyprlock/hyprlock.conf"])
            }

            MenuItem {
                text: "Заблокувати і призупинити"
                icon: "\uf159" // bedtime
                onClicked: root.run([
                    "bash", "-c",
                    "pidof hyprlock >/dev/null || hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf & " +
                    "for i in $(seq 1 30); do pgrep -x hyprlock >/dev/null && break; sleep 0.1; done; " +
                    "sleep 0.5; " +
                    "systemctl suspend"
                ])
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                height: 1
                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)
            }

            MenuItem {
                text: "Вийти з сеансу"
                icon: "\ue9ba" // logout
                onClicked: root.run(["hyprctl", "dispatch", "exit"])
            }

            MenuItem {
                text: "Перезавантаження"
                icon: "\uf053" // restart_alt
                hoverColor: Qt.rgba(1, 0.7, 0.2, 0.2)
                onClicked: root.run(["systemctl", "reboot"])
            }

            MenuItem {
                text: "Вимкнути ПК"
                icon: "\uf8c7" // power_settings_new
                hoverColor: Qt.rgba(1, 0.3, 0.3, 0.2)
                onClicked: root.run(["systemctl", "poweroff"])
            }
        }
    }

    // Компонент елемента списку меню
    component MenuItem: Rectangle {
        id: itemRoot

        property string text: ""
        property string icon: ""
        property color hoverColor: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12)

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 36
        color: itemMouseArea.containsMouse ? hoverColor : "transparent"
        radius: 8

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            Text {
                text: itemRoot.icon
                color: Colors.fg
                Layout.preferredWidth: 18
                horizontalAlignment: Text.AlignHCenter
                font.family: "Material Symbols Rounded"
                font.pixelSize: 14
            }

            Text {
                Layout.fillWidth: true
                text: itemRoot.text
                color: Colors.fg
                font.pixelSize: 13
            }
        }

        MouseArea {
            id: itemMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: itemRoot.clicked()
        }
    }
}
