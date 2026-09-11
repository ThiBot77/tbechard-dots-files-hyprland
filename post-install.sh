#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
HYPR_LUA="$HYPR_DIR/hyprland.lua"
HYPR_DEFAULT="/usr/share/hypr/hyprland.lua"
STAMP="$(date +%Y%m%d-%H%M%S)"

ok()   { printf '\033[32m[ ok ]\033[0m %s\n' "$1"; }
skip() { printf '\033[90m[ -- ]\033[0m %s\n' "$1"; }
die()  { printf '\033[31m[ !! ]\033[0m %s\n' "$1" >&2; exit 1; }

banner() {
    printf '\033[36m'
    cat <<'ART'
╭───────────────────────────────────────────────────────────────╮
│   _____ _     _ ____  __  __            _     _               │
│  |_   _| |__ (_) __ )|  \/  | __ _  ___| |__ (_)_ __   ___    │
│    | | | '_ \| |  _ \| |\/| |/ _` |/ __| '_ \| | '_ \ / _ \   │
│    | | | | | | | |_) | |  | | (_| | (__| | | | | | | |  __/   │
│    |_| |_| |_|_|____/|_|  |_|\__,_|\___|_| |_|_|_| |_|\___|   │
├───────────────────────────────────────────────────────────────┤
│                      N O C T A L I A                          │
├───────────────────────────────────────────────────────────────┤

ART
    printf '\033[0m\n'
}

usage() {
    cat <<EOF
Usage: ${0##*/}

Certificates, packages, noctalia. Hyprland stays stock apart from starting
noctalia and a French keyboard.

Env:
  SKIP_PACKAGES=1    Leave packages/*.txt alone
  SKIP_NOCTALIA=1    Do not install the noctalia package
EOF
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    "")        ;;
    *)         usage >&2; die "Unknown argument: $1" ;;
esac

banner

# --- CA certificates --------------------------------------------------------
CERT_DIR="$REPO/certs"
ANCHORS="/etc/ca-certificates/trust-source/anchors"
shopt -s nullglob
CERTS=("$CERT_DIR"/*.crt)
shopt -u nullglob

if [ ${#CERTS[@]} -eq 0 ]; then
    skip "No certificate in certs/"
elif ! command -v update-ca-trust >/dev/null; then
    skip "update-ca-trust missing"
else
    CHANGED=0
    for cert in "${CERTS[@]}"; do
        target="$ANCHORS/$(basename "$cert")"
        [ -f "$target" ] && cmp -s "$cert" "$target" && continue
        openssl x509 -in "$cert" -noout >/dev/null 2>&1 || {
            echo "  $(basename "$cert"): unreadable PEM, skipped"; continue
        }
        sudo install -m 644 -D "$cert" "$target"
        CHANGED=1
    done
    if [ "$CHANGED" = "1" ]; then
        sudo update-ca-trust
        ok "Certificate store rebuilt"
    else
        skip "Certificates already trusted"
    fi
fi

# --- Packages ---------------------------------------------------------------
if [ "${SKIP_PACKAGES:-0}" = "1" ]; then
    skip "Packages skipped (SKIP_PACKAGES=1)"
elif [ ! -f "$REPO/packages/pacman.txt" ]; then
    skip "packages/pacman.txt missing"
else
    mapfile -t PKGS < <(grep -vE '^\s*(#|$)' "$REPO/packages/pacman.txt")
    MISSING=()
    for p in "${PKGS[@]}"; do pacman -Q "$p" >/dev/null 2>&1 || MISSING+=("$p"); done

    AURPKGS=(); AURMISSING=()
    [ -f "$REPO/packages/aur.txt" ] && mapfile -t AURPKGS < <(grep -vE '^\s*(#|$)' "$REPO/packages/aur.txt")
    for p in "${AURPKGS[@]}"; do pacman -Q "$p" >/dev/null 2>&1 || AURMISSING+=("$p"); done

    if [ ${#MISSING[@]} -eq 0 ] && [ ${#AURMISSING[@]} -eq 0 ]; then
        skip "All packages already installed"
    else
        [ ${#MISSING[@]} -gt 0 ] && {
            echo "  repos: ${MISSING[*]}"
            sudo pacman -S --needed --noconfirm "${MISSING[@]}"
        }
        [ ${#AURMISSING[@]} -gt 0 ] && {
            command -v yay >/dev/null || die "yay missing, required for: ${AURMISSING[*]}"
            echo "  aur: ${AURMISSING[*]}"
            yay -S --needed --noconfirm "${AURMISSING[@]}"
        }
        ok "Packages installed"
    fi
fi

# --- Noctalia ---------------------------------------------------------------
if [ "${SKIP_NOCTALIA:-0}" = "1" ]; then
    skip "Noctalia install skipped (SKIP_NOCTALIA=1)"
elif pacman -Q noctalia >/dev/null 2>&1; then
    skip "noctalia $(pacman -Q noctalia | cut -d' ' -f2) already installed"
else
    sudo pacman -S --needed --noconfirm noctalia
    ok "Noctalia installed from [extra]"
fi

# --- Hyprland ---------------------------------------------------------------
if [ -f "$HYPR_LUA" ]; then
    skip "hyprland.lua already in place"
elif [ ! -f "$HYPR_DEFAULT" ]; then
    die "Missing $HYPR_DEFAULT. Is the hyprland package installed?"
else
    mkdir -p "$HYPR_DIR"
    cp -a "$HYPR_DEFAULT" "$HYPR_LUA"
    ok "Stock Hyprland config seeded from $HYPR_DEFAULT"
fi

if grep -qF 'hl.exec_cmd("noctalia")' "$HYPR_LUA"; then
    skip "hyprland.lua already starts noctalia"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-noctalia-$STAMP"
    cat >> "$HYPR_LUA" <<'LUA'


hl.config({ input = { kb_layout = "fr" } })

hl.on("hyprland.start", function()
  hl.exec_cmd("noctalia")
end)
LUA
    ok "hyprland.lua starts noctalia, keyboard set to French"
fi

# --- Reload -----------------------------------------------------------------
if command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null && ok "Hyprland reloaded"
else
    skip "Hyprland not detected, restart your session to apply"
fi
