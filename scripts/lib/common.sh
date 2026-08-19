#!/usr/bin/env bash
# Shared helpers sourced by every scripts/*.sh step.

DRY_RUN="${DRY_RUN:-0}"

_color() { printf '\033[%sm%s\033[0m' "$1" "$2"; }

log_info()  { echo "$(_color 36 '[info]')  $*"; }
log_warn()  { echo "$(_color 33 '[warn]')  $*"; }
log_error() { echo "$(_color 31 '[error]') $*" >&2; }
log_step()  { echo; echo "$(_color 35 '==>') $(_color 1 "$*")"; }

# Run a command, or just print it under --dry-run.
run() {
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "  $ $*"
    else
        "$@"
    fi
}

confirm() {
    local prompt="${1:-Continue?}"
    local reply
    read -r -p "$prompt [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

# Move an existing real file/dir out of the way before stow creates a symlink
# there. Leaves already-correct symlinks alone (including files that are only
# reachable *through* an already-symlinked ancestor directory — e.g. once
# `~/.config/waybar` itself is a symlink into the repo, every file under it
# resolves into $STOW_DIR even though the file itself isn't a symlink; back
# it up anyway and you're moving the repo's own file out from under it).
# No-op if nothing exists.
backup_if_exists() {
    local target="$1"
    local backup_dir="$2"

    if [[ -e "$target" || -L "$target" ]]; then
        local resolved
        resolved="$(readlink -f "$target" 2>/dev/null || true)"
        if [[ -n "$resolved" && -n "${STOW_DIR:-}" && "$resolved" == "$STOW_DIR"/* ]]; then
            return 0
        fi

        local rel="${target#"$HOME"/}"
        local dest="$backup_dir/$rel"
        log_warn "backing up existing $target -> $dest"
        run mkdir -p "$(dirname "$dest")"
        run mv "$target" "$dest"
    fi
}
