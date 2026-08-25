import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("VPN")
    statusText: Network.vpnActive ? Network.vpnName : Translation.tr("Off")
    tooltipText: Network.vpnActive
        ? Translation.tr("%1 | Right-click for connections").arg(Network.vpnName)
        : Translation.tr("VPN | Right-click for connections")
    icon: Network.vpnActive ? "vpn_lock" : "vpn_key_off"

    available: Network.vpnProfiles.length > 0
    toggled: Network.vpnActive
    mainAction: () => Network.toggleLastVpn()
    hasMenu: true
}
