#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: ./migrate-from-gnome.sh [options]

Installs these dotfiles on an Arch machine that already runs GNOME: the
configs already in $HOME are moved aside, GNOME and GDM are removed, then
the regular install steps run.

Options:
  --dry-run          Print every command instead of running it
  -y, --yes          Do not ask before removing the GNOME packages
  --keep=pkg1,pkg2   Keep these packages instead of removing them
                     (e.g. --keep=gnome-calculator,gnome-disk-utility)
  --keep-gnome       Skip the removal entirely, only back up and install
  -h, --help         This message
EOF
}

ASSUME_YES=0
KEEP_EXTRA=""
KEEP_GNOME=0

for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=1 ;;
        -y|--yes)    ASSUME_YES=1 ;;
        --keep=*)    KEEP_EXTRA="${arg#--keep=}" ;;
        --keep-gnome) KEEP_GNOME=1 ;;
        -h|--help)   usage; exit 0 ;;
        *)           log_error "Unknown option: $arg"; usage; exit 1 ;;
    esac
done

export DRY_RUN ASSUME_YES KEEP_EXTRA
export BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)}"

if [[ "$KEEP_GNOME" != "1" && "$DRY_RUN" != "1" ]] \
   && [[ "${XDG_CURRENT_DESKTOP:-}" == *GNOME* ]]; then
    log_warn "You are running this from inside a GNOME session."
    log_warn "gnome-shell is about to be removed from under it: the session will"
    log_warn "misbehave until you reboot, and anything unsaved goes with it."
    log_warn "A TTY (Ctrl+Alt+F3) is the safe place to run this."
    if [[ "$ASSUME_YES" != "1" ]]; then
        read -rp "$(_color 33 '[?]')      Continue anyway? [y/N] " answer
        [[ "$answer" =~ ^[yY] ]] || exit 1
    fi
fi

# Packages first: if that step fails, the machine still has a working GNOME.
bash "$SCRIPT_DIR/scripts/00-check-system.sh"
bash "$SCRIPT_DIR/scripts/migrate-backup-configs.sh"
bash "$SCRIPT_DIR/scripts/10-install-packages.sh"
if [[ "$KEEP_GNOME" != "1" ]]; then
    bash "$SCRIPT_DIR/scripts/migrate-remove-gnome.sh"
fi
bash "$SCRIPT_DIR/scripts/20-copy-configs.sh"
bash "$SCRIPT_DIR/scripts/30-post-install.sh"
bash "$SCRIPT_DIR/scripts/40-sddm.sh"

cat <<EOF

==================================================================
 Migration GNOME -> Hyprland terminee.

 - Redemarre : GDM a ete desactive au profit de SDDM, et les
   paquets GNOME ont ete retires sous la session en cours.
 - Choisis "Hyprland" dans le selecteur de session de SDDM.
 - Tes anciennes confs (kitty, fastfetch, .zshrc, etat GNOME...)
   sont dans $BACKUP_DIR
   Rien n'a ete supprime : deplace ce que tu veux recuperer
   depuis ce dossier vers ~/.
==================================================================
EOF
