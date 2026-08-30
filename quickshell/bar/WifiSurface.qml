import "root:/"
import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// WifiSurface.qml — вміст (без вікна) для Pill-режиму: повний Wi-Fi
// менеджер. Уся nmcli-логіка — в WifiService.qml (той singleton), тут
// тільки відображення готових властивостей + виклики його функцій.
// Стиль/кольори/компонент-мова — та сама, що LinkSurface.qml (той файл
// не чіпався).
// ==========================================================================

Item {
    id: root

    property string passwordInput: ""

    // Тригер сканування при відкритті поверхні (не безперервний poll).
    Component.onCompleted: WifiService.scan()

    function signalIcon(signalPct) {
        const s = signalPct / 100
        if (s >= 0.75) return "\ue1ba"       // network_wifi (full)
        if (s >= 0.50) return "\uebe1"       // network_wifi_3_bar
        if (s >= 0.25) return "\uebd6"       // network_wifi_2_bar
        return "\uebe4"                       // network_wifi_1_bar
    }

    component NetworkRow: Rectangle {
        id: row
        property string ssid: ""
        property int signalPct: 0
        property bool secured: false
        property bool inUse: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 38
        radius: 10
        color: inUse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : Colors.bg2
        border.color: inUse ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: root.signalIcon(row.signalPct)
                color: row.inUse ? Colors.accent : Colors.fg
                font { family: "Material Symbols Rounded"; pixelSize: 15 }
            }

            Text {
                Layout.fillWidth: true
                text: row.ssid
                color: Colors.fg
                font { family: "SF Pro Display"; pixelSize: 12; weight: row.inUse ? 600 : 400 }
                elide: Text.ElideRight
            }

            Text {
                visible: row.secured
                text: "\ue899" // lock
                color: Colors.grey2
                font { family: "Material Symbols Rounded"; pixelSize: 12 }
            }

            Text {
                text: row.signalPct + "%"
                color: Colors.grey2
                font { family: "SF Pro Display"; pixelSize: 11 }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }

    // ---- головний список мереж ----
    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        visible: WifiService.connectionState !== "passwordRequired"

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "\ue63e" // wifi
                color: Colors.accent
                font { family: "Material Symbols Rounded"; pixelSize: 15 }
            }
            Text {
                Layout.fillWidth: true
                text: Networking.wifiEnabled ? "Wi-Fi" : "Wi-Fi вимкнено"
                color: Colors.fg
                font { family: "SF Pro Display"; pixelSize: 12; weight: 600 }
            }

            // рефреш зі станом сканування
            Text {
                text: "\ue5d5" // refresh
                color: refreshHover.hovered ? Colors.accent : Colors.grey2
                font { family: "Material Symbols Rounded"; pixelSize: 15 }
                opacity: WifiService.scanning ? 0.4 : 1.0

                RotationAnimation on rotation {
                    running: WifiService.scanning
                    loops: Animation.Infinite
                    from: 0; to: 360
                    duration: 900
                }

                HoverHandler { id: refreshHover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    enabled: !WifiService.scanning
                    onClicked: WifiService.scan()
                }
            }

            // тогл Wi-Fi on/off
            Rectangle {
                width: 34
                height: 18
                radius: 9
                color: Networking.wifiEnabled ? Colors.accent : Colors.bg3

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: Colors.bg0
                    anchors.verticalCenter: parent.verticalCenter
                    x: Networking.wifiEnabled ? parent.width - width - 2 : 2

                    Behavior on x {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiService.toggleWifi()
                }
            }
        }

        // ---- поточне підключення ----
        RowLayout {
            Layout.fillWidth: true
            visible: WifiService.currentNetwork !== null
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: WifiService.currentNetwork ? ("Підключено: " + WifiService.currentNetwork.ssid) : ""
                color: Colors.accent
                font { family: "SF Pro Display"; pixelSize: 11 }
                elide: Text.ElideRight
            }

            Text {
                text: "\ue16f" // link_off
                color: disconnectHover.hovered ? Colors.red : Colors.grey2
                font { family: "Material Symbols Rounded"; pixelSize: 14 }

                HoverHandler { id: disconnectHover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiService.disconnectCurrent()
                }
            }
        }

        // ---- помилка підключення ----
        RowLayout {
            Layout.fillWidth: true
            visible: WifiService.connectionState === "failed"
            spacing: 6

            Text {
                text: "\uf8b6" // error
                color: Colors.red
                font { family: "Material Symbols Rounded"; pixelSize: 13 }
            }
            Text {
                Layout.fillWidth: true
                text: WifiService.connectionError + " (" + WifiService.pendingSsid + ")"
                color: Colors.red
                font { family: "SF Pro Display"; pixelSize: 10 }
                elide: Text.ElideRight
            }
            Text {
                text: "Повторити"
                color: Colors.accent
                font { family: "SF Pro Display"; pixelSize: 10; underline: true }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiService.requestConnect(WifiService.pendingSsid)
                }
            }
        }

        // ---- список мереж ----
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: networksCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: networksCol
                width: parent.width
                spacing: 6

                Text {
                    visible: !Networking.wifiEnabled
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: "Увімкни Wi-Fi, щоб побачити мережі"
                    color: Colors.grey1
                    font { family: "SF Pro Display"; pixelSize: 11 }
                }

                Text {
                    visible: Networking.wifiEnabled && !WifiService.scanning && WifiService.networks.length === 0
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: "Мереж не знайдено"
                    color: Colors.grey1
                    font { family: "SF Pro Display"; pixelSize: 11 }
                }

                Repeater {
                    model: Networking.wifiEnabled ? WifiService.networks : []
                    delegate: NetworkRow {
                        required property var modelData
                        ssid: modelData.ssid
                        signalPct: modelData.signal
                        secured: modelData.secured
                        inUse: modelData.inUse
                        onClicked: WifiService.requestConnect(modelData.ssid)
                    }
                }
            }
        }
    }

    // ---- ввід пароля ----
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        visible: WifiService.connectionState === "passwordRequired" || WifiService.connectionState === "connecting"

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "\ue5c4" // arrow_back
                color: backHover.hovered ? Colors.accent : Colors.grey2
                font { family: "Material Symbols Rounded"; pixelSize: 15 }
                HoverHandler { id: backHover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    enabled: WifiService.connectionState === "passwordRequired"
                    onClicked: WifiService.cancelPassword()
                }
            }

            Text {
                Layout.fillWidth: true
                text: WifiService.pendingSsid
                color: Colors.fg
                font { family: "SF Pro Display"; pixelSize: 13; weight: 600 }
                elide: Text.ElideRight
            }
        }

        Text {
            visible: WifiService.connectionState === "connecting"
            text: "Підключення..."
            color: Colors.grey2
            font { family: "SF Pro Display"; pixelSize: 11 }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            visible: WifiService.connectionState === "passwordRequired"
            radius: 8
            color: Colors.bg2
            border.color: pwInput.activeFocus ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)
            border.width: 1

            TextInput {
                id: pwInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.fg
                font { family: "SF Pro Display"; pixelSize: 12 }
                echoMode: TextInput.Password
                focus: WifiService.connectionState === "passwordRequired"
                text: root.passwordInput
                onTextChanged: root.passwordInput = text

                Keys.onReturnPressed: {
                    if (text.length > 0) {
                        WifiService.connectTo(WifiService.pendingSsid, text)
                        root.passwordInput = ""
                    }
                }
                Keys.onEnterPressed: {
                    if (text.length > 0) {
                        WifiService.connectTo(WifiService.pendingSsid, text)
                        root.passwordInput = ""
                    }
                }
                // Escape навмисно НЕ перехоплюється тут — спливає до
                // централізованого Keys.onEscapePressed на pill у
                // PillShell.qml, той сам закриває поверхню в idle.
            }
        }

        Text {
            visible: WifiService.connectionState === "passwordRequired"
            text: "Enter — підключитись"
            color: Colors.grey1
            font { family: "SF Pro Display"; pixelSize: 9; italic: true }
        }
    }
}
