#!/usr/bin/env bash
#
# Rejoue ce que l'installateur de serpantinum ne conserve pas.
#
# Il reecrit ~/.config/hypr/config/keybinds.lua a chaque installation ou mise a
# jour, ce qui efface les corrections ci-dessous. Ce script est idempotent :
# relance-le apres chaque passage de l'installateur.
set -euo pipefail

KEYBINDS="$HOME/.config/hypr/config/keybinds.lua"
SETTINGS="$HOME/.config/hypr/config/settings.lua"
AUTOSTART="$HOME/.config/hypr/config/autostart.lua"
KITTY="$HOME/.config/kitty/kitty.conf"

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

# Remplace une chaine exacte, ou echoue bruyamment si le motif a disparu :
# mieux vaut s arreter que patcher a moitie.
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

# --- Reglages du terminal -----------------------------------------------------
# Serpantinum livre son propre kitty.conf, avec une police en corps 16, aucune
# transparence et 4 px de marge. On revient aux reglages d avant, en gardant
# son include de colors.conf pour que la palette continue de le suivre.
#
# Sa police par defaut, "JetBrains Mono", n existe pas sur Arch : le paquet
# fournit "FiraCode Nerd Font" ou "JetBrainsMono Nerd Font". Sans correction,
# kitty retombe sur Noto Sans Mono, sans glyphes Nerd Font.
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
    ("background_opacity 1.0",            "background_opacity 0.85\ndynamic_background_opacity yes"),
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
    ok "Kitty : police, corps 10.5, transparence 0.85, marge 24 px"
fi

# --- Agent de secrets NetworkManager ------------------------------------------
# Serpantinum ne gere pas le VPN : aucun de ses fichiers ne le mentionne, son
# panneau reseau se limite au wifi et au bluetooth. Sans agent de secrets,
# NetworkManager ne peut demander ni mot de passe ni code MFA et abandonne la
# connexion en silence. nm-applet fournit cet agent, et son menu de barre
# systeme permet en prime de monter les VPN.
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
# L installateur remet kb_layout a "us" a chaque passage. On repasse en
# francais, en gardant le us en second groupe : grp:alt_shift_toggle bascule
# entre les deux, ce qui depanne pour les jeux et certains logiciels.
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
# L original ne bind que SUPER+Return. On ajoute T sans retirer Return.
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
# SUPER+A sert a l autohide dans l original : on le decale sur SHIFT+A.
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
# L original bind les keysyms "1".."0". En AZERTY les chiffres sont sur le
# niveau Shift, ces raccourcis sont donc injouables tels quels. Les codes bruts
# 10..19 designent la rangee physique quelle que soit la disposition.
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
              '-- Codes bruts : la rangee des chiffres quelle que soit la disposition.
local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
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
