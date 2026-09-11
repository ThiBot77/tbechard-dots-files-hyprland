#!/usr/bin/env bash
set -euo pipefail

KEYBINDS="$HOME/.config/hypr/config/keybinds.lua"
SETTINGS="$HOME/.config/hypr/config/settings.lua"
AUTOSTART="$HOME/.config/hypr/config/autostart.lua"
KITTY="$HOME/.config/kitty/kitty.conf"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MATUGEN="$HOME/.local/share/serpantinum/src/assets/matugen"

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
│                             S E T U P                         │
├───────────────────────────────────────────────────────────────┤

ART
    printf '\033[0m\n'
}

banner

backup_once() {
    local dest="$KEYBINDS.avant-post-install"
    [ -f "$dest" ] || cp -a "$KEYBINDS" "$dest"
}

patch_lua() {
    python3 - "$KEYBINDS" "$1" "$2" "$3" <<'PYEOF'
import sys
path, old, new, label = sys.argv[1:5]
s = open(path).read()
if s.count(old) != 1:
    sys.exit("pattern missing or ambiguous for %s: upstream changed, fix by hand" % label)
open(path, "w").write(s.replace(old, new))
PYEOF
}

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

# --- Packages ------------------------------------------------------------------
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

# --- Serpantinum --------------------------------------------------------------
SERP_INSTALLER="https://raw.githubusercontent.com/ilyamiro/serpantinum/master/install/install.sh"

SERP_VERSION="$(serpantinum --version 2>/dev/null | head -1 || true)"

if [ "${SKIP_SERPANTINUM:-0}" = "1" ]; then
    skip "Serpantinum install skipped (SKIP_SERPANTINUM=1)"
elif ! command -v serpantinumd >/dev/null; then
    echo "  upstream installer: $SERP_INSTALLER"
    bash -c "$(curl -fsSL "$SERP_INSTALLER")"
    ok "Serpantinum installed"
elif [ "${UPDATE_SERPANTINUM:-0}" = "1" ]; then
    echo "  installed: ${SERP_VERSION:-unknown}"
    echo "  upstream installer: $SERP_INSTALLER"
    bash -c "$(curl -fsSL "$SERP_INSTALLER")"
    ok "Serpantinum updated, the sections below put our own files back"
else
    skip "${SERP_VERSION:-Serpantinum} already installed (UPDATE_SERPANTINUM=1 to update)"
fi

[ -f "$KEYBINDS" ] || die "Missing: $KEYBINDS. Did the serpantinum install fail?"
[ -f "$SETTINGS" ] || die "Missing: $SETTINGS. Did the serpantinum install fail?"
[ -f "$AUTOSTART" ] || die "Missing: $AUTOSTART. Did the serpantinum install fail?"

# --- Themed prompt ---------------------------------------------
if [ ! -d "$MATUGEN" ]; then
    skip "Serpantinum matugen assets not found"
elif [ ! -f "$REPO/config/starship/starship.toml.template" ]; then
    skip "Starship template missing from the repo"
elif grep -q "templates.starship" "$MATUGEN/config.toml" \
     && grep -q "templates.starship" "$MATUGEN/config-static.toml" \
     && cmp -s "$REPO/config/starship/starship.toml.template" "$MATUGEN/templates/starship.toml.template"; then
    skip "Starship template already in place"
else
    cp -a "$REPO/config/starship/starship.toml.template" "$MATUGEN/templates/starship.toml.template"
    for cfg in config.toml config-static.toml; do
        [ -f "$MATUGEN/$cfg" ] || continue
        grep -q "templates.starship" "$MATUGEN/$cfg" || cat >> "$MATUGEN/$cfg" <<'TOML'

[templates.starship]
input_path = "templates/starship.toml.template"
output_path = "~/.config/starship.toml"
TOML
    done
    ok "Starship template installed for wallpaper and preset themes"
fi

# --- Fastfetch ----------------------------------------------------------------
FF_SRC="$REPO/config/fastfetch/config.jsonc.template"
FF_DEST="$MATUGEN/templates/fastfetch.jsonc.template"

if [ ! -d "$MATUGEN" ]; then
    skip "Serpantinum matugen assets not found"
elif [ ! -f "$FF_SRC" ]; then
    skip "Fastfetch template missing from the repo"
elif cmp -s "$FF_SRC" "$FF_DEST"; then
    skip "Fastfetch template already in place"
else
    cp -a "$FF_SRC" "$FF_DEST"
    ok "Fastfetch template installed, applied on the next theme render"
fi

# --- GTK theme ----------------------------------------------------------------
GTK_SRC="$REPO/config/gtk/gtk.css.template"
GTK_DEST="$MATUGEN/templates/gtk.css.template"
GTK_HOOK="systemctl --user try-restart xdg-desktop-portal-gtk.service"

if [ ! -d "$MATUGEN" ]; then
    skip "Serpantinum matugen assets not found"
elif [ ! -f "$GTK_SRC" ]; then
    skip "GTK template missing from the repo"
elif grep -q "try-restart xdg-desktop-portal-gtk" "$MATUGEN/config.toml" \
     && grep -q "try-restart xdg-desktop-portal-gtk" "$MATUGEN/config-static.toml" \
     && cmp -s "$GTK_SRC" "$GTK_DEST"; then
    skip "GTK template already in place"
else
    cp -a "$GTK_SRC" "$GTK_DEST"
    for d in "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
        [ -f "$d/gtk.css" ] || continue
        grep -q "generated by matugen" "$d/gtk.css" && continue
        [ -f "$d/gtk.css.avant-post-install" ] || cp -a "$d/gtk.css" "$d/gtk.css.avant-post-install"
    done
    for cfg in config.toml config-static.toml; do
        [ -f "$MATUGEN/$cfg" ] || continue
        python3 - "$MATUGEN/$cfg" "$GTK_HOOK" <<'PYEOF'
import re, sys
path, hook = sys.argv[1:3]
s = open(path).read()
s = re.sub(r'\n*\[templates\.gtk[34]\][^\[]*', '\n', s).rstrip()
for n, out in (("gtk3", "gtk-3.0"), ("gtk4", "gtk-4.0")):
    s += '\n\n[templates.%s]\ninput_path = "templates/gtk.css.template"\noutput_path = "~/.config/%s/gtk.css"' % (n, out)
    if n == "gtk3":
        s += '\npost_hook = "%s"' % hook
open(path, "w").write(s + "\n")
PYEOF
    done
    $GTK_HOOK >/dev/null 2>&1 || true
    ok "GTK template installed, re-pick your wallpaper or preset to render it"
fi

# --- oh-my-zsh ----------------------------------------------------------------
if [ -d "$HOME/.oh-my-zsh" ]; then
    skip "oh-my-zsh already in HOME"
elif [ -d /usr/share/oh-my-zsh ]; then
    cp -a /usr/share/oh-my-zsh "$HOME/.oh-my-zsh"
    ok "oh-my-zsh copied from /usr/share into HOME"
else
    skip "oh-my-zsh not found, install the oh-my-zsh-git package"
fi

# --- zsh ----------------------------------------------------------------------
if [ ! -f "$REPO/config/zsh/.zshrc" ]; then
    skip "config/zsh/.zshrc missing from the repo"
elif cmp -s "$REPO/config/zsh/.zshrc" "$HOME/.zshrc"; then
    skip "zshrc already up to date"
else
    [ -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc.avant-post-install" ] \
        && cp -a "$HOME/.zshrc" "$HOME/.zshrc.avant-post-install"
    cp -a "$REPO/config/zsh/.zshrc" "$HOME/.zshrc"
    ok "zshrc deployed from the repo"
fi

# --- Terminal settings -----------------------------------------------------
if [ ! -f "$KITTY" ]; then
    skip "kitty.conf missing"
elif grep -qF 'font_size        10.5' "$KITTY"; then
    skip "Kitty settings already in place"
else
    [ -f "$KITTY.avant-post-install" ] || cp -a "$KITTY" "$KITTY.avant-post-install"
    python3 - "$KITTY" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path).read()
subs = [
    ("font_family      JetBrains Mono",   "font_family      FiraCode Nerd Font"),
    ("font_size        16.0",             "font_size        10.5"),
    ("background_opacity 1.0",            "background_opacity 0.70\ndynamic_background_opacity yes"),
    ("window_padding_width 4",            "window_padding_width 24"),
    ("scrollback_lines 2000",             "scrollback_lines 10000"),
    ("cursor_trail 1",                    "cursor_shape beam\ncursor_blink_interval 0"),
]
missing = [old for old, _ in subs if s.count(old) != 1]
if missing:
    sys.exit("kitty patterns not found (%s): upstream changed, fix by hand" % ", ".join(missing))
for old, new in subs:
    s = s.replace(old, new)
open(path, "w").write(s)
PYEOF
    ok "Kitty: font, size 10.5, opacity 0.70, 24px padding"
fi

# --- NetworkManager secret agent ------------------------------------------
if grep -qF 'nm-applet' "$AUTOSTART"; then
    skip "nm-applet already autostarted"
else
    [ -f "$AUTOSTART.avant-post-install" ] || cp -a "$AUTOSTART" "$AUTOSTART.avant-post-install"
    python3 - "$AUTOSTART" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path).read()
old = '  hl.exec_cmd("serpantinumd start")'
if s.count(old) != 1:
    sys.exit("autostart pattern not found: upstream changed, fix by hand")
open(path, "w").write(s.replace(old, '  hl.exec_cmd("nm-applet")\n' + old))
PYEOF
    pgrep -x nm-applet >/dev/null || (nohup nm-applet >/dev/null 2>&1 &)
    ok "nm-applet autostarted, secret agent for VPNs"
fi

# --- Keyboard layout ------------------------------------------------------
if grep -qF 'kb_layout = "fr' "$SETTINGS"; then
    skip "Keyboard already French"
else
    [ -f "$SETTINGS.avant-post-install" ] || cp -a "$SETTINGS" "$SETTINGS.avant-post-install"
    python3 - "$SETTINGS" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path).read()
old = '    kb_layout = "us",'
if s.count(old) != 1:
    sys.exit("kb_layout pattern not found: upstream changed, fix by hand")
open(path, "w").write(s.replace(old, '    kb_layout = "fr,us",'))
PYEOF
    ok "Keyboard set to French, us as second group"
fi

# --- Terminal on SUPER+T -----------------------------------------------------
if grep -qF 'mainMod .. " + T", hl.dsp.exec_cmd(terminal)' "$KEYBINDS"; then
    skip "SUPER+T already bound"
else
    backup_once
    patch_lua 'hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))' \
              'hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))' \
              "SUPER+T"
    ok "SUPER+T opens the terminal"
fi

# --- Launcher on SUPER+A ------------------------------------------------------
if grep -qF '" + A", hl.dsp.exec_cmd("serpantinum msg toggle launcher")' "$KEYBINDS"; then
    skip "SUPER+A already bound"
else
    backup_once
    patch_lua 'hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("serpantinum msg toggle autohide"))' \
              'hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("serpantinum msg toggle autohide"))' \
              "deplacement de l autohide"
    patch_lua 'hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("serpantinum msg toggle launcher"))' \
              'hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("serpantinum msg toggle launcher"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("serpantinum msg toggle launcher"))' \
              "SUPER+A"
    ok "SUPER+A opens the launcher, autohide moved to SUPER+SHIFT+A"
fi

# --- AZERTY workspaces -----------------------------------------------------
if grep -qF 'numberkey' "$KEYBINDS"; then
    skip "AZERTY workspaces already bound"
else
    backup_once
    patch_lua 'for i = 1, 10 do
  local ws = tostring(i)
  local key = tostring(i % 10)
  hl.bind(mainMod .. " + " .. key, hl.dsp.exec_cmd("serpantinum msg workspace " .. ws))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd("serpantinum msg workspace " .. ws .. " move"))
end' \
              'local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
for i = 1, 10 do
  local ws = tostring(i)
  hl.bind(mainMod .. " + code:" .. numberkey[i], hl.dsp.exec_cmd("serpantinum msg workspace " .. ws))
  hl.bind(mainMod .. " + SHIFT + code:" .. numberkey[i], hl.dsp.exec_cmd("serpantinum msg workspace " .. ws .. " move"))
end' \
              "workspaces AZERTY"
    ok "Workspaces on the & e \" ( row without Shift"
fi

# --- File picker --------------------------------------------------------------
PORTALS="$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
FILECHOOSER="org.freedesktop.impl.portal.FileChooser"
FILEMANAGER="org.gnome.Nautilus.desktop"

if ! pacman -Q xdg-desktop-portal-gtk >/dev/null 2>&1; then
    skip "xdg-desktop-portal-gtk missing, add it to packages/pacman.txt"
elif [ ! -f "/usr/share/applications/$FILEMANAGER" ]; then
    skip "Nautilus missing, add it to packages/pacman.txt"
elif grep -qE "^[[:space:]]*$FILECHOOSER[[:space:]]*=[[:space:]]*gtk[[:space:]]*$" "$PORTALS" 2>/dev/null \
     && [ "$(xdg-mime query default inode/directory 2>/dev/null)" = "$FILEMANAGER" ]; then
    skip "GTK file picker already the default"
else
    mkdir -p "$(dirname "$PORTALS")"
    if [ -f "$PORTALS" ] && [ ! -f "$PORTALS.avant-post-install" ]; then
        cp -a "$PORTALS" "$PORTALS.avant-post-install"
    fi
    python3 - "$PORTALS" "$FILECHOOSER" <<'PYEOF'
import os, sys
path, key = sys.argv[1:3]
lines = open(path).read().splitlines() if os.path.exists(path) else ["[preferred]", "default = hyprland;gtk"]
if "[preferred]" not in lines:
    lines.insert(0, "[preferred]")
out, done = [], False
for line in lines:
    if line.split("=")[0].strip() == key:
        if done:
            continue
        line, done = "%s = gtk" % key, True
    out.append(line)
    if line.strip() == "[preferred]" and not done:
        out.append("%s = gtk" % key)
        done = True
open(path, "w").write("\n".join(out) + "\n")
PYEOF
    xdg-mime default "$FILEMANAGER" inode/directory
    systemctl --user restart xdg-desktop-portal.service >/dev/null 2>&1 || true
    ok "File picker set to GTK, Nautilus opens directories"
fi

# --- Reload -------------------------------------------------------------
if command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null && ok "Hyprland reloaded"
else
    skip "Hyprland not detected, restart your session to apply"
fi
