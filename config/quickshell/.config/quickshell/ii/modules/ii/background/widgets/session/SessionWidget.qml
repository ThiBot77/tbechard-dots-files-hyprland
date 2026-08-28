import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "session"

    // A path set in the settings wins; otherwise fall back to whatever picture
    // the system already has for this user.
    readonly property string avatarSource: configEntry.avatarPath.length > 0 ? configEntry.avatarPath : Directories.userAvatarPathAccountsService

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    StyledDropShadow {
        target: card
    }

    Rectangle {
        id: card
        anchors.fill: parent
        implicitWidth: 380
        implicitHeight: cardColumn.implicitHeight + 36
        radius: Appearance.rounding.large
        color: Appearance.colors.colSecondaryContainer

        ColumnLayout {
            id: cardColumn
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 18
            }
            spacing: 16

            RowLayout { // Identity
                Layout.fillWidth: true
                spacing: 14

                Item {
                    id: avatarContainer
                    visible: root.configEntry.showAvatar
                    Layout.preferredWidth: visible ? 56 : 0
                    Layout.preferredHeight: 56

                    Rectangle { // Shows through until the avatar loads, or if there is none
                        anchors.fill: parent
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colSurfaceContainerHigh

                        MaterialSymbol {
                            anchors.centerIn: parent
                            iconSize: 30
                            color: Appearance.colors.colOnSecondaryContainer
                            opacity: 0.5
                            text: "person"
                        }
                    }

                    StyledImage {
                        id: avatar
                        anchors.fill: parent
                        // AccountsService is where a display manager puts it;
                        // the dotfiles-only path is ~/.face.
                        source: root.avatarSource
                        // Only worth chasing ~/.face when no explicit path is set.
                        fallbacks: root.configEntry.avatarPath.length > 0 ? [] : [Directories.userAvatarPathRicersAndWeirdSystems, Directories.userAvatarPathRicersAndWeirdSystems2]
                        fillMode: Image.PreserveAspectCrop

                        // StyledImage *assigns* source when it walks its fallbacks,
                        // which breaks the binding above for good. Re-arm it when
                        // the configured path changes, or picking a new avatar in
                        // the settings would do nothing.
                        Connections {
                            target: root
                            function onAvatarSourceChanged() {
                                avatar.currentFallbackIndex = 0;
                                avatar.source = root.avatarSource;
                            }
                        }
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Circle {
                                diameter: avatar.height
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        color: Appearance.colors.colOnSecondaryContainer
                        font {
                            pixelSize: Appearance.font.pixelSize.large
                            family: Appearance.font.family.expressive
                            weight: Font.DemiBold
                        }
                        elide: Text.ElideRight
                        text: `${SystemInfo.username}@${SystemInfo.hostname}`
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Appearance.colors.colOnSecondaryContainer
                        opacity: 0.7
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        elide: Text.ElideRight
                        text: Translation.tr("Up • %1").arg(DateTime.uptime)
                    }
                }
            }

            RowLayout { // Actions
                Layout.fillWidth: true
                spacing: 8

                SessionButton {
                    Layout.fillWidth: true
                    iconName: "lock"
                    label: Translation.tr("Lock")
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colBackgroundActive: Appearance.colors.colPrimaryActive
                    colForeground: Appearance.colors.colOnPrimary
                    onClicked: Session.lock()
                }

                SessionButton {
                    iconName: "settings"
                    onClicked: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")])
                }

                SessionButton {
                    // The session screen, not poweroff outright: one misclick
                    // on the desktop should not take the machine down.
                    iconName: "power_settings_new"
                    onClicked: GlobalStates.sessionOpen = true
                }
            }
        }
    }
}
