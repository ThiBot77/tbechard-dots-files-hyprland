#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Checking system requirements"

if [[ "$EUID" -eq 0 ]]; then
    log_error "Do not run this script as root. It will call sudo itself when needed."
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    log_error "pacman not found — this installer targets Arch Linux only."
    exit 1
fi

if ! command -v yay >/dev/null 2>&1; then
    log_info "yay not found — bootstrapping it from the AUR (yay-bin)."
    run sudo pacman -S --needed --noconfirm base-devel git

    tmp_dir="$(mktemp -d)"
    run git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin"
    if [[ "$DRY_RUN" != "1" ]]; then
        (cd "$tmp_dir/yay-bin" && makepkg -si --noconfirm)
    else
        echo "  $ (cd $tmp_dir/yay-bin && makepkg -si --noconfirm)"
    fi
    run rm -rf "$tmp_dir"
fi

log_info "Arch Linux + yay detected. OK."
