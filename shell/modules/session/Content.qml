pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.utils

// matte skin: the session panel is a floating matte island holding the buttons
Bubble {
    id: root

    required property DrawerVisibilities visibilities

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
    radius: Tokens.rounding.extraLarge
    level: 3
    matte: 0 // flat container surface — elements on it keep the shading

    Column {
        id: col

        anchors.centerIn: parent
        padding: Tokens.padding.large
        spacing: Tokens.spacing.large

        SessionButton {
            id: logout

            icon: Config.session.icons.logout
            command: Config.session.commands.logout

            KeyNavigation.down: shutdown

            Component.onCompleted: forceActiveFocus()

            Connections {
                function onLauncherChanged(): void {
                    if (!root.visibilities.launcher)
                        logout.forceActiveFocus();
                }

                target: root.visibilities
            }
        }

        SessionButton {
            id: shutdown

            icon: Config.session.icons.shutdown
            command: Config.session.commands.shutdown
            primary: true

            KeyNavigation.up: logout
            KeyNavigation.down: hibernate
        }

        AnimatedImage {
            width: Tokens.sizes.session.button
            height: Tokens.sizes.session.button
            sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)

            playing: visible
            asynchronous: true
            speed: Config.general.sessionGifSpeed
            source: Paths.absolutePath(Config.paths.sessionGif)
            fillMode: AnimatedImage.PreserveAspectFit
        }

        SessionButton {
            id: hibernate

            icon: Config.session.icons.hibernate
            command: Config.session.commands.hibernate

            KeyNavigation.up: shutdown
            KeyNavigation.down: reboot
        }

        SessionButton {
            id: reboot

            icon: Config.session.icons.reboot
            command: Config.session.commands.reboot

            KeyNavigation.up: hibernate
        }

        component SessionButton: IconButton {
            id: button

            required property list<string> command
            property bool primary // matte skin: accent-filled primary action

            function exec(): void {
                if (!SessionManager.exec(command))
                    Quickshell.execDetached(command);
            }

            implicitWidth: Tokens.sizes.session.button
            implicitHeight: Tokens.sizes.session.button

            inactiveColour: primary ? Colours.palette.m3primary : activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
            inactiveOnColour: primary ? Colours.palette.m3onPrimary : activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            radius: pressed ? Tokens.rounding.medium : activeFocus ? Tokens.rounding.extraLarge : Tokens.rounding.largeIncreased
            font: Tokens.font.icon.builders.large.scale(1.3).build()
            onClicked: exec()

            Keys.onEnterPressed: exec()
            Keys.onReturnPressed: exec()
            Keys.onEscapePressed: root.visibilities.session = false
            Keys.onPressed: event => {
                if (!Config.session.vimKeybinds)
                    return;

                if (event.modifiers & Qt.ControlModifier) {
                    if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.down) {
                        KeyNavigation.down.focus = true;
                        event.accepted = true;
                    } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.up) {
                        KeyNavigation.up.focus = true;
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                    if (KeyNavigation.up) {
                        KeyNavigation.up.focus = true;
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
