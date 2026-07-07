pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts
    required property Item dashboard
    required property bool fullscreen

    readonly property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)

    readonly property int clampedHeight: Math.max(Config.border.minThickness, implicitHeight)
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    // matte skin: taller reserved zone = slightly taller island + room for the
    // top / bottom wallpaper gaps of the floating island
    readonly property int contentHeight: Tokens.sizes.bar.innerWidth + padding * 2 + 18
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || visibilities.bar) ? contentHeight : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || visibilities.bar || isHovered)
    property bool isHovered

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function checkPopout(x: real): void {
        (content.item as Bar)?.checkPopout(x);
    }

    function handleWheel(x: real, angleDelta: point): void {
        (content.item as Bar)?.handleWheel(x, angleDelta);
    }

    clip: true
    visible: height > Config.border.thickness
    implicitHeight: fullscreen ? 0 : Config.border.thickness

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitHeight: root.contentHeight
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitHeight"
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                type: Anim.Emphasized
            }
        }
    ]

    // matte skin: floating island background — a detached rounded matte strip
    // offset from the screen edge (the connecting frame is removed)
    Bubble {
        id: island

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 6
        height: root.contentHeight - 14 // 8px wallpaper gap on top, 6px on bottom

        // one step darker than the pills (Colours.bubble*) so they read raised
        color: Colours.barIsland
        radius: Tokens.rounding.large
        level: 2
        matte: 0 // flat container surface — the pills on it keep the shading
        visible: root.shouldBeVisible
    }

    Loader {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        active: root.shouldBeVisible

        sourceComponent: Bar {
            height: root.contentHeight
            screen: root.screen
            visibilities: root.visibilities
            popouts: root.popouts // qmllint disable incompatible-type
            dashboard: root.dashboard
            fullscreen: root.fullscreen
        }
    }
}
