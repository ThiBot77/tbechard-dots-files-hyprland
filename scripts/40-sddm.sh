#!/usr/bin/env bash
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

if ! systemctl is-enabled sddm >/dev/null 2>&1; then
    run sudo systemctl enable sddm
fi

log_info "SDDM enabled."
