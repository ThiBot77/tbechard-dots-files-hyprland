#!/usr/bin/env bash

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
