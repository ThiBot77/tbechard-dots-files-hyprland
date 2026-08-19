# tbe-dots-files

Dotfiles + install script pour ajouter **Hyprland** à côté d'une session **GNOME**
existante sur Arch Linux, avec un rice noir & blanc / glassmorphism, et un
visualiseur audio `cava` en widget toggleable.

GNOME n'est ni modifié ni supprimé : Hyprland est installé en plus, sélectionnable
au login depuis GDM.

## Installation

```sh
git clone <ce repo> ~/Documents/tbe-dots-files
cd ~/Documents/tbe-dots-files
./install.sh
```

- `./install.sh --dry-run` affiche toutes les actions (paquets, symlinks) sans rien
  exécuter.
- Le script est idempotent : relançable sans risque après une modif.
- Toute config déjà présente sur ta machine et qui serait écrasée par un des
  packages ci-dessous est d'abord déplacée dans `~/.dotfiles-backup-<date>/`.

## Structure

```
install.sh                 point d'entrée, orchestre scripts/*.sh dans l'ordre
packages/pacman.txt         paquets dépôts officiels
packages/aur.txt            paquets AUR (installés via yay)
scripts/                    étapes numérotées (system check, packages, stow, post-install)
stow/<package>/             un dossier par "package" GNU Stow, arbo miroir de $HOME
```

## Packages / composants

| Rôle          | Programme              |
|---------------|-------------------------|
| Compositor    | Hyprland                |
| Barre         | waybar                  |
| Launcher      | rofi                    |
| Notifications | mako                    |
| Lock / idle   | hyprlock / hypridle     |
| Terminal      | kitty                   |
| Fichiers      | thunar                  |
| Visualiseur   | cava                    |
| Réseau        | nm-applet (icône tray)  |
| Wallpaper     | awww                    |
| Power menu    | wlogout (bouton barre ou `SUPER+SHIFT+M`) |

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
| `SUPER + Q`          | Fermer la fenêtre active        |
| `SUPER + 1..0`       | Aller au workspace N             |
| `SUPER + SHIFT + 1..0` | Envoyer la fenêtre au workspace N |
| `PRINT`              | Capture d'une zone, ouvre swappy pour annoter |
| `SUPER + SHIFT + PRINT` | Capture plein écran instantanée (presse-papiers) |
| `SUPER + PRINT`      | Capture de la fenêtre active     |

Voir `stow/hypr/.config/hypr/conf.d/keybinds.conf` pour la liste complète.

## Après l'install

1. Se déconnecter.
2. Sur l'écran GDM, choisir la session **Hyprland** (icône engrenage à côté du
   champ mot de passe).
3. GNOME reste le choix par défaut si tu ne changes rien.

## Modifier / re-stow un seul package

```sh
# éditer les fichiers dans stow/waybar/... puis :
stow -d stow -t ~ -R waybar
```

## Palette de couleur

`SUPER + SHIFT + T` ouvre un menu rofi pour changer de thème. Toutes les
couleurs changent : fond, texte, accent et palette du terminal, dans
Hyprland, hyprlock, waybar, rofi, mako, kitty, cava, les applis GTK
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
| mako     | `~/.config/mako/colors`                |
| kitty    | `~/.config/kitty/theme.conf`           |
| cava     | `~/.config/cava/themes/current`        |
| GTK 3/4  | `~/.config/gtk-{3,4}.0/gtk.css`        |
| Qt 5/6   | `~/.config/qt{5,6}ct/colors/current.conf` |

Les configs des applis ne contiennent aucune couleur en dur : elles
importent seulement ces fichiers générés.

Rechargement à chaud pour Hyprland, waybar, mako et kitty. Les applis
GTK/Qt déjà ouvertes doivent être relancées ; un widget cava ouvert
garde ses couleurs jusqu'à réouverture (`SUPER + V` deux fois) ou la
touche `c`.

Pour créer un thème : copie un dossier existant, change les valeurs de
`palette.sh`, c'est tout.

## Polices

- **Interface** (waybar, rofi, mako, hyprlock) : `Adwaita Sans`, une
  sans-serif — plus lisible qu'une chasse fixe pour de l'UI.
- **Terminal** (kitty) et visualiseur : `FiraCode Nerd Font`.

Les icônes de la barre et des menus sont des glyphes Nerd Font : elles
restent affichées grâce au fallback fontconfig, qui les résout vers
FiraCode même quand la police principale est Adwaita Sans.

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
