# tbe-dots-files

Hyprland desktop for Arch Linux, based on [end-4's dots-hyprland](https://github.com/end-4/dots-hyprland),
themed in graphite.

## Install

On a fresh Arch install:

```sh
git clone <this repo> ~/Documents/tbe-dots-files
cd ~/Documents/tbe-dots-files
./install.sh              # --dry-run to see what it would do first
```

Then **log out and back in**. Hyprland reads its config at startup, and the
new user groups only apply at session start.

The installer runs four steps, in order:

| Step | What it does |
|---|---|
| `scripts/00-check-system.sh` | Checks it is Arch, installs `yay` if missing |
| `scripts/10-install-packages.sh` | Installs everything in `packages/pacman.txt` and `packages/aur.txt` |
| `scripts/20-copy-configs.sh` | Copies each package in `config/` into `$HOME` |
| `scripts/30-post-install.sh` | Oh My Zsh, Python venv, spicetify, user groups |
| `scripts/40-sddm.sh` | Installs and enables the SDDM login theme |

To reinstall a single config after editing it:

```sh
scripts/20-copy-configs.sh kitty      # no argument installs everything
```

Configs are copied, not symlinked: edit the file in `config/`, not in
`~/.config`, then re-run the command above. The copy overwrites the target.

## Main packages

**Desktop**

| Package | Role |
|---|---|
| `hyprland` | The Wayland compositor. Config is `~/.config/hypr/hyprland.lua` |
| `quickshell` | The shell itself: bar, notifications, launcher, settings panel |
| `hyprlock`, `hypridle` | Lock screen and idle daemon |
| `matugen` | Generates the Material You palette from the wallpaper |
| `sddm` | Login screen. Custom theme in `sddm/` |
| `xdg-desktop-portal-hyprland`, `-gtk`, `-kde` | Screen sharing and file dialogs |
| `pipewire-pulse`, `wireplumber` | Audio |
| `polkit-kde-agent`, `gnome-keyring` | Authentication prompts and secrets |
| `networkmanager`, `plasma-nm`, `bluedevil` | Network and Bluetooth |

**Tools the shell calls**

| Package | Role |
|---|---|
| `cliphist`, `wl-clipboard` | Clipboard history |
| `hyprshot`, `slurp`, `swappy` | Screenshots and annotation |
| `brightnessctl`, `ddcutil` | Brightness, including external monitors |
| `playerctl`, `cava` | Media controls and audio visualiser |
| `ydotool`, `wtype` | Virtual input |
| `tesseract` | OCR from a screenshot |
| `nwg-displays` | Monitor layout editor, writes `~/.config/hypr/monitors.lua` |
| `uv` | Builds the Python venv end-4's tooling needs |

**Terminal**

| Package | Role |
|---|---|
| `kitty` | Terminal emulator |
| `zsh` + Oh My Zsh | Shell |
| `starship` | Prompt |
| `fastfetch` | System summary on terminal start |
| `eza`, `ripgrep`, `jq` | Everyday CLI tools |

**Theming**

| Package | Role |
|---|---|
| `darkly-bin`, `breeze-plus` | Qt/KDE widget style |
| `adw-gtk-theme-git` | GTK theme |
| `bibata-cursor-theme-bin` | Cursor |
| `ttf-firacode-nerd`, `ttf-jetbrains-mono-nerd`, `otf-space-grotesk`, `ttf-material-symbols-variable` | Fonts and icons |

**Apps**

`firefox`, `google-chrome`, `zen-browser-bin`, `visual-studio-code-bin`,
`discord`, `spotify` (+ `spicetify-cli` for the graphite theme), `dolphin`,
`dbeaver`, `filezilla`, `forticlient-vpn`.

## Keyboard shortcuts

`SUPER + /` opens the full cheatsheet in the shell. The main ones:

**Apps**

| Shortcut | Action |
|---|---|
| `SUPER + Return` | Terminal (kitty) |
| `SUPER + W` | Browser (Chrome) |
| `SUPER + E` | File manager (Dolphin) |
| `SUPER + C` | Code editor (VS Code) |
| `SUPER + I` | Settings panel |
| `CTRL + SHIFT + Escape` | Task manager |
| `CTRL + SUPER + V` | Volume mixer |

**Windows**

| Shortcut | Action |
|---|---|
| `SUPER + Q` | Close window |
| `SUPER + ←↑→↓` | Focus window in that direction |
| `SUPER + SHIFT + ←↑→↓` | Move window in that direction |
| `SUPER + F` | Fullscreen |
| `SUPER + D` | Maximize |
| `SUPER + ALT + Space` | Float / tile |
| `SUPER + P` | Pin |
| `SUPER + drag` | Move window (`SUPER + right-drag` to resize) |

**Workspaces**

| Shortcut | Action |
|---|---|
| `SUPER + 1..0` | Go to workspace |
| `SUPER + ALT + 1..0` | Send window to workspace |
| `CTRL + SUPER + ←/→` | Previous / next workspace |
| `SUPER + scroll` | Previous / next workspace |
| `SUPER + S` | Toggle scratchpad (`SUPER + ALT + S` sends the window there) |
| `SUPER + Tab` | Overview |

**Shell**

| Shortcut | Action |
|---|---|
| `SUPER` (tap) | Search / launcher |
| `SUPER + /` | Cheatsheet |
| `SUPER + N` | Right sidebar (notifications) |
| `SUPER + V` | Clipboard history |
| `SUPER + .` | Emoji picker |
| `SUPER + M` | Media controls |
| `SUPER + J` | Show / hide the bar |
| `CTRL + SUPER + T` | Change wallpaper (`+ ALT` for a random one) |
| `CTRL + SUPER + R` | Restart the shell |
| `CTRL + ALT + Delete` | Session menu |

**Utilities**

| Shortcut | Action |
|---|---|
| `SUPER + SHIFT + S` | Region screenshot to clipboard |
| `Print` | Full screenshot to clipboard (`CTRL + Print` also saves a file) |
| `SUPER + SHIFT + R` | Record a region (`SUPER + SHIFT + ALT + R` full screen with sound) |
| `SUPER + SHIFT + C` | Colour picker |
| `SUPER + SHIFT + X` | OCR the screen to clipboard |
| `SUPER + SHIFT + T` | Translate what is on screen |
| `SUPER + SHIFT + A` | Search a region with Google Lens |
| `SUPER + -` / `SUPER + =` | Zoom out / in |

**Session and media**

| Shortcut | Action |
|---|---|
| `SUPER + L` | Lock |
| `SUPER + SHIFT + L` | Suspend |
| `SUPER + SHIFT + P` | Play / pause |
| `SUPER + SHIFT + N` / `SUPER + SHIFT + B` | Next / previous track |
| `SUPER + SHIFT + M` | Mute (`SUPER + ALT + M` for the mic) |

Add your own in `config/hypr/.config/hypr/custom/keybinds.lua`; that file is
loaded last, so it wins over the defaults.

## Colors

The palette follows the wallpaper. Picking a wallpaper or a scheme in the
quickshell settings runs `scripts/colors/switchwall.sh`, which regenerates the
Material You colors and writes a kitty palette to
`~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf`, then
reloads kitty in place. `kitty.conf` includes that file after `theme.conf`, so
the graphite palette in `theme.conf` is the base and the generated colors
override it; comment the include out to pin kitty to graphite.

The generated ANSI colors start from the graphite palette (it seeds
`scripts/colors/terminal/scheme-base.json`) and are blended toward the
wallpaper accent. How far is controlled by `harmony` and `termFgBoost` under
`appearance.wallpaperTheming.terminalGenerationProps`; picking the monochrome
scheme skips the blend entirely and gives back graphite as-is.

## Repository layout

| Directory | Contents |
|---|---|
| `config/` | One directory per config; each mirrors `$HOME` and is copied there |
| `packages/` | The pacman and AUR package lists |
| `scripts/` | The install steps |
| `sddm/` | The login screen theme |
| `vendor/` | Files taken from end-4 that the scripts use: the `kdeglobals` base and the Python requirements |