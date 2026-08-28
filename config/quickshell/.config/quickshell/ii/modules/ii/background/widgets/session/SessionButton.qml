import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

/*
 * A button for the session widget: a circle when it only has an icon, a pill
 * once it is given a label. Its own MouseArea, so pressing it clicks instead
 * of dragging the card: the nested area takes the press before the drag
 * handler on AbstractWidget ever sees it.
 */
MouseArea {
    id: root

    required property string iconName
    property string label: ""
    property real diameter: 44
    property real iconSize: 22
    property color colBackground: Appearance.colors.colSurfaceContainerHighest
    property color colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
    property color colBackgroundActive: Appearance.colors.colSurfaceContainerHighestActive
    property color colForeground: Appearance.colors.colOnSecondaryContainer

    implicitWidth: root.label.length > 0 ? content.implicitWidth + 36 : diameter
    implicitHeight: diameter
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: root.containsPress ? root.colBackgroundActive : root.containsMouse ? root.colBackgroundHover : root.colBackground

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 8

            MaterialSymbol {
                iconSize: root.iconSize
                color: root.colForeground
                text: root.iconName
            }

            StyledText {
                visible: root.label.length > 0
                color: root.colForeground
                font {
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.Medium
                }
                text: root.label
            }
        }
    }
}
