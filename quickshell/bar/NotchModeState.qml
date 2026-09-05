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
        onTextChanged: root.active = text().trim() === "1"
        Component.onCompleted: root.active = text().trim() === "1"
    }
}
