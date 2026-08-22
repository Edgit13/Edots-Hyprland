import "root:/"
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: panel
    required property var modelData
    screen: modelData

    property bool open: false
    property bool everOpened: false
    signal requestClose()

    exclusionMode: ExclusionMode.Ignore
    visible: panel.open || panel.implicitHeight > 0

    onOpenChanged: {
        if (open) {
            everOpened = true
            refreshToggles()
        }
    }

    anchors {
        top: true
    }

    margins.top: 48

    implicitWidth: 820
    implicitHeight: panel.open ? 430 : 0
    exclusiveZone: 0
    color: "transparent"

    Behavior on implicitHeight {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    // ---- Toggles & State ----
    property bool wifiOn: true
    property bool btOn: true
    property bool dndOn: false
    property string currentPowerProfile: "balanced"
    property int brightnessVal: 100

    function refreshToggles() {
        wifiQuery.running = true
        btQuery.running = true
        powerProfileQuery.running = true
        brightnessQuery.running = true
    }

    Process {
        id: wifiQuery
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: panel.wifiOn = text.trim() === "enabled"
        }
    }

    Process {
        id: btQuery
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: panel.btOn = text.trim() === "on"
        }
    }

    Process {
        id: powerProfileQuery
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: panel.currentPowerProfile = text.trim()
        }
    }

    Process {
        id: brightnessQuery
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim())
                if (!isNaN(val)) panel.brightnessVal = val
            }
        }
    }

    Process { id: wifiToggleProc }
    Process { id: btToggleProc }
    Process { id: dndToggleProc }
    Process { id: powerProfileSetProc }
    Process { id: brightnessSetProc }
    
    Process {
        id: menuIpcProc
        command: ["qsh", "ipc", "call", "menu", "toggle"]
    }

    function toggleWifi() {
        wifiToggleProc.command = ["nmcli", "radio", "wifi", wifiOn ? "off" : "on"]
        wifiToggleProc.running = true
        wifiOn = !wifiOn
    }

    function toggleBt() {
        btToggleProc.command = ["bluetoothctl", "power", btOn ? "off" : "on"]
        btToggleProc.running = true
        btOn = !btOn
    }

    function toggleDnd() {
        dndToggleProc.command = ["swaync-client", dndOn ? "-df" : "-dn"]
        dndToggleProc.running = true
        dndOn = !dndOn
    }

    function setPowerProfile(profile) {
        powerProfileSetProc.command = ["powerprofilesctl", "set", profile]
        powerProfileSetProc.running = true
        currentPowerProfile = profile
    }

    function setBrightness(val) {
        let clamped = Math.max(5, Math.min(100, val))
        panel.brightnessVal = clamped
        brightnessSetProc.command = ["brightnessctl", "s", clamped + "%"]
        brightnessSetProc.running = true
    }

    component ToggleChip: Rectangle {
        id: chip
        property string label: ""
        property string icon: ""
        property bool active: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.preferredHeight: 46
        radius: 12
        color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                       : Colors.bg2
        border.color: active ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 180 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Rectangle {
                width: 28
                height: 28
                radius: 8
                color: chip.active ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)

                Text {
                    anchors.centerIn: parent
                    text: chip.icon
                    color: chip.active ? Colors.bg0 : Colors.fg
                    font { family: "Material Symbols Rounded"; pixelSize: 13 }
                }
            }

            Text {
                Layout.fillWidth: true
                text: chip.label
                color: chip.active ? Colors.fg : Colors.grey2
                font { family: "SF Pro Display"; pixelSize: 11; weight: chip.active ? 600 : 400 }
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    component PowerRow: Rectangle {
        id: prow
        property string label: ""
        property string profileName: ""
        property string icon: ""
        signal clicked()

        readonly property bool active: panel.currentPowerProfile === profileName

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 10
        color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2) : Colors.bg2
        border.color: active ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 180 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: prow.icon
                color: prow.active ? Colors.accent : Colors.grey1
                font { family: "Material Symbols Rounded"; pixelSize: 13 }
            }

            Text {
                Layout.fillWidth: true
                text: prow.label
                color: prow.active ? Colors.accent : Colors.fg
                font { family: "SF Pro Display"; pixelSize: 11; weight: prow.active ? 600 : 400 }
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: prow.clicked()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.95)
        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25)
        border.width: 1
        clip: true

        Loader {
            anchors.fill: parent
            anchors.margins: 16
            active: panel.open || panel.everOpened

            sourceComponent: Component {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    // --- Header ---
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "Панель керування"
                            color: Colors.fg
                            font { family: "SF Pro Display"; weight: 700; pixelSize: 15 }
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 6
                            visible: UPower.displayDevice && UPower.displayDevice.isPresent

                            Text {
                                text: {
                                    if (!UPower.displayDevice) return ""
                                    let p = Math.round(UPower.displayDevice.percentage * 100)
                                    if (p > 80) return String.fromCodePoint(0xe1a5) // battery_full
                                    if (p > 40) return String.fromCodePoint(0xf09e) // battery_3_bar
                                    return String.fromCodePoint(0xe19c) // battery_alert
                                }
                                color: Colors.accent
                                font { family: "Material Symbols Rounded"; pixelSize: 13 }
                            }

                            Text {
                                text: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
                                color: Colors.grey2
                                font { family: "SF Pro Display"; pixelSize: 11 }
                            }
                        }

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 6
                            color: closeHover.containsMouse ? Colors.bg3 : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)

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

                    // --- Main Columns Container ---
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12

                        // Left Column (Fixed Width 390px)
                        ColumnLayout {
                            Layout.preferredWidth: 390
                            Layout.maximumWidth: 390
                            Layout.fillHeight: true
                            spacing: 10

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 8
                                columnSpacing: 8

                                ToggleChip {
                                    label: "Меню програм"
                                    icon: String.fromCodePoint(0xe5c3) // apps
                                    active: false
                                    onClicked: {
                                        menuIpcProc.running = true
                                        panel.requestClose()
                                    }
                                }
                                ToggleChip {
                                    label: "Wi-Fi"
                                    icon: String.fromCodePoint(0xe63e) // wifi
                                    active: panel.wifiOn
                                    onClicked: panel.toggleWifi()
                                }
                                ToggleChip {
                                    label: "Bluetooth"
                                    icon: String.fromCodePoint(0xe1a7) // bluetooth
                                    active: panel.btOn
                                    onClicked: panel.toggleBt()
                                }
                                ToggleChip {
                                    label: "DND"
                                    icon: String.fromCodePoint(0xf08f) // do_not_disturb_on
                                    active: panel.dndOn
                                    onClicked: panel.toggleDnd()
                                }
                            }

                            // Sliders Box
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 76
                                radius: 12
                                color: Colors.bg2

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        property var sink: Pipewire.defaultAudioSink
                                        readonly property bool ready: sink && sink.ready
                                        readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0

                                        Text {
                                            text: String.fromCodePoint(0xe050) // volume_up
                                            color: Colors.accent
                                            font { family: "Material Symbols Rounded"; pixelSize: 13 }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 6
                                            radius: 3
                                            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12)

                                            Rectangle {
                                                width: parent.width * (parent.parent.vol / 100)
                                                height: parent.height
                                                radius: 3
                                                color: Colors.accent
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: (mouse) => {
                                                    let pct = Math.max(0, Math.min(1, mouse.x / width))
                                                    if (parent.parent.ready) parent.parent.sink.audio.volume = pct
                                                }
                                            }
                                        }

                                        Text {
                                            text: parent.vol + "%"
                                            color: Colors.grey2
                                            font { family: "SF Pro Display"; pixelSize: 10 }
                                            Layout.preferredWidth: 28
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: String.fromCodePoint(0xe3ab) // brightness_6
                                            color: Colors.yellow
                                            font { family: "Material Symbols Rounded"; pixelSize: 13 }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 6
                                            radius: 3
                                            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12)

                                            Rectangle {
                                                width: parent.width * (panel.brightnessVal / 100)
                                                height: parent.height
                                                radius: 3
                                                color: Colors.yellow
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: (mouse) => {
                                                    let pct = Math.round(Math.max(5, Math.min(100, (mouse.x / width) * 100)))
                                                    panel.setBrightness(pct)
                                                }
                                            }
                                        }

                                        Text {
                                            text: panel.brightnessVal + "%"
                                            color: Colors.grey2
                                            font { family: "SF Pro Display"; pixelSize: 10 }
                                            Layout.preferredWidth: 28
                                        }
                                    }
                                }
                            }

                            // Media Player Box
                            Rectangle {
                                id: mediaBox
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: Colors.bg2

                                property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: String.fromCodePoint(0xe405) // music_note
                                            color: Colors.accent
                                            font { family: "Material Symbols Rounded"; pixelSize: 14 }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: mediaBox.player ? (mediaBox.player.identity || "Медіаплеєр") : "Немає відтворення"
                                            color: Colors.grey2
                                            font { family: "SF Pro Display"; pixelSize: 11; weight: 600 }
                                            elide: Text.ElideRight
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: mediaBox.player ? (mediaBox.player.trackTitle || "Невідомий трек") : "Музика не грає"
                                            color: Colors.fg
                                            font { family: "SF Pro Display"; weight: 600; pixelSize: 13 }
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: mediaBox.player ? (mediaBox.player.trackArtist || "—") : ""
                                            color: Colors.grey2
                                            font { family: "SF Pro Display"; pixelSize: 11 }
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 28

                                        Text {
                                            text: String.fromCodePoint(0xe045) // skip_previous
                                            color: (mediaBox.player && mediaBox.player.canGoPrevious) ? Colors.fg : Colors.grey1
                                            font { family: "Material Symbols Rounded"; pixelSize: 18 }
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -8
                                                cursorShape: Qt.PointingHandCursor
                                                enabled: mediaBox.player && mediaBox.player.canGoPrevious
                                                onClicked: mediaBox.player.previous()
                                            }
                                        }

                                        Text {
                                            text: (mediaBox.player && mediaBox.player.isPlaying)
                                                  ? String.fromCodePoint(0xe034) : String.fromCodePoint(0xe037) // pause / play_arrow
                                            color: Colors.accent
                                            font { family: "Material Symbols Rounded"; pixelSize: 22 }
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -8
                                                cursorShape: Qt.PointingHandCursor
                                                enabled: mediaBox.player && mediaBox.player.canTogglePlaying
                                                onClicked: mediaBox.player.isPlaying = !mediaBox.player.isPlaying
                                            }
                                        }

                                        Text {
                                            text: String.fromCodePoint(0xe044) // skip_next
                                            color: (mediaBox.player && mediaBox.player.canGoNext) ? Colors.fg : Colors.grey1
                                            font { family: "Material Symbols Rounded"; pixelSize: 18 }
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -8
                                                cursorShape: Qt.PointingHandCursor
                                                enabled: mediaBox.player && mediaBox.player.canGoNext
                                                onClicked: mediaBox.player.next()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Right Column (Calendar & Power Profiles)
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10

                            // Calendar Box
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: Colors.bg2

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: Qt.formatDate(new Date(), "MMMM yyyy")
                                            color: Colors.fg
                                            font { family: "SF Pro Display"; weight: 600; pixelSize: 13 }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            text: Qt.formatDate(new Date(), "dd dddd")
                                            color: Colors.accent
                                            font { family: "SF Pro Display"; pixelSize: 11; weight: 500 }
                                        }
                                    }

                                    GridLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        columns: 7
                                        rowSpacing: 4
                                        columnSpacing: 4

                                        Repeater {
                                            model: ["Пн","Вт","Ср","Чт","Пт","Сб","Нд"]
                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: modelData
                                                color: Colors.grey1
                                                font { family: "SF Pro Display"; pixelSize: 10; weight: 600 }
                                            }
                                        }

                                        Repeater {
                                            model: {
                                                const now = new Date()
                                                const first = new Date(now.getFullYear(), now.getMonth(), 1)
                                                const startOffset = (first.getDay() + 6) % 7
                                                const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
                                                const cells = []
                                                for (let i = 0; i < startOffset; i++) cells.push("")
                                                for (let d = 1; d <= daysInMonth; d++) cells.push(String(d))
                                                return cells
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 24
                                                radius: 6
                                                color: modelData !== "" && parseInt(modelData) === new Date().getDate()
                                                       ? Colors.accent : "transparent"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    color: modelData !== "" && parseInt(modelData) === new Date().getDate()
                                                           ? Colors.bg0 : Colors.fg
                                                    font {
                                                        family: "SF Pro Display"
                                                        pixelSize: 11
                                                        weight: modelData !== "" && parseInt(modelData) === new Date().getDate() ? 700 : 400
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Power Profile Selector
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                radius: 14
                                color: Colors.bg2

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 4

                                    Text {
                                        text: "Профіль продуктивності"
                                        color: Colors.grey2
                                        font { family: "SF Pro Display"; pixelSize: 10; weight: 500 }
                                        Layout.leftMargin: 4
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 6

                                        PowerRow {
                                            label: "Максимум"
                                            profileName: "performance"
                                            icon: String.fromCodePoint(0xea0b) // bolt
                                            onClicked: panel.setPowerProfile("performance")
                                        }
                                        PowerRow {
                                            label: "Баланс"
                                            profileName: "balanced"
                                            icon: String.fromCodePoint(0xeaf6) // balance
                                            onClicked: panel.setPowerProfile("balanced")
                                        }
                                        PowerRow {
                                            label: "Економія"
                                            profileName: "power-saver"
                                            icon: String.fromCodePoint(0xea35) // eco
                                            onClicked: panel.setPowerProfile("power-saver")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
