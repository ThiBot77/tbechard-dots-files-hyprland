#!/usr/bin/env bash
# JSON status for the waybar custom/wifi module: shows the connected SSID
# even when wifi isn't the primary/default route (e.g. wired is active too).
set -euo pipefail

info="$(nmcli -t -f active,ssid,signal dev wifi list | awk -F: '$1=="yes"{print $2":"$3; exit}')"

if [[ -n "$info" ]]; then
    ssid="${info%%:*}"
    signal="${info##*:}"
    printf '{"text":"󰖩 %s","tooltip":"Wi-Fi: %s (%s%%)","class":"connected"}\n' "$ssid" "$ssid" "$signal"
else
    printf '{"text":"","tooltip":"Wi-Fi disconnected","class":"disconnected"}\n'
fi
