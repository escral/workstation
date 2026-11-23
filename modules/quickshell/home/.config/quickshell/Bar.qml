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

        Item {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            width: workspaces.width
            height: 22

            // One pill slides to the focused workspace instead of each tab
            // fading its own background, so a switch reads as one motion.
            Rectangle {
                id: indicator
                property Item target: null
                visible: target !== null
                x: target ? target.x : 0
                width: target ? target.width : 0
                height: parent.height
                radius: height / 2
                color: Theme.accent

                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            Row {
                id: workspaces
                spacing: 4

                Repeater {
                    // Not `id > 0`: workspaces opened by name have no id (-1).
                    model: Hyprland.workspaces.values.filter(ws => ws.monitor === bar.monitor && !ws.name.startsWith("special:"))

                    Rectangle {
                        id: tab
                        required property var modelData
                        readonly property bool focused: modelData.focused

                        onFocusedChanged: if (focused) indicator.target = tab
                        Component.onCompleted: if (focused) indicator.target = tab

                        // Same width focused or not, so switching never shifts the row.
                        width: Math.max(28, label.implicitWidth + 16)
                        height: 22
                        radius: height / 2
                        color: modelData.urgent ? Theme.red
                             : hover.hovered && !focused ? Theme.highlight
                             : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Label {
                            id: label
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: bar.icons[modelData.name] ?? modelData.name
                            color: focused || modelData.urgent ? Theme.bg
                                 : modelData.active ? Theme.text
                                 : Theme.subtext

                            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }

                        HoverHandler { id: hover }
                        // Not modelData.activate(): it sends the pre-Lua `workspace N`
                        // dispatch, which Hyprland 0.57 rejects. By id where there is
                        // one: "name:AI" would open a second AI instead of workspace 3.
                        TapHandler {
                            onTapped: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${tab.modelData.id > 0
                                ? tab.modelData.id : JSON.stringify("name:" + tab.modelData.name)} })`)
                        }
                    }
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
