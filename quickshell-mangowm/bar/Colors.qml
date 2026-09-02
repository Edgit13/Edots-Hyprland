pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string barDir: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")
    readonly property string forkDir: barDir.replace(/\/bar\/?$/, "")

    property color bg0: "#040e0d"
    property color bg1: "#0a1816"
    property color bg2: "#0f211f"
    property color bg3: "#1d3631"
    property color bg4: "#152a26"

    property color fg: "#f5e2c5"
    property color accent: "#3dd1b0"

    property color red: "#ff6048"
    property color orange: "#ffa478"
    property color yellow: "#f5cd5b"
    property color green: "#7ad9a8"
    property color aqua: "#3dd1b0"
    property color blue: "#5fc8d4"
    property color purple: "#e89aa8"

    property color grey0: "#3a1a35"
    property color grey1: "#5a4d3e"
    property color grey2: "#c4b09a"

    property color bg: bg0

    FileView {
        id: colorsFile
        path: root.forkDir + "/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.applyColors(text())
    }

    function applyColors(raw) {
        if (!raw || raw.length === 0)
            return

        try {
            var c = JSON.parse(raw)
            for (var key in c) {
                if (root.hasOwnProperty(key))
                    root[key] = c[key]
            }
        } catch (e) {
            console.log("Colors.qml parse error:", e)
        }
    }
}