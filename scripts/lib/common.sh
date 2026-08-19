#!/usr/bin/env bash
# Shared helpers sourced by every scripts/*.sh step.

DRY_RUN="${DRY_RUN:-0}"

_color() { printf '\033[%sm%s\033[0m' "$1" "$2"; }

log_info()  { echo "$(_color 36 '[info]')  $*"; }
log_warn()  { echo "$(_color 33 '[warn]')  $*"; }
log_error() { echo "$(_color 31 '[error]') $*" >&2; }
log_step()  { echo; echo "$(_color 35 '==>') $(_color 1 "$*")"; }

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
