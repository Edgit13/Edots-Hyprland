import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: panel
    required property var modelData
    screen: modelData

    property bool open: false
    property int refreshTick: 0
    signal requestClose()
    signal requestWipeConfirm()

    property var entries: []

    // Розрахунок динамічної висоти на основі кількості записів
    // Якщо елементів немає, висота буде невеликою (90px), щоб вмістити компактну іконку.
    readonly property int calculatedHeight: {
        if (panel.entries.length === 0) {
            return 90;
        }
        var contentHeight = (panel.entries.length * 40) + 36;
        return Math.min(Math.max(contentHeight, 90), 350); // Мінімальна висота 90px, максимальна 350px
    }

    anchors {
        top: true
        left: true
        right: true
    }

    margins.top: 30
    margins.left: 8
    implicitWidth: Math.round((panel.screen ? panel.screen.width : 1920) * 0.57)
    implicitHeight: panel.open ? panel.calculatedHeight : 0
    exclusiveZone: 0
    color: "transparent"

    Behavior on implicitWidth {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    onOpenChanged: if (open) refresh()
    onRefreshTickChanged: if (open) refresh()

    function refresh() {
        listProc.running = false
        listProc.running = true
    }

    function parseList(raw) {
        var lines = raw.split("\n")
        var out = []
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line.length === 0)
                continue
            var tabIdx = line.indexOf("\t")
            if (tabIdx === -1)
                continue
            out.push({
                id: line.slice(0, tabIdx),
                preview: line.slice(tabIdx + 1)
            })
        }
        panel.entries = out
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: panel.parseList(this.text)
        }
    }

    Process {
        id: copyProc

        function copy(id, preview) {
            command = ["sh", "-c",
                "printf '%s\\t%s' \"$1\" \"$2\" | cliphist decode | wl-copy",
                "--", id, preview
            ]
            running = true
        }

        onExited: refreshTimer.restart()
    }

    Process {
        id: deleteProc

        function del(id, preview) {
            command = ["sh", "-c",
                "printf '%s\\t%s' \"$1\" \"$2\" | cliphist delete",
                "--", id, preview
            ]
            running = true
        }

        onExited: refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 150
        onTriggered: panel.refresh()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 8
        radius: 14
        
        // Повертаємо стандартний колір панелі замість великого синього екрана
        color: Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.88)
        border.color: Colors.bg4
        border.width: 1
        clip: true

        Behavior on color {
            ColorAnimation { duration: 200 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }

        // Компактний BSOD-смайлик та текст по центру панелі, коли вона порожня
        RowLayout {
            anchors.centerIn: parent
            visible: panel.entries.length === 0
            spacing: 14

            Text {
                text: ":("
                color: Colors.accent || "#0078d7"
                font.pixelSize: 28
                font.family: "monospace"
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "you dont have any history right now"
                    color: Colors.fg
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                Text {
                    text: "code: 0"
                    color: Colors.grey1
                    font.pixelSize: 10
                    font.family: "monospace"
                }
            }
        }

        // Список кліпборда (показується, коли є записи)
        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 10
            anchors.topMargin: 32 // Залишаємо місце зверху під кнопки керування
            anchors.rightMargin: 36
            spacing: 6
            clip: true
            model: panel.entries
            visible: panel.entries.length > 0

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index

                width: list.width
                height: 34
                radius: 8
                color: rowHover.containsMouse ? Colors.bg3 : Colors.bg2

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.preview
                        color: Colors.fg
                        elide: Text.ElideRight
                        font.pixelSize: 12
                    }

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 5
                        color: delHover.containsMouse ? Colors.red : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: delHover.containsMouse ? Colors.bg0 : Colors.grey2
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: delHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: deleteProc.del(row.modelData.id, row.modelData.preview)
                        }
                    }
                }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        copyProc.copy(row.modelData.id, row.modelData.preview)
                        panel.requestClose()
                    }
                }
            }
        }

        // Скролінг коліщатком миші
        MouseArea {
            anchors.fill: list
            acceptedButtons: Qt.NoButton
            visible: panel.entries.length > 0
            onWheel: (event) => {
                list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, list.contentY - event.angleDelta.y))
                event.accepted = true
            }
        }

        // Кнопка очищення (кошик)
        Rectangle {
            id: wipeBtn
            width: 22
            height: 22
            radius: 6
            anchors.top: parent.top
            anchors.right: closeBtn.left
            anchors.margins: 6
            anchors.rightMargin: 6
            color: wipeHover.containsMouse ? Colors.bg3 : "transparent"

            Text {
                anchors.centerIn: parent
                text: "🗑"
                color: Colors.fg
                font.pixelSize: 11
            }

            MouseArea {
                id: wipeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.requestWipeConfirm()
            }
        }

        // Кнопка закриття (хрестик)
        Rectangle {
            id: closeBtn
            width: 22
            height: 22
            radius: 6
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 6
            color: closeHover.containsMouse ? Colors.bg3 : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: Colors.fg
                font.pixelSize: 11
            }

            MouseArea {
                id: closeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.requestClose()
            }
        }
    }
}
