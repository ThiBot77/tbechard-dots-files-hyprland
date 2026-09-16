# tbechard dotfiles — Arch / Hyprland

My desktop setup: Hyprland, Noctalia shell, SDDM, zsh.

## Install

```bash
./post-install.sh
```

Installs the packages listed in `packages/`, deploys everything under `config/`
to its real destination, and sets up the SDDM greeter, the Tela icons and the
XDG portals. Existing files are backed up with a timestamp before being
replaced, and the script skips whatever is already up to date.

## Layout

| | |
|---|---|
| `config/` | one directory per tool, copied to its destination by the script |
| `packages/` | pacman and AUR package lists |
| `certs/` | the Arcacloud root CA |
| `sddm/` | greeter theme and configuration |
| `post-install.sh` | deploys everything |
| `cleanup-packages.sh` | removes packages absent from the lists |
| `monitors.sh` | applies the monitor layout |

## Not in here

SSH and GPG private keys are deliberately excluded. Copy them across by hand.
