pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool active: false

    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/notchmode.state"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.active = text().trim() === "1"
    }
}
