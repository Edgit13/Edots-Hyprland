import "root:/"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "Dash" as Dash
import "Menu" as AppMenu
import "Wallpaper" as Wall
import "Clipboard" as Clip
import "Notifications" as Swaync
import "Power" as Power
import "Tray" as Tray

ShellRoot {
    id: root

    property bool dashboardOpen: false
    property int notchIdleHeight: 32

    property bool menuOpen: false
    property bool wallOpen: false
    property bool clipOpen: false
    property bool clipWipeConfirmOpen: false
    property int clipRefreshTick: 0
    property bool powerOpen: false
    property bool trayOpen: false

    IpcHandler {
        target: "dashboard"
        function toggle(): void { dashboardOpen = !dashboardOpen }
        function open(): void { dashboardOpen = true }
        function close(): void { dashboardOpen = false }
    }

    IpcHandler {
        target: "menu"
        function toggle(): void { menuOpen = !menuOpen }
        function open(): void { menuOpen = true }
        function close(): void { menuOpen = false }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { wallOpen = !wallOpen }
        function open(): void { wallOpen = true }
        function close(): void { wallOpen = false }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { clipOpen = !clipOpen }
        function open(): void { clipOpen = true }
        function close(): void { clipOpen = false }
    }

    // Спільна "пілюля" для лівого/правого островів — окрема капсула на
    // групу, як у референсі (github.com/patheonsceo/Dynamic-island-for-arch),
    // а не один суцільний бар.
    component IslandPill: Rectangle {
        radius: GameModeState.active ? 0 : height / 2
        color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 1.0)
        border.width: GameModeState.active ? 0 : 1
        border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12)

        Behavior on radius {
            NumberAnimation { duration: 150 }
        }
    }

    Variants {
        model: Quickshell.screens

        Dash.Panel {
            open: root.dashboardOpen
            onRequestClose: root.dashboardOpen = false
        }
    }

    // ==========================================================================
    // Резервація місця зверху екрана. Окреме, завжди-стабільне, повністю
    // клікпрохідне вікно — той самий підхід, що й "islandReserve" у референсі:
    // тримає exclusiveZone ОКРЕМО від самого notch'а, бо notch тепер
    // анкорений на всі 4 сторони (для надійного центрування) — а 4-анкорні
    // вікна не можуть самі резервувати зону (потрібно рівно 1 або 3 анкори).
    // ==========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: root.notchIdleHeight + 8

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: root.notchIdleHeight + 8
            color: "transparent"
            mask: Region {} // суто резервування місця, кліки проходять крізь
        }
    }

    // ==========================================================================
    // Центральний notch. Вікно анкорене на ВСІ 4 сторони (на весь екран,
    // прозоре, exclusiveZone:0), а сама пілюля центрується через
    // anchors.horizontalCenter батька — це надійно завжди, на відміну від
    // "порожній anchors.left = авто-центр", який виявився ненадійним.
    // ==========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: notchWindow
            required property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            mask: Region { item: notchPill }

            Rectangle {
                id: notchPill
                anchors.top: parent.top
                anchors.topMargin: GameModeState.active ? 0 : 4
                anchors.horizontalCenter: parent.horizontalCenter

                width: 320
                height: root.notchIdleHeight

                radius: GameModeState.active ? 0 : height / 2
                color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.97)
                border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, GameModeState.active ? 0 : 0.25)
                border.width: GameModeState.active ? 0 : 1
                clip: true

                Behavior on radius {
                    NumberAnimation { duration: 150 }
                }

                Behavior on border.color {
                    ColorAnimation { duration: 260; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    anchors.fill: parent
                    z: 10
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dashboardOpen = !root.dashboardOpen
                }

                Item {
                    id: notchContent
                    anchors.centerIn: parent
                    width: parent.width - 20
                    height: parent.height - 8

                    RowLayout {
                        anchors.fill: parent
                        spacing: 8

                        Text {
                            text: "\uefd6" // schedule
                            color: Colors.accent
                            font { family: "Material Symbols Rounded"; pixelSize: 13 }
                        }

                        Text {
                            id: clockText
                            Layout.fillWidth: true
                            text: Qt.formatDateTime(clockText.currentTime, "hh:mm  |  dd MMM")
                            color: Colors.fg
                            font { family: "SF Pro Display"; pixelSize: 12; weight: 600 }
                            horizontalAlignment: Text.AlignHCenter

                            property date currentTime: new Date()

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: clockText.currentTime = new Date()
                            }
                        }

                        Text {
                            text: "\ue8b8" // settings
                            color: Colors.grey2
                            font { family: "Material Symbols Rounded"; pixelSize: 13 }
                        }
                    }
                }
            }
        }
    }

    // ==========================================================================
    // Лівий острів — те, чого не вистачало: кнопка меню (тому й не можна
    // було відкрити налаштування — її просто не було в файлі) + воркспейси.
    // ==========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            anchors {
                top: true
                left: true
            }

            margins.top: GameModeState.active ? 0 : 4
            margins.left: GameModeState.active ? 0 : 4

            implicitWidth: leftRow.implicitWidth
            implicitHeight: root.notchIdleHeight
            color: "transparent"
            mask: Region { item: leftRow }

            RowLayout {
                id: leftRow
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 6

                IslandPill {
                    Layout.fillHeight: true
                    Layout.preferredWidth: menuInner.implicitWidth + 20

                    AppMenu.Button {
                        id: menuInner
                        anchors.centerIn: parent
                        open: root.menuOpen
                        onToggleRequested: function() {
                            root.menuOpen = !root.menuOpen
                        }
                    }
                }

                IslandPill {
                    Layout.fillHeight: true
                    Layout.preferredWidth: wsInner.implicitWidth + 20

                    Workspaces {
                        id: wsInner
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }

    // ==========================================================================
    // Правий острів — буфер/шпалери/сповіщення/трей/мережа/звук/батарея/
    // game mode в одній пілюлі, живлення окремо (як живлення завжди
    // виділене в референсі).
    // ==========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            anchors {
                top: true
                right: true
            }

            margins.top: GameModeState.active ? 0 : 4
            margins.right: GameModeState.active ? 0 : 4

            implicitWidth: rightRow.implicitWidth
            implicitHeight: root.notchIdleHeight
            color: "transparent"
            mask: Region { item: rightRow }

            RowLayout {
                id: rightRow
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 6

                IslandPill {
                    Layout.fillHeight: true
                    Layout.preferredWidth: utilRow.implicitWidth + 20

                    RowLayout {
                        id: utilRow
                        anchors.centerIn: parent
                        spacing: 18

                        Clip.Button {
                            open: root.clipOpen
                            onToggleRequested: function() {
                                root.clipOpen = !root.clipOpen
                            }
                        }

                        Wall.Button {
                            open: root.wallOpen
                            onToggleRequested: function() {
                                root.wallOpen = !root.wallOpen
                            }
                        }

                        Swaync.Button {}

                        Tray.Button {
                            open: root.trayOpen
                            onToggleRequested: function() {
                                root.trayOpen = !root.trayOpen
                            }
                        }

                        Network {}
                        Volume {}
                        Battery {}
                        GameMode {}
                    }
                }

                IslandPill {
                    Layout.fillHeight: true
                    Layout.preferredWidth: powerInner.implicitWidth + 20

                    Power.Button {
                        id: powerInner
                        anchors.centerIn: parent
                        open: root.powerOpen
                        onToggleRequested: function() {
                            root.powerOpen = !root.powerOpen
                        }
                    }
                }
            }
        }
    }

    // ==========================================================================
    // Панелі, що випадають з кнопок вище
    // ==========================================================================
    Variants {
        model: Quickshell.screens

        AppMenu.Panel {
            open: root.menuOpen
            onRequestClose: root.menuOpen = false
        }
    }

    Variants {
        model: Quickshell.screens

        Wall.Panel {
            open: root.wallOpen
            onRequestClose: root.wallOpen = false
        }
    }

    Variants {
        model: Quickshell.screens

        Clip.Panel {
            open: root.clipOpen
            refreshTick: root.clipRefreshTick
            onRequestClose: root.clipOpen = false
            onRequestWipeConfirm: root.clipWipeConfirmOpen = true
        }
    }

    Variants {
        model: Quickshell.screens

        Clip.ConfirmWipe {
            open: root.clipWipeConfirmOpen
            onRequestClose: root.clipWipeConfirmOpen = false
            onConfirmed: root.clipRefreshTick += 1
        }
    }

    Variants {
        model: Quickshell.screens

        Power.Panel {
            open: root.powerOpen
            onRequestClose: root.powerOpen = false
        }
    }

    Variants {
        model: Quickshell.screens

        Tray.Panel {
            open: root.trayOpen
            onRequestClose: root.trayOpen = false
        }
    }
}
