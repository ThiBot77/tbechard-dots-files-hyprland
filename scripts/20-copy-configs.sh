#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$REPO_DIR/config"

source "$SCRIPT_DIR/lib/common.sh"

log_step "Installing dotfiles"

if [[ $# -gt 0 ]]; then
    packages=("$@")
    for package in "${packages[@]}"; do
        if [[ ! -d "$CONFIG_DIR/$package" ]]; then
            log_error "Unknown package: $package"
            exit 1
        fi
    done
else
    packages=()
    for package_dir in "$CONFIG_DIR"/*/; do
        packages+=("$(basename "$package_dir")")
    done
fi

for package in "${packages[@]}"; do
    log_info "Installing: $package"
    run cp -a "$CONFIG_DIR/$package/." "$HOME/"
done

log_info "Done."
