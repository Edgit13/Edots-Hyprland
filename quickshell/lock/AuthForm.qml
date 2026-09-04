import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var auth

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 14

        GlowField {
            id: field
            placeholderText: auth && auth.authenticating ? "Authenticating..." : "Enter password"
            busy: auth ? auth.authenticating : false
            errorMessage: auth ? auth.lastError : ""
            onAccepted: password => {
                if (auth && password.length > 0)
                    auth.submit(password)
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: auth && auth.authenticating ? "Checking credentials..." : "Unlock session"
            color: Colors.grey2
            font.family: "SF Pro Display"
            font.pixelSize: 12
        }
    }

    Connections {
        target: auth
        function onFailed() {
            field.errorState = true
            field.text = ""
        }
        function onSucceeded() {
            field.errorState = false
            field.text = ""
        }
    }
}
