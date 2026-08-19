#!/usr/bin/env bash
# Sets a wallpaper via awww and refreshes the cached thumbnail/blur used by
# the rofi launcher's side panel. Single entry point so every caller
# (startup, random pick, picker menu) keeps that cache in sync.
#
# Usage: apply-wallpaper.sh /path/to/image
set -euo pipefail

CACHE_DIR="$HOME/.cache/hypr-wallpaper"
mkdir -p "$CACHE_DIR"

wallpaper="${1:?usage: apply-wallpaper.sh <image>}"

awww img "$wallpaper"

# Side panel of the launcher: a portrait crop, plus a blurred copy behind
# the mode switcher.
magick "$wallpaper" -resize 800x1200^ -gravity center -extent 800x1200 \
    "$CACHE_DIR/wall.thmb.png" 2>/dev/null || true
magick "$wallpaper" -resize 400x600^ -gravity center -extent 400x600 \
    -blur 0x18 "$CACHE_DIR/wall.blur.png" 2>/dev/null || true
