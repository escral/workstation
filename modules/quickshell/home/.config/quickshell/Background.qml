import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "ws-background"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.bgDark

    // Each frame repaints the whole screen, so the rate is capped by a timer
    // instead of following vsync. Motion is slow enough that 10 fps reads as
    // smooth. WS_BG_FPS=0 freezes it.
    readonly property int fps: parseInt(Quickshell.env("WS_BG_FPS") ?? "10")
    property real t: 0

    Timer {
        interval: 1000 / Math.max(root.fps, 1)
        running: root.fps > 0
        repeat: true
        onTriggered: root.t += interval / 1000
    }

    function mix(a, b, k) {
        return Qt.rgba(a.r + (b.r - a.r) * k, a.g + (b.g - a.g) * k, a.b + (b.b - a.b) * k, 1)
    }
    // 0..1..0 over `period` seconds
    function wave(period, phase) {
        return (Math.sin(2 * Math.PI * (t / period + phase)) + 1) / 2
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.bg }
            GradientStop { position: 1.0; color: Theme.bgDark }
        }
    }

    Glow {
        cx: root.width * (0.15 + 0.25 * root.wave(97, 0))
        cy: root.height * (0.10 + 0.30 * root.wave(71, 0.3))
        size: Math.max(root.width, root.height) * 0.9
        tint: root.mix(Theme.blue, Theme.cyan, root.wave(53, 0))
        strength: 0.22
    }

    Glow {
        cx: root.width * (0.85 - 0.25 * root.wave(83, 0.5))
        cy: root.height * (0.90 - 0.30 * root.wave(109, 0.1))
        size: Math.max(root.width, root.height) * 0.8
        tint: root.mix(Theme.magenta, Theme.purple, root.wave(61, 0.4))
        strength: 0.20
    }

    component Glow: Shape {
        id: glow
        property real cx
        property real cy
        property real size
        property color tint
        property real strength

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: glow.cx; centerY: glow.cy
                focalX: glow.cx; focalY: glow.cy
                centerRadius: glow.size / 2
                GradientStop { position: 0.0; color: Qt.rgba(glow.tint.r, glow.tint.g, glow.tint.b, glow.strength) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            PathRectangle { width: root.width; height: root.height }
        }
    }
}
