import QtQuick
import qs.modules.common
import qs.modules.common.widgets

/*
 * One tile of the resources widget: a percentage, a label and an icon.
 */
Item {
    id: root

    required property string iconName
    required property string label
    required property real percentage // 0..1
    property color colBackground: Appearance.colors.colPrimaryContainer
    property color colForeground: Appearance.colors.colOnPrimaryContainer
    property real tileSize: 150

    implicitWidth: tileSize
    implicitHeight: tileSize

    StyledDropShadow {
        target: tile
    }

    Rectangle {
        id: tile
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: root.colBackground

        Rectangle { // Icon bubble
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 14
                rightMargin: 14
            }
            implicitWidth: 40
            implicitHeight: 40
            radius: Appearance.rounding.full
            color: root.colForeground

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 22
                color: root.colBackground
                text: root.iconName
            }
        }

        StyledText {
            anchors {
                left: parent.left
                bottom: labelText.top
                leftMargin: 16
                bottomMargin: 2
            }
            color: root.colForeground
            font {
                pixelSize: 34
                family: Appearance.font.family.expressive
                weight: Font.DemiBold
            }
            // Rounded, not truncated: 99.6% reading as 99% looks stuck.
            text: `${Math.round(root.percentage * 100)}%`
        }

        StyledText {
            id: labelText
            anchors {
                left: parent.left
                bottom: parent.bottom
                leftMargin: 16
                bottomMargin: 16
            }
            color: root.colForeground
            opacity: 0.7
            font.pixelSize: Appearance.font.pixelSize.smaller
            text: root.label
        }
    }
}
