import QtQuick
import qs.modules.common
import qs.modules.common.widgets

/*
 * One timezone of the world clock: city, UTC offset, time, and a sun or moon.
 */
Item {
    id: root

    required property string label
    required property string offsetLabel
    required property string time
    required property bool daytime
    property color colBackground: Appearance.colors.colSurfaceContainerHigh
    property color colForeground: Appearance.colors.colOnSecondaryContainer

    implicitWidth: 168
    implicitHeight: 74

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: root.colBackground

        StyledText {
            id: cityText
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: 12
                topMargin: 9
            }
            width: parent.width - offsetText.width - 32
            color: root.colForeground
            font.pixelSize: Appearance.font.pixelSize.smaller
            elide: Text.ElideRight
            text: root.label
        }

        StyledText {
            id: offsetText
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 12
                topMargin: 9
            }
            color: root.colForeground
            opacity: 0.5
            font.pixelSize: Appearance.font.pixelSize.smallest
            text: root.offsetLabel
        }

        StyledText {
            anchors {
                left: parent.left
                bottom: parent.bottom
                leftMargin: 12
                bottomMargin: 10
            }
            color: root.colForeground
            font {
                pixelSize: 24
                family: Appearance.font.family.expressive
                weight: Font.DemiBold
            }
            text: root.time
        }

        MaterialSymbol {
            anchors {
                right: parent.right
                bottom: parent.bottom
                rightMargin: 12
                bottomMargin: 12
            }
            iconSize: 18
            color: root.colForeground
            opacity: 0.6
            text: root.daytime ? "light_mode" : "dark_mode"
        }
    }
}
