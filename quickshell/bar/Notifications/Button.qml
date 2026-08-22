import "root:/"
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: swayncButton

    property bool active: false
    property bool dndActive: false
    property int notificationCount: 0

    implicitWidth: icon.implicitWidth + (notificationCount > 0 ? 28 : 14)
    implicitHeight: 22
    radius: GameModeState.active ? 0 : 6

    // Колір фону кнопки при наведенні чи активності
    color: (swayncButton.active || mouseArea.containsMouse) ? "#1d3631" : "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Behavior on radius {
        NumberAnimation { duration: 150 }
    }

    // Процес для отримання поточного статусу DND (Не турбувати)
    Process {
        id: statusProc
        command: ["swaync-client", "-D"]
        stdout: StdioCollector {
            onStreamFinished: {
                var isDnd = this.text.trim() === "true"
                swayncButton.dndActive = isDnd
                countProc.running = true
            }
        }
    }

    // Процес для отримання кількості пропущених сповіщень
    Process {
        id: countProc
        command: ["swaync-client", "-c"]
        stdout: StdioCollector {
            onStreamFinished: {
                var count = parseInt(this.text.trim())
                swayncButton.notificationCount = isNaN(count) ? 0 : count
            }
        }
    }

    // Процес для виклику оригінальної панелі SwayNC
    Process {
        id: toggleProc
        command: ["swaync-client", "-t", "-sw"]
    }

    // Таймер для автоматичного фонового оновлення статусу кожні 3 секунди
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statusProc.running = false
            statusProc.running = true
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            id: icon
            text: swayncButton.dndActive ? "\uf08f" : "\ue7f5" // do_not_disturb_on / notifications
            color: swayncButton.notificationCount > 0 ? "#3dd1b0" : "#f5e2c5"
            font {
                family: "Material Symbols Rounded"
                pixelSize: 13
            }
        }

        // Червоний кружечок із кількістю сповіщень
        Rectangle {
            visible: swayncButton.notificationCount > 0
            width: 14
            height: 14
            radius: GameModeState.active ? 0 : 7
            color: "#ff5555"

            Behavior on radius {
                NumberAnimation { duration: 150 }
            }
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: swayncButton.notificationCount
                color: "#ffffff"
                font.pixelSize: 9
                font.bold: true
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggleProc.running = true // Перемикаємо оригінальну панель SwayNC
            statusProc.running = true // Миттєво оновлюємо іконку та лічильник
        }
    }
}
