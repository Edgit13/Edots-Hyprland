pragma ComponentBehavior: Bound
import "root:/"
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// MediaSurface.qml — вміст (без вікна) для Pill-режиму. MPRIS-логіка й
// властивості 1:1 взяті з медіа-блоку Dash/Panel.qml (той файл не
// чіпався) — тільки перевірені властивості, нічого нового не вигадано.
// ==========================================================================

Item {
    id: root

    readonly property var player: {
        const list = Mpris.players.values
        if (!list || list.length === 0) return null
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i]
        }
        return list[0]
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: String.fromCodePoint(0xe405) // music_note
                color: Colors.accent
                font { family: "Material Symbols Rounded"; pixelSize: 15 }
            }

            Text {
                Layout.fillWidth: true
                text: root.player ? (root.player.identity || "Медіаплеєр") : "Немає відтворення"
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
                text: root.player ? (root.player.trackTitle || "Невідомий трек") : "Музика не грає"
                color: Colors.fg
                font { family: "SF Pro Display"; weight: 600; pixelSize: 15 }
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackArtist || "—") : ""
                color: Colors.grey2
                font { family: "SF Pro Display"; pixelSize: 12 }
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 28

            Text {
                text: String.fromCodePoint(0xe045) // skip_previous
                color: (root.player && root.player.canGoPrevious) ? Colors.fg : Colors.grey1
                font { family: "Material Symbols Rounded"; pixelSize: 20 }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.player && root.player.canGoPrevious
                    onClicked: root.player.previous()
                }
            }

            Text {
                text: (root.player && root.player.isPlaying)
                      ? String.fromCodePoint(0xe034) : String.fromCodePoint(0xe037) // pause / play_arrow
                color: Colors.accent
                font { family: "Material Symbols Rounded"; pixelSize: 26 }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.player && root.player.canTogglePlaying
                    onClicked: root.player.isPlaying = !root.player.isPlaying
                }
            }

            Text {
                text: String.fromCodePoint(0xe044) // skip_next
                color: (root.player && root.player.canGoNext) ? Colors.fg : Colors.grey1
                font { family: "Material Symbols Rounded"; pixelSize: 20 }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.player && root.player.canGoNext
                    onClicked: root.player.next()
                }
            }
        }
    }
}
