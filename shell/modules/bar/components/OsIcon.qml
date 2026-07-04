import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Matte-skin: the caelestia gargantua logo in its own dedicated bubble,
// opening the launcher. Always uses the caelestia logo (not the distro icon).
Bubble {
    id: root

    // match the width of the other bar pills (workspaces/status/clock)
    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: Tokens.sizes.bar.innerWidth
    radius: Tokens.rounding.full
    level: 2
    // same raised-pill tones as the other bar bubbles
    topColor: Colours.bubbleTop
    bottomColor: Colours.bubbleBottom

    Logo {
        anchors.centerIn: parent
        implicitWidth: Math.round(root.implicitWidth * 0.82)
        implicitHeight: Math.round(root.implicitWidth * 0.82)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const visibilities = Visibilities.getForActive();
            visibilities.launcher = !visibilities.launcher;
        }
    }
}
