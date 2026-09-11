#!/usr/bin/env bash
set -euo pipefail

DRY=1
FALLBACK_SDDM_THEME="maldives"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_THEMES="/usr/share/sddm/themes"
FREED=0

ok()   { printf '\033[32m[ rm ]\033[0m %s\n' "$1"; }
skip() { printf '\033[90m[ -- ]\033[0m %s\n' "$1"; }
warn() { printf '\033[33m[ ?? ]\033[0m %s\n' "$1"; }
head_() { printf '\n\033[36m== %s\033[0m\n' "$1"; }

usage() {
    cat <<EOF
Usage: ${0##*/} [-y|--yes]

  -y, --yes   Actually remove. Without it, nothing is touched.
  -h, --help  This text
EOF
}

case "${1:-}" in
    -y|--yes)  DRY=0 ;;
    -h|--help) usage; exit 0 ;;
    "")        ;;
    *)         usage >&2; printf '\033[31m[ !! ]\033[0m Unknown argument: %s\n' "$1" >&2; exit 1 ;;
esac

[ "$DRY" = "1" ] && warn "Dry run. Nothing is removed. Pass --yes to go through with it."

drop() {
    local path="$1" label="${2:-}"
    [ -e "$path" ] || [ -L "$path" ] || { skip "absent: $path"; return 0; }

    local size
    size="$(du -sh "$path" 2>/dev/null | cut -f1 || echo '?')"
    local bytes
    bytes="$(du -sb "$path" 2>/dev/null | cut -f1 || echo 0)"
    FREED=$((FREED + bytes))

    if [ "$DRY" = "1" ]; then
        ok "$path ($size)${label:+ — $label}"
        return 0
    fi

    if [ -w "$(dirname "$path")" ]; then
        rm -rf -- "$path"
    else
        sudo rm -rf -- "$path"
    fi
    ok "$path ($size)${label:+ — $label}"
}

# --- Serpantinum ------------------------------------------------------------
head_ "Serpantinum"

if [ "$DRY" = "0" ] && pgrep -x serpantinumd >/dev/null; then
    pkill -x serpantinumd || true
    ok "serpantinumd stopped"
fi

drop "$HOME/.local/bin/serpantinum"
drop "$HOME/.local/bin/serpantinumd"
drop "$HOME/.local/share/serpantinum"
drop "$HOME/.config/serpantinum"
drop "$HOME/.local/state/serpantinum"
drop "$HOME/.cache/serpantinum"
drop "$HOME/.cache/serpantinum-installer"
drop "$HOME/.cache/serpantinum-wallpapers"

# --- Hyprland config --------------------------------------------------------
head_ "Hyprland config"

HYPR_DIR="$HOME/.config/hypr"
if [ ! -d "$HYPR_DIR" ]; then
    skip "absent: $HYPR_DIR"
elif ! grep -rqF 'serpantinum' "$HYPR_DIR" 2>/dev/null; then
    skip "$HYPR_DIR does not mention serpantinum"
else
    ASIDE="$HYPR_DIR.avant-noctalia-$(date +%Y%m%d-%H%M%S)"
    if [ "$DRY" = "1" ]; then
        warn "$HYPR_DIR calls serpantinum, would move it to $ASIDE"
    else
        mv "$HYPR_DIR" "$ASIDE"
        warn "$HYPR_DIR moved to $ASIDE, run post-install.sh to get a stock one back"
    fi
fi

# --- Old backups ------------------------------------------------------------
head_ "Old backups"

drop "$HOME/.config/hypr_backup"
shopt -s nullglob
for d in "$HOME/.local/share/pre-ambxst-backup-"*; do drop "$d"; done
shopt -u nullglob

# --- SDDM themes ------------------------------------------------------------
head_ "SDDM themes"

ORPHANS=()
if [ -d "$SDDM_THEMES" ]; then
    for t in "$SDDM_THEMES"/*/; do
        t="${t%/}"
        pacman -Qoq "$t" >/dev/null 2>&1 || ORPHANS+=("$t")
    done
fi

if [ ${#ORPHANS[@]} -eq 0 ]; then
    skip "Every installed theme comes from a package"
else
    CURRENT="$(grep -rhoP '^\s*Current\s*=\s*\K.*' "$SDDM_CONF_DIR" /etc/sddm.conf 2>/dev/null | tail -1 | tr -d '[:space:]' || true)"
    DOOMED=0
    for t in "${ORPHANS[@]}"; do
        [ "$(basename "$t")" = "$CURRENT" ] && DOOMED=1
    done

    if [ "$DOOMED" = "1" ]; then
        if [ ! -d "$SDDM_THEMES/$FALLBACK_SDDM_THEME" ]; then
            warn "Active theme '$CURRENT' is on the list but fallback '$FALLBACK_SDDM_THEME' is missing. SDDM left alone."
            ORPHANS=()
        else
            warn "Active theme '$CURRENT' is on the list, switching SDDM to '$FALLBACK_SDDM_THEME' first"
            if [ "$DRY" = "0" ]; then
                sudo install -d -m 755 "$SDDM_CONF_DIR"
                printf '[Theme]\nCurrent=%s\n' "$FALLBACK_SDDM_THEME" \
                    | sudo tee "$SDDM_CONF_DIR/10-theme.conf" >/dev/null
                shopt -s nullglob
                for c in "$SDDM_CONF_DIR"/*.conf; do
                    [ "$c" = "$SDDM_CONF_DIR/10-theme.conf" ] && continue
                    grep -qP '^\s*Current\s*=' "$c" || continue
                    sudo mv "$c" "$c.avant-noctalia"
                    ok "$c moved aside, it also set a theme"
                done
                shopt -u nullglob
                ok "SDDM now on '$FALLBACK_SDDM_THEME'"
            fi
        fi
    fi

    for t in "${ORPHANS[@]}"; do drop "$t"; done
fi

# --- Themes -----------------------------------------------------------------
head_ "Themes"

shopt -s nullglob
for d in "$HOME/.themes/Orchis"*; do drop "$d"; done
shopt -u nullglob

drop "$HOME/.local/share/icons/illogical-impulse.svg"

# Whatever wrote these, noctalia rebuilds gtk.css as a one-line import of the
# noctalia.css it generates. Restoring an older one buries that import under
# stale @define-colors, and CSS ignores an @import that is not first.
for d in "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
    for f in "$d/gtk.css" "$d/gtk.css.avant-post-install"; do
        [ -f "$f" ] || continue
        grep -qE "generated by (matugen|Ambxst)" "$f" 2>/dev/null || { skip "$f is not generated"; continue; }
        drop "$f"
    done
done

# --- Packages ---------------------------------------------------------------
head_ "Unneeded packages"

for p in quickshell matugen; do
    pacman -Q "$p" >/dev/null 2>&1 || { skip "$p not installed"; continue; }
    if [ -n "$(pacman -Qi "$p" | awk -F': ' '/^(Required By|Requis par)/{print $2}' | grep -v '^None$\|^--$' || true)" ]; then
        skip "$p is still required by something"
        continue
    fi
    if [ "$DRY" = "1" ]; then
        ok "pacman -Rns $p"
    else
        sudo pacman -Rns --noconfirm "$p" && ok "$p removed"
    fi
done

# --- Tally ------------------------------------------------------------------
printf '\n'
if [ "$DRY" = "1" ]; then
    warn "$(numfmt --to=iec "$FREED" 2>/dev/null || echo "$FREED bytes") would be freed. Re-run with --yes."
else
    ok "$(numfmt --to=iec "$FREED" 2>/dev/null || echo "$FREED bytes") freed"
fi
