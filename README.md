# tbe-dots-files

Configuration Hyprland sur Arch Linux

Le shell — barre, notifications, launcher, panneau de réglages, écran de
verrouillage — est celui d'end-4, rapatrié dans ce dépôt et installé par
`install.sh`. On garde nos propres kitty, zsh, fastfetch et fonds d'écran.

## Installation

```sh
git clone <ce repo> ~/Documents/tbe-dots-files
cd ~/Documents/tbe-dots-files
./install.sh          # --dry-run pour voir sans rien modifier
```

Puis **se déconnecter et se reconnecter** : Hyprland ne lit sa config qu'au
démarrage, et les nouveaux groupes utilisateur ne s'appliquent qu'à
l'ouverture de session.

## Qui fait quoi

Chaque dossier de `stow/` est un paquet GNU Stow : son arborescence est
recopiée en liens symboliques dans `$HOME`.

### Le bureau

| Paquet | Installe dans | Rôle |
|---|---|---|
| `hypr` | `~/.config/hypr` | Config **Hyprland** d'end-4, en **Lua** (`hyprland.lua`, pas `hyprland.conf`). Raccourcis, règles de fenêtres, animations, lancement du shell. Tes réglages perso vont dans `custom/*.lua`, chargés en dernier. |
| `quickshell` | `~/.config/quickshell` | **Le shell lui-même** : barre, notifications, launcher, panneau de réglages, sidebars, dock, écran de verrouillage. ~586 fichiers QML d'end-4. Quickshell n'est que le moteur ; toute l'interface vient d'ici. |
| `matugen` | `~/.config/matugen`, `~/.config/kde-material-you-colors` | **Génération des couleurs.** Extrait une palette Material You du fond d'écran et la décline vers Hyprland, hyprlock, fuzzel, GTK et Qt. C'est lui qui rend le thème monochrome. |
| `portal` | `~/.config/xdg-desktop-portal` | Choix du portail XDG. Indispensable au **partage d'écran** (Discord, visios) sous Wayland. |

### Applications habillées par le thème

| Paquet | Installe dans | Rôle |
|---|---|---|
| `kde` | `~/.config/{dolphinrc,konsolerc,darklyrc,fontconfig}`, `~/.local/share` | Réglages des applis **KDE** (Dolphin, Konsole) et style Darkly. Le rendu sous-pixel est désactivé via fontconfig. |
| `kvantum` | `~/.config/Kvantum` | Moteur de thème **Qt**. Habille les applis Qt qui ne suivent pas kdeglobals. |
| `fuzzel` | `~/.config/fuzzel` | Launcher de secours. `fuzzel_theme.ini` est **généré par matugen** (donc non versionné). |
| `wlogout` | `~/.config/wlogout` | Menu d'extinction. |
| `mpv` | `~/.config/mpv` | Lecteur vidéo. |
| `swappy` | `~/.config/swappy` | Annotation de captures d'écran. |
| `browsers` | `~/.config/*-flags.conf` | Options de lancement de Chrome, VS Code et Thorium (Wayland natif, trousseau GNOME). |
| `spicetify` | `~/.config/spicetify` | Thème graphite pour le client **Spotify**. |

### Ce qu'on garde à nous

| Paquet | Installe dans | Rôle |
|---|---|---|
| `kitty` | `~/.config/kitty` | Terminal. Config et couleurs maison, indépendantes d'end-4. |
| `zsh` | `~/.zshrc` | Shell : Oh My Zsh pour le plugin git, prompt délégué à starship. |
| `starship` | `~/.config/starship.toml` | Prompt powerline arrondi. Couleurs **nommées**, donc héritées de la palette du terminal. |
| `fastfetch` | `~/.config/fastfetch` | Résumé système à l'ouverture d'un terminal. |
| `wallpaper` | `~/Images/Wallpapers` | Les fonds d'écran. Ce chemin n'est pas décoratif : c'est là que le sélecteur d'end-4 va les chercher. |

## Palette

Le graphite ne vient pas de couleurs écrites en dur : c'est le schéma
Material You **`scheme-monochrome`** avec le mode sombre forcé, défini dans
`quickshell/ii/modules/common/Config.qml`. matugen produit donc une palette
en niveaux de gris à partir de n'importe quel fond d'écran.

Les couleurs sémantiques (liens, succès, erreur) restent teintées — c'est
voulu par Material You, un lien doit rester reconnaissable.

Le panneau de réglages (`SUPER + I`) écrit dans
`~/.config/illogical-impulse/config.json`, pas dans les fichiers QML : ceux-ci
ne fournissent que les valeurs par défaut au premier lancement.

## Fichiers générés, volontairement non versionnés

matugen et kde-material-you-colors réécrivent des fichiers de couleurs à
chaque changement de fond. Comme stow replie ces dossiers en liens vers le
dépôt, ces outils écrivent **droit dans l'arbre de travail** : sans
précaution, chaque wallpaper produirait un diff.

| Fichier | Écrit par |
|---|---|
| `hypr/hyprland/colors.lua`, `hypr/hyprlock/colors.conf` | matugen (dans `.gitignore`) |
| `fuzzel/fuzzel_theme.ini` | matugen (dans `.gitignore`) |
| `~/.config/kdeglobals` | kde-material-you-colors — **hors stow**, semé depuis `vendor/end4/kdeglobals.default` |
| `~/.config/hypr/monitors.lua` | nwg-displays — machine-local, semé à l'install |

## Environnement Python

Une partie de l'outillage d'end-4 n'est pas installée en paquets système mais
dans un venv, à `~/.local/state/quickshell/.venv`, désigné par
`$ILLOGICAL_IMPULSE_VIRTUAL_ENV`. **`kde-material-you-colors` en fait partie** :
sans ce venv, Dolphin et les dialogues KDE gardent leurs couleurs par défaut.
`install.sh` le construit avec `uv` depuis `vendor/end4/requirements.txt`.

## Écran de connexion (SDDM)

Thème maison dans `sddm/`, installé par `scripts/40-sddm.sh`. Il reprend la
mise en page de l'écran de verrouillage. Ses couleurs sont dupliquées dans
`sddm/theme/theme.conf` : le greeter tourne avant toute session utilisateur et
ne peut rien lire sous `$HOME`.

Valider avec `sddm-greeter` (le binaire Qt5 réellement utilisé), **pas**
`sddm-greeter-qt6`, plus permissif : il laisse passer des erreurs qui, en
vrai, font retomber SDDM sur son thème par défaut sans rien afficher.

## Divers

- **Clavier** : end-4 force `kb_layout = "us"`. L'override AZERTY est dans
  `hypr/custom/general.lua`, le fichier qu'ils prévoient pour ça.
- **Hyprland régénère un `hyprland.conf` bidon** dès qu'il n'en trouve pas, et
  ce stub masque `hyprland.lua`. `install.sh` le supprime.
- **Spotify** : relancer `spicetify apply` après chaque mise à jour, le patch
  saute.
- Le code d'end-4 est sous **GPL-3.0** ; leur licence est conservée à la
  racine (`LICENSE-end4`).

## Modifier / re-stow un paquet

```sh
stow -d stow -t ~ -R quickshell     # -n pour simuler, -D pour retirer
```
