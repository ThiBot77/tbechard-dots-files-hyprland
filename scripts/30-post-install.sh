#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Post-install"

run chmod +x "$HOME/.local/bin/toggle-cava-widget.sh" "$HOME/.local/bin/set-wallpaper.sh"

run fc-cache -f

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh"
    run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) \"\" --unattended"
fi

if [[ "$SHELL" != */zsh ]]; then
    log_info "Setting zsh as the default shell"
    run chsh -s "$(command -v zsh)" "$USER"
fi

if ! id -nG "$USER" | grep -qw video; then
    log_info "Adding $USER to the 'video' group (needed for brightnessctl)"
    run sudo usermod -aG video "$USER"
    log_warn "Log out and back in for the new group membership to take effect."
fi

cat <<'EOF'

==================================================================
 Hyprland is installed

 See README.md for the full keybind list and how to restow a
 single package after editing it.
==================================================================
EOF
