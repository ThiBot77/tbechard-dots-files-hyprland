#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ASSUME_YES="${ASSUME_YES:-0}"
KEEP_EXTRA="${KEEP_EXTRA:-}"

log_step "Removing GNOME"

# GNOME packages that are in neither the gnome nor the gnome-extra group.
EXTRA_GNOME=(
    gdm
    gnome-browser-connector
    gnome-shell-extensions
    xdg-desktop-portal-gnome
)

# Shared plumbing that stays: switchwall.sh drives the GTK theme and the
# light/dark mode through gsettings, which needs dconf and the schemas, and
# gvfs is what GTK file dialogs mount remote shares with.
KEEP_ALWAYS=(
    adwaita-cursors
    adwaita-fonts
    adwaita-icon-theme
    dconf
    glib2
    gnome-keyring
    gsettings-desktop-schemas
    gtk3
    gtk4
    gvfs
    libadwaita
    xdg-user-dirs
)

read_list() {
    grep -vE '^\s*(#|$)' "$1"
}

mapfile -t keep < <(
    {
        read_list "$REPO_DIR/packages/pacman.txt"
        read_list "$REPO_DIR/packages/aur.txt"
        printf '%s\n' "${KEEP_ALWAYS[@]}"
        tr ',' '\n' <<< "$KEEP_EXTRA"
    } | tr -d '[:blank:]' | grep -v '^$' | sort -u
)

mapfile -t candidates < <(
    {
        pacman -Sg gnome gnome-extra 2>/dev/null | awk '{print $2}'
        printf '%s\n' "${EXTRA_GNOME[@]}"
    } | sort -u
)

mapfile -t to_remove < <(
    comm -12 <(printf '%s\n' "${candidates[@]}") <(pacman -Qq | sort -u) \
        | comm -23 - <(printf '%s\n' "${keep[@]}")
)

if systemctl is-enabled gdm >/dev/null 2>&1; then
    log_info "Disabling gdm — SDDM takes over at the last step"
    run sudo systemctl disable gdm
fi

if [[ "${#to_remove[@]}" -eq 0 ]]; then
    log_info "No GNOME package left to remove."
    exit 0
fi

log_warn "${#to_remove[@]} packages are about to be removed with pacman -Rns:"
printf '%s\n' "${to_remove[@]}" | tr '\n' ' ' | fmt -w 74 | sed 's/^/    /'
log_warn "Spare one with --keep=pkg1,pkg2 if you still want it."

if [[ "$ASSUME_YES" != "1" && "$DRY_RUN" != "1" ]]; then
    read -rp "$(_color 33 '[?]')      Continue? [y/N] " answer
    if [[ ! "$answer" =~ ^[yY] ]]; then
        log_error "Aborted. The packages from packages/ are already installed;"
        log_error "run scripts/20-copy-configs.sh yourself to keep going."
        exit 1
    fi
fi

if ! run sudo pacman -Rns --noconfirm "${to_remove[@]}"; then
    log_warn "Removing them in one go failed — retrying one package at a time."
    for package in "${to_remove[@]}"; do
        pacman -Qq "$package" >/dev/null 2>&1 || continue
        if ! run sudo pacman -Rns --noconfirm "$package"; then
            log_warn "Kept $package: something still depends on it."
        fi
    done
fi

log_info "GNOME removed. 'pacman -Qdtq' lists the orphans left behind, if any."
