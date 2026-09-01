import "root:/"
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// LauncherSurface.qml — вміст (без вікна) для Pill-режиму. Нативний
// QML-лаунчер (заміна Rofi лише тут, у Pill; сам "Super+Space -> rofi"
// у binds.lua НЕ чіпався — окреме питання перепризначення keybind'а).
// ==========================================================================

Item {
    id: root

    signal appLaunched()

    onVisibleChanged: {
        if (visible) {
            LauncherService.reset()
            searchInput.forceActiveFocus()
        }
    }

    function launchAndClose() {
        if (LauncherService.results.length === 0 || LauncherService.selectedIndex >= LauncherService.results.length)
            return

        LauncherService.launchSelected()
        root.appLaunched()
    }

    component ResultRow: Rectangle {
        id: row
        property int rowIndex: -1
        required property var app
        required property bool selected
        signal clicked()

        readonly property string title: LauncherService.entryName(app)
        readonly property string subtitle: {
            const genericName = typeof app.genericName === "string" ? app.genericName.trim() : ""
            if (genericName.length > 0 && genericName !== title)
                return genericName

            return ""
        }

        Layout.fillWidth: true
        implicitHeight: 42
        radius: 10
        color: selected ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : "transparent"
        border.color: selected ? Colors.accent : "transparent"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 10

            Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Colors.bg3
                    visible: appIcon.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: row.title.length > 0 ? row.title[0].toUpperCase() : "?"
                        color: Colors.grey1
                        font { family: "SF Pro Display"; pixelSize: 10; weight: 600 }
                    }
                }

                IconImage {
                    id: appIcon
                    anchors.fill: parent
                    asynchronous: true
                    source: row.app.icon ? Quickshell.iconPath(row.app.icon, true) : ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: row.title
                    color: Colors.fg
                    font { family: "SF Pro Display"; pixelSize: 12; weight: row.selected ? 600 : 400 }
                    elide: Text.ElideRight
                }

                Text {
                    visible: text.length > 0
                    text: row.subtitle
                    color: Colors.grey1
                    font { family: "SF Pro Display"; pixelSize: 10 }
                    elide: Text.ElideRight
                }
            }
        }

        HoverHandler {
            onHoveredChanged: if (hovered) LauncherService.selectedIndex = row.rowIndex
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: Colors.bg2
            border.color: searchInput.activeFocus ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                Text {
                    text: "\uef7a" // search
                    color: Colors.grey2
                    font { family: "Material Symbols Rounded"; pixelSize: 14 }
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Colors.fg
                    font { family: "SF Pro Display"; pixelSize: 12 }
                    text: LauncherService.query
                    onTextChanged: LauncherService.query = text

                    Keys.onDownPressed: LauncherService.moveSelection(1)
                    Keys.onUpPressed: LauncherService.moveSelection(-1)
                    Keys.onReturnPressed: root.launchAndClose()
                    Keys.onEnterPressed: root.launchAndClose()
                    // Escape навмисно не перехоплюється — спливає до
                    // централізованого Keys.onEscapePressed на pill.

                    Text {
                        visible: searchInput.text.length === 0
                        text: "Пошук застосунків..."
                        color: Colors.grey1
                        font: searchInput.font
                    }
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: resultsCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: resultsCol
                width: parent.width
                spacing: 4

                Text {
                    visible: LauncherService.results.length === 0
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                    text: "Нічого не знайдено"
                    color: Colors.grey1
                    font { family: "SF Pro Display"; pixelSize: 11 }
                }

                Repeater {
                    model: LauncherService.results
                    delegate: Item {
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: row.implicitHeight

                        ResultRow {
                            id: row
                            anchors.fill: parent
                            rowIndex: index
                            app: modelData
                            selected: rowIndex === LauncherService.selectedIndex
                            onClicked: {
                                LauncherService.selectedIndex = rowIndex
                                root.launchAndClose()
                            }
                        }
                    }
                }
            }
        }
    }
}
