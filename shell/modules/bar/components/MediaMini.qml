pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Matte-skin: compact now-playing widget for the bar — cover art, a marquee
// title (fixed width; scrolls after a delay instead of shrinking the text) and
// transport controls. Mirrors what the dashboard Media tab tracks (Players/Mpris).
Bubble {
    id: root

    required property DrawerVisibilities visibilities

    readonly property MprisPlayer player: Players.active
    // fixed title area ≈ 18-20 chars; past this the text marquees
    readonly property int titleWidth: 170

    visible: root.player
    implicitHeight: Tokens.sizes.bar.innerWidth
    implicitWidth: root.player ? layout.implicitWidth + Tokens.padding.medium * 2 : 0

    topColor: Colours.bubbleTop
    bottomColor: Colours.bubbleBottom
    level: 2
    radius: Tokens.rounding.full

    Behavior on implicitWidth {
        Anim {}
    }

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        // album / video cover
        StyledClippingRect {
            Layout.alignment: Qt.AlignVCenter

            implicitWidth: root.implicitHeight - Tokens.padding.small * 2
            implicitHeight: implicitWidth
            radius: Tokens.rounding.small
            color: Colours.palette.m3surfaceContainerHigh

            MaterialIcon {
                anchors.centerIn: parent
                text: "music_note"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
                visible: cover.status !== Image.Ready
            }

            Image {
                id: cover

                anchors.fill: parent
                source: Players.getArtUrl(root.player)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }
        }

        // marquee title
        Item {
            id: titleClip

            readonly property real overflow: Math.max(0, titleText.implicitWidth - width)

            Layout.alignment: Qt.AlignVCenter
            clip: true
            implicitWidth: Math.min(titleText.implicitWidth, root.titleWidth)
            implicitHeight: titleText.implicitHeight

            StyledText {
                id: titleText

                text: root.player?.trackTitle ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurface
            }

            // hold still when it fits
            Binding {
                target: titleText
                property: "x"
                value: 0
                when: titleClip.overflow <= 0
            }

            // roll across after a pause, then back — keeps the text at full size
            SequentialAnimation {
                running: titleClip.overflow > 0
                loops: Animation.Infinite

                PauseAnimation {
                    duration: 2000
                }
                NumberAnimation {
                    target: titleText
                    property: "x"
                    from: 0
                    to: -titleClip.overflow
                    duration: Math.max(1, titleClip.overflow) * 28
                    easing.type: Easing.InOutQuad
                }
                PauseAnimation {
                    duration: 1200
                }
                NumberAnimation {
                    target: titleText
                    property: "x"
                    from: -titleClip.overflow
                    to: 0
                    duration: Math.max(1, titleClip.overflow) * 28
                    easing.type: Easing.InOutQuad
                }
            }
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter
            type: IconButton.Text
            icon: "skip_previous"
            font: Tokens.font.icon.small
            onClicked: root.player?.previous()
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter
            type: IconButton.Text
            icon: root.player?.isPlaying ? "pause" : "play_arrow"
            font: Tokens.font.icon.small
            onClicked: root.player?.togglePlaying()
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter
            type: IconButton.Text
            icon: "skip_next"
            font: Tokens.font.icon.small
            disabled: !(root.player?.canGoNext ?? false)
            onClicked: root.player?.next()
        }
    }
}
