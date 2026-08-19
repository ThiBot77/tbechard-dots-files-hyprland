#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STOW_DIR="$REPO_DIR/stow"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

source "$SCRIPT_DIR/lib/common.sh"

log_step "Stowing dotfiles"

if ! command -v stow >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "GNU Stow not installed yet — it will be after scripts/10-install-packages.sh runs for real."
    else
        log_error "GNU Stow not found — run scripts/10-install-packages.sh first."
        exit 1
    fi
fi

backup_package_targets() {
    local package="$1"
    local package_dir="$STOW_DIR/$package"
    local file
    while IFS= read -r -d '' file; do
        local rel="${file#"$package_dir"/}"
        backup_if_exists "$HOME/$rel" "$BACKUP_DIR"
    done < <(find "$package_dir" -type f -print0)
}

for package_dir in "$STOW_DIR"/*/; do
    package="$(basename "$package_dir")"
    log_info "Preparing package: $package"
    backup_package_targets "$package"
done

if [[ -d "$BACKUP_DIR" ]]; then
    log_warn "Existing configs backed up to $BACKUP_DIR"
fi

for package_dir in "$STOW_DIR"/*/; do
    package="$(basename "$package_dir")"
    log_info "Stowing: $package"
    run stow -d "$STOW_DIR" -t "$HOME" -S "$package"
done

log_info "Done."
