pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    // Reusable trigger icon used in the hover bar.
    // Emits activated() on click so callers can stay in the enclosing scope.
    component TriggerIcon: Text {
        required property string glyph
        property color hoverColor: Colors.accent
        signal activated()

        Layout.alignment: Qt.AlignVCenter
        text: glyph
        color: iconHover.hovered ? hoverColor : Colors.grey1
        font { family: "Material Symbols Rounded"; pixelSize: 15 }

        Behavior on color { ColorAnimation { duration: 120 } }

        HoverHandler { id: iconHover }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
    }

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

        function showClipboard(): void { root.openSurface("clipboard") }
        function toggleClipboard(): void { root.toggleSurface("clipboard") }

        function showMixer(): void { root.openSurface("mixer") }
        function toggleMixer(): void { root.toggleSurface("mixer") }

        function showWifi(): void { root.openSurface("wifi") }
        function toggleWifi(): void { root.toggleSurface("wifi") }

        function showMedia(): void { root.openSurface("media") }
        function toggleMedia(): void { root.toggleSurface("media") }

        function showLink(): void { root.openSurface("link") }
        function toggleLink(): void { root.toggleSurface("link") }

        function showPower(): void { root.openSurface("power") }
        function togglePower(): void { root.toggleSurface("power") }

        function showNotifications(): void { notificationsProc.running = true }
        function toggleNotifications(): void { notificationsProc.running = true }

        function showSettings(): void { root.openSurface("settings") }
        function toggleSettings(): void { root.toggleSurface("settings") }

        function close(): void { root.activeSurface = "idle" }
    }

    Process {
        id: notificationsProc
        command: ["sh", "-c", "swaync-client -t"]
        running: false
    }

    // "idle" (only clock) | "hover" (workspaces + clock + triggers) | surface name
    property string activeSurface: "idle"

    readonly property int idleHeight: 36
    readonly property int idleHorizontalPadding: 20
    readonly property int expandedWidth: 480
    readonly property int expandedHeight: 300

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: root.idleHeight + 5

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: root.idleHeight + 5
            color: "transparent"
            mask: Region {}
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: pillWindow
            required property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            // OnDemand — keyboard focus only when a surface is open,
            // so Escape doesn't steal keys from other windows in idle/hover.
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

                // Central Escape handler — surfaces do not each manage their own.
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

                // Full stadium in idle/hover; soft corner radius when a surface is open.
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
                    // idle <-> hover only; open surfaces close via Escape or background click.
                    onHoveredChanged: {
                        if (hovered && root.activeSurface === "idle") {
                            root.activeSurface = "hover"
                        } else if (!hovered && root.activeSurface === "hover") {
                            root.activeSurface = "idle"
                        }
                    }
                }

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

                Behavior on width  { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
                Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
                Behavior on radius { NumberAnimation { duration: 220 } }
                Behavior on scale  { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                Behavior on border.width { NumberAnimation { duration: 160 } }
                Behavior on border.color { ColorAnimation  { duration: 160 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    // Close only a real open surface; hover collapses via its own HoverHandler.
                    onClicked: {
                        if (root.activeSurface !== "idle" && root.activeSurface !== "hover")
                            root.activeSurface = "idle"
                    }
                }

                // ---- idle state: clock only ----
                Item {
                    id: idleClockRow
                    anchors.centerIn: parent
                    implicitWidth: idleClock.implicitWidth
                    implicitHeight: idleClock.implicitHeight
                    visible: root.activeSurface === "idle"
                    opacity: visible ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Clock {
                        id: idleClock
                        anchors.centerIn: parent
                    }
                }

                // ---- hover state: Workspaces + Clock + trigger icons ----
                RowLayout {
                    id: hoverRow
                    anchors.centerIn: parent
                    spacing: 10
                    visible: root.activeSurface === "hover"
                    opacity: visible ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Workspaces { Layout.alignment: Qt.AlignVCenter }

                    Rectangle {
                        width: 1
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillHeight: true
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.15)
                    }

                    Clock { Layout.alignment: Qt.AlignVCenter }

                    Rectangle {
                        width: 1
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillHeight: true
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.15)
                    }

                    TriggerIcon { glyph: "\ue1bc"; onActivated: root.activeSurface = "wallpaper" }
                    TriggerIcon { glyph: "\ue405"; onActivated: root.activeSurface = "media" }
                    TriggerIcon { glyph: "\ue63e"; onActivated: root.activeSurface = "wifi" }
                    TriggerIcon { glyph: "\ue1a7"; onActivated: root.activeSurface = "link" }
                    TriggerIcon { glyph: "\uf8c7"; hoverColor: Colors.red; onActivated: root.activeSurface = "power" }
                    TriggerIcon { glyph: "\ue429"; onActivated: root.activeSurface = "mixer" }
                    TriggerIcon { glyph: "\ue14f"; onActivated: root.activeSurface = "clipboard" }
                    TriggerIcon { glyph: "\ue7f4"; onActivated: notificationsProc.running = true }
                    TriggerIcon { glyph: "\ue5c3"; onActivated: root.activeSurface = "launcher" }
                    TriggerIcon { glyph: "\ue8b8"; onActivated: root.activeSurface = "settings" }
                }

                // ---- surfaces — loaded on demand, unloaded when closed ----

                Loader {
                    anchors.fill: parent; anchors.margins: 14
                    active: root.activeSurface === "wallpaper"
                    opacity: active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    sourceComponent: WallpaperSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: 14
                    active: root.activeSurface === "media"
                    opacity: active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    sourceComponent: MediaSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: 14
                    active: root.activeSurface === "power"
                    opacity: active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    sourceComponent: PowerSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: 14
                    active: root.activeSurface === "mixer"
                    opacity: active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    sourceComponent: MixerSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: 14
                    active: root.activeSurface === "clipboard"
                    opacity: active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    sourceComponent: ClipboardSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: 14
                    active: root.activeSurface === "launcher"
                    opacity: active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    sourceComponent: LauncherSurface {}
                    onLoaded: item.appLaunched.connect(function() { root.activeSurface = "idle" })
                }

                Loader {
                    anchors.fill: parent; anchors.margins: 14
                    active: root.activeSurface === "wifi"
                    opacity: active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    sourceComponent: WifiSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: 14
                    active: root.activeSurface === "settings"
                    opacity: active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    sourceComponent: SettingsSurface {}
                    onLoaded: item.rootWindow = root
                }

                Loader {
                    anchors.fill: parent; anchors.margins: 14
                    active: root.activeSurface === "link"
                    opacity: active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    sourceComponent: LinkSurface {}
                }
            }
        }
    }
}
