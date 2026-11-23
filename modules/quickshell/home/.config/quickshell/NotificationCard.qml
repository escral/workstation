import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// One popup. It owns its life: slides in, and on the way out slides away,
// folds its height so the cards above settle down, then destroys itself.
Item {
    id: card

    required property var n
    readonly property bool critical: n.urgency === NotificationUrgency.Critical
    readonly property color tint: critical ? Theme.red : Theme.accent
    // Apps send -1 for "your default"; critical ones wait for the user.
    readonly property int lifetime: critical ? 0 : n.expireTimeout > 0 ? n.expireTimeout * 1000 : 5000
    property bool leaving: false

    // `close` reaches the notification only once the card is gone: closing it
    // frees the object the card's texts still read from.
    function leave(close) {
        if (leaving)
            return;
        leaving = true;
        exit.close = close;
        exit.start();
    }

    // The gap above the card lives inside it, so folding the card closes the
    // gap too instead of leaving it to jump at the end.
    height: face.height + Theme.gap
    clip: true

    Connections {
        target: card.n
        // Closed by the app or replaced elsewhere: just animate out.
        function onClosed() { card.leave(null) }
    }

    // Slide-out and fold overlap, so the stack starts settling while the card
    // is still leaving.
    SequentialAnimation {
        id: exit
        property var close
        ParallelAnimation {
            NumberAnimation { target: slide; property: "x"; to: card.width; duration: 160; easing.type: Easing.InQuad }
            NumberAnimation { target: face; property: "opacity"; to: 0; duration: 140 }
            SequentialAnimation {
                PauseAnimation { duration: 90 }
                NumberAnimation { target: card; property: "height"; to: 0; duration: 160; easing.type: Easing.OutQuint }
            }
        }
        ScriptAction {
            script: {
                if (exit.close)
                    exit.close();
                card.destroy();
            }
        }
    }

    Rectangle {
        id: face
        anchors.bottom: parent.bottom
        width: parent.width
        height: content.implicitHeight + 28
        radius: Theme.radius
        // Bg tinted with the accent (red when critical), so the card stands
        // out on dark windows by hue and on light ones by contrast.
        color: Qt.tint(Theme.bg, Qt.rgba(card.tint.r, card.tint.g, card.tint.b, hover.hovered ? 0.28 : 0.22))
        border { width: 1; color: Qt.rgba(card.tint.r, card.tint.g, card.tint.b, 0.3) }
        Behavior on color { ColorAnimation { duration: 150 } }
        clip: true

        opacity: 0
        transform: Translate { id: slide; x: card.width * 0.4 }
        Component.onCompleted: enter.start()

        ParallelAnimation {
            id: enter
            NumberAnimation { target: slide; property: "x"; to: 0; duration: 320; easing.type: Easing.OutQuint }
            NumberAnimation { target: face; property: "opacity"; to: 1; duration: 160 }
        }

        // Time left, drawn as a line along the bottom edge; hovering pauses it.
        Rectangle {
            anchors { left: parent.left; bottom: parent.bottom; leftMargin: Theme.radius }
            height: 2
            radius: 1
            color: card.tint
            opacity: 0.6
            visible: card.lifetime > 0
            width: parent.width - Theme.radius * 2

            NumberAnimation on width {
                to: 0
                duration: card.lifetime
                running: card.lifetime > 0
                paused: running && hover.hovered
                onFinished: card.leave(() => card.n.expire())
            }
        }

        HoverHandler { id: hover }
        // Left click does what the app asks for, right click just dismisses.
        TapHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onTapped: (point, button) => {
                if (button === Qt.LeftButton)
                    card.n.actions.find(a => a.identifier === "default")?.invoke();
                card.leave(() => card.n.dismiss());
            }
        }

        Row {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 12

            NotificationIcon {
                id: icon
                n: card.n
                critical: card.critical
                tint: card.tint
            }

            Column {
                width: content.width - icon.width - content.spacing
                spacing: 2

                Text {
                    width: parent.width
                    text: card.n.appName
                    visible: text !== ""
                    color: card.tint
                    elide: Text.ElideRight
                    font { family: Theme.font; pointSize: Theme.fontSize - 2 }
                }

                Text {
                    width: parent.width
                    topPadding: 2
                    text: card.n.summary
                    color: Theme.text
                    elide: Text.ElideRight
                    font { family: Theme.font; pointSize: Theme.fontSize; bold: true }
                }

                Text {
                    width: parent.width
                    text: card.n.body
                    visible: text !== ""
                    color: Theme.subtext
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    textFormat: Text.StyledText
                    lineHeight: 1.15
                    font { family: Theme.font; pointSize: Theme.fontSize - 1 }
                }

                Row {
                    readonly property var buttons: card.n.actions.filter(a => a.identifier !== "default")
                    visible: buttons.length > 0
                    topPadding: 8
                    spacing: 6

                    Repeater {
                        model: parent.buttons

                        Rectangle {
                            required property var modelData
                            width: label.implicitWidth + 22
                            height: 26
                            radius: height / 2
                            color: Qt.rgba(card.tint.r, card.tint.g, card.tint.b, pointer.hovered ? 0.3 : 0.12)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                id: label
                                anchors.centerIn: parent
                                text: parent.modelData.text
                                color: Theme.text
                                font { family: Theme.font; pointSize: Theme.fontSize - 2 }
                            }

                            HoverHandler { id: pointer }
                            TapHandler {
                                onTapped: {
                                    const action = parent.modelData;
                                    card.leave(() => { action.invoke(); card.n.dismiss() });
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
