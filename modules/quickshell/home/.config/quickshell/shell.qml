import Quickshell
import QtQuick

ShellRoot {
    Lock {}
    Notifications {}
    VolumeOsd {}
    Launcher {}
    HelpOverlay {}

    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData

            Background { screen: modelData }
            Calendar { id: calendar; screen: modelData }
            Bar { screen: modelData; onDateClicked: calendar.toggle() }
        }
    }
}
