import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Matte-skin: the dashboard "handle" in the bar. The dashboard drops from the
// top on hover, and its trigger zone is the dashboard's own width — so this is
// a full-length pill matching that zone (not a plain circle), which also toggles
// the dashboard on click.
Bubble {
    id: root

    required property DrawerVisibilities visibilities
    required property Item dashboard

    readonly property int pillHeight: icon.implicitHeight + Tokens.padding.small * 2

    implicitHeight: pillHeight
    // a shortened handle proportional to the dashboard's hover area
    implicitWidth: Math.max(pillHeight, (dashboard?.width ?? 400) * 0.45)

    radius: Tokens.rounding.full
    level: 2
    // same raised-pill tones as the other bar bubbles
    topColor: Colours.bubbleTop
    bottomColor: Colours.bubbleBottom

    Behavior on implicitWidth {
        Anim {}
    }

    StateLayer {
        anchors.fill: parent
        radius: Tokens.rounding.full
        onClicked: root.visibilities.dashboard = !root.visibilities.dashboard
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "dashboard"
        color: Colours.palette.m3primary
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
    }
}
