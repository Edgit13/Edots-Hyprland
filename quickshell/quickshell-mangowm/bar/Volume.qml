import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 7

    property var sink: Pipewire.defaultAudioSink

    readonly property bool ready: sink && sink.ready
    readonly property bool muted: ready && sink.audio.muted
    readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0

    readonly property string icon: {
        if (!ready || muted) return String.fromCodePoint(0xe04f) // volume_off
        if (vol === 0) return String.fromCodePoint(0xe04e) // volume_mute
        if (vol < 50) return String.fromCodePoint(0xe04d) // volume_down

        return String.fromCodePoint(0xe050) // volume_up
    }

    Text {
        text: root.icon
        color: Colors.yellow

        font {
            family: "Material Symbols Rounded"
            pixelSize: 13
        }
    }

    Text {
        text: {
            if (!root.ready) return "-"
            if (root.muted) return "Muted"

            return root.vol + "%"
        }

        color: root.muted ? Colors.grey2 : Colors.fg

        font {
            family: "SF Pro Display"
            weight: 500
        }
    }

    PwObjectTracker {
        objects: [root.sink]
    }
}