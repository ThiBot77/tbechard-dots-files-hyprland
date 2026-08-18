#!/usr/bin/env bash
# Rofi picker for the accent palette, bound to SUPER+SHIFT+T.
set -euo pipefail

THEMES_DIR="$HOME/Documents/tbe-dots-files/themes"

chosen="$(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | rofi -dmenu -i -p "Theme")"

if [[ -n "$chosen" ]]; then
    "$HOME/.local/bin/theme-switch.sh" "$chosen"
fi
