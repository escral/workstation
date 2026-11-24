import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

// The month at a glance, from the bar's date. Qt's MonthGrid does the date
// math; this styles it and behaves like the launcher: no animation, Esc or a
// click anywhere else closes.
PanelWindow {
    id: root

    property bool open: false
    property int month: 0
    property int year: 0

    readonly property date today: clock.date
    // Monday first, whatever the session locale says.
    readonly property var locale: Qt.locale("en_GB")

    function toggle() {
        if (!open)
            shift(0, true);
        open = !open;
    }

    // fresh: back to today's month, n ignored.
    function shift(n, fresh) {
        const d = fresh ? today : new Date(year, month + n, 1);
        month = d.getMonth();
        year = d.getFullYear();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Stays mapped while closed, taking no input, like the launcher: a fresh
    // map would bring Hyprland's layer fade.
    mask: open ? null : passThrough
    readonly property Region passThrough: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ws-calendar"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    onOpenChanged: if (open) content.forceActiveFocus()

    // Covers the bar too, so clicking the date again closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Rectangle {
        id: panel
        readonly property int pad: 16
        readonly property int cell: 36

        visible: root.open
        anchors {
            right: parent.right; bottom: parent.bottom
            rightMargin: Theme.gap; bottomMargin: Theme.barHeight + 2 * Theme.gap
        }
        width: content.width + 2 * pad
        height: content.height + 2 * pad
        radius: 16
        color: Theme.bgDark
        border { width: 1; color: Theme.alpha(Theme.accent, 0.28) }

        // Swallows clicks so they don't reach the closing area; the wheel
        // pages months.
        MouseArea {
            anchors.fill: parent
            onWheel: wheel => root.shift(wheel.angleDelta.y > 0 ? -1 : 1)
        }

        Column {
            id: content
            x: panel.pad
            y: panel.pad
            spacing: 12

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape)
                    root.open = false;
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_PageUp)
                    root.shift(-1);
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_PageDown)
                    root.shift(1);
                else if (event.key === Qt.Key_Up)
                    root.shift(-12);
                else if (event.key === Qt.Key_Down)
                    root.shift(12);
                else if (event.key === Qt.Key_Home || event.key === Qt.Key_T)
                    root.shift(0, true);
                else
                    return;
                event.accepted = true;
            }

            // A click here brings today's month back.
            Item {
                width: grid.width
                height: 40

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: root.today.toLocaleDateString(root.locale, "dddd")
                        color: Theme.accent
                        font { family: Theme.font; pointSize: 9 }
                    }

                    Text {
                        text: root.today.toLocaleDateString(root.locale, "d MMMM yyyy")
                        color: Theme.text
                        font { family: Theme.font; pointSize: 14; bold: true }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shift(0, true)
                }
            }

            Rectangle {
                width: grid.width
                height: 1
                color: Theme.alpha(Theme.accent, 0.12)
            }

            Item {
                width: grid.width
                height: 24

                Label {
                    anchors { left: parent.left; leftMargin: 6 }
                    textFormat: Text.StyledText
                    text: `<b><font color="${Theme.text}">${root.locale.standaloneMonthName(root.month)}</font></b>`
                        + `<font color="${Theme.subtext}">  ${root.year}</font>`
                }

                Row {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    spacing: 2

                    Repeater {
                        model: [["\u{F0141}", -1], ["\u{F0142}", 1]]

                        Rectangle {
                            id: button
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            height: 26
                            radius: 8
                            color: arrow.containsMouse ? Theme.highlight : "transparent"

                            // Centered on the chevron's own outline: the
                            // glyph sits off its advance and line box.
                            TextMetrics { id: outline; font: chevron.font; text: chevron.text }

                            Text {
                                id: chevron
                                readonly property rect box: outline.tightBoundingRect
                                anchors { left: parent.left; baseline: parent.top }
                                anchors.leftMargin: (button.width - box.width) / 2 - box.x
                                anchors.baselineOffset: button.height / 2 - (box.y + box.height / 2)
                                text: button.modelData[0]
                                color: arrow.containsMouse ? Theme.text : Theme.subtext
                                font { family: Theme.font; pointSize: Theme.fontSize }
                            }

                            MouseArea {
                                id: arrow
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.shift(parent.modelData[1])
                            }
                        }
                    }
                }
            }

            Column {
                DayOfWeekRow {
                    width: grid.width
                    height: 24
                    spacing: 0
                    locale: root.locale

                    delegate: Text {
                        required property var model
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: model.shortName.slice(0, 2)
                        color: model.day === Qt.Saturday || model.day === Qt.Sunday ? Theme.red : Theme.subtext
                        font { family: Theme.font; pointSize: 9 }
                    }
                }

                MonthGrid {
                    id: grid
                    width: 7 * panel.cell
                    height: 6 * panel.cell
                    spacing: 0
                    month: root.month
                    year: root.year
                    locale: root.locale

                    delegate: Item {
                        id: day
                        required property var model
                        readonly property bool inMonth: model.month === grid.month
                        readonly property bool weekend: model.date.getDay() === 0 || model.date.getDay() === 6

                        width: panel.cell
                        height: panel.cell

                        // The number sits in the circle, so both center on
                        // the same box.
                        Rectangle {
                            anchors.centerIn: parent
                            width: panel.cell - 6
                            height: width
                            radius: width / 2
                            color: day.model.today ? Theme.accent : "transparent"

                            Text {
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: day.model.day
                                font { family: Theme.font; pointSize: 10; bold: day.model.today }
                                color: day.model.today ? Theme.bgDark
                                     : !day.inMonth ? Theme.muted
                                     : day.weekend ? Theme.red
                                     : Theme.text
                            }
                        }
                    }
                }
            }
        }
    }
}
