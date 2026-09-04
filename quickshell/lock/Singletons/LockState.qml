pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string quickshellWallpaperPath: Quickshell.env("HOME") + "/.config/quickshell/current-wallpaper.txt"
    readonly property string colorsPath: Quickshell.env("HOME") + "/.config/mango/swaylock/colors.conf"
    readonly property string awwwStatePath: Quickshell.env("HOME") + "/.cache/awww/last"
    readonly property string avatarPath: Quickshell.env("HOME") + "/.face"

    property string wallpaperPath: ""
    readonly property string wallpaperSource: wallpaperPath.length > 0 ? wallpaperPath : ""
    property string timeText: Qt.formatTime(new Date(), "HH:mm")
    property string dateText: Qt.formatDate(new Date(), "dddd, dd MMMM yyyy")
    property string weatherText: ""
    property string musicText: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.timeText = Qt.formatTime(new Date(), "HH:mm")
            root.dateText = Qt.formatDate(new Date(), "dddd, dd MMMM yyyy")
        }
    }

    Process {
        id: weatherProc
        command: [Quickshell.env("HOME") + "/.config/mango/scripts/swaylock-weather.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.weatherText = text.trim()
        }
    }

    Process {
        id: musicProc
        command: [Quickshell.env("HOME") + "/.config/mango/scripts/swaylock-music.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.musicText = text.trim()
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: musicProc.running = true
    }

    function applyWallpaperPath(raw) {
        if (!raw || raw.length === 0)
            return

        const match = raw.match(/set \$wallpaper_path\s+(.+)/)
        if (match && match[1])
            root.wallpaperPath = match[1].trim().replace(/^"|"$/g, "")
    }

    function applyDirectWallpaper(raw) {
        const candidate = raw ? raw.trim().replace(/^"|"$/g, "") : ""
        if (candidate.length > 0)
            root.wallpaperPath = candidate
    }

    FileView {
        id: quickshellWallpaperFile
        path: root.quickshellWallpaperPath
        watchChanges: true
        printErrors: false
        onTextChanged: root.applyDirectWallpaper(text())
        Component.onCompleted: root.applyDirectWallpaper(text())
    }

    FileView {
        id: colorsFile
        path: root.colorsPath
        watchChanges: true
        onFileChanged: {
            reload()
            if (root.wallpaperPath.length === 0)
                root.applyWallpaperPath(text())
        }
        onTextChanged: {
            if (root.wallpaperPath.length === 0)
                root.applyWallpaperPath(text())
        }
        Component.onCompleted: {
            if (root.wallpaperPath.length === 0)
                root.applyWallpaperPath(text())
        }
    }

    FileView {
        id: awwwStateFile
        path: root.awwwStatePath
        watchChanges: true
        printErrors: false
        onTextChanged: {
            if (root.wallpaperPath.length === 0)
                root.applyDirectWallpaper(text())
        }
        Component.onCompleted: {
            if (root.wallpaperPath.length === 0)
                root.applyDirectWallpaper(text())
        }
    }
}
