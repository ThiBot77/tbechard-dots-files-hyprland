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

# Replaced, not merged: the theme has changed its file layout before, and
# copying on top of the previous one leaves the files it dropped behind.
run sudo rm -rf /usr/share/sddm/themes/tbe
run sudo mkdir -p /usr/share/sddm/themes/tbe /etc/sddm.conf.d
run sudo cp -r "$REPO_DIR/sddm/theme/." /usr/share/sddm/themes/tbe/
run sudo cp "$REPO_DIR/sddm/conf.d/10-tbe.conf" /etc/sddm.conf.d/10-tbe.conf

log_info "Theme installed to /usr/share/sddm/themes/tbe"

# /etc/sddm.conf.d is read in alphabetical order and the last [Theme] Current
# wins, so a file another rice left behind silently overrides ours. SDDM only
# reads *.conf, so renaming is enough to disable one, and it stays revertible.
for conf in /etc/sddm.conf.d/*.conf; do
    [[ -e "$conf" ]] || continue
    [[ "$(basename "$conf")" == "10-tbe.conf" ]] && continue
    grep -qE '^[[:space:]]*Current[[:space:]]*=' "$conf" || continue
    log_warn "$(basename "$conf") sets a theme of its own — disabling it"
    run sudo mv "$conf" "$conf.disabled"
done

if ! systemctl is-enabled sddm >/dev/null 2>&1; then
    run sudo systemctl enable sddm
fi

log_info "SDDM enabled."
