import "root:/"
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel

PanelWindow {
    id: panel
    required property var modelData
    screen: modelData

    property bool open: false
    property bool everOpened: false
    signal requestClose()

    property string wallpaperDir: "/home/eduard/Pictures/Wallpapers"

    onOpenChanged: if (open) everOpened = true

    anchors {
        top: true
        left: true
    }

    // Панель спливає по центру, під островами.
    margins.top: 48
    margins.left: Math.round((panel.screen ? panel.screen.width : 1920) / 2 - implicitWidth / 2)

    implicitWidth: Math.round((panel.screen ? panel.screen.width : 1920) * 0.5)
    implicitHeight: panel.open ? 360 : 0
    exclusiveZone: 0
    color: "transparent"

    Behavior on implicitWidth {
        NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
    }

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

    Rectangle {
        anchors.fill: parent
        anchors.margins: 8
 
        radius: 14
        color: Qt.rgba(Colors.bg1.r, Colors.bg1.g, Colors.bg1.b, 0.88)
        border.color: Colors.bg4
        border.width: 1
        clip: true

        Behavior on color {
            ColorAnimation { duration: 200 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            active: panel.open || panel.everOpened

            sourceComponent: Component {
                Item {
                    id: mainContainer

                    // Модель для статичних шпалер
                    FolderListModel {
                        id: staticModel
                        folder: "file://" + panel.wallpaperDir
                        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"]
                        showDirs: false
                        sortField: FolderListModel.Name
                    }

                    // Модель для анімованих шпалер (GIF)
                    FolderListModel {
                        id: animatedModel
                        folder: "file://" + panel.wallpaperDir
                        nameFilters: ["*.gif", "*.GIF"]
                        showDirs: false
                        sortField: FolderListModel.Name
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: staticModel.count === 0 && animatedModel.count === 0
                        text: "No wallpapers in " + panel.wallpaperDir
                        color: Colors.grey1
                        font.pixelSize: 12
                    }

                    // Спільний делегат для відображення картинок
                    Component {
                        id: wallpaperDelegate
                        ClippingRectangle {
                            id: thumb
                            required property string filePath
                            required property string fileName

                            width: 160
                            height: ListView.view.height
                            radius: 10
                            color: Colors.bg2

                            property bool hovered: hoverArea.containsMouse

                            border.width: hovered ? 2 : 0
                            border.color: Colors.accent

                            Behavior on border.width {
                                NumberAnimation { duration: 120 }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }

                            Image {
                                anchors.fill: parent
                                source: "file://" + thumb.filePath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize.width: 320
                                sourceSize.height: 280
                                mipmap: true
                            }

                            MouseArea {
                                id: hoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: applyProc.apply(thumb.filePath)
                            }
                        }
                    }

                    // Делегат-плитка для сітки (Notch-режим) — квадратні тайли,
                    // як у референсній "Workspace overview" сітці.
                    Component {
                        id: wallpaperGridDelegate
                        ClippingRectangle {
                            id: gridThumb
                            required property string filePath
                            required property string fileName

                            width: GridView.view.cellWidth - 8
                            height: GridView.view.cellHeight - 8
                            radius: 12
                            color: Colors.bg2

                            property bool hovered: gridHoverArea.containsMouse

                            border.width: hovered ? 2 : 0
                            border.color: Colors.accent

                            Behavior on border.width {
                                NumberAnimation { duration: 120 }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }
                            Behavior on scale {
                                SpringAnimation { spring: 4; damping: 0.35 }
                            }
                            scale: hovered ? 1.04 : 1.0

                            Image {
                                anchors.fill: parent
                                source: "file://" + gridThumb.filePath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize.width: 220
                                sourceSize.height: 160
                                mipmap: true
                            }

                            MouseArea {
                                id: gridHoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: applyProc.apply(gridThumb.filePath)
                            }
                        }
                    }

                    // Макет, що розділяє статичні та анімовані шпалери
                    // Сітка плиток. Два окремі GridView (статичні / анімовані).
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        anchors.rightMargin: 36
                        spacing: 8

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
            }
        }

        Rectangle {
            id: closeBtn
            width: 22
            height: 22
            radius: 6
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 6
            color: closeHover.containsMouse ? Colors.bg3 : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: Colors.fg
                font.pixelSize: 11
            }

            MouseArea {
                id: closeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.requestClose()
            }
        }
    }
}
