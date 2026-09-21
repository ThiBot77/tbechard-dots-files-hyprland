#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
HYPR_LUA="$HYPR_DIR/hyprland.lua"
HYPR_DEFAULT="/usr/share/hypr/hyprland.lua"
STAMP="$(date +%Y%m%d-%H%M%S)"

ok()   { printf '\033[32m[ ok ]\033[0m %s\n' "$1"; }
skip() { printf '\033[90m[ -- ]\033[0m %s\n' "$1"; }
warn() { printf '\033[33m[ ?? ]\033[0m %s\n' "$1"; }
die()  { printf '\033[31m[ !! ]\033[0m %s\n' "$1" >&2; exit 1; }

# True when every file of $1 is present and identical under $2.
tree_synced() {
    local rel
    while IFS= read -r rel; do
        cmp -s "$1/$rel" "$2/$rel" || return 1
    done < <(cd "$1" && find . -type f -printf '%P\n')
    return 0
}

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
  FORCE_SETTINGS=1   Overwrite this machine's noctalia settings.toml with the
                     repo's copy, keeping the old one beside it as
                     .overwritten-<date>. By default an existing file is left
                     alone: its per-monitor entries are machine-specific.
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

# --- AUR helper -------------------------------------------------------------
if command -v yay >/dev/null; then
    skip "yay already installed"
elif [ "${SKIP_PACKAGES:-0}" = "1" ]; then
    skip "yay bootstrap skipped (SKIP_PACKAGES=1)"
else
    sudo pacman -S --needed --noconfirm git base-devel
    YAY_TMP="$(mktemp -d)"
    git clone -q https://aur.archlinux.org/yay-bin.git "$YAY_TMP/yay-bin"
    (cd "$YAY_TMP/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$YAY_TMP"
    ok "yay built from the AUR"
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

if systemctl is-enabled --quiet bluetooth.service 2>/dev/null; then
    skip "Bluetooth service already enabled"
else
    sudo systemctl enable --now bluetooth.service
    # WirePlumber only probes bluez at startup: without this, headsets stay
    # invisible as audio sinks until the next reboot.
    systemctl --user restart wireplumber
    ok "Bluetooth service enabled"
fi

if systemctl is-enabled --quiet accounts-daemon.service 2>/dev/null; then
    skip "AccountsService already enabled"
else
    sudo systemctl enable --now accounts-daemon.service
    ok "AccountsService enabled"
fi

if [ "$(timedatectl show -p Timezone --value)" = "Europe/Paris" ]; then
    skip "Timezone already Europe/Paris"
else
    sudo timedatectl set-timezone Europe/Paris
    ok "Timezone set to Europe/Paris"
fi

if [ "$SHELL" = "/usr/bin/zsh" ] || [ "$SHELL" = "/bin/zsh" ]; then
    skip "Default shell already zsh"
else
    chsh -s /usr/bin/zsh
    # The user manager caches SHELL from login: without this, apps it activates
    # keep spawning the old shell until the next reboot.
    systemctl --user set-environment SHELL=/usr/bin/zsh
    ok "Default shell set to zsh (log out and back in for it to take effect)"
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
     '''local azerty = { "ampersand", "eacute", "quotedbl", "apostrophe", "parenleft",
                 "minus", "egrave", "underscore", "ccedilla", "agrave" }
for i = 1, 10 do
    hl.bind(mainMod .. " + " .. azerty[i],          hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. azerty[i],   hl.dsp.window.move({ workspace = i }))
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

if grep -qF 'hyprpolkitagent' "$HYPR_LUA"; then
    skip "Polkit agent already started"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-polkit-$STAMP"
    cat >> "$HYPR_LUA" <<'LUA'

-- Without an agent, pkexec apps (Ventoy...) never show a password prompt.
hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
LUA
    ok "Polkit agent starts with the session"
fi

if grep -qF 'CN41512CCR' "$HYPR_LUA"; then
    skip "Desk layout already pinned"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-monitors-$STAMP"
    cat >> "$HYPR_LUA" <<'LUA'

hl.monitor({ output = "desc:LG Display 0x0764",              mode = "1920x1080@60.02", position = "0x0",    scale = 1 })
hl.monitor({ output = "desc:HP Inc. HP E24 G4 CN41512CCR",   mode = "1920x1080@60",    position = "1920x0", scale = 1 })
hl.monitor({ output = "desc:HP Inc. HP E24 G4 CN42023N27",   mode = "1920x1080@60",    position = "3840x0", scale = 1 })
LUA
    ok "Screens pinned: laptop, CN41512CCR, CN42023N27"
fi

if grep -qF 'LEN140WUXGA' "$HYPR_LUA"; then
    skip "Lenovo screen already pinned"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-monitors-$STAMP"
    cat >> "$HYPR_LUA" <<'LUA'

-- 16/15: the only scale near 1.1 that keeps 1920x1200 a whole number of pixels.
hl.monitor({ output = "desc:Lenovo Group Limited LEN140WUXGA", mode = "1920x1200@60.00", position = "0x0", scale = 1.0666667 })
LUA
    ok "Screen pinned: Lenovo laptop panel, scale 16/15"
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

if grep -qF 'loginctl lock-session' "$HYPR_LUA"; then
    skip "Lock keys already go through logind"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-lock-$STAMP"
    python3 - "$HYPR_LUA" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path).read()

noctalia = """hl.bind("SUPER + L", hl.dsp.exec_cmd("noctalia msg session lock"), { locked = true })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("noctalia msg session lock"), { locked = true })"""
logind = """hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"), { locked = true })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("loginctl lock-session"), { locked = true })"""

if noctalia in s:
    s = s.replace(noctalia, logind)
else:
    s = s.rstrip("\n") + "\n\n" + logind + "\n"
open(path, "w").write(s)
PYEOF
    ok "SUPER+L and the power key lock through logind"
fi

if grep -qF 'hl.exec_cmd("hypridle")' "$HYPR_LUA"; then
    skip "hypridle already autostarted"
else
    cp -a "$HYPR_LUA" "$HYPR_LUA.avant-hypridle-$STAMP"
    cat >> "$HYPR_LUA" <<'LUA'

hl.on("hyprland.start", function()
  hl.exec_cmd("hypridle")
end)
LUA
    ok "hypridle autostarted"
fi

MUSIC_SRC="$REPO/config/hypr/hyprlock-music.sh"
MUSIC_DEST="$HYPR_DIR/hyprlock-music.sh"

if [ ! -f "$MUSIC_SRC" ]; then
    skip "config/hypr/hyprlock-music.sh missing from the repo"
elif cmp -s "$MUSIC_SRC" "$MUSIC_DEST"; then
    skip "Lock screen media helper already up to date"
else
    mkdir -p "$HYPR_DIR"
    install -m 755 "$MUSIC_SRC" "$MUSIC_DEST"
    ok "Lock screen media helper deployed"
fi

QUOTES_SRC="$REPO/config/hypr/quotes.txt"
QUOTES_DEST="$HYPR_DIR/quotes.txt"

if [ ! -f "$QUOTES_SRC" ]; then
    skip "config/hypr/quotes.txt missing from the repo"
elif cmp -s "$QUOTES_SRC" "$QUOTES_DEST"; then
    skip "Lock screen quotes already up to date"
else
    mkdir -p "$HYPR_DIR"
    cp -a "$QUOTES_SRC" "$QUOTES_DEST"
    ok "Lock screen quotes deployed ($(grep -c . "$QUOTES_SRC") lines)"
fi

AVATAR_SRC="$REPO/config/hypr/avatar.png"
AVATAR_DEST="$HOME/.face.icon"

if [ -f "$AVATAR_DEST" ]; then
    skip "Lock screen avatar already in place"
elif [ -f "$AVATAR_SRC" ]; then
    cp -a "$AVATAR_SRC" "$AVATAR_DEST"
    ok "Lock screen avatar installed from the repo"
elif [ -f "$HOME/.config/fastfetch/avatar.png" ]; then
    cp -a "$HOME/.config/fastfetch/avatar.png" "$AVATAR_DEST"
    ok "Lock screen avatar taken from the fastfetch one"
else
    skip "No avatar found, hyprlock will show an empty frame. Drop a PNG at ~/.face.icon"
fi

# SDDM reads the AccountsService copy, not ~/.face.icon: the greeter runs as
# its own user and can't traverse a 700 home directory.
if [ -f "$AVATAR_DEST" ] && command -v gdbus >/dev/null && systemctl is-active --quiet accounts-daemon.service; then
    if [ -f "/var/lib/AccountsService/icons/$USER" ]; then
        skip "Avatar already registered with AccountsService"
    else
        gdbus call --system --dest org.freedesktop.Accounts \
            --object-path "/org/freedesktop/Accounts/User$(id -u)" \
            --method org.freedesktop.Accounts.User.SetIconFile "$AVATAR_DEST" >/dev/null
        ok "Avatar registered with AccountsService (SDDM will pick it up)"
    fi
fi

HYPRIDLE_SRC="$REPO/config/hypr/hypridle.conf"
HYPRIDLE_DEST="$HYPR_DIR/hypridle.conf"

if [ ! -f "$HYPRIDLE_SRC" ]; then
    skip "config/hypr/hypridle.conf missing from the repo"
elif cmp -s "$HYPRIDLE_SRC" "$HYPRIDLE_DEST"; then
    skip "hypridle.conf already up to date"
else
    if [ -f "$HYPRIDLE_DEST" ]; then
        cp -a "$HYPRIDLE_DEST" "$HYPRIDLE_DEST.overwritten-$STAMP"
    fi
    cp -a "$HYPRIDLE_SRC" "$HYPRIDLE_DEST"
    pkill -x hypridle 2>/dev/null || true
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        setsid hypridle >/dev/null 2>&1 &
    fi
    ok "hypridle.conf deployed: lock at 10 min, screens off at 15, lock before sleep"
fi

# --- Noctalia config --------------------------------------------------------
NOCT_DIR="$HOME/.config/noctalia"
NOCT_SRC="$REPO/config/noctalia"

if [ ! -d "$NOCT_SRC" ]; then
    skip "config/noctalia missing from the repo"
else
    NOCT_STALE=0
    cmp -s "$NOCT_SRC/config.toml" "$NOCT_DIR/config.toml" || NOCT_STALE=1
    for t in "$NOCT_SRC/templates/"*; do
        [ -f "$t" ] || continue
        cmp -s "$t" "$NOCT_DIR/templates/$(basename "$t")" || NOCT_STALE=1
    done

    if [ "$NOCT_STALE" = "0" ]; then
        skip "Noctalia config already up to date"
    else
        mkdir -p "$NOCT_DIR/templates"
        if [ -f "$NOCT_DIR/config.toml" ]; then
            cp -a "$NOCT_DIR/config.toml" "$NOCT_DIR/config.toml.overwritten-$STAMP"
        fi
        cp -a "$NOCT_SRC/config.toml" "$NOCT_DIR/config.toml"
        for t in "$NOCT_SRC/templates/"*; do
            [ -f "$t" ] || continue
            cp -a "$t" "$NOCT_DIR/templates/"
        done
        ok "Noctalia config and templates deployed: $(cd "$NOCT_SRC/templates" && ls | tr '\n' ' ')"
    fi
fi

if command -v noctalia >/dev/null && pgrep -x noctalia >/dev/null; then
    noctalia msg config-reload >/dev/null 2>&1 || true
    noctalia msg templates-apply >/dev/null 2>&1 || true
    ok "Templates rendered for the current palette"
fi

# --- Wallpapers -------------------------------------------------------------
WALL_SRC="$REPO/config/wallpapers"
WALL_DEST="$HOME/Images/Wallpapers"

if [ ! -d "$WALL_SRC" ]; then
    skip "config/wallpapers missing from the repo"
else
    mkdir -p "$WALL_DEST"
    BEFORE=$(find "$WALL_DEST" -maxdepth 1 -type f | wc -l)
    cp -an "$WALL_SRC"/. "$WALL_DEST"/ 2>/dev/null || true
    AFTER=$(find "$WALL_DEST" -maxdepth 1 -type f | wc -l)
    if [ "$BEFORE" = "$AFTER" ]; then
        skip "Wallpapers already there ($AFTER)"
    else
        ok "Wallpapers copied ($((AFTER - BEFORE)) new, $AFTER total)"
    fi
fi

# --- Noctalia settings ------------------------------------------------------
SETTINGS_SRC="$REPO/config/noctalia/settings.toml"
SETTINGS_DEST="$HOME/.local/state/noctalia/settings.toml"

write_settings() {
    local was_running=0
    if pgrep -x noctalia >/dev/null; then
        was_running=1
        pkill -x noctalia
        sleep 2
    fi
    mkdir -p "$(dirname "$SETTINGS_DEST")"
    sed "s|__HOME__|$HOME|g" "$SETTINGS_SRC" > "$SETTINGS_DEST"
    if [ "$was_running" = "1" ]; then
        setsid noctalia -d >/dev/null 2>&1 &
        sleep 3
    fi
}

if [ ! -f "$SETTINGS_SRC" ]; then
    skip "config/noctalia/settings.toml missing from the repo"
elif [ -f "$SETTINGS_DEST" ] && [ "${FORCE_SETTINGS:-0}" != "1" ]; then
    skip "Noctalia settings left alone (FORCE_SETTINGS=1 to overwrite)"
elif [ -f "$SETTINGS_DEST" ] && sed "s|__HOME__|$HOME|g" "$SETTINGS_SRC" | cmp -s - "$SETTINGS_DEST"; then
    skip "Noctalia settings already match the repo"
else
    if [ -f "$SETTINGS_DEST" ]; then
        cp -a "$SETTINGS_DEST" "$SETTINGS_DEST.overwritten-$STAMP"
        write_settings
        ok "Noctalia settings deployed, previous one kept as .overwritten-$STAMP"
    else
        write_settings
        ok "Noctalia settings deployed: bar, dock, desktop widgets, lockscreen, theme"
    fi
    SCREENS="$(grep -oE '"(eDP|DP|HDMI)-[0-9]+"' "$SETTINGS_SRC" | sort -u | tr -d '"' | tr '\n' ' ')"
    [ -n "$SCREENS" ] && echo "  Per-monitor entries expect: $SCREENS"
fi

# --- Tela icons -------------------------------------------------------------
TELA_SRC="$REPO/packages/tela-icon-theme"

if [ "${SKIP_PACKAGES:-0}" = "1" ]; then
    skip "Tela skipped (SKIP_PACKAGES=1)"
elif [ ! -f "$TELA_SRC/PKGBUILD" ]; then
    skip "packages/tela-icon-theme/PKGBUILD missing from the repo"
elif pacman -Qq tela-icon-theme-standard >/dev/null 2>&1; then
    skip "Tela icons already installed"
elif ! command -v makepkg >/dev/null; then
    skip "makepkg missing, install base-devel"
else
    TELA_BUILD="$(mktemp -d)"
    trap 'rm -rf "$TELA_BUILD"' EXIT
    cp "$TELA_SRC/PKGBUILD" "$TELA_BUILD/"
    echo "  building from $TELA_SRC/PKGBUILD, a minute or so"
    ( cd "$TELA_BUILD" && makepkg -si --noconfirm --needed ) \
        || die "Tela build failed. See the output above."
    rm -rf "$TELA_BUILD"
    trap - EXIT
    ok "Tela icons installed, standard colour only"
fi

# --- Icons and cursor -------------------------------------------------------
ICON_THEME="Tela"
CURSOR_THEME="Bibata-Modern-Ice"
CURSOR_SIZE=24

icon_dir() {
    [ -d "/usr/share/icons/$1" ] || [ -d "$HOME/.local/share/icons/$1" ]
}

if ! icon_dir "$ICON_THEME"; then
    skip "Icon theme $ICON_THEME not installed, see packages/aur.txt"
elif ! icon_dir "$CURSOR_THEME"; then
    skip "Cursor theme $CURSOR_THEME not installed, see packages/aur.txt"
else
    CURSOR_INDEX="$(printf '[Icon Theme]\nName=Default\nComment=Default cursor\nInherits=%s\n' "$CURSOR_THEME")"
    THEMED=0

    for d in "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
        f="$d/settings.ini"
        [ -f "$f" ] || continue
        grep -q 'gtk-cursor-theme-name' "$f" || continue
        grep -q 'gtk-theme-name' "$f" && continue
        rm "$f"
        THEMED=1
    done

    mkdir -p "$HOME/.icons/default"
    if ! printf '%s\n' "$CURSOR_INDEX" | cmp -s - "$HOME/.icons/default/index.theme"; then
        printf '%s\n' "$CURSOR_INDEX" > "$HOME/.icons/default/index.theme"
        THEMED=1
    fi

    if ! grep -qF 'XCURSOR_THEME' "$HYPR_LUA"; then
        cp -a "$HYPR_LUA" "$HYPR_LUA.avant-cursor-$STAMP"
        cat >> "$HYPR_LUA" <<LUA

hl.env("XCURSOR_THEME", "$CURSOR_THEME")
LUA
        THEMED=1
    fi

    if command -v gsettings >/dev/null; then
        for pair in "icon-theme $ICON_THEME" "cursor-theme $CURSOR_THEME"; do
            key="${pair%% *}"; val="${pair#* }"
            [ "$(gsettings get org.gnome.desktop.interface "$key" 2>/dev/null)" = "'$val'" ] && continue
            gsettings set org.gnome.desktop.interface "$key" "$val"
            THEMED=1
        done
        if [ "$(gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null)" != "$CURSOR_SIZE" ]; then
            gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"
            THEMED=1
        fi
    fi

    if [ "$THEMED" = "0" ]; then
        skip "Icons on $ICON_THEME, cursor on $CURSOR_THEME already"
    else
        if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
            hyprctl setcursor "$CURSOR_THEME" "$CURSOR_SIZE" >/dev/null 2>&1 || true
        fi
        ok "Icons on $ICON_THEME, cursor on $CURSOR_THEME at ${CURSOR_SIZE}px"
    fi
fi

# --- Portals ----------------------------------------------------------------
PORTAL_SRC="$REPO/config/xdg-desktop-portal/hyprland-portals.conf"
PORTAL_DEST="$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"

if [ ! -f "$PORTAL_SRC" ]; then
    skip "config/xdg-desktop-portal missing from the repo"
elif cmp -s "$PORTAL_SRC" "$PORTAL_DEST"; then
    skip "Portal preferences already up to date"
else
    mkdir -p "$(dirname "$PORTAL_DEST")"
    if [ -f "$PORTAL_DEST" ]; then
        cp -a "$PORTAL_DEST" "$PORTAL_DEST.overwritten-$STAMP"
    fi
    cp -a "$PORTAL_SRC" "$PORTAL_DEST"
    systemctl --user restart xdg-desktop-portal.service 2>/dev/null || true
    ok "File chooser portal on the GTK backend, not the unthemed Qt one"
fi

# --- Kitty ------------------------------------------------------------------
KITTY_SRC="$REPO/config/kitty"
KITTY_DEST="$HOME/.config/kitty"

if [ ! -f "$KITTY_SRC/kitty.conf" ]; then
    skip "config/kitty missing from the repo"
elif tree_synced "$KITTY_SRC" "$KITTY_DEST"; then
    skip "Kitty config already up to date"
else
    [ -d "$KITTY_DEST" ] && cp -a "$KITTY_DEST" "$KITTY_DEST.overwritten-$STAMP"
    mkdir -p "$KITTY_DEST"
    cp -a "$KITTY_SRC/." "$KITTY_DEST/"
    ok "Kitty deployed: FiraCode Nerd Font, 90% opacity (colors come from noctalia)"
fi

# --- btop -------------------------------------------------------------------
BTOP_SRC="$REPO/config/btop"
BTOP_DEST="$HOME/.config/btop"

if [ ! -f "$BTOP_SRC/btop.conf" ]; then
    skip "config/btop missing from the repo"
elif tree_synced "$BTOP_SRC" "$BTOP_DEST"; then
    skip "btop config already up to date"
else
    [ -d "$BTOP_DEST" ] && cp -a "$BTOP_DEST" "$BTOP_DEST.overwritten-$STAMP"
    mkdir -p "$BTOP_DEST"
    cp -a "$BTOP_SRC/." "$BTOP_DEST/"
    ok "btop deployed (the noctalia theme file is generated by noctalia)"
fi

# --- VS Code ----------------------------------------------------------------
CODE_SRC="$REPO/config/vscode"
CODE_DEST="$HOME/.config/Code/User"

if [ ! -f "$CODE_SRC/settings.json" ]; then
    skip "config/vscode missing from the repo"
elif cmp -s "$CODE_SRC/settings.json" "$CODE_DEST/settings.json"; then
    skip "VS Code settings already up to date"
else
    mkdir -p "$CODE_DEST"
    if [ -f "$CODE_DEST/settings.json" ]; then
        cp -a "$CODE_DEST/settings.json" "$CODE_DEST/settings.json.overwritten-$STAMP"
    fi
    cp -a "$CODE_SRC/settings.json" "$CODE_DEST/settings.json"
    ok "VS Code settings deployed: theme, icons, Nerd Font in the terminal"
fi

# Extensions are listed one per line; the marketplace is the source of truth.
if [ ! -f "$CODE_SRC/extensions.txt" ]; then
    skip "config/vscode/extensions.txt missing from the repo"
elif ! command -v code >/dev/null; then
    skip "VS Code not installed yet, extensions left alone"
else
    CODE_HAVE="$(code --list-extensions 2>/dev/null | tr 'A-Z' 'a-z' | sort)"
    CODE_MISSING=()
    while IFS= read -r ext; do
        [ -z "$ext" ] && continue
        printf '%s\n' "$CODE_HAVE" | grep -qxF "$(printf '%s' "$ext" | tr 'A-Z' 'a-z')" || CODE_MISSING+=("$ext")
    done < "$CODE_SRC/extensions.txt"

    if [ ${#CODE_MISSING[@]} -eq 0 ]; then
        skip "VS Code extensions already installed"
    else
        for ext in "${CODE_MISSING[@]}"; do
            code --install-extension "$ext" --force >/dev/null 2>&1 || warn "Extension failed: $ext"
        done
        ok "VS Code extensions installed: ${CODE_MISSING[*]}"
    fi
fi

# --- SDDM greeter -----------------------------------------------------------
SDDM_SRC="$REPO/sddm"
SDDM_THEME_DIR="/usr/share/sddm/themes/silent"
SDDM_CONF="/etc/sddm.conf.d/zz-silent.conf"

if [ ! -d "$SDDM_SRC/silent" ]; then
    skip "sddm/silent missing from the repo"
elif ! command -v sddm >/dev/null; then
    skip "sddm not installed, see packages/pacman.txt"
elif diff -rq "$SDDM_SRC/silent" "$SDDM_THEME_DIR" >/dev/null 2>&1 \
     && cmp -s "$SDDM_SRC/conf.d/zz-silent.conf" "$SDDM_CONF" \
     && [ -d /usr/share/fonts/redhat ]; then
    skip "SDDM greeter already on the silent theme"
else
    sudo rm -rf "$SDDM_THEME_DIR"
    sudo mkdir -p "$SDDM_THEME_DIR" /etc/sddm.conf.d
    sudo cp -r "$SDDM_SRC/silent/." "$SDDM_THEME_DIR/"
    sudo cp "$SDDM_SRC/conf.d/zz-silent.conf" "$SDDM_CONF"
    sudo rm -f /etc/sddm.conf.d/10-tbe.conf /etc/sddm.conf.d/zz-tbe.conf
    sudo rm -rf /usr/share/sddm/themes/tbe

    sudo cp -r "$SDDM_SRC/silent/fonts/redhat" "$SDDM_SRC/silent/fonts/redhat-vf" /usr/share/fonts/
    sudo fc-cache -f >/dev/null 2>&1 || true

    for conf in /etc/sddm.conf.d/*; do
        [ -f "$conf" ] || continue
        if [ "$(basename "$conf")" = "zz-silent.conf" ]; then continue; fi
        if ! grep -qE '^[[:space:]]*Current[[:space:]]*=' "$conf"; then continue; fi
        sudo mkdir -p /etc/sddm.conf.d.disabled
        sudo mv "$conf" /etc/sddm.conf.d.disabled/
        echo "  $(basename "$conf") also set a theme, moved to /etc/sddm.conf.d.disabled"
    done
    ok "SDDM greeter on the silent theme, RedHat fonts installed"
fi

if systemctl is-enabled sddm >/dev/null 2>&1; then
    skip "sddm already enabled"
else
    sudo systemctl enable sddm
    ok "sddm enabled"
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

# --- ssh --------------------------------------------------------------------
SSH_SRC="$REPO/config/ssh/config"
SSH_DIR="$HOME/.ssh"

if [ ! -f "$SSH_SRC" ]; then
    skip "config/ssh/config missing from the repo"
elif grep -qE 'PRIVATE KEY' "$SSH_SRC"; then
    die "$SSH_SRC contains a private key. Remove it from the repo."
else
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    if [ -f "$SSH_DIR/config" ]; then
        skip "ssh config already exists, left alone"
    else
        install -m 600 "$SSH_SRC" "$SSH_DIR/config"
        ok "ssh config seeded ($(grep -cE '^[[:space:]]*Host[[:space:]]' "$SSH_SRC") hosts)"
    fi
    for k in "$SSH_DIR"/id_*; do
        [ -f "$k" ] || continue
        case "$k" in *.pub) continue ;; esac
        chmod 600 "$k"
    done
    if [ ! -f "$SSH_DIR/id_rsa" ]; then
        skip "No ~/.ssh/id_rsa here. Copy it across by hand, it is deliberately not in the repo."
    fi
fi

# --- claude -----------------------------------------------------------------
if [ ! -f "$REPO/config/claude/CLAUDE.md" ]; then
    skip "config/claude/CLAUDE.md missing from the repo"
elif cmp -s "$REPO/config/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"; then
    skip "CLAUDE.md already up to date"
else
    mkdir -p "$HOME/.claude"
    [ -f "$HOME/.claude/CLAUDE.md" ] && cp -a "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.overwritten-$STAMP"
    cp -a "$REPO/config/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    ok "CLAUDE.md deployed from the repo"
fi

# --- Reload -----------------------------------------------------------------
if command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null && ok "Hyprland reloaded"
else
    skip "Hyprland not detected, restart your session to apply"
fi
