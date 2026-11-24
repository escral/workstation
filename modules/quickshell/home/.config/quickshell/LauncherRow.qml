import QtQuick

// One launcher result, or a heading between groups of them.
Item {
    id: row

    required property var modelData
    required property int index
    property int pad: 8
    property int rowHeight: 52
    property int headingHeight: 28
    signal hovered
    signal activated(bool fresh)

    readonly property var item: modelData
    readonly property bool isHeading: !!item.heading
    readonly property bool current: ListView.isCurrentItem

    width: ListView.view.width
    height: isHeading ? headingHeight : item.big ? 66 : rowHeight

    Text {
        visible: row.isHeading
        anchors { left: parent.left; leftMargin: 24; bottom: parent.bottom; bottomMargin: 6 }
        text: row.item.heading ?? ""
        color: Theme.muted
        font { family: Theme.font; pixelSize: 11; letterSpacing: 0.5 }
    }

    Item {
        visible: !row.isHeading
        anchors { fill: parent; leftMargin: row.pad + 12; rightMargin: row.pad + 14 }

        AppGlyph {
            id: glyph
            anchors.verticalCenter: parent.verticalCenter
            size: 36
            appId: row.item.appId ?? ""
            appClass: row.item.appClass ?? ""
            categories: row.item.categories ?? []
            glyph: row.item.glyph ?? ""
        }

        Column {
            anchors {
                left: glyph.right; leftMargin: 14
                right: action.left; rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            spacing: 3

            Text {
                width: parent.width
                text: row.item.name ?? ""
                color: Theme.text
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: row.item.big ? 26 : 14 }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: row.item.sub ?? ""
                color: Theme.muted
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: 11 }
            }
        }

        // Marks a running app; on the selected row the action says so instead.
        Rectangle {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: !!row.item.running && !row.current
            width: 6
            height: 6
            radius: 3
            color: Theme.accent
        }

        Label {
            id: action
            anchors.right: parent.right
            visible: row.current
            text: row.item.enter ?? ""
            color: Theme.accent
            font.pointSize: 8.25
        }
    }

    // Selects on motion only: a pointer that happens to rest where the panel
    // opens shouldn't move the selection.
    MouseArea {
        anchors.fill: parent
        enabled: !row.isHeading
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: row.hovered()
        onClicked: mouse => row.activated(mouse.modifiers & Qt.ShiftModifier)
    }
}
