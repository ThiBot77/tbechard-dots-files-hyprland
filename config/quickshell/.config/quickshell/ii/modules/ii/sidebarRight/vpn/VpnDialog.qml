import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 500

    WindowDialogTitle {
        text: Translation.tr("VPN connections")
    }
    WindowDialogSeparator {}
    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large

        clip: true
        spacing: 0

        model: ScriptModel {
            values: Network.vpnProfiles
            objectProp: "uuid"
        }
        delegate: VpnConnectionItem {
            required property var modelData
            vpnProfile: modelData
            width: ListView.view.width
        }
    }
    StyledText {
        visible: Network.vpnProfiles.length === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        color: Appearance.colors.colSubtext
        text: Translation.tr("No VPN connection configured")
    }
    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Details")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Config.options.apps.network}`]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
