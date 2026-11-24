pragma Singleton
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray
import QtQuick

// Apps waiting on you, in place of a tray: one entry per app, only while it
// has something. Signals, most reliable first: the unread count an app
// publishes for docks (Telegram), notifications that came while the app
// wasn't focused (Slack, Discord: their tray icons only redraw), windows
// asking for focus, and tray items that do set NeedsAttention.
Singleton {
    id: root

    // app key → { appId, names, ids: notification ids }. Ids, not a count:
    // apps replace a notification under the same id as messages pile up.
    property var unread: ({})

    property string focused: ""

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow")
                root.focused = event.data.split(",")[0].toLowerCase();
        }
    }

    onFocusedChanged: forget(u => u.names.includes(focused))

    // A loop, not Object.fromEntries: Qt's JS engine lacks it.
    function forget(test) {
        const u = {};
        let dropped = false;
        for (const key in unread) {
            if (test(unread[key], key))
                dropped = true;
            else
                u[key] = unread[key];
        }
        if (dropped)
            unread = u;
    }

    // What a window of the app may report as its class: the desktop id, its
    // StartupWMClass, or, for a few, only the binary.
    function namesOf(entry, ...more) {
        return [...new Set([entry?.id, entry?.startupClass, entry?.command?.[0]?.split("/").pop(), ...more]
            .filter(n => n)
            .map(n => n.toLowerCase()))];
    }

    // Unread counts apps publish for docks (Unity LauncherEntry over D-Bus).
    // Telegram does; Electron apps only under Unity. Such an app is trusted
    // over its notifications: read on the phone, and it clears here too.
    // app key → { appId, names, count }
    property var badges: ({})

    function badged(uri, count) {
        const id = uri.replace(/\.desktop$/, "");
        const entry = DesktopEntries.byId(id);
        const names = namesOf(entry, id);
        const b = Object.assign({}, badges);
        b[names[0]] = { appId: entry?.id ?? "", names: names, count: count };
        badges = b;
    }

    function hasBadge(names) {
        for (const key in badges)
            if (badges[key].names.some(n => names.includes(n)))
                return true;
        return false;
    }

    Process {
        running: true
        command: ["dbus-monitor", "--session", "type='signal',interface='com.canonical.Unity.LauncherEntry',member='Update'"]
        // One value per line: the app's uri, then key and variant lines in
        // turn. The array's closing "]" is the only line at that indent, so
        // it ends the signal; keys may come in any order.
        stdout: SplitParser {
            property string app: ""
            property string key: ""
            property real count: 0
            property bool shown: true

            onRead: line => {
                let m;
                if ((m = line.match(/string "application:\/\/(.+)"/))) {
                    app = m[1];
                    count = 0;
                    shown = true;
                } else if ((m = line.match(/^\s*string "(.+)"$/))) {
                    key = m[1];
                } else if ((m = line.match(/variant\s+\S+ (\S+)$/))) {
                    if (key === "count")
                        count = Number(m[1]);
                    else if (key === "count-visible")
                        shown = m[1] === "true";
                } else if (line === "   ]" && app !== "") {
                    root.badged(app, shown ? count : 0);
                    app = "";
                }
            }
        }
    }

    function notified(n) {
        if (n.urgency === NotificationUrgency.Low)
            return;
        const entry = DesktopEntries.byId(n.desktopEntry) ?? DesktopEntries.heuristicLookup(n.appName);
        const names = namesOf(entry, n.desktopEntry, n.appName);
        if (names.length === 0 || names.includes(focused) || hasBadge(names))
            return;
        const key = names[0];
        const u = Object.assign({}, unread);
        u[key] = {
            appId: entry?.id ?? "",
            names: names,
            ids: [...new Set([...(u[key]?.ids ?? []), n.id])],
        };
        unread = u;
    }

    function windowOf(names) {
        return Hyprland.toplevels.values.find(t => names.includes((t.wayland?.appId ?? "").toLowerCase())) ?? null;
    }

    function focus(t) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${t.address}" })`);
    }

    function appItem(key, app, count, dismiss) {
        return {
            key: key,
            appId: app.appId,
            appClass: key,
            count: count,
            workspace: windowOf(app.names)?.workspace?.id ?? 0,
            open: () => {
                const t = windowOf(app.names);
                if (t)
                    focus(t);
                else if (app.appId)
                    Quickshell.execDetached(["uwsm", "app", "--", app.appId + ".desktop"]);
            },
            dismiss: dismiss,
        };
    }

    readonly property var items: {
        const out = [];
        for (const key in badges)
            if (badges[key].count > 0)
                out.push(appItem(key, badges[key], badges[key].count, null));
        for (const key in unread)
            if (!hasBadge(unread[key].names))
                out.push(appItem(key, unread[key], unread[key].ids.length, () => forget((_, k) => k === key)));
        const all = Object.assign({}, unread, badges);
        const covered = name => out.some(i => all[i.key]?.names.includes(name));

        for (const t of Hyprland.toplevels.values) {
            const cls = (t.wayland?.appId ?? "").toLowerCase();
            if (t.urgent && cls && !covered(cls))
                out.push({ key: "window:" + cls, appClass: cls, count: 0, workspace: t.workspace?.id ?? 0, open: () => focus(t) });
        }

        for (const item of SystemTray.items.values) {
            const id = item.id.toLowerCase();
            if (item.status === Status.NeedsAttention && !covered(id))
                out.push({ key: "tray:" + id, appClass: id, count: 0, workspace: windowOf([id])?.workspace?.id ?? 0, open: () => item.activate() });
        }
        return out;
    }
}
