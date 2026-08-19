#!/usr/bin/env bash
# Installs the SDDM greeter theme system-wide.
#
# Deliberately does NOT switch the display manager: a broken greeter locks
# you out of the graphical login, so enabling sddm stays a manual, informed
# step. GDM keeps working until you run the command printed at the end.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "SDDM greeter theme"

if ! command -v sddm >/dev/null 2>&1; then
    log_warn "sddm not installed — skipping (it's in packages/pacman.txt)."
    exit 0
fi

run sudo mkdir -p /usr/share/sddm/themes/tbe /etc/sddm.conf.d
run sudo cp -r "$REPO_DIR/sddm/theme/." /usr/share/sddm/themes/tbe/
run sudo cp "$REPO_DIR/sddm/conf.d/10-tbe.conf" /etc/sddm.conf.d/10-tbe.conf

log_info "Theme installed to /usr/share/sddm/themes/tbe"

if systemctl is-enabled gdm >/dev/null 2>&1; then
    cat <<'EOF'

------------------------------------------------------------------
 SDDM is installed but NOT enabled — GDM is still your login screen.

 Preview it first (safe, runs in a window):
     sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/tbe

 If it looks right, switch over with:
     sudo systemctl disable gdm && sudo systemctl enable sddm

 To go back at any time:
     sudo systemctl disable sddm && sudo systemctl enable gdm
------------------------------------------------------------------
EOF
fi
