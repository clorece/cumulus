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
    required property bool fullscreen

    readonly property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)

    readonly property int clampedWidth: Math.max(Config.border.minThickness, implicitWidth)
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    // matte skin: wider reserved zone = slightly wider island + room for the
    // 8px left / 6px right wallpaper gaps of the floating island
    readonly property int contentWidth: Tokens.sizes.bar.innerWidth + padding * 2 + 18
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || visibilities.bar) ? contentWidth : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || visibilities.bar || isHovered)
    property bool isHovered

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function checkPopout(y: real): void {
        (content.item as Bar)?.checkPopout(y);
    }

    function handleWheel(y: real, angleDelta: point): void {
        (content.item as Bar)?.handleWheel(y, angleDelta);
    }

    clip: true
    visible: width > Config.border.thickness
    implicitWidth: fullscreen ? 0 : Config.border.thickness

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitWidth: root.contentWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                type: Anim.Emphasized
            }
        }
    ]

    // matte skin: floating island background — a detached rounded matte strip
    // offset from the screen edge (the connecting frame is removed)
    Bubble {
        id: island

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.rightMargin: 6
        width: root.contentWidth - 14 // 8px wallpaper gap on the left, 6px on the right

        // one step darker than the pills (Colours.bubble*) so they read raised
        color: Colours.barIsland
        radius: Tokens.rounding.large
        level: 2
        matte: 0 // flat container surface — the pills on it keep the shading
        visible: root.shouldBeVisible
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        active: root.shouldBeVisible

        sourceComponent: Bar {
            width: root.contentWidth
            screen: root.screen
            visibilities: root.visibilities
            popouts: root.popouts // qmllint disable incompatible-type
            fullscreen: root.fullscreen
        }
    }
}
