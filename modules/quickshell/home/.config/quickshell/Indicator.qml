import QtQuick

// A bar glyph, with an optional reading, that exists only while something
// needs attention; clicking it is the quickest fix for that something.
Item {
    id: indicator

    required property bool active
    required property string icon
    // Styled text, so a reading can dim its less important part.
    property string label: ""
    // Who the reading is about, set apart in a chip so it doesn't read as
    // part of the number.
    property string detail: ""
    property color color: Theme.red
    signal clicked

    implicitWidth: row.implicitWidth
    height: parent?.height ?? 0
    opacity: active ? 1 : 0
    scale: active ? 1 : 0.6
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 160 } }
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        id: row
        height: parent.height
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: indicator.icon
            color: indicator.color
            font { family: Theme.font; pointSize: Theme.fontSize + 2 }
        }

        Label {
            visible: indicator.label !== ""
            text: indicator.label
            textFormat: Text.StyledText
            color: indicator.color
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: indicator.detail !== ""
            width: name.implicitWidth + 14
            height: 18
            radius: height / 2
            color: Theme.highlight

            Label {
                id: name
                anchors.horizontalCenter: parent.horizontalCenter
                text: indicator.detail.length > 16 ? indicator.detail.slice(0, 15) + "…" : indicator.detail
                color: Theme.subtext
                font.pointSize: Theme.fontSize - 2
            }
        }
    }

    TapHandler { onTapped: indicator.clicked() }
}
