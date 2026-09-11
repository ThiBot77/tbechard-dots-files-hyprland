#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEEP="${KEEP:-2}"
JOURNAL_SIZE="${JOURNAL_SIZE:-200M}"
DRY=0
ASSUME_YES=0
SHOW_UNTRACKED=0

ok()   { printf '\033[32m[ ok ]\033[0m %s\n' "$1"; }
skip() { printf '\033[90m[ -- ]\033[0m %s\n' "$1"; }
warn() { printf '\033[33m[ ?? ]\033[0m %s\n' "$1"; }
die()  { printf '\033[31m[ !! ]\033[0m %s\n' "$1" >&2; exit 1; }
head_() { printf '\n\033[36m== %s\033[0m\n' "$1"; }

usage() {
    cat <<EOF
Usage: ${0##*/} [-n|--dry-run] [-y|--yes] [--untracked]

  -n, --dry-run   Report what would be removed, change nothing
  -y, --yes       Do not ask, run every step
      --untracked List the explicit packages absent from packages/*.txt
  -h, --help      This text

Env: KEEP=$KEEP (cached versions per package), JOURNAL_SIZE=$JOURNAL_SIZE
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY=1 ;;
        -y|--yes)     ASSUME_YES=1 ;;
        --untracked)  SHOW_UNTRACKED=1 ;;
        -h|--help)    usage; exit 0 ;;
        *)            usage >&2; die "Unknown argument: $1" ;;
    esac
    shift
done

confirm() {
    [ "$DRY" = "1" ] && return 1
    [ "$ASSUME_YES" = "1" ] && return 0
    local answer
    read -r -p "  $1 [y/N] " answer </dev/tty || return 1
    case "$answer" in [yYoO]*) return 0 ;; *) return 1 ;; esac
}

command -v pacman >/dev/null || die "pacman missing, this is not the Arch machine"
[ "$DRY" = "1" ] && warn "Dry run, nothing will be removed"

USED_BEFORE="$(df -P / | awk 'NR==2{print $3}')"

# --- Orphans ------------------------------------------------------------------
head_ "Orphan packages"
KEEPFILE="$REPO/packages/keep-orphans.txt"
ROUND=0
while :; do
    mapfile -t ORPHANS < <(
        if [ -f "$KEEPFILE" ]; then
            pacman -Qtdq 2>/dev/null | grep -vxF -f <(grep -vE '^\s*(#|$)' "$KEEPFILE") || true
        else
            pacman -Qtdq 2>/dev/null || true
        fi
    )
    [ ${#ORPHANS[@]} -eq 0 ] && break
    printf '  %s\n' "${ORPHANS[*]}"
    if ! confirm "Remove these ${#ORPHANS[@]} orphan(s)?"; then
        skip "Orphans kept"
        break
    fi
    sudo pacman -Rns --noconfirm "${ORPHANS[@]}"
    ROUND=$((ROUND + 1))
    [ "$ROUND" -ge 10 ] && { warn "Still orphans after 10 rounds, stopping"; break; }
done
[ ${#ORPHANS[@]} -eq 0 ] && [ "$ROUND" = "0" ] && skip "No orphan package"
[ "$ROUND" -gt 0 ] && ok "Orphans removed in $ROUND round(s)"

# --- Untracked explicit packages ---------------------------------------------
head_ "Explicit packages missing from packages/*.txt"
if [ ! -f "$REPO/packages/pacman.txt" ]; then
    skip "packages/pacman.txt missing"
else
    TRACKED="$(mktemp)"; trap 'rm -f "$TRACKED"' EXIT
    grep -hvE '^\s*(#|$)' "$REPO/packages/pacman.txt" "$REPO/packages/aur.txt" 2>/dev/null | sort -u > "$TRACKED"
    UNTRACKED="$(comm -23 <(pacman -Qqe | sort -u) "$TRACKED" | grep -vxF -f <(pacman -Qqg base base-devel 2>/dev/null | sort -u) || true)"
    if [ -z "$UNTRACKED" ]; then
        skip "Every explicit package is tracked"
    elif [ "$SHOW_UNTRACKED" = "1" ]; then
        printf '  %s\n' $UNTRACKED
        warn "Add them to packages/*.txt or remove them by hand, nothing done here"
    else
        warn "$(printf '%s\n' $UNTRACKED | wc -l) untracked, list them with --untracked"
    fi
fi

# --- Pacman cache -------------------------------------------------------------
head_ "Pacman cache"
if ! command -v paccache >/dev/null; then
    skip "paccache missing, install pacman-contrib"
else
    paccache -dk"$KEEP" || true
    paccache -duk0 || true
    if confirm "Trim the cache to $KEEP version(s) and drop uninstalled packages?"; then
        sudo paccache -rk"$KEEP" >/dev/null
        sudo paccache -ruk0 >/dev/null
        ok "Pacman cache trimmed"
    else
        skip "Pacman cache kept"
    fi
fi

# --- AUR build cache ----------------------------------------------------------
head_ "AUR build cache"
YAY_CACHE="$HOME/.cache/yay"
if [ ! -d "$YAY_CACHE" ] || [ -z "$(ls -A "$YAY_CACHE" 2>/dev/null)" ]; then
    skip "No yay build cache"
else
    echo "  $YAY_CACHE: $(du -sh "$YAY_CACHE" | cut -f1)"
    if confirm "Clear the yay build directories?"; then
        rm -rf -- "${YAY_CACHE:?}"/*
        ok "yay build cache cleared"
    else
        skip "yay build cache kept"
    fi
fi

# --- Flatpak ------------------------------------------------------------------
head_ "Flatpak runtimes"
if ! command -v flatpak >/dev/null; then
    skip "flatpak missing"
elif [ -z "$(flatpak list --app --columns=application 2>/dev/null)" ]; then
    skip "No flatpak application installed"
else
    flatpak uninstall --unused --dry-run 2>/dev/null || true
    if confirm "Remove the unused flatpak runtimes?"; then
        flatpak uninstall --unused -y
        ok "Unused flatpak runtimes removed"
    else
        skip "Flatpak runtimes kept"
    fi
fi

# --- Journal ------------------------------------------------------------------
head_ "systemd journal"
if ! command -v journalctl >/dev/null; then
    skip "journalctl missing"
else
    echo "  current: $(journalctl --disk-usage 2>/dev/null | sed 's/^.*take up //')"
    if confirm "Vacuum the journal down to $JOURNAL_SIZE?"; then
        sudo journalctl --vacuum-size="$JOURNAL_SIZE" >/dev/null 2>&1
        ok "Journal vacuumed to $JOURNAL_SIZE"
    else
        skip "Journal kept"
    fi
fi

# --- Config leftovers ---------------------------------------------------------
head_ ".pacnew / .pacsave files"
if ! command -v pacdiff >/dev/null; then
    skip "pacdiff missing, install pacman-contrib"
else
    LEFTOVERS="$(pacdiff -o 2>/dev/null || true)"
    if [ -z "$LEFTOVERS" ]; then
        skip "No leftover config file"
    else
        printf '  %s\n' $LEFTOVERS
        warn "Merge them yourself with: sudo -E DIFFPROG=nvim pacdiff"
    fi
fi

# --- Total --------------------------------------------------------------------
USED_AFTER="$(df -P / | awk 'NR==2{print $3}')"
FREED=$(( (USED_BEFORE - USED_AFTER) ))
if [ "$FREED" -gt 0 ]; then
    printf '\n'; ok "About $(numfmt --to=iec --from-unit=1024 "$FREED") freed on /"
else
    printf '\n'; skip "Nothing freed on /"
fi
