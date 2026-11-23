import QtQuick

ShaderEffect {
    fragmentShader: "shaders/background.frag.qsb"

    property real time: SkyTime.t
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
