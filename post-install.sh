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
    sed 's/^\(\s*scale\s*=\s*\)"auto",/\1'"1"',/' "$HYPR_DEFAULT" > "$HYPR_LUA"
    ok "Stock Hyprland config seeded from $HYPR_DEFAULT, scale pinned to 1"
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

hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"), { release = true })
LUA
    ok "hyprland.lua starts noctalia, keyboard set to French"
fi

if grep -qF '"ampersand"' "$HYPR_LUA"; then
    skip "Keybinds already rebound"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-binds-$STAMP"
    python3 - "$HYPR_LUA" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path).read()

subs = [
    ('local fileManager = "dolphin"',
     'local fileManager = "nautilus"'),
    ('local menu        = "hyprlauncher"',
     'local menu        = "noctalia msg panel-toggle launcher"'),
    ('hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))',
     'hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))'),
    ('local closeWindowBind = hl.bind(mainMod .. " + C", hl.dsp.window.close())',
     'local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())'),
    ('''for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end''',
     '''-- code:NN registers an empty bind through the Lua API, keysyms do not.
-- With SHIFT the AZERTY row already yields the digits, so those stay as they are.
local azerty = { "ampersand", "eacute", "quotedbl", "apostrophe", "parenleft",
                 "minus", "egrave", "underscore", "ccedilla", "agrave" }
for i = 1, 10 do
    hl.bind(mainMod .. " + " .. azerty[i],          hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. (i % 10),   hl.dsp.window.move({ workspace = i }))
end'''),
]

for old, new in subs:
    if s.count(old) != 1:
        sys.exit("pattern missing or ambiguous: %r" % old[:60])
    s = s.replace(old, new)
open(path, "w").write(s)
PYEOF
    ok "SUPER+T terminal, SUPER+E files, SUPER+Q close, AZERTY workspaces"
fi

if grep -qF 'screenshot-region' "$HYPR_LUA"; then
    skip "Screenshot keys already bound"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-screenshot-$STAMP"
    cat >> "$HYPR_LUA" <<'LUA'

hl.bind("Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("noctalia msg screenshot-annotate"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen all"))
LUA
    ok "Print captures a region, Shift annotates, SUPER takes the screen"
fi

if grep -qF 'general = { border_size = 0 }' "$HYPR_LUA"; then
    skip "Window borders already off"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-border-$STAMP"
    cat >> "$HYPR_LUA" <<'LUA'

hl.config({ general = { border_size = 0 } })
LUA
    ok "Window borders off"
fi

if grep -qF 'settings-toggle' "$HYPR_LUA"; then
    skip "Settings key already bound"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-settings-$STAMP"
    cat >> "$HYPR_LUA" <<'LUA'

hl.bind("SUPER + comma", hl.dsp.exec_cmd("noctalia msg settings-toggle"))
LUA
    ok "SUPER+, opens the noctalia settings"
fi

if grep -qF 'session lock' "$HYPR_LUA"; then
    skip "Lock keys already bound"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-lock-$STAMP"
    cat >> "$HYPR_LUA" <<'LUA'

hl.bind("SUPER + L", hl.dsp.exec_cmd("noctalia msg session lock"), { locked = true })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("noctalia msg session lock"), { locked = true })
LUA
    ok "SUPER+L and the power key lock the screen"
fi

# --- Noctalia config --------------------------------------------------------
NOCT_DIR="$HOME/.config/noctalia"
NOCT_SRC="$REPO/config/noctalia"

if [ ! -d "$NOCT_SRC" ]; then
    skip "config/noctalia missing from the repo"
elif cmp -s "$NOCT_SRC/config.toml" "$NOCT_DIR/config.toml" \
     && cmp -s "$NOCT_SRC/templates/fastfetch.jsonc" "$NOCT_DIR/templates/fastfetch.jsonc"; then
    skip "Noctalia config already up to date"
else
    mkdir -p "$NOCT_DIR/templates"
    [ -f "$NOCT_DIR/config.toml" ] && cp -a "$NOCT_DIR/config.toml" "$NOCT_DIR/config.toml.overwritten-$STAMP"
    cp -a "$NOCT_SRC/config.toml" "$NOCT_DIR/config.toml"
    cp -a "$NOCT_SRC/templates/fastfetch.jsonc" "$NOCT_DIR/templates/fastfetch.jsonc"
    ok "Noctalia templates: kitty, starship, gtk, btop, fastfetch"
fi

if command -v noctalia >/dev/null && pgrep -x noctalia >/dev/null; then
    noctalia msg config-reload >/dev/null 2>&1 || true
    noctalia msg templates-apply >/dev/null 2>&1 || true
    ok "Templates rendered for the current palette"
fi

# --- zsh --------------------------------------------------------------------
if [ -d "$HOME/.oh-my-zsh" ]; then
    skip "oh-my-zsh already in HOME"
elif [ -d /usr/share/oh-my-zsh ]; then
    cp -a /usr/share/oh-my-zsh "$HOME/.oh-my-zsh"
    ok "oh-my-zsh copied from /usr/share into HOME"
else
    skip "oh-my-zsh not found, install the oh-my-zsh-git package"
fi

if [ ! -f "$REPO/config/zsh/.zshrc" ]; then
    skip "config/zsh/.zshrc missing from the repo"
elif cmp -s "$REPO/config/zsh/.zshrc" "$HOME/.zshrc"; then
    skip "zshrc already up to date"
else
    [ -f "$HOME/.zshrc" ] && cp -a "$HOME/.zshrc" "$HOME/.zshrc.overwritten-$STAMP"
    cp -a "$REPO/config/zsh/.zshrc" "$HOME/.zshrc"
    ok "zshrc deployed from the repo"
fi

# --- Reload -----------------------------------------------------------------
if command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null && ok "Hyprland reloaded"
else
    skip "Hyprland not detected, restart your session to apply"
fi
