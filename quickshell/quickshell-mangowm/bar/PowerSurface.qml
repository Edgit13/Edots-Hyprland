import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Power controls for the MangoWM-oriented pill shell fork.
// Session lock / logout commands are intentionally generic stubs and may
// need to be adjusted to your compositor/session setup.

Item {
    id: root

    Process {
        id: powerProc
    }

    function run(cmd) {
        powerProc.command = cmd
        powerProc.running = true
    }

    component PowerItem: Rectangle {
        id: itemRoot
        property string text: ""
        property string icon: ""
        property color hoverColor: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12)
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 36
        radius: 8
        color: itemHover.hovered ? hoverColor : "transparent"

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
                font { family: "Material Symbols Rounded"; pixelSize: 14 }
            }
            Text {
                Layout.fillWidth: true
                text: itemRoot.text
                color: Colors.fg
                font.pixelSize: 12
            }
        }

        HoverHandler { id: itemHover }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: itemRoot.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        PowerItem {
            text: "Заблокувати"
            icon: "\ue899" // lock
            onClicked: root.run(["loginctl", "lock-session"])
        }

        PowerItem {
            text: "Заблокувати і призупинити"
            icon: "\uf159" // bedtime
            onClicked: root.run(["bash", "-lc", "loginctl lock-session; sleep 0.5; systemctl suspend"])
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            height: 1
            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)
        }

        PowerItem {
            text: "Вийти з сеансу"
            icon: "\ue9ba" // logout
            onClicked: root.run(["loginctl", "terminate-user", Quickshell.env("USER")])
        }

        PowerItem {
            text: "Перезавантаження"
            icon: "\uf053" // restart_alt
            hoverColor: Qt.rgba(1, 0.7, 0.2, 0.2)
            onClicked: root.run(["systemctl", "reboot"])
        }

        PowerItem {
            text: "Вимкнути ПК"
            icon: "\uf8c7" // power_settings_new
            hoverColor: Qt.rgba(1, 0.3, 0.3, 0.2)
            onClicked: root.run(["systemctl", "poweroff"])
        }

        Item { Layout.fillHeight: true }
    }
}
