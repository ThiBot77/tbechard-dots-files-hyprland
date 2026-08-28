#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Installing packages"

read_list() {
    grep -vE '^\s*(#|$)' "$1"
}

mapfile -t PACMAN_PKGS < <(read_list "$REPO_DIR/packages/pacman.txt")
mapfile -t AUR_PKGS < <(read_list "$REPO_DIR/packages/aur.txt")

# -Syu, not -S: installing today's packages onto a system that is a few
# updates behind is a partial upgrade, and pacman refuses it as soon as one
# of the new dependencies has a newer soname than an installed package.
log_info "Official repo packages: ${PACMAN_PKGS[*]}"
log_info "Upgrading the whole system in the same transaction."
run sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"

mapfile -t IGNORED < <(read_list "$REPO_DIR/packages/ignore.txt")
yay_args=(-S --needed --noconfirm)
for package in "${IGNORED[@]}"; do
    yay_args+=(--ignore "$package")
done

log_info "AUR packages: ${AUR_PKGS[*]}"
if [[ "${#IGNORED[@]}" -gt 0 ]]; then
    log_info "Left alone: ${IGNORED[*]}"
fi
run yay "${yay_args[@]}" "${AUR_PKGS[@]}"
