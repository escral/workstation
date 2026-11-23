import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "ws-background"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.bgDark

    // Each frame repaints the whole screen, so the rate is capped by a timer
    // instead of following vsync. Motion is slow enough that 10 fps reads as
    // smooth; profiles with a stronger GPU raise it. WS_BG_FPS=0 freezes it.
    readonly property int fps: parseInt(Quickshell.env("WS_BG_FPS") ?? "10")
    // Random start, so each session opens on a different frame.
    property real t: Math.random() * 3600

    Timer {
        interval: 1000 / Math.max(root.fps, 1)
        running: root.fps > 0
        repeat: true
        onTriggered: root.t += interval / 1000
    }

    ShaderEffect {
        anchors.fill: parent
        fragmentShader: "shaders/background.frag.qsb"

        property real time: root.t
        property size resolution: Qt.size(width, height)
        property color skyTop: Theme.bg
        property color skyBottom: Theme.bgDark
        // Glow tints walk through these in order, so neighbours should blend well.
        property color c0: Theme.blue
        property color c1: Theme.cyan
        property color c2: Theme.teal
        property color c3: Theme.purple
        property color c4: Theme.magenta
        property color c5: Theme.red
    }
}
