import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick

// Shows the default output's volume for a moment whenever it or mute changes,
// whatever changed it: media keys, pavucontrol, a headset's own buttons.
Scope {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    property bool open: false

    // Pipewire fills in volume and mute only for tracked nodes.
    PwObjectTracker { objects: [root.sink] }

    Connections {
        target: root.sink?.audio ?? null
        // A node reports its levels once on becoming ready; that is not a change.
        enabled: root.sink?.ready ?? false
        function onVolumesChanged() { root.show() }
        function onMutedChanged() { root.show() }
    }

    function show() {
        open = true;
        hide.restart();
    }

    Timer {
        id: hide
        interval: 1200
        onTriggered: root.open = false
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: face.opacity > 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "ws-osd"
        exclusionMode: ExclusionMode.Ignore
        anchors.bottom: true
        // Same distance above the windows' bottom edge as the notifications.
        margins.bottom: Theme.barHeight + Theme.gap * 4
        implicitWidth: 260
        implicitHeight: 44
        color: "transparent"
        // Purely informative: clicks go to whatever is underneath.
        mask: Region {}

        Rectangle {
            id: face
            readonly property color tint: root.muted ? Theme.muted : Theme.accent

            width: parent.width
            height: parent.height
            radius: height / 2
            color: Qt.tint(Theme.bg, Qt.rgba(tint.r, tint.g, tint.b, 0.22))
            border { width: 1; color: Qt.rgba(tint.r, tint.g, tint.b, 0.3) }
            Behavior on color { ColorAnimation { duration: 150 } }

            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: root.open ? 140 : 200 } }
            transform: Translate {
                y: root.open ? 0 : 10
                Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutQuint } }
            }

            Row {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: 12

                Text {
                    id: icon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    text: root.muted || root.volume === 0 ? "\u{F075F}"
                        : root.volume < 0.34 ? "\u{F057F}"
                        : root.volume < 0.67 ? "\u{F0580}" : "\u{F057E}"
                    color: face.tint
                    font { family: Theme.font; pointSize: 14 }
                }

                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - icon.width - percent.width - parent.spacing * 2
                    height: 6
                    radius: 3
                    color: Qt.rgba(face.tint.r, face.tint.g, face.tint.b, 0.2)

                    Rectangle {
                        width: track.width * Math.min(root.volume, 1)
                        height: parent.height
                        radius: parent.radius
                        color: face.tint
                        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                Text {
                    id: percent
                    anchors.verticalCenter: parent.verticalCenter
                    // Wide enough for "100", so the track doesn't jump at the ends.
                    width: 30
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.volume * 100)
                    color: root.muted ? Theme.muted : Theme.text
                    font { family: Theme.font; pointSize: Theme.fontSize; bold: true }
                }
            }
        }
    }
}
