import QtQuick
import qs.services

// Canonical matte-bubble lighting recipe — the ONE place the skin's
// shine/shade geometry is defined, shared by Bubble, the bar workspace
// pill, slider fills, etc., so every surface shades identically.
//
// Ratio: the shine (lit tone) owns most of the body; the shade is
// compressed into the bottom edge only. Stops are proportional (0–1),
// so the recipe scales with any element height, including animated /
// dynamically resizing ones (workspace pill, slider fill).
Gradient {
    id: root

    // the lit body tone and the bottom-edge shade tone
    property color topColor
    property color bottomColor
    // lighting strength (0 = flat); scales the extra top glint
    property real matte: 1

    // extra glint above the lit tone, confined to the very top
    readonly property color hi: topColor.a > 0 ? Colours.mixColour(topColor, "#ffffff", 0.08 * matte) : "transparent"
    // body stays shine-dominant almost all the way down
    readonly property color mid: topColor.a > 0 && bottomColor.a > 0 ? Colours.mixColour(topColor, bottomColor, 0.15) : topColor

    GradientStop {
        position: 0
        color: root.hi
    }
    GradientStop {
        position: 0.12
        color: root.topColor
    }
    GradientStop {
        position: 0.8
        color: root.mid
    }
    GradientStop {
        position: 1
        color: root.bottomColor
    }
}
