#!/usr/bin/env bash
# Rofi picker for ~/.config/hypr/wallpapers, bound to SUPER+SHIFT+W.
set -euo pipefail

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

mapfile -t images < <(find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort)

if [[ ${#images[@]} -eq 0 ]]; then
    notify-send "Wallpaper" "No wallpaper found in $WALLPAPER_DIR"
    exit 0
fi

menu=""
for img in "${images[@]}"; do
    name="$(basename "$img")"
    menu+="$name\0icon\x1f$img\n"
done

chosen="$(printf '%b' "$menu" | rofi -dmenu -i -show-icons -p "Wallpaper")"

if [[ -n "$chosen" ]]; then
    awww img "$WALLPAPER_DIR/$chosen"
fi
