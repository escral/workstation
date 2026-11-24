import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// The hotkeys from the action catalog (hypr/catalog.lua), grouped, while
// Super is held. Hyprland shows and hides it (quickshell/actions.d/help.lua);
// it never takes the keyboard, so the held Super still reaches Hyprland.
Scope {
    id: root

    property bool open: false
    property var entries: []
    // Modifiers held besides Super, e.g. ["SHIFT"].
    property var mods: []

    IpcHandler {
        target: "help"
        // mods: the other held modifiers, comma separated, or "none".
        function hold(mods: string): void {
            root.mods = mods === "none" ? [] : mods.split(",");
            root.open = true;
        }
        function release(): void {
            root.open = false;
            root.mods = [];
        }
    }

    FileView {
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/ws/actions.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.entries = JSON.parse(text()).filter(e => e.help && e.keys.length);
            } catch (e) {
                root.entries = [];
            }
        }
        onLoadFailed: root.entries = []
    }

    // An app's own keys only while that app is focused.
    readonly property string focusedApp: (ToplevelManager.activeToplevel?.appId ?? "").toLowerCase()

    readonly property var groups: {
        const order = [];
        const byName = {};
        for (const e of entries) {
            if (e.app && e.app.toLowerCase() !== focusedApp)
                continue;
            const name = e.group || "Other";
            if (!byName[name]) {
                byName[name] = [];
                order.push(name);
            }
            byName[name].push(e);
        }
        return order.map(name => ({ name: name, entries: byName[name] }));
    }

    // As many columns as the screen fits; each group goes to the shortest
    // column so far, keeping the panel even.
    readonly property int columnWidth: 340
    readonly property int columnGap: 40
    readonly property int columnCount: Math.max(1, Math.floor((window.width - 96 + columnGap) / (columnWidth + columnGap)))
    readonly property var columns: {
        const cols = Array.from({ length: columnCount }, () => ({ groups: [], rows: 0 }));
        for (const g of groups) {
            const col = cols.reduce((a, b) => b.rows < a.rows ? b : a);
            col.groups.push(g);
            col.rows += g.entries.length + 2;
        }
        return cols.filter(c => c.groups.length).map(c => c.groups);
    }

    readonly property var capNames: ({
        SUPER: "Super", SHIFT: "Shift", CTRL: "Ctrl", ALT: "Alt",
        RETURN: "Enter", ENTER: "Enter", ESCAPE: "Esc", SPACE: "Space", TAB: "Tab",
        GRAVE: "`", MINUS: "-", BACKSPACE: "⌫", DELETE: "Del", PRINT: "PrtSc",
        LEFT: "←", RIGHT: "→", UP: "↑", DOWN: "↓",
        "MOUSE:272": "LMB", "MOUSE:273": "RMB", MOUSE_DOWN: "Wheel ↓", MOUSE_UP: "Wheel ↑",
        XF86AUDIORAISEVOLUME: "Vol +", XF86AUDIOLOWERVOLUME: "Vol −", XF86AUDIOMUTE: "Mute",
    })

    function caps(combo) {
        return combo.split(/\s*\+\s*/).map(p => capNames[p.toUpperCase()] ?? (p.length === 1 ? p.toUpperCase() : p));
    }

    // Reachable when one of its combos holds Super and every held modifier:
    // its held caps dim and the rest show what is left to press. Rows that
    // can't be reached dim whole rather than hide, so nothing moves while
    // modifiers come and go.
    readonly property var heldCaps: ["Super", ...mods.map(m => capNames[m])]

    function reachable(keys) {
        return keys.some(k => {
            const parts = k.toUpperCase().split(/\s*\+\s*/);
            return parts.includes("SUPER") && mods.every(m => parts.includes(m));
        });
    }

    // "Super H" and "Super ←" read as one combo with "H / ←" as its last key.
    function capsOf(keys) {
        const all = keys.map(caps);
        const head = all[0].slice(0, -1);
        const same = all.every(c => c.length === all[0].length && c.slice(0, -1).join() === head.join());
        return same ? [...head, all.map(c => c[c.length - 1]).join(" / ")] : all[0];
    }

    PanelWindow {
        id: window
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        // Mapped all the time and never taking input: mapping anew on every
        // hold would add a layer fade and a fresh surface.
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "ws-help"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        Rectangle {
            anchors.centerIn: parent
            width: content.width + 56
            height: content.height + 48
            radius: 16
            color: Qt.tint(Theme.bg, Theme.alpha(Theme.accent, 0.08))
            border { width: 1; color: Theme.alpha(Theme.accent, 0.28) }
            visible: root.open && root.entries.length > 0

            Row {
                id: content
                anchors.centerIn: parent
                spacing: root.columnGap

                Repeater {
                    model: root.columns

                    Column {
                        required property var modelData
                        spacing: 18

                        Repeater {
                            model: parent.modelData

                            Column {
                                required property var modelData
                                spacing: 4

                                Text {
                                    text: parent.modelData.name.toUpperCase()
                                    color: Theme.accent
                                    font { family: Theme.font; pixelSize: 11; letterSpacing: 1.5 }
                                    bottomPadding: 4
                                }

                                Repeater {
                                    model: parent.modelData.entries

                                    Item {
                                        required property var modelData
                                        opacity: root.reachable(modelData.keys) ? 1 : 0.3
                                        width: root.columnWidth
                                        height: 24

                                        Text {
                                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                            width: parent.width - keys.width - 12
                                            elide: Text.ElideRight
                                            text: parent.modelData.title
                                            color: Theme.subtext
                                            font { family: Theme.font; pixelSize: 13 }
                                        }

                                        Row {
                                            id: keys
                                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                            spacing: 3

                                            Repeater {
                                                model: root.capsOf(parent.parent.modelData.keys)

                                                // A held key is outlined and lettered in the accent:
                                                // set apart from the keys left to press, and from
                                                // the grey of a row out of reach.
                                                Rectangle {
                                                    required property string modelData
                                                    readonly property bool held: root.heldCaps.includes(modelData)
                                                    width: cap.implicitWidth + 12
                                                    height: 20
                                                    radius: 5
                                                    color: held ? "transparent" : Theme.alpha(Theme.accent, 0.08)
                                                    border { width: 1; color: held ? Theme.accent : Theme.border }

                                                    Text {
                                                        id: cap
                                                        anchors.centerIn: parent
                                                        text: parent.modelData
                                                        color: parent.held ? Theme.accent : Theme.text
                                                        font { family: Theme.font; pixelSize: 11 }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
