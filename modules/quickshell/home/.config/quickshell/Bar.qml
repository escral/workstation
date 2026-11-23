import Quickshell
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: bar

    readonly property var monitor: Hyprland.monitorFor(screen)

    anchors { bottom: true; left: true; right: true }
    margins { bottom: Theme.gap; left: Theme.gap; right: Theme.gap }
    implicitHeight: 32
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.88)
        border { width: 1; color: Theme.highlight }

        Row {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            spacing: 4

            Repeater {
                model: Hyprland.workspaces.values.filter(ws => ws.monitor === bar.monitor && ws.id > 0)

                Rectangle {
                    required property var modelData
                    readonly property bool focused: modelData.focused

                    width: focused ? 34 : 24
                    height: 22
                    radius: height / 2
                    color: modelData.urgent ? Theme.red
                         : focused ? Theme.accent
                         : hover.hovered ? Theme.highlight
                         : "transparent"

                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 160 } }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.name
                        color: focused || modelData.urgent ? Theme.bg
                             : modelData.active ? Theme.text
                             : Theme.subtext
                        font.bold: focused
                    }

                    HoverHandler { id: hover }
                    TapHandler { onTapped: modelData.activate() }
                }
            }
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Label {
            anchors { right: parent.right; rightMargin: 14 }
            textFormat: Text.StyledText
            text: `<font color="${Theme.subtext}">${Qt.formatDateTime(clock.date, "ddd dd.MM.yyyy")}</font>`
                + `<font color="${Theme.border}">  ·  </font>`
                + `<b>${Qt.formatDateTime(clock.date, "HH:mm")}</b>`
        }
    }
}
