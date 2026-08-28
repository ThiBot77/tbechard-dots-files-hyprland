import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "media"

    readonly property var track: MprisController.activeTrack
    readonly property string artUrl: track?.artUrl ?? ""

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    StyledDropShadow {
        target: card
    }

    Rectangle {
        id: card
        anchors.fill: parent
        implicitWidth: 440
        implicitHeight: 116
        radius: Appearance.rounding.large
        color: Appearance.colors.colSecondaryContainer

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Rectangle { // Art, rounded by masking rather than clipping
                id: artBackground
                Layout.preferredWidth: card.implicitHeight - 28
                Layout.fillHeight: true
                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainerHigh
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: artBackground.width
                        height: artBackground.height
                        radius: artBackground.radius
                    }
                }

                MaterialSymbol { // Shows through whenever the art is missing
                    anchors.centerIn: parent
                    iconSize: 36
                    color: Appearance.colors.colOnSecondaryContainer
                    opacity: 0.5
                    text: "music_note"
                }

                StyledImage {
                    anchors.fill: parent
                    // Bound straight to the MPRIS url. Remote art loads over
                    // the network and local art over file://, both natively;
                    // the download in mediaControls/ exists only because its
                    // colour quantizer needs a file on disk.
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                }
            }

            ColumnLayout { // Track info
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                Item { Layout.fillHeight: true }

                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSecondaryContainer
                    font {
                        pixelSize: Appearance.font.pixelSize.large
                        family: Appearance.font.family.expressive
                        weight: Font.DemiBold
                    }
                    elide: Text.ElideRight
                    text: root.track?.title ?? Translation.tr("Nothing playing")
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSecondaryContainer
                    opacity: 0.7
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    elide: Text.ElideRight
                    text: root.track?.artist ?? ""
                }

                Item { Layout.fillHeight: true }
            }

            RowLayout { // Controls
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                MediaButton {
                    iconName: "skip_previous"
                    enabled: MprisController.canGoPrevious
                    onClicked: MprisController.previous()
                }

                MediaButton {
                    iconName: MprisController.isPlaying ? "pause" : "play_arrow"
                    enabled: MprisController.canTogglePlaying
                    diameter: 46
                    iconSize: 26
                    colBackground: Appearance.colors.colPrimary
                    colForeground: Appearance.colors.colOnPrimary
                    onClicked: MprisController.togglePlaying()
                }

                MediaButton {
                    iconName: "skip_next"
                    enabled: MprisController.canGoNext
                    onClicked: MprisController.next()
                }
            }
        }
    }
}
