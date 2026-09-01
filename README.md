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

The installer runs six steps, in order:

| Step | What it does |
|---|---|
| `scripts/00-check-system.sh` | Checks it is Arch, installs `yay` if missing |
| `scripts/05-ca-certs.sh` | Adds every certificate in `certs/` to the system trust store |
| `scripts/10-install-packages.sh` | Upgrades the system and installs everything in `packages/pacman.txt` and `packages/aur.txt`, minus `packages/ignore.txt` |
| `scripts/20-copy-configs.sh` | Copies each package in `config/` into `$HOME` |
| `scripts/30-post-install.sh` | Oh My Zsh, Python venv, spicetify, user groups |
| `scripts/40-sddm.sh` | Installs and enables the SDDM login theme |

### On a machine that already runs GNOME

`install.sh` assumes a bare Arch install. If the machine already has a GNOME
desktop and configs of its own, use the migration script instead:

```sh
./migrate-from-gnome.sh          # --dry-run to see what it would do first
```

Run it **from a TTY** (`Ctrl+Alt+F3`): it removes gnome-shell, which the
graphical session you are looking at is made of. **Reboot** when it is done —
here a logout is not enough, the login screen itself changes from GDM to SDDM.

| Step | What it does |
|---|---|
| `scripts/00-check-system.sh` | Same as above |
| `scripts/migrate-backup-configs.sh` | Moves every config this repo is about to write, plus the GNOME session state, into `~/.dotfiles-backup-<date>` |
| `scripts/10-install-packages.sh` | Same as above — before the removal, so a failure here leaves GNOME intact |
| `scripts/migrate-remove-gnome.sh` | Disables GDM, then `pacman -Rns` on the `gnome` and `gnome-extra` groups |
| `scripts/20…40` | Same as above |

Nothing is deleted from `$HOME`: the old kitty, fastfetch and `.zshrc` are
moved, not overwritten, and `~/.config/dconf` goes with them. Move a file back
out of the backup directory to get it back.

The package removal prints its list and asks before running. Options:

| Option | Effect |
|---|---|
| `--dry-run` | Print every command instead of running it |
| `-y`, `--yes` | Do not ask before removing |
| `--keep=pkg1,pkg2` | Keep those packages — e.g. `--keep=gnome-calculator,gnome-disk-utility` |
| `--keep-gnome` | Back up and install, but leave GNOME alone |

Everything in `packages/` is kept automatically, and so is the plumbing the
shell needs: `dconf` and `gsettings-desktop-schemas` (the palette script sets
the GTK theme through `gsettings`), `gnome-keyring`, and `gvfs`.

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

## Login screen

The greeter is [Sugar Candy](https://github.com/MarianArlt/sddm-sugar-candy)
by Marian Arlt (GPL-3.0), vendored in `sddm/theme/` and recoloured graphite.
Two changes were needed beyond `theme.conf`:

- The imports were ported to Qt6. Upstream is a Qt5 theme and pulls in
  `QtGraphicalEffects`, which no longer exists; on a Qt6 SDDM it fails to load
  and the greeter silently falls back to the default one. It is now
  `Qt5Compat.GraphicalEffects`, from `qt6-5compat` in `packages/pacman.txt`.
- The sample backgrounds were dropped for a single `backgrounds/graphite.jpg`.

Everything else lives in `sddm/theme/theme.conf`, which carries the palette
duplicated from `config/kitty/.config/kitty/theme.conf` — the greeter runs
before any user session, so it cannot read anything under `$HOME`.

The background is the rice wallpaper, desaturated. Regenerate it after
changing wallpaper, at exactly the resolution in `ScreenWidth`/`ScreenHeight`
(the theme scales its layout off the image, so a different size shrinks the
form):

```sh
magick ~/.config/quickshell/ii/assets/images/default_wallpaper.png \
    -resize 1920x1080^ -gravity center -extent 1920x1080 \
    -colorspace Gray -colorspace sRGB -quality 92 \
    sddm/theme/backgrounds/graphite.jpg
```

Preview it without installing, and without logging out:

```sh
sddm-greeter-qt6 --test-mode --theme "$PWD/sddm/theme"
```

`scripts/40-sddm.sh` installs the theme to `/usr/share/sddm/themes/tbe`. It
also disables any other file in `/etc/sddm.conf.d/` that sets a theme: that
directory is read in alphabetical order and the last `Current=` wins, so one
left behind by another rice overrides ours without a word.

## Colors

The palette follows the wallpaper. Picking a wallpaper or a scheme in the
quickshell settings runs `scripts/colors/switchwall.sh`, which regenerates the
Material You colors and writes a kitty palette to
`~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf`, then
reloads kitty in place. `kitty.conf` includes that file after `theme.conf`, so
the graphite palette in `theme.conf` is the base and the generated colors
override it; comment the include out to pin kitty to graphite.

The prompt and fastfetch ride along. `starship.toml` styles its segments with
palette indexes (255 primary, 254 primaryContainer, 252 secondaryContainer,
251 tertiary, 249 error) rather than hex, and quickshell rewrites exactly those
slots, so the prompt takes the accent with no value duplicated. fastfetch is
started by `.zshrc` with `--color` read from
`~/.local/state/quickshell/user/generated/terminal/accent`, which
`applycolor.sh` fills with the primary color, falling back to the static accent
in `~/.config/fastfetch/accent`.

The generated ANSI colors start from the graphite palette (it seeds
`scripts/colors/terminal/scheme-base.json`) and are blended toward the
wallpaper accent. How far is controlled by `harmony` and `termFgBoost` under
`appearance.wallpaperTheming.terminalGenerationProps`; picking the monochrome
scheme skips the blend entirely and gives back graphite as-is.

## Repository layout

| Directory | Contents |
|---|---|
| `config/` | One directory per config; each mirrors `$HOME` and is copied there |
| `certs/` | Internal CA certificates the system must trust |
| `packages/` | The pacman and AUR package lists, plus the AUR packages yay must leave alone |
| `scripts/` | The install steps |
| `sddm/` | The login screen theme |
| `vendor/` | Files taken from end-4 that the scripts use: the `kdeglobals` base and the Python requirements |