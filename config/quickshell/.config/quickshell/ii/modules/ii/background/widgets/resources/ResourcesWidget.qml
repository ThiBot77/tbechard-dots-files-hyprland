import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "resources"

    implicitWidth: tileRow.implicitWidth
    implicitHeight: tileRow.implicitHeight

    RowLayout {
        id: tileRow
        anchors.fill: parent
        spacing: 12

        ResourceTile {
            visible: root.configEntry.showCpu
            // A RowLayout still reserves space for an invisible item unless
            // it is excluded from the layout outright.
            Layout.preferredWidth: visible ? implicitWidth : 0
            iconName: "planner_review"
            label: Translation.tr("CPU")
            percentage: ResourceUsage.cpuUsage
            colBackground: Appearance.colors.colPrimaryContainer
            colForeground: Appearance.colors.colOnPrimaryContainer
        }

        ResourceTile {
            visible: root.configEntry.showMemory
            Layout.preferredWidth: visible ? implicitWidth : 0
            iconName: "memory"
            label: Translation.tr("RAM")
            percentage: ResourceUsage.memoryUsedPercentage
            colBackground: Appearance.colors.colSecondaryContainer
            colForeground: Appearance.colors.colOnSecondaryContainer
        }

        ResourceTile {
            // UPower reports no battery on a desktop, so the tile would sit
            // there reading 100% forever.
            visible: root.configEntry.showBattery && Battery.available
            Layout.preferredWidth: visible ? implicitWidth : 0
            iconName: Battery.isCharging ? "battery_charging_full" : "battery_full"
            label: Translation.tr("Battery")
            percentage: Battery.percentage
            colBackground: Battery.isLowAndNotCharging ? Appearance.colors.colErrorContainer : Appearance.colors.colTertiaryContainer
            colForeground: Battery.isLowAndNotCharging ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnTertiaryContainer
        }
    }
}
