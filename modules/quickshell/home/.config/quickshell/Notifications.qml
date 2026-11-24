import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick

// Popups stack up from the bottom-right corner, just above the bar, on the
// focused monitor. Nothing is kept once a popup is gone: no history yet.
Scope {
    NotificationServer {
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        onNotification: n => {
            n.tracked = true;
            Attention.notified(n);
            cardComponent.createObject(stack, { n: n, width: Qt.binding(() => stack.width) });
            // A burst would grow the stack off the screen; the oldest card
            // makes room. There is no history, so it is gone for good.
            const shown = stack.children.filter(c => !c.leaving);
            if (shown.length > 5) {
                const oldest = shown[0];
                oldest.leave(() => oldest.n.expire());
            }
        }
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "ws-notifications"
        exclusionMode: ExclusionMode.Ignore
        anchors { bottom: true; right: true }
        // Windows end Theme.gap from the screen's right edge and Theme.gap
        // above the bar; cards keep the same distance inside both edges, so
        // they never sit on a window border.
        readonly property int inset: Theme.gap * 2
        margins { bottom: Theme.barHeight + Theme.gap * 2 + inset; right: Theme.gap + inset }
        implicitWidth: 360
        implicitHeight: 720
        color: "transparent"
        // Stays mapped even when empty, so the last card's exit animation
        // isn't cut off; only the cards take clicks, the rest passes them on.
        mask: Region { item: stack }

        // Cards are created one per notification rather than from the
        // server's model: the model resets on every close, which would
        // rebuild, and re-animate, every card still on screen.
        Column {
            id: stack
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        }
    }

    Component {
        id: cardComponent
        NotificationCard {}
    }
}
