#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Post-install"

run chmod +x "$HOME/.local/bin/toggle-cava-widget.sh"

run fc-cache -f

if ! id -nG "$USER" | grep -qw video; then
    log_info "Adding $USER to the 'video' group (needed for brightnessctl)"
    run sudo usermod -aG video "$USER"
    log_warn "Log out and back in for the new group membership to take effect."
fi

cat <<'EOF'

==================================================================
 Hyprland is installed alongside GNOME.

 - Log out, and on the GDM login screen pick the "Hyprland"
   session from the gear/session menu next to the password field.
 - GNOME remains the default and untouched.
 - Toggle the cava audio visualizer widget with SUPER + V.
 - Open the launcher with SUPER + R, lock the screen with
   SUPER + L.

 See README.md for the full keybind list and how to restow a
 single package after editing it.
==================================================================
EOF
