import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Pipewire
import QtQuick

PanelWindow {
    id: bar

    signal dateClicked()

    readonly property var monitor: Hyprland.monitorFor(screen)

    function levelColor(level) {
        return level >= 2 ? Theme.red : Theme.orange;
    }

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
    implicitHeight: Theme.barHeight
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

            // One pill slides between tabs, so a switch reads as one motion.
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

                        // An app here has something unread. Not on the
                        // workspace you're on: it would sit on the pill, and
                        // the app's own pill on the right already says it.
                        Rectangle {
                            visible: !tab.focused && Attention.items.some(i => i.workspace === tab.modelData.id)
                            anchors { right: parent.right; top: parent.top; rightMargin: 3; topMargin: 2 }
                            width: 7
                            height: 7
                            radius: width / 2
                            color: Theme.red
                            border { width: 1; color: Theme.bg }
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

        // Volume itself shows in the OSD; the bar only warns that sound is off.
        PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

        Row {
            anchors { right: date.left; rightMargin: 24; top: parent.top; bottom: parent.bottom }
            spacing: 16

            // Apps with something unread, in red so the eye catches them;
            // click opens, right click dismisses what came by notification
            // (an app's own count only clears when it's read).
            Repeater {
                model: Attention.items

                Rectangle {
                    id: app
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    // The plate already pads the glyph, so less on the left.
                    width: pill.width + 4 + 9
                    height: 22
                    radius: height / 2
                    color: Theme.alpha(Theme.red, 0.14)
                    border { width: 1.5; color: Theme.red }

                    Row {
                        id: pill
                        x: 4
                        height: parent.height
                        spacing: 4

                        // Just the glyph: the pill is its plate.
                        AppGlyph {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 20
                            appId: app.modelData.appId ?? ""
                            appClass: app.modelData.appClass
                            color: "transparent"
                            border.width: 0
                        }

                        Label {
                            visible: app.modelData.count > 0
                            text: app.modelData.count > 99 ? "99+" : app.modelData.count
                            color: Theme.red
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => mouse.button === Qt.RightButton
                            ? app.modelData.dismiss?.() : app.modelData.open()
                    }
                }
            }

            Indicator {
                active: Resources.cpuLevel > 0
                color: bar.levelColor(Resources.cpuLevel)
                icon: "\u{F04C5}"
                label: `${Math.round(Resources.cpu)}%`
                detail: Resources.cpuHog
                onClicked: Quickshell.execDetached(["ghostty", "+new-window", "-e", "btop"])
            }

            Indicator {
                active: Resources.memLevel > 0
                color: bar.levelColor(Resources.memLevel)
                icon: "\u{F035B}"
                label: `${Math.round(Resources.memUsed)}%`
                detail: Resources.memHog
                onClicked: Quickshell.execDetached(["ghostty", "+new-window", "-e", "btop"])
            }

            Indicator {
                active: Resources.diskLevel > 0
                color: bar.levelColor(Resources.diskLevel)
                icon: "\u{F02CA}"
                label: `${(Resources.diskFree / 2 ** 30).toFixed(Resources.diskFree < 10 * 2 ** 30 ? 1 : 0)}G<font color="${Theme.muted}"> free</font>`
            }

            // Red with no network at all, orange when connected but the
            // internet is out of reach (no route, or a captive portal).
            Indicator {
                readonly property int connectivity: Networking.connectivity
                active: connectivity === NetworkConnectivity.None
                    || connectivity === NetworkConnectivity.Limited
                    || connectivity === NetworkConnectivity.Portal
                color: connectivity === NetworkConnectivity.None ? Theme.red : Theme.orange
                icon: "\u{F0A8E}"
                onClicked: Quickshell.execDetached(["ghostty", "+new-window", "-e", "nmtui"])
            }

            Indicator {
                active: Pipewire.defaultAudioSink?.audio?.muted ?? false
                icon: "\u{F075F}"
                onClicked: Pipewire.defaultAudioSink.audio.muted = false
            }
        }

        Label {
            id: date
            anchors { right: parent.right; rightMargin: 14 }
            textFormat: Text.StyledText
            text: `<font color="${Theme.subtext}">${Qt.formatDateTime(clock.date, "ddd dd.MM.yyyy")}</font>`
                + `<font color="${Theme.border}">  ·  </font>`
                + `<b>${Qt.formatDateTime(clock.date, "HH:mm")}</b>`

            MouseArea {
                anchors { fill: parent; margins: -6 }
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.dateClicked()
            }
        }
    }
}
