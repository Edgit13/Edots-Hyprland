import "root:/"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// PillShell.qml — САМОСТІЙНИЙ вхід для перевірки одного морфуючого пілла
// (Ricelin-натхненний дизайн, github.com/Gakuseei/Ricelin). НЕ підключений
// до основного shell.qml — той не чіпався. Запуск окремо, без впливу на
// робочий бар:
//
//   qs -p ~/.config/quickshell/bar/PillShell.qml
//
// Поведінка: idle показує ТІЛЬКИ годинник (компактна капсула). Наведення
// миші розгортає в "hover" — воркспейси + годинник + тригери модулів
// (wallpaper/media/wifi/bluetooth). Клік по тригеру морфить пілюлю в сам
// модуль замість окремого вікна. Escape (централізований обробник на pill,
// WlrKeyboardFocus.OnDemand) закриває будь-який відкритий модуль назад
// в idle. Поверхні: wallpaper (WallpaperSurface.qml), media
// (MediaSurface.qml), wifi (WifiSurface.qml — повний менеджер, бекенд
// WifiService.qml), link (LinkSurface.qml, простий bluetooth-тогл — файл
// НЕ чіпався), power (PowerSurface.qml, команди 1:1 з Power/Panel.qml,
// той файл не чіпався), mixer (MixerSurface.qml — батарея + гучність +
// яскравість, 1:1 з Battery.qml/Dash/Panel.qml sliders, жоден не
// чіпався), clipboard (ClipboardSurface.qml, cliphist list/decode/
// delete/wipe 1:1 з Clipboard/Panel.qml + ConfirmWipe.qml, жоден не
// чіпався), launcher (LauncherSurface.qml — нативний QML-лаунчер замість
// Rofi, через вбудований Quickshell.DesktopEntries API, без ручного
// парсингу .desktop-файлів; binds.lua "Super+Space" не чіпався/лишається
// паралельно). Решта поверхонь (calendar/tray) —
// наступні кроки.
// ==========================================================================

ShellRoot {
    id: root

    function openSurface(surface) {
        activeSurface = surface
        pill.forceActiveFocus()
    }

    function toggleSurface(surface) {
        if (activeSurface === surface)
            activeSurface = "idle"
        else
            openSurface(surface)
    }

    IpcHandler {
        target: "pill"

        function showLauncher(): void { root.openSurface("launcher") }
        function toggleLauncher(): void { root.toggleSurface("launcher") }
        function showWallpaper(): void { root.openSurface("wallpaper") }
        function toggleWallpaper(): void { root.toggleSurface("wallpaper") }
        function close(): void { root.activeSurface = "idle" }
    }

    // "idle" (тільки годинник) | "hover" (розгорнутий рядок: воркспейси +
    // годинник + тригери) | "wallpaper" | "media" | "link" — модулі.
    property string activeSurface: "idle"

    readonly property int idleHeight: 32
    readonly property int idleHorizontalPadding: 16
    readonly property int expandedWidth: 480
    readonly property int expandedHeight: 300

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: pillWindow
            required property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            // OnDemand — панель отримує клавіатурний фокус лише коли в неї
            // клікнули (наприклад, відкрили модуль), а не постійно. Так
            // Escape не "краде" клавіатуру в інших вікон у стані idle/hover.
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            mask: Region { item: pill }

            Rectangle {
                id: pill
                anchors.top: parent.top
                anchors.topMargin: GameModeState.active ? 0 : 4
                anchors.horizontalCenter: parent.horizontalCenter

                // Клавіатурний фокус для Escape. Один централізований
                // обробник нижче — не додаємо окремий Keys-хендлер у
                // кожен модуль (wallpaper/media/link).
                focus: true
                Keys.onEscapePressed: (event) => {
                    if (root.activeSurface !== "idle") {
                        root.activeSurface = "idle"
                        event.accepted = true
                    }
                }

                width: {
                    if (root.activeSurface === "idle")
                        return idleClockRow.implicitWidth + root.idleHorizontalPadding * 2
                    if (root.activeSurface === "hover")
                        return hoverRow.implicitWidth + root.idleHorizontalPadding * 2
                    return root.expandedWidth
                }
                height: (root.activeSurface === "idle" || root.activeSurface === "hover")
                    ? root.idleHeight : root.expandedHeight

                // Idle/hover — повна капсула (stadium). Розгорнутий модуль —
                // м'яке заокруглення (як у калькуляторі/мікшері референсу),
                // а не суцільний stadium на всю висоту.
                radius: GameModeState.active ? 0
                    : ((root.activeSurface === "idle" || root.activeSurface === "hover") ? height / 2 : 28)

                color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.97)
                clip: true

                border.width: GameModeState.active ? 0 : (pillHover.hovered ? 2 : 1)
                border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b,
                    pillHover.hovered ? 0.70 : pillGlow.opacity)

                scale: (pillHover.hovered && !GameModeState.active) ? 1.03 : 1.0
                transformOrigin: Item.Center

                HoverHandler {
                    id: pillHover
                    // idle -> hover при наведенні, назад в idle коли миша
                    // йде геть — тільки між цими двома станами; відкритий
                    // модуль (wallpaper/media/link) сам себе не згортає від
                    // втрати наведення, тільки через Escape чи клік по фону.
                    onHoveredChanged: {
                        if (hovered && root.activeSurface === "idle") {
                            root.activeSurface = "hover"
                        } else if (!hovered && root.activeSurface === "hover") {
                            root.activeSurface = "idle"
                        }
                    }
                }

                // Те саме "дихання" рамки, що й в IslandPill/notchPill
                // основного бару — узгоджена мова анімацій.
                SequentialAnimation {
                    running: !GameModeState.active
                    loops: Animation.Infinite
                    NumberAnimation { target: pillGlow; property: "opacity"; to: 0.42; duration: 1600; easing.type: Easing.InOutSine }
                    NumberAnimation { target: pillGlow; property: "opacity"; to: 0.18; duration: 1600; easing.type: Easing.InOutSine }
                }
                QtObject {
                    id: pillGlow
                    property real opacity: 0.18
                }

                Behavior on width {
                    NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
                }
                Behavior on height {
                    NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
                }
                Behavior on radius {
                    NumberAnimation { duration: 220 }
                }
                Behavior on scale {
                    NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
                }
                Behavior on border.width {
                    NumberAnimation { duration: 160 }
                }
                Behavior on border.color {
                    ColorAnimation { duration: 160 }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    // Клік по фону закриває тільки реально відкритий модуль
                    // (wallpaper/media/link). "hover" сам згортається при
                    // втраті наведення (HoverHandler вище) — не займаємось
                    // ним тут, щоб уникнути конфлікту двох джерел стану.
                    onClicked: {
                        if (root.activeSurface !== "idle" && root.activeSurface !== "hover") {
                            root.activeSurface = "idle"
                        }
                    }
                }

                // ---- idle-стан: ТІЛЬКИ годинник ----
                Item {
                    id: idleClockRow
                    anchors.centerIn: parent
                    implicitWidth: idleClock.implicitWidth
                    implicitHeight: idleClock.implicitHeight
                    visible: root.activeSurface === "idle"
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    Clock {
                        id: idleClock
                        anchors.centerIn: parent
                    }
                }

                // ---- hover-стан: Workspaces + Clock + тригери модулів ----
                RowLayout {
                    id: hoverRow
                    anchors.centerIn: parent
                    spacing: 10
                    visible: root.activeSurface === "hover"
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    Workspaces {
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillHeight: true
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.15)
                    }

                    Clock {
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillHeight: true
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.15)
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "\ue1bc" // wallpaper (той самий codepoint, що Wallpaper/Button.qml)
                        color: wallTriggerHover.hovered ? Colors.accent : Colors.grey1
                        font { family: "Material Symbols Rounded"; pixelSize: 15 }

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        HoverHandler {
                            id: wallTriggerHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4 // трохи ширша клікабельна зона
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeSurface = "wallpaper"
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "\ue405" // music_note (той самий codepoint, що Dash/Panel.qml)
                        color: mediaTriggerHover.hovered ? Colors.accent : Colors.grey1
                        font { family: "Material Symbols Rounded"; pixelSize: 15 }

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        HoverHandler {
                            id: mediaTriggerHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeSurface = "media"
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "\ue63e" // wifi — тепер відкриває повний Wi-Fi менеджер (WifiSurface)
                        color: wifiTriggerHover.hovered ? Colors.accent : Colors.grey1
                        font { family: "Material Symbols Rounded"; pixelSize: 15 }

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        HoverHandler {
                            id: wifiTriggerHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeSurface = "wifi"
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "\ue1a7" // bluetooth (той самий codepoint, що Dash/Panel.qml ToggleChip) —
                                        // окрема іконка, щоб LinkSurface (bluetooth-рядок) лишався
                                        // так само досяжним, файл не чіпався
                        color: linkTriggerHover.hovered ? Colors.accent : Colors.grey1
                        font { family: "Material Symbols Rounded"; pixelSize: 15 }

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        HoverHandler {
                            id: linkTriggerHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeSurface = "link"
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "\uf8c7" // power_settings_new (той самий codepoint, що Power/Button.qml)
                        color: powerTriggerHover.hovered ? Colors.red : Colors.grey1
                        font { family: "Material Symbols Rounded"; pixelSize: 15 }

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        HoverHandler {
                            id: powerTriggerHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeSurface = "power"
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "\ue429" // tune (мікшер: батарея + гучність + яскравість)
                        color: mixerTriggerHover.hovered ? Colors.accent : Colors.grey1
                        font { family: "Material Symbols Rounded"; pixelSize: 15 }

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        HoverHandler {
                            id: mixerTriggerHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeSurface = "mixer"
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "\ue14f" // content_paste (той самий codepoint, що Clipboard/Button.qml)
                        color: clipTriggerHover.hovered ? Colors.accent : Colors.grey1
                        font { family: "Material Symbols Rounded"; pixelSize: 15 }

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        HoverHandler {
                            id: clipTriggerHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeSurface = "clipboard"
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "\ue5c3" // apps (той самий codepoint, що Menu/Button.qml)
                        color: launcherTriggerHover.hovered ? Colors.accent : Colors.grey1
                        font { family: "Material Symbols Rounded"; pixelSize: 15 }

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        HoverHandler {
                            id: launcherTriggerHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeSurface = "launcher"
                        }
                    }
                }

                // ---- поверхня wallpaper ----
                WallpaperSurface {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: root.activeSurface === "wallpaper"
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }

                // ---- поверхня media ----
                MediaSurface {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: root.activeSurface === "media"
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }

                // ---- поверхня power ----
                PowerSurface {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: root.activeSurface === "power"
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }

                // ---- поверхня mixer (батарея + гучність + яскравість) ----
                MixerSurface {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: root.activeSurface === "mixer"
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }

                // ---- поверхня clipboard ----
                ClipboardSurface {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: root.activeSurface === "clipboard"
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }

                // ---- поверхня launcher ----
                LauncherSurface {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: root.activeSurface === "launcher"
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    onAppLaunched: root.activeSurface = "idle"
                }

                // ---- поверхня wifi (повний менеджер) ----
                WifiSurface {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: root.activeSurface === "wifi"
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }

                // ---- поверхня link (простий bluetooth-тогл, не чіпалась) ----
                LinkSurface {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: root.activeSurface === "link"
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }
            }
        }
    }
}
