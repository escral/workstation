import Quickshell
import QtQuick

// The clock and password field the lock screen and the login screen share.
// `auth` is whoever checks the password; it provides user, password, failed,
// busy, leaving, hint and submit().
Item {
    id: screen

    required property var auth

    opacity: 0
    Component.onCompleted: opacity = 1
    states: State {
        when: screen.auth.leaving
        PropertyChanges { screen.opacity: 0 }
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

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: field.top
        anchors.bottomMargin: 14
        text: "\u{F0004}  " + screen.auth.user
        color: Theme.muted
        font { family: Theme.font; pointSize: Theme.fontSize + 1 }
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
        border {
            width: 1
            color: screen.auth.failed ? Theme.red : screen.auth.busy ? Theme.accent : Theme.border
        }
        // Hidden until typing starts, so the idle screen is just the clock.
        opacity: screen.auth.password !== "" || screen.auth.busy || screen.auth.failed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        // Centers the dots themselves: the font's line box carries extra
        // ascent for Nerd Font icons, which lifts plain vertical centering.
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
            enabled: !screen.auth.busy && !screen.auth.leaving

            // Every screen has its own field; they share one password.
            text: screen.auth.password
            onTextChanged: {
                screen.auth.password = text;
                if (text !== "")
                    screen.auth.failed = false;
            }
            onAccepted: screen.auth.submit()
            Keys.onEscapePressed: screen.auth.password = ""
        }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -10; duration: 50 }
            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 8; duration: 70 }
            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -4; duration: 70 }
            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
        }

        Connections {
            target: screen.auth
            function onFailedChanged() { if (screen.auth.failed) shake.start() }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: field.bottom
        anchors.topMargin: 14
        text: screen.auth.hint
        color: Theme.orange
        font { family: Theme.font; pointSize: Theme.fontSize }
        opacity: text !== "" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
}
