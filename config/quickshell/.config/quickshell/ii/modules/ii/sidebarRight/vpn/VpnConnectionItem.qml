import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    required property var vpnProfile
    readonly property bool busy: Network.vpnBusyUuid === (root.vpnProfile?.uuid ?? "")

    active: root.vpnProfile?.active ?? false
    enabled: !root.busy
    onClicked: Network.toggleVpn(root.vpnProfile)

    contentItem: RowLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 10

        MaterialSymbol {
            iconSize: Appearance.font.pixelSize.larger
            text: root.vpnProfile?.active ? "vpn_lock" : "vpn_key"
            color: Appearance.colors.colOnSurfaceVariant
        }
        StyledText {
            Layout.fillWidth: true
            color: Appearance.colors.colOnSurfaceVariant
            elide: Text.ElideRight
            text: root.vpnProfile?.name ?? Translation.tr("Unknown")
            textFormat: Text.PlainText
        }
        StyledText {
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
            text: root.vpnProfile?.type ?? ""
            textFormat: Text.PlainText
        }
        MaterialSymbol {
            visible: root.busy || (root.vpnProfile?.active ?? false)
            text: root.busy ? "settings_ethernet" : "check"
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnSurfaceVariant
        }
    }
}
