import Quickshell
import Quickshell.Services.Greetd
import QtQuick

// The login screen: greetd runs it in cage, next to a copy of the user's
// Quickshell config, so it looks like the lock screen. One user per machine,
// so there is only a password to ask for.
ShellRoot {
    id: root

    readonly property string user: Quickshell.env("WS_USER")
    property string password: ""
    property bool failed: false
    property bool busy: false
    property bool leaving: false
    readonly property string hint: ""

    function submit() {
        if (password === "" || busy || leaving)
            return;
        failed = false;
        busy = true;
        Greetd.createSession(user);
    }

    function fail() {
        Greetd.cancelSession();
        busy = false;
        password = "";
        failed = true;
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired)
                Greetd.respond(root.password);
        }
        function onAuthFailure(message) { root.fail() }
        function onError(error) { root.fail() }
        function onReadyToLaunch() {
            root.leaving = true;
            launchDelay.start();
        }
    }

    // Lets the fade-out finish before the session takes the screen.
    Timer {
        id: launchDelay
        interval: 300
        onTriggered: Greetd.launch(["uwsm", "start", "hyprland.desktop"])
    }

    FloatingWindow {
        color: Theme.bgDark

        LockScreen {
            id: screen
            anchors.fill: parent
            auth: root
        }

        // logind lets the session on the seat power off without a password,
        // so the machine can be turned off from here.
        Row {
            anchors { right: parent.right; bottom: parent.bottom; margins: 28 }
            spacing: 22
            opacity: screen.opacity

            Repeater {
                model: [
                    { icon: "\u{F0709}", command: ["systemctl", "reboot"] },
                    { icon: "\u{F0425}", command: ["systemctl", "poweroff"] },
                ]

                Text {
                    id: button
                    required property var modelData
                    text: modelData.icon
                    color: hover.hovered ? Theme.text : Theme.muted
                    font { family: Theme.font; pointSize: Theme.fontSize + 6 }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Quickshell.execDetached(button.modelData.command) }
                }
            }
        }
    }
}
