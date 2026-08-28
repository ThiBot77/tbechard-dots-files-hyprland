#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$REPO_DIR/config"
source "$SCRIPT_DIR/lib/common.sh"

BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)}"

log_step "Moving the configs already on this machine out of the way"

# Directories that only hold other configs: descend into them instead of
# moving the whole thing away.
CONTAINERS=(.config .local .local/share .local/state Images)

is_container() {
    local candidate="$1" container
    for container in "${CONTAINERS[@]}"; do
        [[ "$candidate" == "$container" ]] && return 0
    done
    return 1
}

# Every path, relative to $HOME, that 20-copy-configs.sh is going to write.
collect_targets() {
    local base="$1" rel="${2:-}" path child
    while IFS= read -r -d '' path; do
        child="${rel:+$rel/}$(basename "$path")"
        if [[ -d "$path" ]] && is_container "$child"; then
            collect_targets "$base" "$child"
        else
            printf '%s\n' "$child"
        fi
    done < <(find "$base${rel:+/$rel}" -mindepth 1 -maxdepth 1 -print0)
}

# GNOME session state that means nothing under Hyprland. gtk-3.0/gtk-4.0 are
# in there because matugen regenerates their gtk.css from the wallpaper.
GNOME_STATE=(
    .config/dconf
    .config/gnome-control-center
    .config/gnome-session
    .config/gtk-3.0
    .config/gtk-4.0
    .config/monitors.xml
    .local/share/gnome-shell
    .local/share/gnome-settings-daemon
)

targets=()
for package_dir in "$CONFIG_DIR"/*/; do
    while IFS= read -r target; do
        targets+=("$target")
    done < <(collect_targets "${package_dir%/}")
done
targets+=("${GNOME_STATE[@]}")

mapfile -t targets < <(printf '%s\n' "${targets[@]}" | sort -u)

moved=0
for target in "${targets[@]}"; do
    [[ -e "$HOME/$target" || -L "$HOME/$target" ]] || continue
    log_info "$target"
    run mkdir -p "$BACKUP_DIR/$(dirname "$target")"
    run mv "$HOME/$target" "$BACKUP_DIR/$target"
    moved=$((moved + 1))
done

if [[ "$moved" -eq 0 ]]; then
    log_info "Nothing to back up."
else
    log_info "$moved entries moved to $BACKUP_DIR"
    log_warn "Nothing was deleted: restore with 'mv $BACKUP_DIR/<path> ~/<path>'."
fi
