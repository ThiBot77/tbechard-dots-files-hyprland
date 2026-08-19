#!/usr/bin/env bash
# Clipboard history picker (SUPER+SHIFT+V).
set -euo pipefail

cliphist list | rofi -dmenu -theme ~/.config/rofi/theme.rasi -p "Presse-papiers" | cliphist decode | wl-copy
