import QtQuick

// A key cap and what it does, for the launcher's footer.
Row {
    property string key
    property string does

    spacing: 6
    height: 18

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: cap.implicitWidth + 10
        height: 18
        radius: 5
        color: "transparent"
        border { width: 1; color: Theme.border }

        Label {
            id: cap
            anchors.horizontalCenter: parent.horizontalCenter
            text: parent.parent.key
            color: Theme.subtext
            font.pointSize: 7.5
        }
    }

    Label {
        text: parent.does
        color: Theme.muted
        font.pointSize: 8.25
    }
}
