import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Matte-skin: power/session button in its own dedicated bubble.
Bubble {
    id: root

    required property DrawerVisibilities visibilities

    readonly property int diameter: icon.implicitHeight + Tokens.padding.small * 2

    implicitWidth: diameter
    implicitHeight: diameter
    radius: Tokens.rounding.full
    level: 2
    // same raised-pill tones as the other bar bubbles
    topColor: Colours.bubbleTop
    bottomColor: Colours.bubbleBottom

    StateLayer {
        anchors.fill: parent
        radius: Tokens.rounding.full
        onClicked: root.visibilities.session = !root.visibilities.session
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "power_settings_new"
        color: Colours.palette.m3error
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
    }
}
