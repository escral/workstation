import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// What the launcher shows for a query: apps, projects, open windows, a
// calculator, actions and the web, ranked by how well they match plus what each
// query ended up opening before, so the same letters go straight there.
Scope {
    id: root

    property string query: ""
    property int scope: 0
    // Window lookups only matter while the launcher is open.
    property bool active: false

    readonly property var scopes: ["All", "Apps", "Projects", "Windows", "Actions", "Web"]

    FileView {
        id: store
        path: Quickshell.statePath("launcher.json")
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        JsonAdapter {
            id: memory
            // item key → { n: times opened, t: last time, ms }
            property var counts: ({})
            // query → { item key → times it was chosen for that query }
            property var picks: ({})
        }
    }

    function remember(key, q) {
        const counts = Object.assign({}, memory.counts);
        counts[key] = { n: (counts[key]?.n ?? 0) + 1, t: Date.now() };
        memory.counts = counts;
        if (q !== "") {
            const picks = Object.assign({}, memory.picks);
            picks[q] = Object.assign({}, picks[q]);
            picks[q][key] = (picks[q][key] ?? 0) + 1;
            memory.picks = picks;
        }
        store.writeAdapter();
    }

    // Recent use counts more; a launch ten days ago is worth half.
    function frecency(key) {
        const c = memory.counts[key];
        return c ? c.n * Math.pow(0.5, (Date.now() - c.t) / 864000000) : 0;
    }

    // What this query, or the shorter ones it grew from, ended up opening.
    function learned(key, q) {
        for (let i = q.length; i > 0; i--) {
            const n = memory.picks[q.slice(0, i)]?.[key];
            if (n)
                return Math.min(n, 5) * (i === q.length ? 12 : 6);
        }
        return 0;
    }

    // Text typed with the Russian layout still active, read as English keys.
    readonly property string ru: "йцукенгшщзхъфывапролджэячсмитьбю.ё"
    readonly property string en: "qwertyuiop[]asdfghjkl;'zxcvbnm,./`"
    function relayout(q) {
        return [...q].map(ch => { const i = ru.indexOf(ch); return i < 0 ? ch : en[i] }).join("");
    }

    // Prefix beats a word start beats a substring beats letters in order;
    // in-order letters must be mostly runs or word initials, so "vsc" finds
    // "Visual Studio Code" but scattered letters don't match everything.
    function fuzzy(q, s) {
        s = (s ?? "").toLowerCase();
        if (s === "" || q === "")
            return -1;
        if (s.startsWith(q))
            return 100;
        const at = s.indexOf(q);
        if (at >= 0)
            return /[\s\-_.]/.test(s[at - 1]) ? 85 : 60;
        let i = 0, score = 0, prev = -2;
        for (let j = 0; j < s.length && i < q.length; j++) {
            if (s[j] !== q[i])
                continue;
            score += j === prev + 1 ? 3 : j === 0 || /[\s\-_.]/.test(s[j - 1]) ? 2 : 0;
            prev = j;
            i++;
        }
        return i === q.length && score >= 3 * (q.length - 1) ? 20 + score : -1;
    }

    // The best of the item's texts, the first weighing most, for the query as
    // typed or as it was meant on the other layout.
    function match(q, texts) {
        let best = -1;
        for (const v of [q, relayout(q)])
            texts.forEach((t, k) => best = Math.max(best, fuzzy(v, t) - (k === 0 ? 0 : 10 + k)));
        return best;
    }

    // An app's open window it was last on, if any. Wayland apps report the
    // desktop id or StartupWMClass as their class; a few only the binary.
    function windowOf(entry) {
        const names = [entry.startupClass, entry.id, entry.command[0]?.split("/").pop()]
            .filter(n => n)
            .map(n => n.toLowerCase());
        return Hyprland.toplevels.values
            .filter(t => names.includes((t.lastIpcObject?.class ?? "").toLowerCase()))
            .sort((a, b) => a.lastIpcObject.focusHistoryID - b.lastIpcObject.focusHistoryID)[0] ?? null;
    }

    function focusWindow(t) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${t.address}" })`);
    }

    function apps(q) {
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .map(e => {
                const w = root.active ? windowOf(e) : null;
                return {
                    key: "app:" + e.id,
                    score: q === "" ? 0 : match(q, [e.name, e.genericName, ...e.keywords, e.id]),
                    name: e.name,
                    sub: w ? "Running · " + (w.workspace?.name ?? "") : (e.genericName || e.comment),
                    appId: e.id, appClass: e.startupClass, categories: e.categories,
                    running: w !== null,
                    enter: w ? "switch" : "open",
                    shift: "new window",
                    run: fresh => w && !fresh ? focusWindow(w) : Quickshell.execDetached(["uwsm", "app", "--", e.id + ".desktop"]),
                };
            });
    }

    function windows(q) {
        return Hyprland.toplevels.values
            .filter(t => t.lastIpcObject?.class)
            .map(t => {
                const o = t.lastIpcObject;
                return {
                    key: "window:" + o.class,
                    score: q === "" ? 0 : match(q, [o.title, o.class]),
                    name: o.title || o.class,
                    sub: o.class + " · " + (t.workspace?.name ?? ""),
                    appClass: o.class,
                    enter: "switch",
                    run: () => focusWindow(t),
                };
            });
    }

    readonly property string home: Quickshell.env("HOME")

    // Projects are the fzf-marks bookmarks ("label : path" lines), the same
    // list `mark` and `ff` keep in the shell.
    property var marks: []

    FileView {
        path: Quickshell.env("FZF_MARKS_FILE") || root.home + "/.fzf-marks"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.marks = text().split("\n")
            .map(line => line.split(" : "))
            .filter(parts => parts.length === 2 && parts[1].trim() !== "")
            .map(([label, path]) => [label.trim(), path.trim()])
        onLoadFailed: root.marks = []
    }

    function projects(q) {
        return marks.map(([label, path]) => ({
            key: "project:" + path,
            score: q === "" ? 0 : match(q, [label, path.split("/").pop(), path]),
            name: label,
            sub: path.startsWith(home + "/") ? "~" + path.slice(home.length) : path,
            glyph: "\u{F024B}",
            enter: "open in IDE",
            shift: "terminal here",
            run: fresh => Quickshell.execDetached([home + "/.local/bin/" + (fresh ? "ghostty-here" : "ide"), path]),
        }));
    }

    readonly property var catalog: Catalog.entries.filter(e => e.launcher && e.runs)

    function actions(q) {
        return catalog.map(e => ({
            key: "action:" + e.title,
            score: q === "" ? 0 : match(q, [e.title, e.group, ...e.words]),
            name: e.title,
            sub: [e.group, e.keys.join(" or ")].filter(s => s).join("  ·  "),
            glyph: e.glyph || "\u{F0E7}",
            enter: "run",
            run: () => Catalog.run(e.title),
        }));
    }

    function web(q) {
        if (q === "")
            return [];
        const raw = root.query.trim();
        const items = [];
        if (/^(https?:\/\/)?[\w-]+(\.[\w-]+)+(:\d+)?(\/\S*)?$/.test(raw)) {
            const url = /^https?:\/\//.test(raw) ? raw : "https://" + raw;
            items.push({ key: "web:url", score: 90, name: raw, sub: "Open in the browser", glyph: "\u{F01E7}",
                enter: "open", run: () => Quickshell.execDetached(["xdg-open", url]) });
        }
        items.push({ key: "web:search", score: 1, name: `Search “${raw}”`, sub: "Google", glyph: "\u{F070F}",
            enter: "search", run: () => Quickshell.execDetached(["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(raw)]) });
        return items;
    }

    // qalc answers in a few ms; the row shows only once it has.
    property string answer: ""
    readonly property bool mathy: /\d/.test(query) && /^[\d\s.,+\-*/^%()a-z]+$/i.test(query.trim()) && /[+\-*/^%]|\b(to|in)\b|\(/.test(query)
    onQueryChanged: {
        answer = "";
        if (mathy) {
            calc.running = false;
            calc.command = ["qalc", "-t", query.trim()];
            calc.running = true;
        }
    }

    Process {
        id: calc
        stdout: StdioCollector {
            onStreamFinished: {
                const a = text.trim();
                if (root.mathy && a !== "" && !/error|warning/i.test(a))
                    root.answer = a;
            }
        }
    }

    function calculator() {
        if (answer === "")
            return [];
        return [{ key: "calc", score: 200, name: answer, sub: root.query.trim(), big: true,
            glyph: "\u{F00EC}", enter: "copy",
            run: () => Quickshell.execDetached(["wl-copy", answer]) }];
    }

    function rank(items, q, limit) {
        return items
            .filter(r => q === "" || r.score >= 0)
            .map(r => Object.assign(r, { rank: r.score + learned(r.key, q) + 12 * Math.log2(1 + frecency(r.key)) }))
            .sort((a, b) => b.rank - a.rank || a.name.localeCompare(b.name))
            .slice(0, limit);
    }

    // Rows with headings between groups. In All the empty query shows recent
    // apps; typing shows each kind's best few, the strongest group first.
    readonly property var rows: {
        const q = query.trim().toLowerCase();
        const kind = scopes[scope];
        if (kind !== "All") {
            const all = { Apps: apps, Projects: projects, Windows: windows, Actions: actions, Web: web }[kind](q);
            return rank(all, q, 50);
        }
        if (q === "")
            return [{ heading: "Recent" }, ...rank(apps(q), q, 8)];
        const shownApps = rank(apps(q), q, 5);
        // A running app's row already switches to it; its window would repeat it.
        const covered = shownApps.filter(a => a.running).map(a => [a.appId, a.appClass].map(n => (n ?? "").toLowerCase()));
        const otherWindows = windows(q).filter(w => !covered.some(names => names.includes(w.appClass.toLowerCase())));
        const groups = [
            ["Calculator", rank(calculator(), q, 1)],
            ["Apps", shownApps],
            ["Projects", rank(projects(q), q, 3)],
            ["Windows", rank(otherWindows, q, 3)],
            ["Actions", rank(actions(q), q, 3)],
        ].filter(([, items]) => items.length > 0)
            .sort((a, b) => b[1][0].rank - a[1][0].rank);
        const out = [];
        for (const [name, items] of groups)
            out.push({ heading: name }, ...items);
        const w = web(q);
        if (w.length)
            out.push({ heading: "Web" }, ...w);
        return out;
    }
}
