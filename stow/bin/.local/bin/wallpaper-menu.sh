#!/usr/bin/env bash
# Grid-style rofi wallpaper picker (thumbnails), bound to SUPER+SHIFT+W.
set -euo pipefail

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
THUMB_DIR="$HOME/.cache/hypr-wallpaper-thumbs"
mkdir -p "$THUMB_DIR"

mapfile -t images < <(find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort)

if [[ ${#images[@]} -eq 0 ]]; then
    notify-send "Wallpaper" "No wallpaper found in $WALLPAPER_DIR"
    exit 0
fi

# Roughly square grid: columns = ceil(sqrt(count)), capped so cells stay big.
count=${#images[@]}
columns=$(( $(awk -v n="$count" 'BEGIN{print int(sqrt(n)+0.999)}') ))
[[ $columns -lt 3 ]] && columns=3
[[ $columns -gt 6 ]] && columns=6

menu=""
for img in "${images[@]}"; do
    name="$(basename "$img")"
    thumb="$THUMB_DIR/$name.png"
    if [[ ! -f "$thumb" || "$img" -nt "$thumb" ]]; then
        magick "$img" -resize 400x400^ -gravity center -extent 400x400 "$thumb" 2>/dev/null || cp "$img" "$thumb"
    fi
    menu+="$name\0icon\x1f$thumb\n"
done

grid_theme="window {width: 60%; height: 65%;} listview {columns: $columns; spacing: 1.2em; fixed-height: true;} element {orientation: vertical; padding: 0.6em;} element-icon {size: 8em; border-radius: 12px;} element-text {horizontal-align: 0.5; padding: 0.4em 0 0 0;}"

chosen="$(printf '%b' "$menu" | rofi -dmenu -i -show-icons -p "Wallpaper" -theme-str "$grid_theme")"

if [[ -n "$chosen" ]]; then
    "$HOME/.local/bin/apply-wallpaper.sh" "$WALLPAPER_DIR/$chosen"
fi
