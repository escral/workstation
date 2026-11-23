import QtQuick

// A bar glyph that exists only while something needs attention; clicking it
// is the quickest fix for that something.
Text {
    id: indicator

    required property bool active
    signal clicked

    anchors.verticalCenter: parent?.verticalCenter
    color: Theme.red
    font { family: Theme.font; pointSize: Theme.fontSize + 2 }
    opacity: active ? 1 : 0
    scale: active ? 1 : 0.6
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 160 } }
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
    Behavior on color { ColorAnimation { duration: 150 } }

    TapHandler { onTapped: indicator.clicked() }
}
