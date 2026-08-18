#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Installing packages"

# Strip comments/blank lines from a package list file.
read_list() {
    grep -vE '^\s*(#|$)' "$1"
}

mapfile -t PACMAN_PKGS < <(read_list "$REPO_DIR/packages/pacman.txt")
mapfile -t AUR_PKGS < <(read_list "$REPO_DIR/packages/aur.txt")

log_info "Official repo packages: ${PACMAN_PKGS[*]}"
run sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

log_info "AUR packages: ${AUR_PKGS[*]}"
run yay -S --needed --noconfirm "${AUR_PKGS[@]}"
