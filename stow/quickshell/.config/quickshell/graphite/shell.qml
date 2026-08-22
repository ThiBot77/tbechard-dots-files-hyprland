// Barre Quickshell, palette graphite. Lancement : quickshell -c graphite
//
// Composition ET langage visuel repris de end-4/dots-hyprland (modules/ii/bar) :
// ilots multiples, ressources et media a gauche, workspaces au centre, horloge
// et indicateurs a droite, le tout en icones plutot qu'en libelles texte.
// Seules les couleurs changent (graphite au lieu de Material You).
//
// Material Symbols fonctionne par LIGATURES : le texte est le nom de l'icone
// ("wifi", "volume_up"), pas un codepoint. L'axe variable FILL passe d'une
// icone evidee a pleine.
//
// L'API vient des .qmltypes livres par le paquet, pas du site : celui-ci est
// rendu cote client et son index par defaut est celui de la v0.1.0, qui ne
// liste ni Networking ni Bluetooth alors que la 0.3.1 les fournit.

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Widgets
import QtQuick

ShellRoot {
    id: root

    readonly property color cBg:     "#0a0a0b"
    readonly property color cFg:     "#d6d6d8"
    readonly property color cDim:    "#6b6b70"
    readonly property color cAccent: "#b9b9be"
    readonly property color cDimmer: "#5a5a5f"
    readonly property color cBorder: "#1c1c1f"

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    // --- disposition clavier : evenement Hyprland, pas de sondage -----------
    property string kbLayout: "fr"
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return;
            const p = event.data.split(",");
            root.kbLayout = p[p.length - 1].slice(0, 2).toLowerCase();
        }
    }

    // --- CPU : deux echantillons de /proc/stat -----------------------------
    property real cpuUsage: 0
    property var _prevCpu: null
    FileView { id: statFile; path: "/proc/stat" }
    FileView { id: memFile;  path: "/proc/meminfo" }

    property real memUsage: 0

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();

            const line = statFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            if (line.length >= 4) {
                const idle = line[3] + (line[4] ?? 0);
                const total = line.reduce((a, b) => a + b, 0);
                if (root._prevCpu) {
                    const dTotal = total - root._prevCpu.total;
                    const dIdle = idle - root._prevCpu.idle;
                    if (dTotal > 0) root.cpuUsage = Math.max(0, Math.min(1, 1 - dIdle / dTotal));
                }
                root._prevCpu = { total: total, idle: idle };
            }

            const mem = memFile.text();
            const grab = k => Number((mem.match(new RegExp(k + ":\\s+(\\d+)")) ?? [0, 0])[1]);
            const totalKb = grab("MemTotal"), availKb = grab("MemAvailable");
            if (totalKb > 0) root.memUsage = (totalKb - availKb) / totalKb;
        }
    }

    // ----------------------------------------------------------------------
    component MIcon: Text {
        property real fill: 0
        font.family: "Material Symbols Rounded"
        font.pixelSize: 17
        font.variableAxes: ({ "FILL": fill, "opsz": 20, "wght": 400 })
        renderType: Text.NativeRendering
        color: root.cDim
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    }

    component MLabel: Text {
        font.family: "Adwaita Sans"
        font.pixelSize: 13
        color: root.cDim
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    }

    // Ilot : fond arrondi qui s'eclaire au survol.
    component Island: Rectangle {
        id: isl
        default property alias content: inner.data
        property alias hovered: ma.containsMouse
        signal clicked()

        implicitWidth: inner.implicitWidth + 20
        implicitHeight: 28
        radius: 14
        color: ma.containsMouse ? Qt.alpha(root.cAccent, 0.14) : Qt.alpha(root.cBg, 0.82)
        border.width: 1
        border.color: ma.containsMouse ? root.cDimmer : root.cBorder
        visible: inner.implicitWidth > 0

        Behavior on color        { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: isl.clicked()
        }

        Row {
            id: inner
            anchors.centerIn: parent
            spacing: 9
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: 40
            color: "transparent"

            readonly property var player: Mpris.players.values.find(p => p.isPlaying)
                                       ?? Mpris.players.values[0] ?? null
            readonly property var sink: Pipewire.defaultAudioSink
            readonly property var bat: UPower.displayDevice

            // ---------------- gauche ----------------
            Row {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 6

                Island {
                    MIcon { text: "memory" }
                    MLabel { text: Math.round(root.cpuUsage * 100) + "%" }
                    MIcon { text: "developer_board"; }
                    MLabel { text: Math.round(root.memUsage * 100) + "%" }
                }

                Island {
                    onClicked: bar.player?.togglePlaying()
                    MIcon {
                        text: bar.player?.isPlaying ? "pause" : "music_note"
                        fill: bar.player?.isPlaying ? 1 : 0
                        color: bar.player?.isPlaying ? root.cAccent : root.cDim
                    }
                    MLabel {
                        text: bar.player?.trackTitle ?? "Aucun média"
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 240)
                    }
                }
            }

            // ---------------- centre ----------------
            Island {
                anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }

                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: modelData.focused ? 22 : 8
                        height: 8
                        radius: 4
                        color: modelData.focused ? root.cAccent
                             : modelData.active  ? root.cDim
                             : root.cDimmer

                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 160 } }

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
                    MLabel {
                        color: root.cFg
                        text: clk.date.toLocaleString(Qt.locale("fr_FR"), "HH:mm")
                    }
                    MLabel {
                        color: root.cDimmer
                        text: "·"
                    }
                    MLabel {
                        text: clk.date.toLocaleString(Qt.locale("fr_FR"), "ddd d MMM")
                    }
                }

                Island {
                    onClicked: Hyprland.dispatch("exec hyprctl switchxkblayout all next")

                    MIcon { text: "keyboard" }
                    MLabel { text: root.kbLayout.toUpperCase() }

                    MIcon {
                        text: !bar.sink?.audio ? "volume_off"
                            : bar.sink.audio.muted ? "volume_off"
                            : bar.sink.audio.volume > 0.5 ? "volume_up" : "volume_down"
                        fill: 1
                    }
                    MLabel {
                        text: !bar.sink?.audio ? "—"
                            : bar.sink.audio.muted ? "muet"
                            : Math.round(bar.sink.audio.volume * 100) + "%"
                    }

                    MIcon {
                        text: Networking.connectivity === NetworkConnectivity.Full ? "wifi" : "wifi_off"
                        fill: 1
                        color: Networking.connectivity === NetworkConnectivity.Full ? root.cDim : root.cAccent
                    }

                    MIcon {
                        text: Bluetooth.defaultAdapter?.enabled ? "bluetooth" : "bluetooth_disabled"
                        fill: 1
                    }

                    MIcon {
                        visible: bar.bat?.isLaptopBattery ?? false
                        text: "battery_full"
                        fill: 1
                    }
                    MLabel {
                        visible: bar.bat?.isLaptopBattery ?? false
                        text: bar.bat ? Math.round(bar.bat.percentage * 100) + "%" : ""
                    }
                }

                Island {
                    Repeater {
                        model: SystemTray.items

                        delegate: IconImage {
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 16
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
