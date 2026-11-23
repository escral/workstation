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

    property string password: ""
    property bool failed: false
    property bool unlocking: false
    property bool capsLock: false
    property string keymap: ""
    readonly property string hint: [
        capsLock ? "Caps Lock is on" : "",
        keymap !== "" && !keymap.startsWith("English") ? keymap : "",
    ].filter(s => s !== "").join("  ·  ")

    function lock() {
        password = "";
        failed = false;
        unlocking = false;
        session.locked = true;
    }

    function submit() {
        if (password === "" || pam.active || unlocking)
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
                root.unlocking = true;
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

            Item {
                id: content
                anchors.fill: parent
                opacity: 0
                Component.onCompleted: opacity = 1
                states: State {
                    when: root.unlocking
                    PropertyChanges { content.opacity: 0 }
                }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                Sky { anchors.fill: parent }
                Rectangle {
                    anchors.fill: parent
                    color: Theme.bgDark
                    opacity: 0.4
                }

                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -40
                    spacing: 6

                    SystemClock {
                        id: clock
                        precision: SystemClock.Minutes
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Theme.text
                        font { family: Theme.font; pointSize: 64; weight: Font.Light }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                        color: Theme.subtext
                        font { family: Theme.font; pointSize: Theme.fontSize + 2 }
                    }
                }

                Rectangle {
                    id: field
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.verticalCenter
                    anchors.topMargin: 80
                    width: 260
                    height: 40
                    radius: height / 2
                    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.8)
                    border { width: 1; color: root.failed ? Theme.red : Theme.highlight }
                    // Hidden until typing starts, so the idle screen is just the clock.
                    opacity: root.password !== "" || pam.active || root.failed ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    // Centers the dots themselves: the font's line box carries
                    // extra ascent for Nerd Font icons, which lifts plain
                    // vertical centering.
                    TextMetrics {
                        id: dot
                        font: input.font
                        text: input.passwordCharacter
                    }

                    TextInput {
                        id: input
                        anchors { left: parent.left; right: parent.right; margins: 12 }
                        anchors.baseline: parent.verticalCenter
                        anchors.baselineOffset: -(dot.tightBoundingRect.y + dot.tightBoundingRect.height / 2)
                        focus: true
                        horizontalAlignment: TextInput.AlignHCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: Theme.text
                        font { family: Theme.font; pointSize: Theme.fontSize + 2 }
                        enabled: !pam.active && !root.unlocking

                        // Every screen has its own field; they share one password.
                        text: root.password
                        onTextChanged: {
                            root.password = text;
                            if (text !== "")
                                root.failed = false;
                        }
                        onAccepted: root.submit()
                        Keys.onEscapePressed: root.password = ""
                    }

                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -10; duration: 50 }
                        NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 8; duration: 70 }
                        NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -4; duration: 70 }
                        NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
                    }

                    Connections {
                        target: root
                        function onFailedChanged() { if (root.failed) shake.start() }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: field.bottom
                    anchors.topMargin: 14
                    text: root.hint
                    color: Theme.orange
                    font { family: Theme.font; pointSize: Theme.fontSize }
                    opacity: root.hint !== "" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }
}
