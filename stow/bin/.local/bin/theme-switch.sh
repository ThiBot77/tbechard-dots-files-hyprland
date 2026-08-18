#!/usr/bin/env bash
# Switches the accent color across hyprland/waybar/rofi/mako.
# Usage: theme-switch.sh <palette-name>
set -euo pipefail

THEMES_DIR="$HOME/Documents/tbe-dots-files/themes"

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <palette>" >&2
    echo "Available: $(ls "$THEMES_DIR")" >&2
    exit 1
fi

palette="$1"
src="$THEMES_DIR/$palette"

if [[ ! -d "$src" ]]; then
    notify-send "Theme" "Unknown palette: $palette"
    exit 1
fi

cp "$src/hypr-colors.conf" "$HOME/.config/hypr/colors.conf"
cp "$src/waybar-colors.css" "$HOME/.config/waybar/colors.css"
cp "$src/rofi-colors.rasi" "$HOME/.config/rofi/colors.rasi"

hex="$(tr -d '#\n' < "$src/mako-accent.txt")"
mako_conf="$HOME/.config/mako/config"
sed -i "s/^border-color=#[0-9a-fA-F]\{6\}26\$/border-color=#${hex}26/" "$mako_conf"
sed -i "s/^border-color=#[0-9a-fA-F]\{6\}\$/border-color=#${hex}/" "$mako_conf"

hyprctl reload >/dev/null
pkill -SIGUSR2 waybar 2>/dev/null || true
makoctl reload >/dev/null 2>&1 || true

notify-send "Theme" "Switched to $palette"
