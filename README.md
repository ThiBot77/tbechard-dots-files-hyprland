# tbe-dots-files

Hyprland setup for Arch Linux.

The shell — bar, notifications, launcher, settings panel, lock screen — is
[end-4's dots-hyprland](https://github.com/end-4/dots-hyprland), vendored here
and installed by `install.sh`. Kitty, zsh, fastfetch and the wallpapers are our
own.

## Install

```sh
git clone <this repo> ~/Documents/tbe-dots-files
cd ~/Documents/tbe-dots-files
./install.sh          # --dry-run to see what it would do
```

Then **log out and back in**: Hyprland only reads its config at startup, and
new user groups apply at session start.

## Layout

Each directory under `config/` is a package: its tree mirrors `$HOME` and is
copied there by the installer.

**Desktop** — `hypr` (Hyprland config, in Lua: `hyprland.lua`, not
`hyprland.conf`; personal overrides go in `custom/*.lua`), `quickshell` (the
shell itself, ~586 QML files), `matugen` (Material You colours derived from the
wallpaper), `portal` (XDG portal choice — needed for screen sharing).

**Themed apps** — `kde`, `kvantum`, `fuzzel`, `wlogout`, `mpv`, `swappy`,
`browsers`, `spicetify`.

**Ours** — `kitty`, `zsh`, `starship`, `fastfetch`, `wallpaper` (installs to
`~/Images/Wallpapers`, where end-4's picker looks for them).

Reinstall a single package after editing it:

```sh
scripts/20-copy-configs.sh quickshell     # no argument installs everything
```

Configs are copied, not symlinked, so an edit in `~/.config` does not reach the
repo: change the file here and re-run the command above. The copy overwrites
whatever is at the target, so back up anything you care about first.

## Palette

The graphite look isn't hardcoded: it's the Material You `scheme-monochrome`
scheme with dark mode forced, set in
`quickshell/ii/modules/common/Config.qml`. Semantic colours (links, success,
error) stay tinted on purpose.

The settings panel (`SUPER + I`) writes to
`~/.config/illogical-impulse/config.json`; the QML files only provide the
first-run defaults.

## Generated files

matugen rewrites `hypr/hyprland/colors.lua`, `hypr/hyprlock/colors.conf` and
`fuzzel/fuzzel_theme.ini` on every wallpaper change. The copies in `config/` are
only the first-run seed; the live ones live in `~/.config` and are never copied
back.

Two more files are seeded outside `config/`, because a reinstall would otherwise
overwrite machine state: `~/.config/kdeglobals` (from
`vendor/end4/kdeglobals.default`, rewritten by kde-material-you-colors) and
`~/.config/hypr/monitors.lua` (nwg-displays).

## Notes

- Part of end-4's tooling lives in a venv at `~/.local/state/quickshell/.venv`
  (`$ILLOGICAL_IMPULSE_VIRTUAL_ENV`), built by `install.sh` with `uv`.
  `kde-material-you-colors` is in there — without it, KDE apps keep their
  default colours.
- **SDDM**: theme in `sddm/`, installed by `scripts/40-sddm.sh`. Its colours are
  duplicated in `sddm/theme/theme.conf` since the greeter runs before any user
  session. Test with `sddm-greeter` (the Qt5 binary actually used), not
  `sddm-greeter-qt6`.
- **Keyboard**: end-4 forces `kb_layout = "us"`; the AZERTY override is in
  `hypr/custom/general.lua`.
- Hyprland regenerates a stub `hyprland.conf` when it finds none, which shadows
  `hyprland.lua`. `install.sh` deletes it.
- **Spotify**: re-run `spicetify apply` after each update.
- end-4's code is GPL-3.0; their licence is kept at the root as `LICENSE-end4`.
