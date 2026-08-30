import "root:/"
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel

// ==========================================================================
// WallpaperSurface.qml — вміст (без вікна) для Pill-режиму. Логіка й
// команда застосування 1:1 взяті з Wallpaper/Panel.qml (той файл
// НЕ чіпався) — тут тільки перевикористання, без нових залежностей.
// ==========================================================================

Item {
    id: root

    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    Process {
        id: applyProc

        function apply(path) {
            if (running) {
                running = false
            }

            command = ["sh", "-c",
                "awww img -t wave '" + path + "' && python3 " +
                Quickshell.env("HOME") + "/.config/hypr/scripts/wallcolors.py '" + path + "'"
            ]
            running = true
        }
    }

    FolderListModel {
        id: staticModel
        folder: "file://" + root.wallpaperDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    FolderListModel {
        id: animatedModel
        folder: "file://" + root.wallpaperDir
        nameFilters: ["*.gif", "*.GIF"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    Text {
        anchors.centerIn: parent
        visible: staticModel.count === 0 && animatedModel.count === 0
        text: "Нема шпалер у " + root.wallpaperDir
        color: Colors.grey1
        font { family: "SF Pro Display"; pixelSize: 11 }
    }

    Component {
        id: wallpaperGridDelegate
        ClippingRectangle {
            id: thumb
            required property string filePath
            required property string fileName

            width: GridView.view.cellWidth - 6
            height: GridView.view.cellHeight - 6
            radius: 10
            color: Colors.bg2

            property bool hovered: gridHoverArea.containsMouse

            border.width: hovered ? 2 : 0
            border.color: Colors.accent

            Behavior on border.width {
                NumberAnimation { duration: 120 }
            }
            Behavior on scale {
                SpringAnimation { spring: 4; damping: 0.35 }
            }
            scale: hovered ? 1.05 : 1.0

            Image {
                anchors.fill: parent
                source: "file://" + thumb.filePath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize.width: 160
                sourceSize.height: 100
                mipmap: true
            }

            MouseArea {
                id: gridHoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: applyProc.apply(thumb.filePath)
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        GridView {
            id: staticGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / 4
            cellHeight: cellWidth * 0.62
            model: staticModel
            delegate: wallpaperGridDelegate
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.bg4
            visible: animatedModel.count > 0
        }

        GridView {
            id: animatedGrid
            Layout.fillWidth: true
            Layout.preferredHeight: animatedModel.count > 0 ? (parent.height * 0.32) : 0
            visible: animatedModel.count > 0
            clip: true
            cellWidth: width / 4
            cellHeight: cellWidth * 0.62
            model: animatedModel
            delegate: wallpaperGridDelegate
        }
    }
}
