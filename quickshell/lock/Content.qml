import "root:/"
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "Singletons"

Item {
    id: root

    required property var auth

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.42)
    }

    Image {
        anchors.fill: parent
        source: LockState.wallpaperPath.length > 0 ? "file://" + LockState.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        opacity: 0.32
        visible: source.length > 0
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.34)
    }

    readonly property var player: {
        const list = Mpris.players.values
        if (!list || list.length === 0)
            return null
        for (let i = 0; i < list.length; i++) {
            const p = list[i]
            if (p && p.canControl)
                return p
        }
        return list[0]
    }

    function mediaAction(action) {
        if (!player || !player.canControl)
            return
        if (action === "previous" && player.canGoPrevious)
            player.previous()
        else if (action === "playpause" && player.canTogglePlaying)
            player.togglePlaying()
        else if (action === "next" && player.canGoNext)
            player.next()
        else if (action === "stop" && player.canStop)
            player.stop()
    }

    component MediaButton: Rectangle {
        id: button
        required property string label
        required property string action
        radius: 16
        color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.72)
        border.width: 1
        border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.10)
        implicitWidth: 54
        implicitHeight: 42

        Text {
            anchors.centerIn: parent
            text: button.label
            color: Colors.fg
            font.family: "Material Symbols Rounded"
            font.pixelSize: 18
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.mediaAction(button.action)
        }
    }

    Rectangle {
        width: Math.min(parent.width * 0.78, 900)
        height: Math.min(parent.height * 0.78, 680)
        anchors.centerIn: parent
        radius: 34
        color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.48)
        border.width: 1
        border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.10)

        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius + 2
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 34
            spacing: 16

            Item { Layout.fillHeight: true }

            Image {
                Layout.alignment: Qt.AlignHCenter
                source: "file://" + LockState.avatarPath
                sourceSize.width: 112
                sourceSize.height: 112
                width: 112
                height: 112
                fillMode: Image.PreserveAspectCrop
                smooth: true
                cache: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: LockState.timeText
                color: Colors.fg
                font.family: "SF Pro Display"
                font.pixelSize: 76
                font.weight: 700
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: LockState.dateText
                color: Colors.grey2
                font.family: "SF Pro Display"
                font.pixelSize: 18
            }

            AuthForm {
                Layout.alignment: Qt.AlignHCenter
                auth: root.auth
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                radius: 18
                color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.68)
                border.width: 1
                border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)
                implicitWidth: 440
                implicitHeight: infoLayout.implicitHeight + 28

                ColumnLayout {
                    id: infoLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: LockState.weatherText.length > 0 ? LockState.weatherText : "Fetching weather..."
                        color: Colors.accent
                        font.family: "SF Pro Display"
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: LockState.musicText.length > 0 ? LockState.musicText : "No media playing"
                        color: Colors.grey2
                        font.family: "SF Pro Display"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        MediaButton { label: "\ue045"; action: "previous" }
                        MediaButton { label: "\ue047"; action: "playpause" }
                        MediaButton { label: "\ue047"; action: "stop" }
                        MediaButton { label: "\ue044"; action: "next" }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
