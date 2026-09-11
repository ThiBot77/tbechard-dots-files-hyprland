#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
HYPR_LUA="$HYPR_DIR/hyprland.lua"
NOCTALIA_LUA="$HYPR_DIR/noctalia.lua"
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

Installs the certificates, the packages and noctalia, then wires noctalia
into an otherwise stock Hyprland configuration.

Env:
  SKIP_PACKAGES=1    Leave packages/*.txt alone
  SKIP_NOCTALIA=1    Do not install the noctalia package
  RESET_HYPRLAND=1   Move the current ~/.config/hypr aside and start again
                     from the stock $HYPR_DEFAULT
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
# https://docs.noctalia.dev/noctalia/getting-started/installation/?section=arch
if [ "${SKIP_NOCTALIA:-0}" = "1" ]; then
    skip "Noctalia install skipped (SKIP_NOCTALIA=1)"
elif pacman -Q noctalia >/dev/null 2>&1; then
    skip "noctalia $(pacman -Q noctalia | cut -d' ' -f2) already installed"
else
    sudo pacman -S --needed --noconfirm noctalia
    ok "Noctalia installed from [extra]"
fi

# --- A stock Hyprland to build on -------------------------------------------
if [ "${RESET_HYPRLAND:-0}" = "1" ] && [ -d "$HYPR_DIR" ]; then
    mv "$HYPR_DIR" "$HYPR_DIR.avant-noctalia-$STAMP"
    ok "Old config moved to $HYPR_DIR.avant-noctalia-$STAMP"
fi

if [ -f "$HYPR_LUA" ]; then
    skip "hyprland.lua already in place"
elif [ ! -f "$HYPR_DEFAULT" ]; then
    die "Missing $HYPR_DEFAULT. Is the hyprland package installed?"
else
    mkdir -p "$HYPR_DIR"
    cp -a "$HYPR_DEFAULT" "$HYPR_LUA"
    ok "Stock Hyprland config seeded from $HYPR_DEFAULT"
fi

# --- Noctalia in Hyprland ---------------------------------------------------
# Straight from https://docs.noctalia.dev/noctalia/compositor-settings/hyprland/
# Loaded last by hyprland.lua so its binds win over the stock ones.
noctalia_lua() {
    cat <<'LUA'
-- Noctalia, wired into Hyprland.
-- Generated by post-install.sh, edit hyprland.lua instead if you want it to survive.
-- https://docs.noctalia.dev/noctalia/compositor-settings/hyprland/

---- AUTOSTART ----

hl.on("hyprland.start", function()
  hl.exec_cmd("noctalia")
end)

---- COMPOSITOR SETTINGS ----

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
  },
  decoration = {
    rounding = 20,
    rounding_power = 2,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = 0xee1a1a1a,
    },
    blur = {
      enabled = true,
      size = 3,
      passes = 2,
      vibrancy = 0.1696,
    },
  },
})

---- PERSISTENT WORKSPACES ----

-- Keeps empty workspaces visible in the noctalia bar instead of only the ones
-- holding a window. Set your own monitor first, `hyprctl monitors` lists them.
-- hl.workspace_rule({ workspace = "1", monitor = "DP-1", persistent = true, default_name = "web" })
-- hl.workspace_rule({ workspace = "2", monitor = "DP-1", persistent = true, default_name = "code" })
-- hl.workspace_rule({ workspace = "3", monitor = "DP-1", persistent = true, default_name = "chat" })
-- hl.workspace_rule({ workspace = "4", monitor = "DP-1", persistent = true, default_name = "game" })
-- hl.workspace_rule({ workspace = "5", monitor = "DP-1", persistent = true, default_name = "design" })

---- IPC KEYBINDS ----

local mainMod = "SUPER"
local ipc = "noctalia msg "

hl.bind(mainMod .. "+Space", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. "+S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mainMod .. "+comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd(ipc .. "window-switcher"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"))

---- NOCTALIA SETTINGS WINDOW ----

hl.window_rule({
  match = { class = "dev.noctalia.Noctalia" },
  float = true,
  size = { 1080, 920 },
})

---- BLUR ----

-- Hyprland's own layer animations are off here so they do not fight noctalia's.
hl.layer_rule({
  name = "noctalia",
  match = {
    namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
  },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})
LUA
}

if [ -f "$NOCTALIA_LUA" ] && noctalia_lua | cmp -s - "$NOCTALIA_LUA"; then
    skip "noctalia.lua already up to date"
else
    [ -f "$NOCTALIA_LUA" ] && cp -a "$NOCTALIA_LUA" "$NOCTALIA_LUA.overwritten-$STAMP"
    noctalia_lua > "$NOCTALIA_LUA"
    ok "noctalia.lua written: autostart, keybinds, blur"
fi

if grep -qF 'require("noctalia")' "$HYPR_LUA"; then
    skip "hyprland.lua already requires noctalia"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-noctalia-$STAMP"
    cat >> "$HYPR_LUA" <<'LUA'


-- Noctalia, last so its binds win over the stock ones above.
require("noctalia")
LUA
    ok "hyprland.lua now requires noctalia"
fi

# --- Reload -----------------------------------------------------------------
if command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null && ok "Hyprland reloaded"
else
    skip "Hyprland not detected, restart your session to apply"
fi
