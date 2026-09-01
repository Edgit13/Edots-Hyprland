import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var rootWindow
    property int currentTab: 0

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell"
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    function writeState(path, enabled) {
        stateWriteProc.command = ["sh", "-c", "mkdir -p \"$3\" && printf '%s\\n' \"$1\" > \"$2\"", "--", enabled ? "1" : "0", path, cacheDir]
        stateWriteProc.running = true
    }

    function fileStatus(fileView) {
        const data = fileView.text()
        return data && data.length > 0 ? "Loaded" : "Missing or empty"
    }

    Process {
        id: reloadShellProc
        command: ["sh", "-c", "pkill -f 'qs .*bar/shell.qml' 2>/dev/null || true; qs -c bar >/dev/null 2>&1 &"]
    }

    Process {
        id: reloadHyprProc
        command: ["hyprctl", "reload"]
    }

    Process {
        id: stateWriteProc
    }

    Process {
        id: gameModeProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/gamemode.sh"]
        running: false
    }

    FileView {
        id: keybindsFile
        path: Quickshell.env("HOME") + "/.config/hypr/modules/binds.lua"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: startupFile
        path: Quickshell.env("HOME") + "/.config/hypr/modules/autostart.lua"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: inputFile
        path: Quickshell.env("HOME") + "/.config/hypr/modules/input.lua"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: envFile
        path: Quickshell.env("HOME") + "/.config/hypr/modules/env.lua"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: monitorFile
        path: Quickshell.env("HOME") + "/.config/hypr/modules/monitors.lua"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: wallpaperScriptFile
        path: Quickshell.env("HOME") + "/.config/hypr/scripts/wallcolors.py"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: gameModeScriptFile
        path: Quickshell.env("HOME") + "/.config/quickshell/scripts/gamemode.sh"
        watchChanges: true
        onFileChanged: reload()
    }

    component TabButton: Rectangle {
        id: tab
        required property int tabIndex
        required property string label

        Layout.fillWidth: true
        implicitHeight: 28
        radius: 8
        color: root.currentTab === tabIndex
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
            : Qt.rgba(Colors.bg3.r, Colors.bg3.g, Colors.bg3.b, 0.45)
        border.width: 1
        border.color: root.currentTab === tabIndex ? Colors.accent : "transparent"

        Text {
            anchors.centerIn: parent
            text: tab.label
            color: root.currentTab === tabIndex ? Colors.accent : Colors.fg
            font { family: "SF Pro Display"; pixelSize: 11; weight: 600 }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.currentTab = tab.tabIndex
        }
    }

    component ToggleRow: Rectangle {
        id: row
        required property string label
        required property string description
        required property bool value
        signal toggled()

        Layout.fillWidth: true
        implicitHeight: 50
        radius: 10
        color: Qt.rgba(Colors.bg3.r, Colors.bg3.g, Colors.bg3.b, 0.55)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: row.label
                    color: Colors.fg
                    elide: Text.ElideRight
                    font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
                }

                Text {
                    Layout.fillWidth: true
                    text: row.description
                    color: Colors.grey1
                    elide: Text.ElideRight
                    font { family: "SF Pro Display"; pixelSize: 10 }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 54
                Layout.preferredHeight: 26
                radius: 13
                color: row.value ? Colors.accent : Colors.bg4

                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    y: 3
                    x: row.value ? 31 : 3
                    color: Colors.bg0

                    Behavior on x {
                        NumberAnimation { duration: 120 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.toggled()
                }
            }
        }
    }

    component ActionButton: Rectangle {
        id: button
        required property string label
        required property string description
        required property color accentColor
        signal pressed()

        Layout.fillWidth: true
        implicitHeight: 42
        radius: 10
        color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)
        border.width: 1
        border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: button.label
                color: Colors.fg
                elide: Text.ElideRight
                font { family: "SF Pro Display"; pixelSize: 12; weight: 600 }
            }

            Text {
                Layout.fillWidth: true
                text: button.description
                color: Colors.grey1
                elide: Text.ElideRight
                font { family: "SF Pro Display"; pixelSize: 10 }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: button.pressed()
        }
    }

    component InfoRow: Rectangle {
        id: row
        required property string title
        required property string detail

        Layout.fillWidth: true
        implicitHeight: 40
        radius: 10
        color: Qt.rgba(Colors.bg3.r, Colors.bg3.g, Colors.bg3.b, 0.45)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: row.title
                color: Colors.fg
                elide: Text.ElideRight
                font { family: "SF Pro Display"; pixelSize: 11; weight: 600 }
            }

            Text {
                Layout.fillWidth: true
                text: row.detail
                color: Colors.grey1
                elide: Text.ElideMiddle
                font { family: "SF Pro Display"; pixelSize: 10 }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "Settings"
            color: Colors.fg
            font { family: "SF Pro Display"; pixelSize: 14; weight: 700 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            TabButton { tabIndex: 0; label: "Look" }
            TabButton { tabIndex: 1; label: "Modules" }
            TabButton { tabIndex: 2; label: "Binds" }
            TabButton { tabIndex: 3; label: "System" }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: pageContent.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: pageContent
                width: parent.width
                spacing: 8

                ColumnLayout {
                    visible: root.currentTab === 0
                    width: parent.width
                    spacing: 8

                    ToggleRow {
                        label: "Pill design"
                        description: "Round hover-growing pill style with accent glow."
                        value: PillDesignState.active
                        onToggled: root.writeState(root.cacheDir + "/pilldesign.state", !PillDesignState.active)
                    }

                    ToggleRow {
                        label: "Modern mode"
                        description: "Alternate stored shell look flag."
                        value: ModernModeState.active
                        onToggled: root.writeState(root.cacheDir + "/modernmode.state", !ModernModeState.active)
                    }

                    ToggleRow {
                        label: "Notch mode"
                        description: "Alternate stored shell shape flag."
                        value: NotchModeState.active
                        onToggled: root.writeState(root.cacheDir + "/notchmode.state", !NotchModeState.active)
                    }

                    ToggleRow {
                        label: "Game mode"
                        description: "Run the real game mode toggle script."
                        value: GameModeState.active
                        onToggled: {
                            if (!gameModeProc.running)
                                gameModeProc.running = true
                        }
                    }

                    InfoRow {
                        title: "Current wallpaper directory"
                        detail: root.wallpaperDir
                    }

                    InfoRow {
                        title: "Current accent color"
                        detail: Colors.accent.toString()
                    }
                }

                ColumnLayout {
                    visible: root.currentTab === 1
                    width: parent.width
                    spacing: 8

                    ActionButton {
                        label: "Launcher"
                        description: "Open app launcher"
                        accentColor: Colors.accent
                        onPressed: root.rootWindow.openSurface("launcher")
                    }
                    ActionButton {
                        label: "Wallpaper"
                        description: "Open wallpaper picker"
                        accentColor: Colors.blue
                        onPressed: root.rootWindow.openSurface("wallpaper")
                    }
                    ActionButton {
                        label: "Clipboard"
                        description: "Open clipboard history"
                        accentColor: Colors.yellow
                        onPressed: root.rootWindow.openSurface("clipboard")
                    }
                    ActionButton {
                        label: "Mixer"
                        description: "Open audio and brightness"
                        accentColor: Colors.purple
                        onPressed: root.rootWindow.openSurface("mixer")
                    }
                    ActionButton {
                        label: "Wi-Fi"
                        description: "Open network surface"
                        accentColor: Colors.green
                        onPressed: root.rootWindow.openSurface("wifi")
                    }
                    ActionButton {
                        label: "Bluetooth"
                        description: "Open bluetooth surface"
                        accentColor: Colors.aqua
                        onPressed: root.rootWindow.openSurface("link")
                    }
                    ActionButton {
                        label: "Media"
                        description: "Open media controls"
                        accentColor: Colors.orange
                        onPressed: root.rootWindow.openSurface("media")
                    }
                    ActionButton {
                        label: "Power"
                        description: "Open power actions"
                        accentColor: Colors.red
                        onPressed: root.rootWindow.openSurface("power")
                    }
                }

                ColumnLayout {
                    visible: root.currentTab === 2
                    width: parent.width
                    spacing: 8

                    InfoRow { title: "Super + Space"; detail: "Open app launcher" }
                    InfoRow { title: "Super + C"; detail: "Open wallpaper picker" }
                    InfoRow { title: "Super + V"; detail: "Open clipboard history" }
                    InfoRow { title: "Super + W"; detail: "Open Wi-Fi surface" }
                    InfoRow { title: "Super + X"; detail: "Open mixer" }
                    InfoRow { title: "Super + O"; detail: "Open power surface" }
                    InfoRow { title: "Binds file"; detail: keybindsFile.path }
                }

                ColumnLayout {
                    visible: root.currentTab === 3
                    width: parent.width
                    spacing: 8

                    InfoRow { title: "Hyprland binds"; detail: keybindsFile.path + " • " + root.fileStatus(keybindsFile) }
                    InfoRow { title: "Hyprland startup"; detail: startupFile.path + " • " + root.fileStatus(startupFile) }
                    InfoRow { title: "Input config"; detail: inputFile.path + " • " + root.fileStatus(inputFile) }
                    InfoRow { title: "Monitor layout"; detail: monitorFile.path + " • " + root.fileStatus(monitorFile) }
                    InfoRow { title: "Environment config"; detail: envFile.path + " • " + root.fileStatus(envFile) }
                    InfoRow { title: "Wallpaper script"; detail: wallpaperScriptFile.path + " • " + root.fileStatus(wallpaperScriptFile) }
                    InfoRow { title: "Game mode script"; detail: gameModeScriptFile.path + " • " + root.fileStatus(gameModeScriptFile) }
                    InfoRow { title: "Monitor file"; detail: monitorFile.path }

                    ActionButton {
                        label: "Reload Quickshell"
                        description: "Restart the bar config process to pick up changes."
                        accentColor: Colors.orange
                        onPressed: reloadShellProc.running = true
                    }

                    ActionButton {
                        label: "Reload Hyprland"
                        description: "Apply updated Hyprland configuration."
                        accentColor: Colors.blue
                        onPressed: reloadHyprProc.running = true
                    }
                }
            }
        }
    }
}
