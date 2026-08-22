// Barre Quickshell, palette graphite. Lancement : quickshell -c graphite
//
// Composition reprise de end-4/dots-hyprland (modules/ii/bar/BarContent.qml) :
// plusieurs petits ilots par cote plutot qu'un bloc par zone, titre de fenetre
// et media a gauche, workspaces au centre, horloge et indicateurs a droite.
// Le style est le notre (graphite) ; leur code depend de leur systeme Material
// You et de leurs singletons, il n'est pas reutilisable tel quel.
//
// L'API vient des .qmltypes livres par le paquet, pas du site : celui-ci est
// rendu cote client et son index par defaut est celui de la v0.1.0, qui ne
// liste ni Networking ni Bluetooth alors que la 0.3.1 les fournit.

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Widgets
import QtQuick

ShellRoot {
    id: root

    readonly property color cBg:        "#0a0a0b"
    readonly property color cFg:        "#d6d6d8"
    readonly property color cFgDim:     "#6b6b70"
    readonly property color cAccent:    "#b9b9be"
    readonly property color cAccentDim: "#5a5a5f"
    readonly property color cBorder:    "#1c1c1f"

    // Les proprietes audio d'un noeud PipeWire ne sont liees que si l'objet est
    // suivi ; sans tracker, volume et muted restent a zero.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    // Disposition clavier : Hyprland l'annonce via l'evenement activelayout,
    // dont la donnee est "clavier,Disposition". Pas de sondage.
    property string kbLayout: "fr"
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return;
            const parts = event.data.split(",");
            root.kbLayout = parts[parts.length - 1].slice(0, 2).toLowerCase();
        }
    }

    component Island: Rectangle {
        default property alias content: inner.data
        implicitWidth: inner.implicitWidth + 22
        implicitHeight: 26
        radius: 13
        color: Qt.alpha(root.cBg, 0.82)
        border.width: 1
        border.color: root.cBorder
        visible: inner.implicitWidth > 0

        Row {
            id: inner
            anchors.centerIn: parent
            spacing: 10
        }
    }

    component Label: Text {
        color: root.cFgDim
        font.family: "Adwaita Sans"
        font.pixelSize: 13
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: 38
            color: "transparent"

            readonly property var activeToplevel: Hyprland.activeToplevel
            readonly property var player: Mpris.players.values.find(p => p.isPlaying)
                                       ?? Mpris.players.values[0] ?? null

            // ---------------- gauche ----------------
            Row {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 6

                Island {
                    Label {
                        text: bar.activeToplevel?.title ?? "Bureau"
                        color: root.cFg
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 320)
                    }
                }

                Island {
                    Label {
                        visible: bar.player !== null
                        text: bar.player
                            ? (bar.player.isPlaying ? "▶  " : "⏸  ")
                              + (bar.player.trackTitle ?? "")
                            : ""
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 260)

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bar.player?.togglePlaying()
                        }
                    }
                }
            }

            // ---------------- centre : workspaces ----------------
            Island {
                anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }

                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8; height: 8; radius: 4
                        color: modelData.focused ? root.cAccent
                             : modelData.active  ? root.cFgDim
                             : root.cAccentDim

                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("workspace " + modelData.id)
                        }
                    }
                }
            }

            // ---------------- droite ----------------
            Row {
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 6

                Island {
                    SystemClock { id: clk; precision: SystemClock.Minutes }
                    Label {
                        color: root.cFg
                        text: clk.date.toLocaleString(Qt.locale("fr_FR"), "HH:mm  ddd d MMM")
                    }
                }

                Island {
                    Label {
                        text: root.kbLayout.toUpperCase()
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("exec hyprctl switchxkblayout all next")
                        }
                    }

                    Label {
                        readonly property var sink: Pipewire.defaultAudioSink
                        text: !sink?.audio ? ""
                            : sink.audio.muted ? "muet"
                            : Math.round(sink.audio.volume * 100) + "%"
                    }

                    Label {
                        text: Networking.connectivity === NetworkConnectivity.Full ? "net" : "hors ligne"
                        color: Networking.connectivity === NetworkConnectivity.Full
                             ? root.cFgDim : root.cAccent
                    }

                    Label {
                        readonly property var bat: UPower.displayDevice
                        visible: bat?.isLaptopBattery ?? false
                        text: bat ? Math.round(bat.percentage * 100) + "%" : ""
                    }
                }

                Island {
                    Repeater {
                        model: SystemTray.items

                        delegate: IconImage {
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 15
                            source: modelData.icon

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) modelData.secondaryActivate();
                                    else modelData.activate();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
