pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components.effects
import qs.services

// Matte "bubble" surface — the signature element of the redesign skin.
// A rounded surface lit from the top, via a single top→bottom gradient
// (lighter → base → darker) plus an optional outer drop shadow. Mirrors the
// design's --card-grad + --matte recipe.
//
// Drop-in for a `StyledRect { color: … }`: just change the type to `Bubble`.
// The matte gradient is derived from whatever `color` the card already sets
// (its `base`); override `topColor`/`bottomColor` for a bespoke gradient
// (e.g. accent "--hi" bubbles or gated bar pills).
StyledRect {
    id: root

    // outer drop-shadow depth (Elevation level); 0 = no shadow (e.g. bar pills)
    property int level: 2
    // inner lighting/shading strength (0 = flat)
    property real matte: 1
    // when true, a missing/transparent colour falls back to the container colour;
    // set false for buttons so genuinely transparent (e.g. text) buttons stay clear
    property bool autoFill: true

    // base surface colour: reuse the card's own `color` if it set one, else the
    // standard container colour (autoFill) or transparent. Forced opaque so filled
    // cards read as solid matte.
    property color base: color.a > 0 ? Qt.rgba(color.r, color.g, color.b, 1) : (autoFill ? Colours.palette.m3surfaceContainer : "transparent")
    // top-lit → bottom-shaded gradient endpoints (transparent base ⇒ no fill).
    // The shine tone owns most of the body; the shade only kisses the bottom
    // edge (see BubbleGradient), so it stays subtle.
    property color topColor: base.a > 0 ? Colours.mixColour(base, "#ffffff", 0.12 * matte) : "transparent"
    property color bottomColor: base.a > 0 ? Colours.mixColour(base, "#000000", 0.16 * matte) : "transparent"

    radius: Tokens.rounding.large
    antialiasing: true

    // shared skin-wide lighting recipe — keeps every surface's shine/shade
    // ratio identical and proportional to its (possibly animated) height
    gradient: BubbleGradient {
        topColor: root.topColor
        bottomColor: root.bottomColor
        matte: root.matte
    }

    // outer matte drop shadow ("ambient occlusion"), skipped at level 0.
    // A clipping bubble would strangle its own shadow (RectangularShadow
    // paints outside the bounds), so the shadow escapes to the bubble's
    // parent in that case. Only drawn when the bubble actually paints a
    // fill — transparent pills/text buttons cast nothing.
    Elevation {
        parent: root.clip ? root.parent : root
        anchors.fill: root
        visible: root.level > 0 && root.topColor.a > 0
        radius: root.radius
        level: root.level
        opacity: root.opacity
        z: -1
    }
}
