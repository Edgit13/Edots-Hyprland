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

    // Розміщення меню на найвищому шарі (Overlay), щоб воно відкривалося поверх усіх програм
    WlrLayershell.layer: WlrLayer.Overlay
    // Не резервувати ексклюзивну зону екрана, щоб меню не зсувало вікна програм
    exclusiveZone: 0

    anchors {
        top: true
        left: true
    }

    margins {
        // Верхній відступ для позиціонування точно під нотчем
        top: 40
        left: 4
    }

    width: 260
    height: contentLayout.implicitHeight + 24
    color: "transparent"

    // Процес для запуску команд та застосунків
    Process {
        id: appLauncher
    }

    // Процес для перемикання Modern (HyprGlass) режиму
    Process {
        id: modernToggler
    }

    // Головний акриловий контейнер меню
    Rectangle {
        anchors.fill: parent
        // Акрилова напівпрозорість замість щільного фону
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

            // Заголовок розділу
            Text {
                text: "ГОЛОВНЕ МЕНЮ"
                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.5)
                font.bold: true
                font.pixelSize: 11
                Layout.leftMargin: 8
                Layout.topMargin: 4
                Layout.bottomMargin: 6
            }

            // Швидкий запуск додатків
            MenuItem {
                text: "Термінал"
                icon: "\uf120"
                onClicked: {
                    appLauncher.command = ["alacritty"]
                    appLauncher.running = true
                    root.requestClose()
                }
            }

            MenuItem {
                text: "Браузер"
                icon: "\uf0ac"
                onClicked: {
                    appLauncher.command = ["zen-browser"]
                    appLauncher.running = true
                    root.requestClose()
                }
            }

            MenuItem {
                text: "Файловий менеджер"
                icon: "\uf07b"
                onClicked: {
                    appLauncher.command = ["nautilus"]
                    appLauncher.running = true
                    root.requestClose()
                }
            }

            // Розділювальна лінія
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                height: 1
                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)
            }

            // Заголовок розділу дизайну
            Text {
                text: "ДИЗАЙН"
                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.5)
                font.bold: true
                font.pixelSize: 11
                Layout.leftMargin: 8
                Layout.bottomMargin: 4
            }

            MenuToggleItem {
                text: "HyprGlass"
                icon: "\uf5fc"
                active: ModernModeState.active
                onClicked: {
                    modernToggler.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/modernmode.sh"]
                    modernToggler.running = true
                    // Не закриваємо меню — щоб було видно, як індикатор перемкнувся
                }
            }

            // Розділювальна лінія
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                height: 1
                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)
            }

            // Системний заголовок
            Text {
                text: "СИСТЕМА"
                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.5)
                font.bold: true
                font.pixelSize: 11
                Layout.leftMargin: 8
                Layout.bottomMargin: 4
            }

            MenuItem {
                text: "Блокування"
                icon: "\uf023"
                onClicked: {
                    appLauncher.command = ["hyprlock"]
                    appLauncher.running = true
                    root.requestClose()
                }
            }

            MenuItem {
                text: "Перезавантаження"
                icon: "\uf021"
                hoverColor: Qt.rgba(1, 0.7, 0.2, 0.2)
                onClicked: {
                    appLauncher.command = ["systemctl", "reboot"]
                    appLauncher.running = true
                    root.requestClose()
                }
            }

            MenuItem {
                text: "Вимкнути ПК"
                icon: "\uf011"
                hoverColor: Qt.rgba(1, 0.3, 0.3, 0.2)
                onClicked: {
                    appLauncher.command = ["systemctl", "poweroff"]
                    appLauncher.running = true
                    root.requestClose()
                }
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

                font {
                    family: "JetBrainsMono Nerd Font Propo"
                    pixelSize: 14
                }
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

    // Елемент меню-перемикача (з індикатором стану праворуч)
    component MenuToggleItem: Rectangle {
        id: toggleRoot

        property string text: ""
        property string icon: ""
        property bool active: false

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 36
        color: toggleMouseArea.containsMouse ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12) : "transparent"
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
                text: toggleRoot.icon
                color: toggleRoot.active ? Colors.accent : Colors.fg
                Layout.preferredWidth: 18
                horizontalAlignment: Text.AlignHCenter

                font {
                    family: "JetBrainsMono Nerd Font Propo"
                    pixelSize: 14
                }
            }

            Text {
                Layout.fillWidth: true
                text: toggleRoot.text
                color: Colors.fg
                font.pixelSize: 13
            }

            // Індикатор-пігулка з крапкою, як типовий перемикач
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 30
                height: 16
                radius: 8
                color: toggleRoot.active ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.18)

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    x: toggleRoot.active ? parent.width - width - 2 : 2
                    color: Colors.bg0

                    Behavior on x {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        MouseArea {
            id: toggleMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggleRoot.clicked()
        }
    }
}
