#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Post-install"

if [[ ! -f "$HOME/.config/hypr/monitors.conf" ]]; then
    log_info "Seeding ~/.config/hypr/monitors.conf (edit with nwg-displays)"
    run mkdir -p "$HOME/.config/hypr"
    if [[ "$DRY_RUN" != "1" ]]; then
        printf '# Written by nwg-displays (SUPER+SHIFT+D). Machine-local.\nmonitor = , preferred, auto, 1\n' \
            > "$HOME/.config/hypr/monitors.conf"
    fi
fi

if [[ ! -f "$HOME/.config/hypr/workspaces.conf" ]]; then
    log_info "Seeding ~/.config/hypr/workspaces.conf (edit with nwg-displays)"
    if [[ "$DRY_RUN" != "1" ]]; then
        printf '# Written by nwg-displays (SUPER+SHIFT+D). Machine-local.\n' \
            > "$HOME/.config/hypr/workspaces.conf"
    fi
fi

run fc-cache -f

# --keep-zshrc est indispensable : sans lui KEEP_ZSHRC vaut "no" et
# l'installeur remplace ~/.zshrc par son propre modele. A ce stade c'est
# deja un lien stow, il serait donc casse et le prompt starship perdu.
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh"
    run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) \"\" --unattended --keep-zshrc"
fi

if [[ "$SHELL" != */zsh ]]; then
    log_info "Setting zsh as the default shell"
    run chsh -s "$(command -v zsh)" "$USER"
fi

# Spicetify patche le client Spotify dans /opt/spotify, qui appartient a
# root. On prend possession du dossier plutot que le chmod a+wr conseille
# par la doc : inscriptible par le seul utilisateur suffit, et evite un
# dossier inscriptible par tout le monde.
if command -v spicetify >/dev/null 2>&1 && [[ -d /opt/spotify ]]; then
    if [[ ! -w /opt/spotify ]]; then
        log_info "Taking ownership of /opt/spotify for spicetify"
        run sudo chown -R "$USER":"$USER" /opt/spotify
    fi
    log_info "Applying the graphite Spicetify theme"
    run spicetify config current_theme graphite color_scheme graphite
    run spicetify backup apply
    log_warn "Re-run 'spicetify apply' after each Spotify update: the patch is undone by it."
fi

if ! id -nG "$USER" | grep -qw video; then
    log_info "Adding $USER to the 'video' group (needed for brightnessctl)"
    run sudo usermod -aG video "$USER"
    log_warn "Log out and back in for the new group membership to take effect."
fi

cat <<'EOF'

==================================================================
 Hyprland is installed. SDDM (scripts/40-sddm.sh) is the display
 manager — log in and pick the "Hyprland" session if prompted.

 - Toggle the cava audio visualizer widget with SUPER + V.
 - Open the launcher with SUPER + R, lock the screen with
   SUPER + L.

 See README.md for the full keybind list and how to restow a
 single package after editing it.
==================================================================
EOF
