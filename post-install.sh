#!/usr/bin/env bash
#
# Rejoue ce que l'installateur de serpantinum ne conserve pas.
#
# Il reecrit ~/.config/hypr/config/keybinds.lua a chaque installation ou mise a
# jour, ce qui efface les corrections ci-dessous. Ce script est idempotent :
# relance-le apres chaque passage de l'installateur.
set -euo pipefail

KEYBINDS="$HOME/.config/hypr/config/keybinds.lua"

ok()   { printf '\033[32m[ ok ]\033[0m %s\n' "$1"; }
skip() { printf '\033[90m[ -- ]\033[0m %s\n' "$1"; }
die()  { printf '\033[31m[ !! ]\033[0m %s\n' "$1" >&2; exit 1; }

[ -f "$KEYBINDS" ] || die "Introuvable : $KEYBINDS. Serpantinum est-il installe ?"

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
