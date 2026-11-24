import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick

// Locks the screen only: nothing is suspended, so running jobs and agents
// carry on. `quickshell ipc call lock lock` locks; so does being idle.
Scope {
    id: root

    readonly property string user: Quickshell.env("USER")
    property string password: ""
    property bool failed: false
    readonly property bool busy: pam.active
    property bool leaving: false
    property bool capsLock: false
    property string keymap: ""
    readonly property string hint: [
        capsLock ? "Caps Lock is on" : "",
        keymap !== "" && !keymap.startsWith("English") ? keymap : "",
    ].filter(s => s !== "").join("  ·  ")

    function lock() {
        password = "";
        failed = false;
        leaving = false;
        session.locked = true;
    }

    function submit() {
        if (password === "" || busy || leaving)
            return;
        failed = false;
        pam.start();
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock() }
    }

    IdleMonitor {
        timeout: 10 * 60
        onIsIdleChanged: if (isIdle) root.lock()
    }

    IdleMonitor {
        timeout: 15 * 60
        onIsIdleChanged: Hyprland.dispatch(`hl.dsp.dpms({ action = "${isIdle ? "off" : "on"}" })`)
    }

    PamContext {
        id: pam
        onPamMessage: if (responseRequired) respond(root.password)
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.leaving = true;
                unlockDelay.start();
            } else {
                root.password = "";
                root.failed = true;
            }
        }
    }

    // Hyprland sends no event for Caps Lock, so poll the keyboard while locked.
    Timer {
        interval: 300
        running: session.locked
        repeat: true
        triggeredOnStart: true
        onTriggered: keyboard.running = true
    }

    Process {
        id: keyboard
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const main = JSON.parse(text).keyboards.find(k => k.main);
                root.capsLock = main?.capsLock ?? false;
                root.keymap = main?.active_keymap ?? "";
            }
        }
    }

    // Lets the fade-out finish before the lock, and its surfaces, go away.
    Timer {
        id: unlockDelay
        interval: 300
        onTriggered: session.locked = false
    }

    WlSessionLock {
        id: session

        WlSessionLockSurface {
            // Transparent so the fades show the desktop underneath; Hyprland
            // only draws it with misc.session_lock_xray.
            color: "transparent"

            LockScreen {
                anchors.fill: parent
                auth: root
            }
        }
    }
}
