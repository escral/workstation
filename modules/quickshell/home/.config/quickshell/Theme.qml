pragma Singleton
import Quickshell
import QtQuick

// Tokyo Night
Singleton {
    readonly property color bg: "#1a1b26"
    readonly property color bgDark: "#16161e"
    readonly property color surface: "#24283b"
    readonly property color highlight: "#292e42"
    readonly property color border: "#414868"
    readonly property color text: "#c0caf5"
    readonly property color subtext: "#a9b1d6"
    readonly property color muted: "#565f89"

    readonly property color blue: "#7aa2f7"
    readonly property color cyan: "#7dcfff"
    readonly property color teal: "#73daca"
    readonly property color magenta: "#bb9af7"
    readonly property color purple: "#9d7cd8"
    readonly property color orange: "#ff9e64"
    readonly property color green: "#9ece6a"
    readonly property color red: "#f7768e"

    readonly property color accent: blue

    readonly property string font: "FiraCode Nerd Font"
    readonly property int fontSize: 11
    readonly property int radius: 10
    readonly property int gap: 8
    readonly property int barHeight: 32

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
