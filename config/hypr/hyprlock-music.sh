#!/usr/bin/env bash
# Feeds the hyprlock media card. Silent when nothing is playing.
set -euo pipefail

COVER="/tmp/hyprlock-cover"
PLACEHOLDER="$HOME/.face.icon"

# Spotify first, then whatever else is around: the browser registers a player
# even with no media, and would win a plain "first in the list".
PLAYERS="spotify,%any"

meta() { playerctl -p "$PLAYERS" metadata "$1" 2>/dev/null || true; }

if [ -z "$(meta xesam:title)" ]; then
    [ "${1:-}" = "--cover" ] && echo "$PLACEHOLDER"
    exit 0
fi

case "${1:-}" in
    --source)
        playerctl -p "$PLAYERS" metadata --format "{{playerName}}" 2>/dev/null || true
        ;;
    --title)
        meta xesam:title | cut -c1-28
        ;;
    --artist)
        meta xesam:artist | cut -c1-28
        ;;
    --status)
        [ "$(playerctl -p "$PLAYERS" status 2>/dev/null || true)" = "Playing" ] && echo "" || echo ""
        ;;
    --now)
        t="$(meta xesam:title)"
        a="$(meta xesam:artist)"
        [ -n "$a" ] && echo "󰎆  $t — $a" || echo "󰎆  $t"
        ;;
    --cover)
        url="$(meta mpris:artUrl)"
        case "$url" in
            file://*) echo "${url#file://}"; exit 0 ;;
            http*)    curl -sf --max-time 5 -o "$COVER" "$url" && echo "$COVER" || echo "$PLACEHOLDER" ;;
            *)        echo "$PLACEHOLDER" ;;
        esac
        ;;
    *)
        echo "usage: ${0##*/} --source|--title|--artist|--status|--cover" >&2
        exit 1
        ;;
esac
