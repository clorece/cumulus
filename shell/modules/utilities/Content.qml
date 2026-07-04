import "cards"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property var props
    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts
    required property matrix4x4 deformMatrix

    readonly property real nonAnimHeight: idleInhibit.nonAnimHeight + record.nonAnimHeight + toggles.implicitHeight + focusedTransparency.nonAnimHeight + layout.spacing * 3

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        IdleInhibit {
            id: idleInhibit
        }

        Record {
            id: record

            props: root.props
            visibilities: root.visibilities
            z: 1
        }

        Toggles {
            id: toggles

            visibilities: root.visibilities
            popouts: root.popouts
        }

        FocusedTransparency {
            id: focusedTransparency
        }
    }

    RecordingDeleteModal {
        props: root.props
        deformMatrix: root.deformMatrix
    }
}
