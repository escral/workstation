import QtQuick

// An app's mark in our own style rather than its icon: one Nerd Font glyph on
// a plate. Glyphs.qml picks the glyph and whether it is coloured.
Rectangle {
    id: plate

    // Any of these may be empty; the first that matches wins.
    property string appId: ""
    property string appClass: ""
    property var categories: []
    // Set to skip the lookup, e.g. for system commands.
    property string glyph: ""
    property int size: 30

    readonly property var mark: glyph !== "" ? { glyph: glyph, hue: "" } : Glyphs.lookup(appId, appClass, categories)
    // False when nothing matched and the mark is the generic app glyph.
    readonly property bool known: mark.glyph !== Glyphs.generic
    readonly property bool colored: mark.hue !== ""
    readonly property color hue: colored ? mark.hue : Theme.subtext

    width: size
    height: size
    radius: Math.round(size * 0.28)
    color: Theme.alpha(hue, colored ? 0.22 : 0.1)
    border { width: colored ? 1 : 0; color: Theme.alpha(hue, 0.35) }

    // Glyphs from different Nerd Font sets differ in size and sit off their
    // line box, so each is measured and its own outline fitted to the middle.
    TextMetrics {
        id: outline
        font { family: Theme.font; pixelSize: 100 }
        text: plate.mark.glyph
    }

    Text {
        readonly property rect box: outline.tightBoundingRect
        // Sized by area, not the longer side, so a thin sparkle and a solid
        // block look equally big; capped so long glyphs keep a margin. Font
        // sizes are whole pixels; the offsets use the size actually drawn.
        readonly property real k: Math.round(100 * plate.size * Math.min(
            0.48 / Math.sqrt(Math.max(box.width * box.height, 1)),
            0.64 / Math.max(box.width, box.height, 1))) / 100

        anchors { left: parent.left; baseline: parent.top }
        anchors.leftMargin: (plate.width - box.width * k) / 2 - box.x * k
        anchors.baselineOffset: plate.height / 2 - (box.y + box.height / 2) * k
        text: plate.mark.glyph
        color: plate.hue
        font { family: Theme.font; pixelSize: Math.round(100 * k) }
    }
}
