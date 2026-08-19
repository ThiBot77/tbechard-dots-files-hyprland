#!/usr/bin/env bash
# Picks a random image from ~/.config/hypr/wallpapers and sets it via awww.
# Bound to SUPER+SHIFT+W, and run once at startup (see conf.d/env.conf).
set -euo pipefail

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

mapfile -t images < <(find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \))

if [[ ${#images[@]} -eq 0 ]]; then
    echo "No wallpaper found in $WALLPAPER_DIR" >&2
    exit 0
fi

pick="${images[RANDOM % ${#images[@]}]}"
"$HOME/.local/bin/apply-wallpaper.sh" "$pick"
