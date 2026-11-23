import Quickshell
import QtQuick

ShellRoot {
    Lock {}
    Notifications {}
    VolumeOsd {}

    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData

            Background { screen: modelData }
            Bar { screen: modelData }
        }
    }
}
