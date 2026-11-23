// Placeholder bar: proves Quickshell runs. Real shell comes later.
import Quickshell
import QtQuick

ShellRoot {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 28
            color: "#303446"

            Text {
                anchors.centerIn: parent
                color: "#c6d0f5"
                text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
            }
        }
    }
}
