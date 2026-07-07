pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Matte-skin reference conversion: the clock renders as a Bubble when its
// background is enabled, and stays a bare pill otherwise. This is the canonical
// pattern for restyling a `StyledRect { color: ...surfaceContainer }` surface —
// see theme/skin/SKIN-README.md "Rollout".
Bubble {
    id: root

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property var font: Tokens.font.body.builders.small.scale(1.1)

    implicitHeight: Tokens.sizes.bar.innerWidth
    implicitWidth: layout.implicitWidth + root.padding * 2

    // gated on the existing config toggle so behaviour is unchanged when off
    topColor: Config.bar.clock.background ? Colours.bubbleTop : "transparent"
    bottomColor: Config.bar.clock.background ? Colours.bubbleBottom : "transparent"
    level: Config.bar.clock.background ? 2 : 0
    matte: Config.bar.clock.background ? 1 : 0
    radius: Tokens.rounding.full

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        Loader {
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            visible: Config.bar.clock.showDate

            text: Time.format("ddd d")
            font: Tokens.font.body.small
            color: root.colour
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            visible: Config.bar.clock.showDate
            implicitWidth: 1
            implicitHeight: time.implicitHeight
            color: Colours.palette.m3outlineVariant
        }

        StyledText {
            id: time

            Layout.alignment: Qt.AlignVCenter
            text: `${Time.hourStr}:${Time.minuteStr}`
            font: root.font.build()
            color: root.colour
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            visible: GlobalConfig.services.useTwelveHourClock
            text: Time.amPmStr.toLowerCase()
            font: Tokens.font.body.builders.small.scale(0.9).build()
            color: root.colour
        }
    }
}
