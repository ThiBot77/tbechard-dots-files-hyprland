import QtQuick
import qs.modules.common
import qs.modules.common.widgets

/*
 * A round icon button for the media widget. Its own MouseArea, so pressing it
 * clicks instead of dragging the widget it sits on: the nested area takes the
 * press before the drag handler on AbstractWidget ever sees it.
 */
MouseArea {
    id: root

    required property string iconName
    property real diameter: 38
    property real iconSize: 22
    property color colBackground: "transparent"
    property color colForeground: Appearance.colors.colOnSecondaryContainer

    implicitWidth: diameter
    implicitHeight: diameter
    hoverEnabled: true
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    opacity: enabled ? 1 : 0.35

    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: root.containsPress ? Appearance.colors.colSecondaryContainerActive : root.containsMouse ? Appearance.colors.colSecondaryContainerHover : root.colBackground

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: root.iconSize
            color: root.colForeground
            text: root.iconName
        }
    }
}
