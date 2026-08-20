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


## Palette

Le rice est monochrome **graphite**, sans système de bascule : les couleurs
vivent directement dans les fichiers de chaque appli.

| Appli    | Fichier                                |
|----------|----------------------------------------|
| Hyprland + hyprlock | `~/.config/hypr/colors.conf` |
| waybar   | `~/.config/waybar/colors.css`          |
| rofi     | `~/.config/rofi/colors.rasi`           |
| swaync   | `~/.config/swaync/colors.css`          |
| kitty    | `~/.config/kitty/theme.conf`           |
| cava     | `~/.config/cava/themes/current`        |
| GTK 3/4  | `~/.config/gtk-{3,4}.0/gtk.css`        |
| Qt 5/6   | `~/.config/qt{5,6}ct/colors/current.conf` |
| starship | `~/.config/starship.toml` (couleurs *nommées*, héritées du terminal) |

Les valeurs du greeter SDDM sont volontairement dupliquées dans
`sddm/theme/theme.conf` : il tourne avant toute session utilisateur et ne
peut rien lire sous `$HOME`.

## Polices

- **Interface** (waybar, rofi, swaync, hyprlock) : `Adwaita Sans`, une
  sans-serif — plus lisible qu'une chasse fixe pour de l'UI.
- **Terminal** (kitty) et visualiseur : `FiraCode Nerd Font`
  (`ttf-firacode-nerd`).

Curseur : `Bibata-Modern-Ice` (`bibata-cursor-theme-bin`, AUR).

## Écran de connexion (SDDM)

Le thème SDDM (`sddm/theme/`) reprend la mise en page de `hyprlock.conf` pour
que l'écran de connexion et l'écran de verrouillage forment un seul design.

Le script `scripts/40-sddm.sh` l'installe dans `/usr/share/sddm/themes/tbe` et active SDDM.

## Wallpaper

`awww-daemon` est lancé au démarrage et applique un fond au hasard depuis
`~/.config/hypr/wallpapers/` 

`SUPER + SHIFT + W` ouvre un menu rofi pour
en choisir un précisément.

