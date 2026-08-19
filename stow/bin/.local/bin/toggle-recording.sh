#!/usr/bin/env bash
# Starts/stops a screen recording of the focused monitor (SUPER+SHIFT+R).
set -euo pipefail

OUT_DIR="$HOME/Videos/Screencasts"
PID_FILE="/tmp/wf-recorder.pid"

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    kill -INT "$(cat "$PID_FILE")"
    rm -f "$PID_FILE"
    notify-send "Enregistrement" "Arrêté, sauvegardé dans $OUT_DIR" -a "wf-recorder"
else
    mkdir -p "$OUT_DIR"
    monitor="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"
    file="$OUT_DIR/rec-$(date +%Y%m%d-%H%M%S).mp4"
    wf-recorder -o "$monitor" -f "$file" &
    disown
    echo $! > "$PID_FILE"
    notify-send "Enregistrement" "Démarré sur $monitor" -a "wf-recorder"
fi
