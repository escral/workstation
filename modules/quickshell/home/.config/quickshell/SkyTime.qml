pragma Singleton
import Quickshell
import QtQuick

// One clock for every Sky, so the lock screen continues the desktop's frame.
Singleton {
    // Each frame repaints the whole screen, so the rate is capped by a timer
    // instead of following vsync. Motion is slow enough that 10 fps reads as
    // smooth; profiles with a stronger GPU raise it. WS_BG_FPS=0 freezes it.
    readonly property int fps: parseInt(Quickshell.env("WS_BG_FPS") ?? "10")
    // Random start, so each session opens on a different frame.
    property real t: Math.random() * 3600

    Timer {
        interval: 1000 / Math.max(fps, 1)
        running: fps > 0
        repeat: true
        onTriggered: t += interval / 1000
    }
}
