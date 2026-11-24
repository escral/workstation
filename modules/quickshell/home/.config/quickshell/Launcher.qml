import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// One field for apps, projects, open windows, a calculator, actions and the
// web (LauncherResults.qml finds them). Super+Space opens it on everything,
// Super+D on apps, Super+P on projects, Super+Ctrl+P on actions; Tab narrows
// or widens from there.
Scope {
    id: root

    property bool open: false
    property string query: ""
    property int scope: 0
    // Reopening soon after keeps the last query, selected, like Spotlight.
    property real closedAt: 0

    readonly property var scopes: results.scopes

    // Each launcher key opens it on its own scope; pressing it again closes,
    // another launcher key switches over.
    function show(name) {
        const wanted = Math.max(0, scopes.findIndex(s => s.toLowerCase() === name));
        if (open && scope === wanted) {
            close();
            return;
        }
        if (!open && Date.now() - closedAt > 60000)
            query = "";
        scope = wanted;
        Hyprland.refreshToplevels();
        open = true;
    }

    function close() {
        open = false;
        closedAt = Date.now();
    }

    IpcHandler {
        target: "launcher"
        function open(scope: string): void { root.show(scope) }
    }

    LauncherResults {
        id: results
        query: root.query
        scope: root.scope
        active: root.open
    }

    function run(item, fresh) {
        if (!item || item.heading)
            return;
        results.remember(item.key, query.trim().toLowerCase());
        close();
        item.run(fresh);
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        // Stays mapped while closed, taking no input: mapping anew would add
        // Hyprland's layer fade and a fresh surface to every open.
        mask: root.open ? null : passThrough
        readonly property Region passThrough: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "ws-launcher"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        // A click anywhere off the panel closes it.
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            id: panel
            readonly property int pad: 8

            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.2)
            width: 600
            height: search.height + chips.height + list.height + footer.height
            radius: 16
            color: Qt.tint(Theme.bg, Theme.alpha(Theme.accent, 0.08))
            border { width: 1; color: Theme.alpha(Theme.accent, 0.28) }
            clip: true

            // No animation on purpose: it opens by key many times a day, and
            // any fade or scale there reads as lag (Raycast, Spotlight).
            visible: root.open

            // Swallows clicks so they don't reach the closing area behind.
            MouseArea { anchors.fill: parent }

            Item {
                id: search
                width: parent.width
                height: 60

                // Both center on their glyphs, not the line box: Nerd Fonts
                // reserve extra ascent for icons, which lifts plain centering.
                TextMetrics { id: glassBox; font: glass.font; text: glass.text }
                TextMetrics { id: textBox; font: input.font; text: "0H" }

                Text {
                    id: glass
                    anchors { left: parent.left; leftMargin: 24 }
                    anchors.baseline: parent.verticalCenter
                    anchors.baselineOffset: -(glassBox.tightBoundingRect.y + glassBox.tightBoundingRect.height / 2)
                    text: "\u{F0349}"
                    color: Theme.accent
                    font { family: Theme.font; pixelSize: 20 }
                }

                TextInput {
                    id: input
                    anchors { left: glass.right; right: parent.right; leftMargin: 14; rightMargin: 24 }
                    anchors.baseline: parent.verticalCenter
                    anchors.baselineOffset: textBox.tightBoundingRect.height / 2
                    color: Theme.text
                    selectionColor: Theme.alpha(Theme.accent, 0.35)
                    selectedTextColor: Theme.text
                    font { family: Theme.font; pixelSize: 17 }
                    focus: true
                    text: root.query
                    onTextChanged: root.query = text

                    // A thin accent bar that stays solid while typing and
                    // breathes rather than blinks when idle.
                    cursorDelegate: Rectangle {
                        width: 2
                        radius: 1
                        color: Theme.accent
                        visible: input.activeFocus

                        SequentialAnimation on opacity {
                            id: breathe
                            loops: Animation.Infinite
                            PauseAnimation { duration: 500 }
                            NumberAnimation { to: 0.15; duration: 350; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 350; easing.type: Easing.InOutSine }
                        }

                        Connections {
                            target: input
                            function onCursorPositionChanged() { breathe.restart() }
                        }
                    }

                    Connections {
                        target: root
                        function onOpenChanged() {
                            if (!root.open)
                                return;
                            input.forceActiveFocus();
                            input.selectAll();
                        }
                    }

                    Text {
                        visible: input.text === ""
                        text: root.scope === 0 ? "Search apps, projects, windows, actions, the web" : "Search " + root.scopes[root.scope].toLowerCase()
                        color: Theme.muted
                        font: input.font
                    }

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        const shift = event.modifiers & Qt.ShiftModifier;
                        if (event.key === Qt.Key_Down || ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))
                            list.select(list.currentIndex + 1, 1);
                        else if (event.key === Qt.Key_Up || ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))
                            list.select(list.currentIndex - 1, -1);
                        else if (event.key === Qt.Key_Tab)
                            root.scope = (root.scope + 1) % root.scopes.length;
                        else if (event.key === Qt.Key_Backtab)
                            root.scope = (root.scope + root.scopes.length - 1) % root.scopes.length;
                        else if (ctrl && event.key >= Qt.Key_1 && event.key < Qt.Key_1 + root.scopes.length)
                            root.scope = event.key - Qt.Key_1;
                        else if (event.key === Qt.Key_Backspace && input.text === "" && root.scope !== 0)
                            root.scope = 0;
                        else if (event.key === Qt.Key_Escape)
                            root.close();
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            root.run(results.rows[list.currentIndex], shift);
                        else
                            return;
                        event.accepted = true;
                    }
                }
            }

            Row {
                id: chips
                anchors { top: search.bottom; left: parent.left; leftMargin: 20 }
                height: 34
                spacing: 4

                Repeater {
                    model: root.scopes

                    Rectangle {
                        id: chip
                        required property string modelData
                        required property int index
                        readonly property bool active: root.scope === index

                        anchors.verticalCenter: parent.verticalCenter
                        width: label.implicitWidth + 20
                        height: 24
                        radius: height / 2
                        color: active ? Theme.alpha(Theme.accent, 0.18) : "transparent"

                        Label {
                            id: label
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: chip.modelData
                            color: chip.active ? Theme.accent : Theme.muted
                            font.pointSize: 9
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.scope = chip.index
                        }
                    }
                }
            }

            Rectangle {
                anchors.top: chips.bottom
                width: parent.width
                height: 1
                color: Theme.alpha(Theme.accent, 0.12)
            }

            ListView {
                id: list
                readonly property int rowHeight: 52
                readonly property int headingHeight: 28
                readonly property int maxHeight: 9 * rowHeight

                // Moves the selection to the nearest row at or past i in the
                // given direction, stepping over headings.
                function select(i, dir) {
                    const rows = results.rows;
                    while (i >= 0 && i < rows.length && rows[i].heading)
                        i += dir;
                    if (i >= 0 && i < rows.length)
                        currentIndex = i;
                    else if (dir < 0 && rows.length)
                        select(0, 1);
                }

                anchors { top: chips.bottom; topMargin: 1 }
                width: parent.width
                height: count ? Math.min(contentHeight + topMargin + bottomMargin, maxHeight) : rowHeight + topMargin + bottomMargin
                topMargin: panel.pad
                bottomMargin: panel.pad
                clip: true
                model: results.rows
                onModelChanged: select(0, 1)
                // The selection jumps: a sliding highlight reads as lag.
                highlightMoveDuration: 0
                highlightResizeDuration: 0
                boundsBehavior: Flickable.StopAtBounds

                // ListView places the highlight itself, so the inset lives
                // on an inner rectangle.
                highlight: Item {
                    visible: list.currentItem && !list.currentItem.isHeading

                    Rectangle {
                        anchors { fill: parent; leftMargin: panel.pad; rightMargin: panel.pad }
                        radius: 10
                        color: Theme.alpha(Theme.accent, 0.14)
                    }
                }

                delegate: LauncherRow {
                    pad: panel.pad
                    rowHeight: list.rowHeight
                    headingHeight: list.headingHeight
                    onHovered: list.currentIndex = index
                    onActivated: fresh => root.run(item, fresh)
                }
            }

            Text {
                anchors.centerIn: list
                visible: list.count === 0
                text: root.query.trim() === "" ? "Type to search"
                    : root.scope === 0 ? "Nothing found"
                    : "No " + root.scopes[root.scope].toLowerCase() + " found"
                color: Theme.muted
                font { family: Theme.font; pixelSize: 14 }
            }

            Rectangle {
                id: footer
                readonly property var item: results.rows[list.currentIndex]

                anchors.top: list.bottom
                width: parent.width
                height: 34
                color: Theme.alpha(Theme.accent, 0.04)

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.alpha(Theme.accent, 0.12)
                }

                Row {
                    anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                    spacing: 14

                    Repeater {
                        model: [
                            footer.item?.enter ? ["↵", footer.item.enter] : null,
                            footer.item?.shift ? ["⇧↵", footer.item.shift] : null,
                            ["tab", "narrow"],
                            ["esc", "close"],
                        ].filter(h => h)

                        KeyHint {
                            required property var modelData
                            key: modelData[0]
                            does: modelData[1]
                        }
                    }
                }
            }
        }
    }
}
