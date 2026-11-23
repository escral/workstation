pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Machine load for the bar. Reading /proc is cheap enough to do all the time;
// finding the culprit spawns processes, so that runs only while it is shown.
// Levels: 0 fine, 1 heavy, 2 critical.
Singleton {
    id: root

    // Percent busy over the last ~10 s, so opening an app doesn't flash it.
    property real cpu: 0
    property int cpuLevel: 0
    property string cpuHog: ""

    property real memUsed: 0
    readonly property int memLevel: memUsed >= 95 ? 2 : memUsed >= 90 ? 1 : 0
    property string memHog: ""

    // The fuller of / and /home. A percentage alone would warn about 200 GB
    // free on a 2 TB disk, so the absolute amount has to be low too.
    property real diskFree: Infinity
    property real diskFreePct: 100
    readonly property int diskLevel: diskFreePct < 5 || diskFree < 5e9 ? 2
        : diskFreePct < 10 && diskFree < 30e9 ? 1 : 0

    property var cpuLast: null
    property var cpuSamples: []

    // A level drops only 10 points below its threshold, so a load hovering
    // right at 50% doesn't blink.
    function cpuLevelFor(value, previous) {
        const up = value >= 80 ? 2 : value >= 50 ? 1 : 0;
        const down = value >= 70 ? 2 : value >= 40 ? 1 : 0;
        return Math.max(up, Math.min(previous, down));
    }

    function poll() {
        stat.reload();
        const fields = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = fields[3] + fields[4];
        const total = fields.reduce((a, b) => a + b, 0);
        if (cpuLast && total > cpuLast.total) {
            cpuSamples.push(100 * (1 - (idle - cpuLast.idle) / (total - cpuLast.total)));
            if (cpuSamples.length > 5)
                cpuSamples.shift();
            cpu = cpuSamples.reduce((a, b) => a + b, 0) / cpuSamples.length;
            cpuLevel = cpuLevelFor(cpu, cpuLevel);
        }
        cpuLast = { idle: idle, total: total };

        meminfo.reload();
        const mem = meminfo.text();
        const field = name => Number(mem.match(new RegExp(name + ":\\s+(\\d+)"))[1]);
        memUsed = 100 * (1 - field("MemAvailable") / field("MemTotal"));

        if (cpuLevel > 0)
            cpuTop.running = true;
        if (memLevel > 0)
            memTop.running = true;
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: disk.running = true
    }

    FileView { id: stat; path: "/proc/stat"; blockLoading: true }
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true }

    // ps reports CPU averaged over a process's whole life; top's second
    // frame is the last second only.
    Process {
        id: cpuTop
        command: ["sh", "-c", "top -b -n 2 -d 1 -o %CPU -w 512 | awk '/^ *PID/ { frame++; next } frame == 2 && NF && $12 != \"top\" { $1 = $2 = $3 = $4 = $5 = $6 = $7 = $8 = $9 = $10 = $11 = \"\"; sub(/^ +/, \"\"); print; exit }'"]
        stdout: StdioCollector { onStreamFinished: root.cpuHog = text.trim() }
    }

    // Summed per name: a browser is dozens of processes, none big alone.
    Process {
        id: memTop
        command: ["sh", "-c", "ps -eo rss=,comm= | awk '{ rss = $1; $1 = \"\"; sum[substr($0, 2)] += rss } END { for (c in sum) print sum[c], c }' | sort -rn | head -1 | cut -d' ' -f2-"]
        stdout: StdioCollector { onStreamFinished: root.memHog = text.trim() }
    }

    Process {
        id: disk
        command: ["sh", "-c", "df -B1 --output=avail,size / /home 2>/dev/null | tail -n +2"]
        stdout: StdioCollector {
            onStreamFinished: {
                const worst = text.trim().split("\n")
                    .map(line => line.trim().split(/\s+/).map(Number))
                    .reduce((a, b) => b[0] / b[1] < a[0] / a[1] ? b : a);
                root.diskFree = worst[0];
                root.diskFreePct = 100 * worst[0] / worst[1];
            }
        }
    }
}
