import QtQuick

// Centers on the glyphs, not the line box: Nerd Fonts reserve extra ascent
// for icons, so plain verticalCenter puts digits and letters visibly high.
Text {
    id: label

    anchors.baseline: parent ? parent.verticalCenter : undefined
    anchors.baselineOffset: glyphs.tightBoundingRect.height / 2

    color: Theme.text
    font { family: Theme.font; pointSize: Theme.fontSize }

    TextMetrics {
        id: glyphs
        font: label.font
        text: "0H"
    }
}
