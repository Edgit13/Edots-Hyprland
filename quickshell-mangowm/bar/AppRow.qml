import "root:/"
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: row

    required property var app
    property bool selected: false

    signal activated()
    signal entered()

    readonly property string title: LauncherService.entryName(app)
    readonly property string secondary: {
        const genericName = typeof app.genericName === "string" ? app.genericName.trim() : ""
        if (genericName.length > 0 && genericName !== title)
            return genericName

        const categories = typeof app.categories === "string" ? app.categories.trim() : ""
        if (categories.length > 0) {
            const first = categories.split(";")[0].trim()
            if (first.length > 0)
                return first
        }

        return ""
    }

    Layout.fillWidth: true
    implicitHeight: 46
    radius: 12
    color: selected ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : "transparent"
    border.width: 1
    border.color: selected ? Colors.accent : "transparent"

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: row.entered()
        onClicked: row.activated()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24

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
                elide: Text.ElideRight
                font { family: "SF Pro Display"; pixelSize: 12; weight: row.selected ? 600 : 400 }
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: row.secondary
                color: Colors.grey1
                elide: Text.ElideRight
                font { family: "SF Pro Display"; pixelSize: 10 }
            }
        }

        Text {
            visible: row.selected
            text: "↵"
            color: Colors.accent
            font { family: "SF Pro Display"; pixelSize: 12; weight: 700 }
        }
    }
}
