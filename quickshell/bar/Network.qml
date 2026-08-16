import Quickshell
import Quickshell.Networking
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Item {
    id: networkRoot
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    // Стани для швидкості мережі та пінгу
    property string pingMs: "--"
    property string rxRateStr: "0.0 B/s"
    property string txRateStr: "0.0 B/s"

    // Оновлення мережевих даних через таймер і Shell-процес
    Process {
        id: statsProc
        command: ["bash", "-c", "
            # Використовуємо LC_ALL=C для коректної обробки крапки в дробових числах ping
            RAW_PING=$(LC_ALL=C ping -c 1 -W 1 1.1.1.1 2>/dev/null)
            PING=$(echo \"$RAW_PING\" | grep -oP 'time=\\K[0-9.]+' | head -n 1 | awk '{printf \"%.0f\", $1}')
            
            if [ -z \"$PING\" ]; then
                PING=$(echo \"$RAW_PING\" | awk -F'/' '/rtt|round-trip/ {printf \"%.0f\", $2}')
            fi
            
            [ -z \"$PING\" ] && PING=\"--\"

            IFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)
            if [ -n \"$IFACE\" ]; then
                RX1=$(cat /proc/net/dev | grep \"$IFACE:\" | awk '{print $2}')
                TX1=$(cat /proc/net/dev | grep \"$IFACE:\" | awk '{print $10}')
                sleep 1
                RX2=$(cat /proc/net/dev | grep \"$IFACE:\" | awk '{print $2}')
                TX2=$(cat /proc/net/dev | grep \"$IFACE:\" | awk '{print $10}')

                RX_DIFF=$((RX2 - RX1))
                TX_DIFF=$((TX2 - TX1))

                format_bytes() {
                    b=$1
                    if [ $b -gt 1048576 ]; then
                        echo \"$(awk -v b=$b 'BEGIN {printf \"%.1f MB/s\", b/1048576}')\"
                    elif [ $b -gt 1024 ]; then
                        echo \"$(awk -v b=$b 'BEGIN {printf \"%.1f KB/s\", b/1024}')\"
                    else
                        echo \"${b} B/s\"
                    fi
                }

                RX_STR=$(format_bytes $RX_DIFF)
                TX_STR=$(format_bytes $TX_DIFF)
            else
                RX_STR=\"0.0 B/s\"
                TX_STR=\"0.0 B/s\"
            fi

            echo \"$PING|$RX_STR|$TX_STR\"
        "]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|")
                if (parts.length === 3) {
                    networkRoot.pingMs = parts[0]
                    networkRoot.rxRateStr = parts[1]
                    networkRoot.txRateStr = parts[2]
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statsProc.running) {
                statsProc.running = true
            }
        }
    }

    // Таймер затримки для плавного закриття підказки
    Timer {
        id: hideTimer
        interval: 150
        onTriggered: infoTooltip.visible = false
    }

    MouseArea {
        id: clickBoundary
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            hideTimer.stop()
            infoTooltip.visible = true
        }

        onExited: hideTimer.start()

        onClicked: terminalProcess.running = true

        Process {
            id: terminalProcess
            command: ["alacritty", "-e", "nmtui"]
            running: false
        }

        RowLayout {
            id: mainLayout
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            property var wifiDevice: {
                if (!Networking.devices || !Networking.devices.values) return null
                return Networking.devices.values.find(d => d.type === DeviceType.wifi || d.type === 2)
            }

            property var activeNetwork: {
                if (!wifiDevice) return null
                if (wifiDevice.connectedNetwork) return wifiDevice.connectedNetwork
                if (wifiDevice.networks && wifiDevice.networks.values) {
                    return wifiDevice.networks.values.find(n => n.connected || n.state === 100)
                }
                return null
            }

            readonly property real signal: activeNetwork ? (activeNetwork.signalStrength || 0.8) : 0

            readonly property string icon: {
                if (!Networking.wifiEnabled) return String.fromCodePoint(0xF05AA)
                if (!activeNetwork && !Networking.connected) return String.fromCodePoint(0xF092D)

                let tier = signal >= 0.75 ? 4
                         : signal >= 0.50 ? 3
                         : signal >= 0.25 ? 2
                         : 1

                return String.fromCodePoint(0xF091F + (tier - 1) * 3)
            }

            Text {
                text: mainLayout.icon
                color: Networking.wifiEnabled ? Colors.purple : Colors.grey1
                Layout.alignment: Qt.AlignVCenter

                font {
                    family: "JetBrainsMono Nerd Font Propo"
                    pixelSize: 13
                }
            }

            Text {
                text: {
                    if (!Networking.wifiEnabled) return "Вимкнено"
                    if (mainLayout.activeNetwork && mainLayout.activeNetwork.ssid) return mainLayout.activeNetwork.ssid
                    if (mainLayout.activeNetwork && mainLayout.activeNetwork.name) return mainLayout.activeNetwork.name
                    if (Networking.connected) return "Підключено"
                    return "Відключено"
                }

                color: Colors.fg
                Layout.alignment: Qt.AlignVCenter

                font {
                    family: "SF Pro Display"
                    weight: 500
                }
            }
        }
    }

    // Спливаюче міні-віконце (PopupWindow) з безпосередньою прив'язкою до елемента
    PopupWindow {
        id: infoTooltip
        visible: false

        anchor.item: networkRoot
        anchor.rect: Qt.rect(0, 0, networkRoot.width, networkRoot.height)

        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        width: popupContent.implicitWidth + 24
        height: popupContent.implicitHeight + 16
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.92)
            border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.2)
            border.width: 1
            radius: 10

            // Внутрішня світла облямівка ефекту скла
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                radius: 9
            }

            ColumnLayout {
                id: popupContent
                anchors.centerIn: parent
                spacing: 6

                // Заголовок
                Text {
                    text: "МЕРЕЖЕВА СТАТИСТИКА"
                    color: Colors.accent
                    font.pixelSize: 10
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.15)
                }

                // Рядок: Ping
                RowLayout {
                    spacing: 12
                    Text {
                        text: "󰅟  Пінг:"
                        color: Colors.fg
                        font.pixelSize: 12
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: networkRoot.pingMs + " ms"
                        color: networkRoot.pingMs === "--" ? Colors.red : Colors.green
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                // Рядок: Завантаження (Download)
                RowLayout {
                    spacing: 12
                    Text {
                        text: "󰇚  Завантаження:"
                        color: Colors.fg
                        font.pixelSize: 12
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: networkRoot.rxRateStr
                        color: Colors.blue
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                // Рядок: Вивантаження (Upload)
                RowLayout {
                    spacing: 12
                    Text {
                        text: "󰕒  Вивантаження:"
                        color: Colors.fg
                        font.pixelSize: 12
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: networkRoot.txRateStr
                        color: Colors.orange
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
        }
    }
}
