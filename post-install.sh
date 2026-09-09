#!/usr/bin/env bash
#
# Rejoue ce que l'installateur de serpantinum ecrase a chaque passage.
# Idempotent : relance-le apres chaque mise a jour.
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

[ -f "$KEYBINDS" ] || die "Introuvable : $KEYBINDS. Serpantinum est-il installe ?"
[ -f "$SETTINGS" ] || die "Introuvable : $SETTINGS. Serpantinum est-il installe ?"
[ -f "$AUTOSTART" ] || die "Introuvable : $AUTOSTART. Serpantinum est-il installe ?"

backup_once() {
    local dest="$KEYBINDS.avant-post-install"
    [ -f "$dest" ] || cp -a "$KEYBINDS" "$dest"
}

# Echoue plutot que de patcher a moitie si l amont a bouge.
patch_lua() {
    python3 - "$KEYBINDS" "$1" "$2" "$3" <<'PYEOF'
import sys
path, old, new, label = sys.argv[1:5]
s = open(path).read()
if s.count(old) != 1:
    sys.exit("motif introuvable ou ambigu pour %s : l amont a change, a revoir a la main" % label)
open(path, "w").write(s.replace(old, new))
PYEOF
}

# --- Prompt aux couleurs du theme ---------------------------------------------
# Serpantinum ne definit que les 16 couleurs ANSI : les index 233-255 dont se
# servait le prompt ne sont plus alimentes. On passe donc par un template
# matugen, qui ecrit starship.toml en hexadecimal a chaque changement de theme.
if [ ! -d "$MATUGEN" ]; then
    skip "assets matugen de serpantinum introuvables"
elif [ ! -f "$REPO/config/starship/starship.toml.template" ]; then
    skip "template starship absent du depot"
elif grep -q "templates.starship" "$MATUGEN/config.toml" \
     && cmp -s "$REPO/config/starship/starship.toml.template" "$MATUGEN/templates/starship.toml.template"; then
    skip "template starship deja en place"
else
    cp -a "$REPO/config/starship/starship.toml.template" "$MATUGEN/templates/starship.toml.template"
    grep -q "templates.starship" "$MATUGEN/config.toml" || cat >> "$MATUGEN/config.toml" <<'TOML'

[templates.starship]
input_path = "templates/starship.toml.template"
output_path = "~/.config/starship.toml"
TOML
    ok "Template starship installe, applique au prochain changement de fond"
fi

# --- zsh ----------------------------------------------------------------------
# Serpantinum ne fournit rien pour le shell. Le depot fait donc autorite :
# edite config/zsh/.zshrc, pas ~/.zshrc, puis relance ce script.
if [ ! -f "$REPO/config/zsh/.zshrc" ]; then
    skip "config/zsh/.zshrc absent du depot"
elif cmp -s "$REPO/config/zsh/.zshrc" "$HOME/.zshrc"; then
    skip "zshrc deja a jour"
else
    [ -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc.avant-post-install" ] \
        && cp -a "$HOME/.zshrc" "$HOME/.zshrc.avant-post-install"
    cp -a "$REPO/config/zsh/.zshrc" "$HOME/.zshrc"
    ok "zshrc deploye depuis le depot"
fi

# --- Reglages du terminal -----------------------------------------------------
# On garde son include de colors.conf : la palette continue de le suivre.
# Sa police "JetBrains Mono" n existe pas sur Arch, kitty retombait sur
# Noto Sans Mono, sans glyphes Nerd Font.
if [ ! -f "$KITTY" ]; then
    skip "kitty.conf absent"
elif grep -qF 'font_size        10.5' "$KITTY"; then
    skip "Reglages kitty deja en place"
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
    sys.exit("motifs kitty introuvables (%s) : l amont a change, a revoir a la main" % ", ".join(missing))
for old, new in subs:
    s = s.replace(old, new)
open(path, "w").write(s)
PYEOF
    ok "Kitty : police, corps 10.5, transparence 0.70, marge 24 px"
fi

# --- Agent de secrets NetworkManager ------------------------------------------
# Serpantinum ne gere pas le VPN. Sans agent, NetworkManager ne peut pas
# demander le code MFA et abandonne en silence. nm-applet le fournit, et son
# menu sert a monter les VPN.
if grep -qF 'nm-applet' "$AUTOSTART"; then
    skip "nm-applet deja au demarrage"
else
    [ -f "$AUTOSTART.avant-post-install" ] || cp -a "$AUTOSTART" "$AUTOSTART.avant-post-install"
    python3 - "$AUTOSTART" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path).read()
old = '  hl.exec_cmd("serpantinumd start")'
if s.count(old) != 1:
    sys.exit("motif autostart introuvable : l amont a change, a revoir a la main")
open(path, "w").write(s.replace(old, '  hl.exec_cmd("nm-applet")\n' + old))
PYEOF
    pgrep -x nm-applet >/dev/null || (nohup nm-applet >/dev/null 2>&1 &)
    ok "nm-applet au demarrage, agent de secrets pour les VPN"
fi

# --- Disposition clavier ------------------------------------------------------
# L installateur remet kb_layout a "us". Le us reste en second groupe,
# Alt+Shift bascule.
if grep -qF 'kb_layout = "fr' "$SETTINGS"; then
    skip "Clavier deja en francais"
else
    [ -f "$SETTINGS.avant-post-install" ] || cp -a "$SETTINGS" "$SETTINGS.avant-post-install"
    python3 - "$SETTINGS" <<'PYEOF'
import sys
path = sys.argv[1]
s = open(path).read()
old = '    kb_layout = "us",'
if s.count(old) != 1:
    sys.exit("motif kb_layout introuvable : l amont a change, a revoir a la main")
open(path, "w").write(s.replace(old, '    kb_layout = "fr,us",'))
PYEOF
    ok "Clavier en francais, us en second groupe"
fi

# --- Terminal sur SUPER+T -----------------------------------------------------
if grep -qF 'mainMod .. " + T", hl.dsp.exec_cmd(terminal)' "$KEYBINDS"; then
    skip "SUPER+T deja en place"
else
    backup_once
    patch_lua 'hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))' \
              'hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))' \
              "SUPER+T"
    ok "SUPER+T ouvre le terminal"
fi

# --- Lanceur sur SUPER+A ------------------------------------------------------
# SUPER+A servait a l autohide, qui passe sur SHIFT+A.
if grep -qF '" + A", hl.dsp.exec_cmd("serpantinum msg toggle launcher")' "$KEYBINDS"; then
    skip "SUPER+A deja en place"
else
    backup_once
    patch_lua 'hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("serpantinum msg toggle autohide"))' \
              'hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("serpantinum msg toggle autohide"))' \
              "deplacement de l autohide"
    patch_lua 'hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("serpantinum msg toggle launcher"))' \
              'hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("serpantinum msg toggle launcher"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("serpantinum msg toggle launcher"))' \
              "SUPER+A"
    ok "SUPER+A ouvre le lanceur, autohide sur SUPER+SHIFT+A"
fi

# --- Workspaces en AZERTY -----------------------------------------------------
# En AZERTY les chiffres sont sur le niveau Shift : les keysyms "1".."0" sont
# injouables. Les codes bruts 10..19 designent la rangee physique.
if grep -qF 'numberkey' "$KEYBINDS"; then
    skip "Workspaces AZERTY deja en place"
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
    ok "Workspaces sur la rangee & e \" ( sans Shift"
fi

# --- Rechargement -------------------------------------------------------------
if command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null && ok "Hyprland recharge"
else
    skip "Hyprland non detecte, relance ta session pour appliquer"
fi
