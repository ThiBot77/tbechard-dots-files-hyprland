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
# there. Leaves already-correct symlinks alone. No-op if nothing exists.
backup_if_exists() {
    local target="$1"
    local backup_dir="$2"

    if [[ -L "$target" ]]; then
        # Already a symlink (likely from a previous run) — let stow handle it.
        return 0
    fi

    if [[ -e "$target" ]]; then
        local rel="${target#"$HOME"/}"
        local dest="$backup_dir/$rel"
        log_warn "backing up existing $target -> $dest"
        run mkdir -p "$(dirname "$dest")"
        run mv "$target" "$dest"
    fi
}
