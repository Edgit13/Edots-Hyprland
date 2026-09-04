import QtQuick

Item {
    id: root

    required property var auth

    Content {
        anchors.fill: parent
        auth: root.auth
    }
}
