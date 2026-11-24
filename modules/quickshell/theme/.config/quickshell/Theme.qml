pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property color bg: "#{{bg}}"
    readonly property color bgDark: "#{{bg_dark}}"
    readonly property color surface: "#{{surface}}"
    readonly property color highlight: "#{{highlight}}"
    readonly property color border: "#{{border}}"
    readonly property color text: "#{{text}}"
    readonly property color subtext: "#{{subtext}}"
    readonly property color muted: "#{{muted}}"

    readonly property color blue: "#{{blue}}"
    readonly property color cyan: "#{{cyan}}"
    readonly property color teal: "#{{teal}}"
    readonly property color magenta: "#{{magenta}}"
    readonly property color purple: "#{{purple}}"
    readonly property color orange: "#{{orange}}"
    readonly property color green: "#{{green}}"
    readonly property color red: "#{{red}}"

    readonly property color accent: "#{{accent}}"

    readonly property string font: "FiraCode Nerd Font"
    readonly property int fontSize: 11
    readonly property int radius: 10
    readonly property int gap: 8
    readonly property int barHeight: 32

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
