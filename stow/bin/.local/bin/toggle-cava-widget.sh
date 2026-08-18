#!/usr/bin/env bash
# Spawns or kills the pinned cava audio-visualizer widget (SUPER+V).
set -euo pipefail

CLASS="cava-widget"

pid="$(hyprctl clients -j | jq -r --arg c "$CLASS" '.[] | select(.class == $c) | .pid' | head -n1)"

if [[ -n "$pid" ]]; then
    kill "$pid"
else
    kitty --class "$CLASS" --title "cava" -e cava &
    disown
fi
