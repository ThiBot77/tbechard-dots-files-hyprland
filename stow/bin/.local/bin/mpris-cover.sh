L#!/usr/bin/env bash
# Prints a local image path for the current MPRIS track's cover art, used as
# hyprlock's image reload_cmd. Falls back to a 1x1 transparent PNG rather than
# an empty string: hyprlock keeps the previous path when reload_cmd prints
# nothing, which would leave a stale cover on screen after the music stops.
set -uo pipefail

CACHE="$HOME/.cache/hypr-mpris-cover.png"
BLANK="$HOME/.cache/hypr-mpris-blank.png"

blank() {
    # PNG32: forces an alpha channel — a plain "xc:none" PNG collapses to
    # 1-bit greyscale with no alpha, which draws as an opaque pixel.
    [[ -f "$BLANK" ]] || magick -size 1x1 xc:none "PNG32:$BLANK" 2>/dev/null
    echo "$BLANK"
}

playerctl status >/dev/null 2>&1 || { blank; exit 0; }

url="$(playerctl metadata mpris:artUrl 2>/dev/null)"

case "$url" in
    file://*) echo "${url#file://}" ;;
    http*)    curl -fsSL --max-time 4 "$url" -o "$CACHE" 2>/dev/null && echo "$CACHE" || blank ;;
    *)        blank ;;
esac
