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
| Wallpaper     | awww                    |
| Power menu    | wlogout                 |

## Raccourcis clavier principaux

| Combo              | Action                          |
|---------------------|----------------------------------|
| `SUPER + T` / `RETURN` | Terminal (kitty)              |
| `SUPER + R` / `A`    | Launcher (rofi)                 |
| `SUPER + E`          | Fichiers (thunar)                |
| `SUPER + V`          | Toggle widget visualiseur cava  |
| `SUPER + SHIFT + W`  | Wallpaper aléatoire suivant      |
| `SUPER + L`          | Verrouiller l'écran             |
| `SUPER + SHIFT + M`  | Menu power (wlogout)            |
| `SUPER + Q`          | Fermer la fenêtre active        |
| `SUPER + 1..0`       | Aller au workspace N             |
| `SUPER + SHIFT + 1..0` | Envoyer la fenêtre au workspace N |
| `PRINT`              | Capture d'une zone (presse-papiers) |

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

## Wallpaper

`awww-daemon` est lancé au démarrage et applique un fond au hasard depuis
`~/.config/hypr/wallpapers/` (package stow `wallpaper`, quelques fonds manga
livrés en 2560x1440). `SUPER + SHIFT + W` en tire un nouveau au hasard.

Pour ajouter les tiens :

```sh
cp mon-fond.png stow/wallpaper/.config/hypr/wallpapers/
stow -d stow -t ~ -R wallpaper
```
