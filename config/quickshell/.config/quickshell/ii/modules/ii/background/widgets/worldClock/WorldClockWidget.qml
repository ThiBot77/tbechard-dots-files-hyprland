pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "worldClock"

    readonly property bool use24h: configEntry.use24h
    readonly property date now: DateTime.clock.date
    // Offsets, not times: they only move at a DST transition, so the process
    // below runs hourly while every clock on the card ticks off `now`.
    property var zoneData: []
    property string localZone: ""
    readonly property string localLabel: {
        if (root.configEntry.localLabel.length > 0)
            return root.configEntry.localLabel;
        return root.cityOf(root.localZone);
    }

    function cityOf(zoneId) {
        const parts = String(zoneId).split("/");
        return parts[parts.length - 1].replace(/_/g, " ");
    }

    function pad(n) {
        return n < 10 ? `0${n}` : `${n}`;
    }

    function formatTime(hours, minutes) {
        if (root.use24h)
            return `${root.pad(hours)}:${root.pad(minutes)}`;
        const suffix = hours < 12 ? "AM" : "PM";
        const hour12 = (hours % 12) === 0 ? 12 : (hours % 12);
        return `${root.pad(hour12)}:${root.pad(minutes)} ${suffix}`;
    }

    // getTime() is an absolute epoch, so shifting it by the zone's offset puts
    // that zone's wall clock in the date's UTC fields; read it back with getUTC*.
    function zoneDate(offsetMinutes) {
        return new Date(root.now.getTime() + offsetMinutes * 60000);
    }

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    // Zone ids come from a hand-edited config file and land in a shell command,
    // so anything outside an IANA id is dropped.
    readonly property string zoneScript: {
        let script = `printf 'LOCAL|%s\\n' "$(readlink -f /etc/localtime | sed 's#.*/zoneinfo/##')"`;
        const zones = root.configEntry.zones;
        for (let i = 0; i < zones.length; i++) {
            const zone = String(zones[i]).replace(/[^A-Za-z0-9_/+-]/g, "");
            if (zone.length === 0)
                continue;
            script += `; TZ="${zone}" date +"ZONE|${zone}|%z"`;
        }
        return script;
    }

    Process {
        id: zoneProc
        command: ["bash", "-c", root.zoneScript]
        stdout: StdioCollector {
            id: zoneCollector
            onStreamFinished: {
                const parsed = [];
                zoneCollector.text.trim().split("\n").forEach(line => {
                    const parts = line.split("|");
                    if (parts[0] === "LOCAL") {
                        root.localZone = parts[1] ?? "";
                        return;
                    }
                    if (parts[0] !== "ZONE" || parts.length < 3)
                        return;
                    const raw = parts[2];
                    const sign = raw.charAt(0) === "-" ? -1 : 1;
                    const hours = Number(raw.substring(1, 3));
                    const minutes = Number(raw.substring(3, 5));
                    parsed.push({
                        id: parts[1],
                        offsetMinutes: sign * (hours * 60 + minutes),
                        offsetLabel: `UTC${raw.charAt(0)}${hours}${minutes > 0 ? ":" + root.pad(minutes) : ""}`
                    });
                });
                root.zoneData = parsed;
            }
        }
    }

    function refreshZones() {
        zoneProc.running = false;
        zoneProc.running = true;
    }

    Component.onCompleted: root.refreshZones()
    onConfigEntryChanged: root.refreshZones()

    Timer {
        // DST transitions land on the hour, so nothing finer is needed.
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.refreshZones()
    }

    StyledDropShadow {
        target: card
    }

    Rectangle {
        id: card
        anchors.fill: parent
        implicitWidth: cardColumn.implicitWidth + 36
        implicitHeight: cardColumn.implicitHeight + 36
        radius: Appearance.rounding.large
        color: Appearance.colors.colSecondaryContainer

        ColumnLayout {
            id: cardColumn
            anchors.centerIn: parent
            spacing: 10

            RowLayout { // Location and the 12h/24h switch
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    iconSize: 20
                    color: Appearance.colors.colOnSecondaryContainer
                    text: "location_on"
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnSecondaryContainer
                    font {
                        pixelSize: Appearance.font.pixelSize.large
                        family: Appearance.font.family.expressive
                        weight: Font.DemiBold
                    }
                    elide: Text.ElideRight
                    text: root.localLabel
                }

                Rectangle { // Segmented 12h/24h toggle
                    implicitWidth: formatRow.implicitWidth + 8
                    implicitHeight: 26
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colSurfaceContainerHigh

                    RowLayout {
                        id: formatRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: [
                                {
                                    label: "12h",
                                    value: false
                                },
                                {
                                    label: "24h",
                                    value: true
                                }
                            ]

                            // Its own MouseArea, so pressing it toggles the
                            // format instead of dragging the card.
                            MouseArea {
                                id: formatButton
                                required property var modelData
                                readonly property bool active: root.use24h === modelData.value

                                implicitWidth: formatLabel.implicitWidth + 16
                                implicitHeight: 22
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.configEntry.use24h = modelData.value

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Appearance.rounding.full
                                    color: formatButton.active ? Appearance.colors.colPrimary : formatButton.containsMouse ? Appearance.colors.colSurfaceContainerHighestHover : "transparent"

                                    Behavior on color {
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }

                                    StyledText {
                                        id: formatLabel
                                        anchors.centerIn: parent
                                        color: formatButton.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                        opacity: formatButton.active ? 1 : 0.6
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        text: formatButton.modelData.label
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledText { // Local time
                Layout.fillWidth: true
                Layout.topMargin: -2
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnSecondaryContainer
                font {
                    pixelSize: 52
                    family: Appearance.font.family.expressive
                    weight: Font.DemiBold
                }
                text: root.formatTime(root.now.getHours(), root.now.getMinutes())
            }

            StyledText { // Local date
                Layout.fillWidth: true
                Layout.topMargin: -8
                Layout.bottomMargin: 2
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnSecondaryContainer
                opacity: 0.7
                font.pixelSize: Appearance.font.pixelSize.small
                // toLocaleDateString, not toString: the latter is a datetime
                // and drags the time and the timezone name in with it. The
                // day/month order belongs to the locale, not to this widget.
                text: root.now.toLocaleDateString(Qt.locale(), Locale.LongFormat)
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: root.zoneData

                    ZoneTile {
                        required property var modelData
                        readonly property date zoneNow: root.zoneDate(modelData.offsetMinutes)

                        Layout.fillWidth: true
                        label: root.cityOf(modelData.id)
                        offsetLabel: modelData.offsetLabel
                        time: root.formatTime(zoneNow.getUTCHours(), zoneNow.getUTCMinutes())
                        daytime: zoneNow.getUTCHours() >= 6 && zoneNow.getUTCHours() < 18
                    }
                }
            }
        }
    }
}
