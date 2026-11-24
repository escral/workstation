pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The action catalog Hyprland writes on every config load (hypr/catalog.lua),
// read once for the launcher's Actions and the help overlay.
Singleton {
    id: root

    property var entries: []

    FileView {
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/ws/actions.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.entries = JSON.parse(text());
            } catch (e) {
                root.entries = [];
            }
        }
        onLoadFailed: root.entries = []
    }

    // Through Hyprland, which holds the entries' Lua functions and dispatchers.
    function run(title) {
        Quickshell.execDetached(["hyprctl", "dispatch", "ws_action(" + JSON.stringify(title) + ")"]);
    }
}
