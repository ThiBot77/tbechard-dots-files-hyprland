// Barre Quickshell, palette graphite.
//
// Lancement : quickshell -c graphite
// Coexiste volontairement avec waybar : c'est une simple surface layer-shell,
// les deux peuvent tourner en meme temps le temps de comparer.
//
// Etat : squelette valide. Construit a partir du seul exemple documente
// (PanelWindow + anchors + implicitHeight) ; les modules (workspaces, tray,
// pipewire, upower) seront ajoutes un par un en verifiant chacun a l'execution,
// la doc etant rendue cote client et son API non consultable hors ligne.

import Quickshell
import QtQuick

PanelWindow {
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 38
    color: "transparent"

    // --- ilot central, meme langage visuel que la waybar actuelle ---
    Rectangle {
        anchors.centerIn: parent
        implicitWidth: row.implicitWidth + 28
        implicitHeight: 28
        radius: 14
        color: "#d10a0a0b"
        border.width: 1
        border.color: "#1c1c1f"

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 10

            Text {
                id: clock
                color: "#d6d6d8"
                font.family: "Adwaita Sans"
                font.pixelSize: 13
                text: Qt.formatDateTime(new Date(), "HH:mm")

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
                }
            }

            Text {
                color: "#6b6b70"
                font.family: "Adwaita Sans"
                font.pixelSize: 13
                text: "quickshell"
            }
        }
    }
}
