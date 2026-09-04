import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property alias text: input.text
    property string placeholderText: "Password"
    property bool errorState: false
    property bool revealPassword: false
    property bool busy: false
    property string errorMessage: ""
    signal accepted(string password)

    radius: 18
    color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.55)
    border.width: 1
    border.color: errorState ? Colors.red : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12)
    implicitWidth: 360
    implicitHeight: 58

    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: parent.radius + 1
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, input.activeFocus ? 0.6 : 0.15)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 12

        GlyphIcon {
            glyph: "\ue897"
            color: root.errorState ? Colors.red : Colors.accent
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            color: Colors.fg
            echoMode: root.revealPassword ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"
            font.family: "SF Pro Display"
            font.pixelSize: 15
            selectByMouse: true
            clip: true
            enabled: !root.busy

            Keys.onReturnPressed: root.accepted(text)
            Keys.onEnterPressed: root.accepted(text)
            onTextChanged: if (root.errorState) root.errorState = false

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0
                text: root.errorState && root.errorMessage.length > 0 ? root.errorMessage : root.placeholderText
                color: root.errorState ? Colors.red : Colors.grey1
                font.family: "SF Pro Display"
                font.pixelSize: 15
            }
        }

        GlyphIcon {
            glyph: root.revealPassword ? "\ue8f4" : "\ue8f5"
            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.85)

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.revealPassword = !root.revealPassword
            }
        }
    }
}
