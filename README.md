# tbe-dots-files

## Installation

```sh
git clone <ce repo> ~/Documents/tbe-dots-files
cd ~/Documents/tbe-dots-files
./install.sh
```

## Packages / composants

| Rôle          | Programme              |
|---------------|-------------------------|
| Compositor    | Hyprland                |
| Barre         | waybar                  |
| Launcher      | rofi                    |
| Notifications | swaync (centre + historique) |
| Lock / idle   | hyprlock / hypridle     |
| Terminal      | kitty                   |
| Fichiers      | thunar                  |
| Visualiseur   | cava                    |
| Réseau        | nm-applet (icône tray)  |
| Wallpaper     | awww                    |
| Power menu    | wlogout (bouton barre ou `SUPER+SHIFT+M`) |
| Calendrier    | gsimplecal (clic sur l'heure) |
| Météo         | wttrbar (barre, à côté de l'heure) |
| OSD volume/luminosité | swayosd            |
| Presse-papiers | cliphist (`SUPER+SHIFT+V`) |
| Screen recording | wf-recorder (`SUPER+SHIFT+R`) |

## Raccourcis clavier principaux

| Combo              | Action                          |
|---------------------|----------------------------------|
| `SUPER + T` / `RETURN` | Terminal (kitty)              |
| `SUPER + R` / `A`    | Launcher (rofi)                 |
| `SUPER + E`          | Fichiers (thunar)                |
| `SUPER + V`          | Toggle widget visualiseur cava  |
| `SUPER + SHIFT + W`  | Menu de sélection du wallpaper (rofi) |
| `SUPER + SHIFT + T`  | Menu de sélection de la palette de couleur |
| `SUPER + L`          | Verrouiller l'écran             |
| `SUPER + SHIFT + M`  | Menu power (wlogout)            |
| `SUPER + N`          | Centre de notifications (swaync) |
| `SUPER + S`          | Terminal scratchpad (afficher/masquer) |
| `SUPER + SHIFT + S`  | Envoyer la fenêtre au scratchpad |
| `SUPER + SHIFT + D`  | Config des écrans (nwg-displays) |
| `SUPER + SHIFT + R`  | Toggle enregistrement d'écran (wf-recorder) |
| `SUPER + SHIFT + V`  | Presse-papiers (cliphist)       |
| `SUPER + Q`          | Fermer la fenêtre active        |
| `SUPER + 1..0`       | Aller au workspace N             |
| `SUPER + SHIFT + 1..0` | Envoyer la fenêtre au workspace N |
| `PRINT`              | Capture d'une zone, ouvre swappy pour annoter |
| `SUPER + SHIFT + PRINT` | Capture plein écran instantanée (presse-papiers) |
| `SUPER + PRINT`      | Capture de la fenêtre active     |


## Palette de couleur

`SUPER + SHIFT + T` ouvre un menu rofi pour changer de thème. Toutes les
couleurs changent : fond, texte, accent et palette du terminal, dans
Hyprland, hyprlock, waybar, rofi, swaync, kitty, cava, les applis GTK
(Thunar…) et les applis Qt.

Thèmes livrés dans `themes/` :

| Thème | Look |
|-------|------|
| `mono` | noir & blanc, défaut |
| `graphite` | ardoise sombre, accent bleu acier désaturé — sobre / pro |
| `cyberpunk` | violet profond, accent rose néon, secondaire cyan |

Chaque thème est **un seul fichier**, `themes/<nom>/palette.sh`, qui
définit les couleurs de base (`BG`, `BG_ALT`, `FG`, `FG_DIM`, `ACCENT`,
`ACCENT_DIM`, `BORDER`) et les 16 couleurs du terminal (`T_*`).
`theme-switch.sh <nom>` en génère les fichiers de couleurs de chaque
appli puis recharge tout à chaud :

| Appli    | Fichier généré                        |
|----------|----------------------------------------|
| Hyprland + hyprlock | `~/.config/hypr/colors.conf` |
| waybar   | `~/.config/waybar/colors.css`          |
| rofi     | `~/.config/rofi/colors.rasi`           |
| swaync   | `~/.config/swaync/colors.css`          |
| kitty    | `~/.config/kitty/theme.conf`           |
| cava     | `~/.config/cava/themes/current`        |
| GTK 3/4  | `~/.config/gtk-{3,4}.0/gtk.css`        |
| Qt 5/6   | `~/.config/qt{5,6}ct/colors/current.conf` |

Les configs des applis ne contiennent aucune couleur en dur : elles
importent seulement ces fichiers générés.

Pour créer un thème : copie un dossier existant, change les valeurs de
`palette.sh`, c'est tout.

## Polices

- **Interface** (waybar, rofi, swaync, hyprlock) : `Adwaita Sans`, une
  sans-serif — plus lisible qu'une chasse fixe pour de l'UI.
- **Terminal** (kitty) et visualiseur : `FiraCode Nerd Font`
  (`ttf-firacode-nerd`).

Les icônes de la barre et des menus sont des glyphes Nerd Font : elles
restent affichées grâce au fallback fontconfig, qui les résout vers
FiraCode même quand la police principale est Adwaita Sans.

Curseur : `Bibata-Modern-Ice` (`bibata-cursor-theme-bin`, AUR).

## Écran de connexion (SDDM)

Le thème SDDM (`sddm/theme/`) reprend la mise en page de `hyprlock.conf` pour
que l'écran de connexion et l'écran de verrouillage forment un seul design :
horloge fine, date en majuscules espacées, avatar cerclé, champs en pastille,
et une barre basse (session / clavier / hôte / alimentation).

`scripts/40-sddm.sh` l'installe dans `/usr/share/sddm/themes/tbe` et active
SDDM.

```sh
# prévisualiser sans risque — s'ouvre dans une fenêtre, ne verrouille rien
sddm-greeter --test-mode --theme /usr/share/sddm/themes/tbe
```

Valider avec `sddm-greeter` (le binaire Qt5 réellement utilisé), **pas**
`sddm-greeter-qt6` : ce dernier est plus tolérant et laisse passer des erreurs
qui, en vrai, font retomber SDDM sur son thème par défaut sans rien afficher.

`QtQuick.Controls 2` et `QtGraphicalEffects` ne sont **pas** installés : les
importer fait échouer tout le document. D'où l'avatar livré déjà détouré en
cercle (seul son anneau est dessiné en QML, pour suivre la couleur d'accent).

Couleurs, nom affiché et chemins d'assets sont dans `sddm/theme/theme.conf` :
le greeter tourne avant toute session utilisateur, donc `theme-switch.sh` ne
peut pas l'atteindre — synchro manuelle avec `themes/graphite/palette.sh`.

Pour régénérer les assets (nouveau fond ou nouvel avatar) :

```sh
magick stow/wallpaper/.config/hypr/wallpapers/<fond>.png \
  -resize '2560x1440^' -gravity center -extent 2560x1440 \
  -blur 0x30 -modulate 34,90,100 -quality 88 sddm/theme/assets/background.jpg

magick stow/hypr/.config/hypr/avatar.png -resize '320x320^' \
  -gravity center -extent 320x320 \
  \( +clone -alpha extract -draw 'fill black polygon 0,0 0,320 320,320 320,0' \
     -draw 'fill white circle 160,160 160,1' \) \
  -alpha off -compose copyopacity -composite PNG32:sddm/theme/assets/avatar.png
```

`PNG32:` est nécessaire : sans lui le PNG retombe en niveaux de gris 1 bit,
sans couche alpha, et les coins du cercle s'affichent en noir opaque.

## Wallpaper

`awww-daemon` est lancé au démarrage et applique un fond au hasard depuis
`~/.config/hypr/wallpapers/` (package stow `wallpaper`, fonds manga +
IT/pro livrés en 2560x1440). `SUPER + SHIFT + W` ouvre un menu rofi pour
en choisir un précisément.

Pour ajouter les tiens :

```sh
cp mon-fond.png stow/wallpaper/.config/hypr/wallpapers/
stow -d stow -t ~ -R wallpaper
```
