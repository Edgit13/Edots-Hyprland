import "root:/"
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// LinkSurface.qml — вміст (без вікна) для Pill-режиму: Wi-Fi + Bluetooth.
// Логіка й команди 1:1 з Dash/Panel.qml (той файл не чіпався) — nmcli
// radio wifi / bluetoothctl power, той самий проєм патерн опитування.
// Статус Wi-Fi додатково бере Networking.wifiEnabled (той самий модуль,
// що вже reactive-використовує Network.qml), тумблер лишається через nmcli.
// ==========================================================================

Item {
    id: root

    property bool btOn: false

    Process {
        id: btQuery
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: root.btOn = text.trim() === "on"
        }
    }

    Process { id: wifiToggleProc }
    Process { id: btToggleProc }

    function toggleWifi() {
        wifiToggleProc.command = ["nmcli", "radio", "wifi", Networking.wifiEnabled ? "off" : "on"]
        wifiToggleProc.running = true
    }

    function toggleBt() {
        btToggleProc.command = ["bluetoothctl", "power", root.btOn ? "off" : "on"]
        btToggleProc.running = true
        root.btOn = !root.btOn
    }

    Component.onCompleted: btQuery.running = true

    component LinkRow: Rectangle {
        id: row
        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool active: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 46
        radius: 12
        color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : Colors.bg2
        border.color: active ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 180 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Rectangle {
                width: 28
                height: 28
                radius: 8
                color: row.active ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)

                Text {
                    anchors.centerIn: parent
                    text: row.icon
                    color: row.active ? Colors.bg0 : Colors.fg
                    font { family: "Material Symbols Rounded"; pixelSize: 14 }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: row.title
                    color: Colors.fg
                    font { family: "SF Pro Display"; pixelSize: 13; weight: 600 }
                }
                Text {
                    text: row.subtitle
                    color: Colors.grey2
                    font { family: "SF Pro Display"; pixelSize: 11 }
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            text: "Мережа"
            color: Colors.accent
            font { family: "SF Pro Display"; pixelSize: 11; weight: 600 }
        }

        LinkRow {
            icon: "\ue63e" // wifi
            title: "Wi-Fi"
            subtitle: Networking.wifiEnabled ? "Увімкнено" : "Вимкнено"
            active: Networking.wifiEnabled
            onClicked: root.toggleWifi()
        }

        LinkRow {
            icon: "\ue1a7" // bluetooth
            title: "Bluetooth"
            subtitle: root.btOn ? "Увімкнено" : "Вимкнено"
            active: root.btOn
            onClicked: root.toggleBt()
        }

        Item { Layout.fillHeight: true }
    }
}
