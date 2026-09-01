import qs.modules.common
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

MaterialShape { // App icon
    id: root
    property var appIcon: ""
    property var appName: ""
    property var summary: ""
    property var urgency: NotificationUrgency.Normal
    property bool isUrgent: urgency === NotificationUrgency.Critical
    property var image: ""
    property real materialIconScale: 0.57
    property real appIconScale: 0.8
    property real smallAppIconScale: 0.49
    property real materialIconSize: implicitSize * materialIconScale

    // app_icon et image-path valent une URI, un chemin absolu ou un nom de
    // theme ; Quickshell emballe les deux derniers en "image://icon/<valeur>"
    // sans verifier. Rend "" quand rien n'est utilisable.
    function resolveIconSource(raw) {
        const value = String(raw ?? "");
        if (value.length === 0)
            return "";
        const themed = value.match(/^image:\/\/icon\/([^?#]+)/);
        const name = themed ? decodeURIComponent(themed[1]) : value;
        if (name.startsWith("/"))
            return `file://${name}`;
        if (themed)
            return Quickshell.hasThemeIcon(name) ? value : "";
        if (name.includes("://"))
            return name;
        return Quickshell.hasThemeIcon(name) ? Quickshell.iconPath(name) : "";
    }

    readonly property string resolvedImage: root.resolveIconSource(root.image)

    // Repli quand app_icon est vide ou mort : "Google Chrome" -> google-chrome.
    readonly property string appNameIcon: {
        const guess = String(root.appName ?? "").trim().toLowerCase().replace(/\s+/g, "-");
        if (guess.length === 0)
            return "";
        return Quickshell.hasThemeIcon(guess) ? Quickshell.iconPath(guess) : "";
    }
    readonly property string resolvedAppIcon: {
        const direct = root.resolveIconSource(root.appIcon);
        return direct !== "" ? direct : root.appNameIcon;
    }

    // Les icones sous /tmp disparaissent avant la notification qui les cite,
    // et ca ne se voit qu'au chargement.
    property bool imageBroken: false
    property bool appIconBroken: false
    onResolvedImageChanged: imageBroken = false
    onResolvedAppIconChanged: appIconBroken = false
    readonly property string shownImage: imageBroken ? "" : resolvedImage
    readonly property string shownAppIcon: appIconBroken ? appNameIcon : resolvedAppIcon

    property real appIconSize: implicitSize * appIconScale
    property real smallAppIconSize: implicitSize * smallAppIconScale

    implicitSize: 38 * scale
    property list<var> urgentShapes: [
        MaterialShape.Shape.VerySunny,
        MaterialShape.Shape.SoftBurst,
    ]
    shape: isUrgent ? urgentShapes[Math.floor(Math.random() * urgentShapes.length)] : MaterialShape.Shape.Circle

    color: isUrgent ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer
    Loader {
        id: materialSymbolLoader
        active: root.shownAppIcon == "" && root.shownImage == ""
        anchors.fill: parent
        sourceComponent: MaterialSymbol {
            text: {
                const defaultIcon = NotificationUtils.findSuitableMaterialSymbol("")
                const guessedIcon = NotificationUtils.findSuitableMaterialSymbol(root.summary)
                return (root.urgency == NotificationUrgency.Critical && guessedIcon === defaultIcon) ?
                    "priority_high" : guessedIcon
            }
            anchors.fill: parent
            color: isUrgent ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
            iconSize: root.materialIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    Loader {
        id: appIconLoader
        active: root.shownImage == "" && root.shownAppIcon != ""
        anchors.centerIn: parent
        sourceComponent: StyledImage {
            id: appIconImage
            width: root.appIconSize
            height: root.appIconSize
            source: root.shownAppIcon
            fillMode: Image.PreserveAspectFit
            Connections {
                target: appIconImage
                function onStatusChanged() {
                    if (appIconImage.status === Image.Error)
                        root.appIconBroken = true;
                }
            }
        }
    }
    Loader {
        id: notifImageLoader
        active: root.shownImage != ""
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            StyledImage {
                id: notifImage
                anchors.fill: parent
                readonly property int size: parent.width

                source: root.shownImage
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true
                asynchronous: true

                Connections {
                    target: notifImage
                    function onStatusChanged() {
                        if (notifImage.status === Image.Error)
                            root.imageBroken = true;
                    }
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: notifImage.size
                        height: notifImage.size
                        radius: Appearance.rounding.full
                    }
                }
            }
            Loader {
                id: notifImageAppIconLoader
                active: root.shownAppIcon != ""
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                sourceComponent: StyledImage {
                    width: root.smallAppIconSize
                    height: root.smallAppIconSize
                    source: root.shownAppIcon
                    fillMode: Image.PreserveAspectFit
                }
            }
        }
    }
}
