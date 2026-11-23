import Quickshell
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: bar

    readonly property var monitor: Hyprland.monitorFor(screen)
    // Keyed by the workspace names hyprland.lua sets; others show their name,
    // which for unnamed workspaces is the number.
    readonly property var icons: ({
        "Code": "\u{F0169}",
        "Terminals": "\u{F489}",
        "AI": "\u{F06A9}",
        "Browser": "\u{F059F}",
        "Chat": "\u{F0B79}",
    })

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
                // Not `id > 0`: Hyprland 0.57 omits the id from its workspace
                // list, so Quickshell reports -1 until an event fills it in.
                model: Hyprland.workspaces.values.filter(ws => ws.monitor === bar.monitor && !ws.name.startsWith("special:"))

                Rectangle {
                    required property var modelData
                    readonly property bool focused: modelData.focused

                    width: Math.max(focused ? 34 : 24, label.implicitWidth + 16)
                    height: 22
                    radius: height / 2
                    color: modelData.urgent ? Theme.red
                         : focused ? Theme.accent
                         : hover.hovered ? Theme.highlight
                         : "transparent"

                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 160 } }

                    Label {
                        id: label
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: bar.icons[modelData.name] ?? modelData.name
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
