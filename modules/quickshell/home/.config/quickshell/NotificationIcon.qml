import Quickshell
import QtQuick

// The app's own icon or image when it sends one that loads; otherwise a bell
// that rings once, or for critical ones a warning that keeps sending out
// rings like a beacon until the card is dealt with.
Rectangle {
    id: plate

    required property var n
    required property bool critical
    required property color tint
    // The notification is freed just before its card is, by then invisible.
    readonly property string image: n?.image ?? ""
    readonly property string appIcon: n?.appIcon ?? ""

    width: 40
    height: 40
    radius: 12
    color: Qt.rgba(tint.r, tint.g, tint.b, 0.15)

    Image {
        id: picture
        anchors.fill: parent
        anchors.margins: plate.image !== "" ? 0 : 6
        source: plate.image !== "" ? plate.image
            : plate.appIcon !== "" ? Quickshell.iconPath(plate.appIcon, true) : ""
        visible: status === Image.Ready
        sourceSize { width: 80; height: 80 }
        fillMode: plate.image !== "" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
    }

    Rectangle {
        id: ring
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border { width: 2; color: plate.tint }
        opacity: 0

        SequentialAnimation {
            running: plate.critical && !picture.visible
            loops: Animation.Infinite
            PauseAnimation { duration: 500 }
            ParallelAnimation {
                NumberAnimation { target: ring; property: "scale"; from: 1; to: 1.6; duration: 1100; easing.type: Easing.OutCubic }
                NumberAnimation { target: ring; property: "opacity"; from: 0.7; to: 0; duration: 1100; easing.type: Easing.OutQuad }
            }
            PauseAnimation { duration: 900 }
        }
    }

    Text {
        id: glyph
        anchors.centerIn: parent
        visible: !picture.visible
        text: plate.critical ? "\u{F0026}" : "\u{F009A}"
        color: plate.tint
        font { family: Theme.font; pointSize: 15 }
        // Swings from its top, like a real bell.
        transformOrigin: Item.Top

        // Waits for the card to finish sliding in, then rings once.
        SequentialAnimation {
            running: glyph.visible && !plate.critical
            PauseAnimation { duration: 550 }
            NumberAnimation { target: glyph; property: "rotation"; to: 16; duration: 70; easing.type: Easing.OutQuad }
            NumberAnimation { target: glyph; property: "rotation"; to: -14; duration: 110; easing.type: Easing.InOutQuad }
            NumberAnimation { target: glyph; property: "rotation"; to: 9; duration: 100; easing.type: Easing.InOutQuad }
            NumberAnimation { target: glyph; property: "rotation"; to: -5; duration: 90; easing.type: Easing.InOutQuad }
            NumberAnimation { target: glyph; property: "rotation"; to: 0; duration: 80; easing.type: Easing.OutQuad }
        }
    }
}
