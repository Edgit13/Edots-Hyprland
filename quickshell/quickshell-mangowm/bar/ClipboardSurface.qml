import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// ClipboardSurface.qml — вміст (без вікна) для Pill-режиму. Логіка й
// команди 1:1 з Clipboard/Panel.qml + ConfirmWipe.qml (жоден файл не
// чіпався): cliphist list/decode/delete/wipe, той самий формат "id\tpreview".
// ==========================================================================

Item {
    id: root

    property var entries: []
    property bool confirmingWipe: false

    function refresh() {
        listProc.running = false
        listProc.running = true
    }

    function parseList(raw) {
        const lines = raw.split("\n")
        const out = []
        for (const line of lines) {
            if (line.length === 0) continue
            const tabIdx = line.indexOf("\t")
            if (tabIdx === -1) continue
            out.push({ id: line.slice(0, tabIdx), preview: line.slice(tabIdx + 1) })
        }
        root.entries = out
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseList(text)
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

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        onExited: {
            root.confirmingWipe = false
            refreshTimer.restart()
        }
    }

    Timer {
        id: refreshTimer
        interval: 150
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Буфер обміну"
                color: Colors.accent
                font { family: "SF Pro Display"; pixelSize: 12; weight: 600 }
            }

            Text {
                visible: root.entries.length > 0 && !root.confirmingWipe
                text: "\ue92e" // delete (кошик — очистити все)
                color: wipeHover.hovered ? Colors.red : Colors.grey2
                font { family: "Material Symbols Rounded"; pixelSize: 14 }

                HoverHandler { id: wipeHover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.confirmingWipe = true
                }
            }
        }

        // ---- інлайн-підтвердження очищення (замість окремого вікна) ----
        RowLayout {
            Layout.fillWidth: true
            visible: root.confirmingWipe
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Очистити всю історію?"
                color: Colors.red
                font { family: "SF Pro Display"; pixelSize: 11 }
            }
            Text {
                text: "Так"
                color: Colors.red
                font { family: "SF Pro Display"; pixelSize: 11; underline: true }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wipeProc.running = true
                }
            }
            Text {
                text: "Скасувати"
                color: Colors.grey2
                font { family: "SF Pro Display"; pixelSize: 11; underline: true }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.confirmingWipe = false
                }
            }
        }

        Text {
            visible: root.entries.length === 0
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            text: "Історія порожня"
            color: Colors.grey1
            font { family: "SF Pro Display"; pixelSize: 11 }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: root.entries.length > 0 && !root.confirmingWipe
            contentHeight: entriesCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: entriesCol
                width: parent.width
                spacing: 6

                Repeater {
                    model: root.entries
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 8
                        color: rowHover.hovered ? Colors.bg3 : Colors.bg2

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
                                font { family: "SF Pro Display"; pixelSize: 11 }
                            }

                            Text {
                                text: "\ue92e" // delete
                                color: delHover.hovered ? Colors.red : Colors.grey2
                                font { family: "Material Symbols Rounded"; pixelSize: 12 }

                                HoverHandler { id: delHover }
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: deleteProc.del(row.modelData.id, row.modelData.preview)
                                }
                            }
                        }

                        HoverHandler { id: rowHover }
                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: copyProc.copy(row.modelData.id, row.modelData.preview)
                        }
                    }
                }
            }
        }
    }
}
