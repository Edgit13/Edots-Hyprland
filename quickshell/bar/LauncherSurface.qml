import "root:/"
import QtQuick
import QtQuick.Layouts

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

    function moveSelection(delta) {
        LauncherService.moveSelection(delta)
        list.positionViewAtIndex(LauncherService.selectedIndex, ListView.Contain)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
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
                    text: "\uef7a"
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

                    Keys.onDownPressed: root.moveSelection(1)
                    Keys.onUpPressed: root.moveSelection(-1)
                    Keys.onReturnPressed: root.launchAndClose()
                    Keys.onEnterPressed: root.launchAndClose()

                    Text {
                        visible: searchInput.text.length === 0
                        text: "Пошук застосунків..."
                        color: Colors.grey1
                        font: searchInput.font
                    }
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            model: LauncherService.results
            currentIndex: LauncherService.selectedIndex

            delegate: AppRow {
                required property var modelData
                required property int index

                width: ListView.view.width
                app: modelData
                selected: index === LauncherService.selectedIndex
                onActivated: {
                    LauncherService.selectedIndex = index
                    root.launchAndClose()
                }
                onEntered: LauncherService.selectedIndex = index
            }

            Text {
                anchors.centerIn: parent
                visible: LauncherService.results.length === 0
                text: "Нічого не знайдено"
                color: Colors.grey1
                font { family: "SF Pro Display"; pixelSize: 11 }
            }
        }
    }
}
