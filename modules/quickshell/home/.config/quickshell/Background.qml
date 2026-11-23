import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "ws-background"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.bgDark

    Sky { anchors.fill: parent }
}
