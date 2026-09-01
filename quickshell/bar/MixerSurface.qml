import "root:/"
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// MixerSurface.qml — вміст (без вікна) для Pill-режиму: батарея (дисплей,
// вбудований наявний Battery.qml) + гучність/яскравість (слайдери 1:1 з
// Dash/Panel.qml "Sliders Box", той файл не чіпався).
// ==========================================================================

Item {
    id: root

    property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink && sink.ready
    readonly property int vol: sinkReady ? Math.round(sink.audio.volume * 100) : 0

    property int brightnessVal: 50

    Process {
        id: brightnessQuery
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim())
                if (!isNaN(val)) root.brightnessVal = val
            }
        }
    }
    Process { id: brightnessSetProc }

    function setBrightness(val) {
        let clamped = Math.max(5, Math.min(100, val))
        root.brightnessVal = clamped
        brightnessSetProc.command = ["brightnessctl", "s", clamped + "%"]
        brightnessSetProc.running = true
    }

    Component.onCompleted: brightnessQuery.running = true

    PwObjectTracker {
        objects: [root.sink]
    }

    component MixerSlider: RowLayout {
        id: sliderRow
        property string icon: ""
        property color iconColor: Colors.accent
        property real fraction: 0 // 0..1
        property string valueLabel: ""
        signal setFraction(real pct)

        Layout.fillWidth: true
        spacing: 8

        Text {
            text: sliderRow.icon
            color: sliderRow.iconColor
            font { family: "Material Symbols Rounded"; pixelSize: 14 }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12)

            Rectangle {
                width: parent.width * sliderRow.fraction
                height: parent.height
                radius: 3
                color: sliderRow.iconColor

                Behavior on width {
                    NumberAnimation { duration: 100 }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    let pct = Math.max(0, Math.min(1, mouse.x / width))
                    sliderRow.setFraction(pct)
                }
            }
        }

        Text {
            text: sliderRow.valueLabel
            color: Colors.grey2
            font { family: "SF Pro Display"; pixelSize: 10 }
            Layout.preferredWidth: 30
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            Battery {}
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)
        }

        MixerSlider {
            icon: String.fromCodePoint(0xe050) // volume_up
            iconColor: Colors.accent
            fraction: root.vol / 100
            valueLabel: root.sinkReady ? (root.vol + "%") : "-"
            onSetFraction: (pct) => {
                if (root.sinkReady) root.sink.audio.volume = pct
            }
        }

        MixerSlider {
            icon: String.fromCodePoint(0xe3ab) // brightness_6
            iconColor: Colors.yellow
            fraction: root.brightnessVal / 100
            valueLabel: root.brightnessVal + "%"
            onSetFraction: (pct) => root.setBrightness(Math.round(pct * 100))
        }

        Item { Layout.fillHeight: true }
    }
}
