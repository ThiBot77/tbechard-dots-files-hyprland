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

    // Le champ `app_icon` et le hint `image-path` d'une notification peuvent
    // etre une URI, un chemin absolu, *ou* un simple nom d'icone de theme (spec
    // freedesktop). Quickshell emballe tout ce qui n'est pas une URI dans
    // "image://icon/<valeur>" sans verifier que le theme connait ce nom, donc :
    //   - un nom que le theme n'a pas ("gnome-lockscreen", envoye par nm-applet)
    //     fait echouer le provider, qui affiche son damier magenta/noir ;
    //   - un chemin absolu n'est pas un nom de theme non plus et se perd de la
    //     meme facon, alors que le fichier existe. Chrome fait exactement ca
    //     pour les notifications web : app_icon pointe son propre logo et
    //     image-path l'avatar de l'expediteur, tous deux dans
    //     /tmp/com.google.Chrome.scoped_dir.XXXX/.
    // On defait donc l'emballage nous-memes et on rend une source utilisable,
    // ou "" pour laisser les Loaders retomber proprement sur le Material Symbol.
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

    // Beaucoup d'apps laissent app_icon vide ; le nom de l'app donne alors
    // souvent un nom d'icone de theme valide ("Google Chrome" ->
    // "google-chrome"). Sert aussi de secours quand app_icon designe un fichier
    // temporaire que l'app a deja efface.
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

    // Une source resolue peut quand meme echouer au chargement : les fichiers
    // sous /tmp disparaissent quand l'app qui les a ecrits se ferme, et une
    // notification lui survit dans le centre de notifications. On ne peut le
    // constater qu'au chargement, d'ou ces deux drapeaux, remis a zero des que
    // la source change.
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
