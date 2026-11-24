import Quickshell
import QtQuick

ShellRoot {
    Lock {}
    Notifications {}
    VolumeOsd {}
    Launcher {}

    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData

            Background { screen: modelData }
            Bar { screen: modelData }
        }
    }
}
