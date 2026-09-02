pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Перемикач "Pill" дизайну бару (натхненний github.com/Gakuseei/Ricelin) —
// тільки форма/анімації островів, не архітектура. За замовчуванням вимкнено
// (лишається поточний Notch-вигляд); вмикається через Меню → Дизайн.
Singleton {
    id: root

    property bool active: false

    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/pilldesign.state"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.active = text().trim() === "1"
    }
}
