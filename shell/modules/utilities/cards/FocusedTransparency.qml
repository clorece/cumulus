import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

// Focused Transparency: opacity offset applied to unfocused windows. The value
// is kept in the old focus-sizing state file for compatibility with existing
// slider settings.
Bubble {
    id: root

    readonly property real nonAnimHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased
    property int offset: 0

    Layout.fillWidth: true
    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: icon.implicitHeight + Tokens.padding.large

                radius: Tokens.rounding.full
                color: root.offset > 0 ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    text: "opacity"
                    color: root.offset > 0 ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Focused Transparency")
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.offset > 0 ? qsTr("%1% opacity offset").arg(root.offset) : qsTr("Off")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.medium * 2

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: parent.implicitHeight

                radius: Tokens.rounding.small
                value: root.offset / 100
                onInteraction: v => {
                    const n = Math.round(v * 100);
                    if (n !== root.offset) {
                        root.offset = n;
                        saveDelay.restart();
                    }
                }
            }
        }
    }

    Timer {
        id: saveDelay

        interval: 150
        onTriggered: stateFile.setText(String(root.offset))
    }

    FileView {
        id: stateFile

        printErrors: false
        path: `${Paths.state}/focus-sizing`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const n = parseInt(text(), 10);
            if (!isNaN(n))
                root.offset = Math.max(0, Math.min(100, n));
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText("0"));
        }
    }
}
