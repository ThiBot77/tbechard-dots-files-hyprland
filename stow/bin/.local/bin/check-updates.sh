#!/usr/bin/env bash
# JSON status for the waybar custom/updates module.
# Shows a package icon + count when updates are pending, nothing otherwise
# (waybar hides a module whose text is empty). Counts live in the tooltip.
set -euo pipefail

PKG_ICON=""

official="$(checkupdates 2>/dev/null | wc -l)"
aur="$(yay -Qua 2>/dev/null | wc -l)"
total=$((official + aur))

if [[ "$total" -eq 0 ]]; then
    printf '{"text":"","tooltip":"Système à jour"}\n'
else
    printf '{"text":"%s %d","tooltip":"%d mise(s) à jour\\n%d officielle(s), %d AUR"}\n' \
        "$PKG_ICON" "$total" "$total" "$official" "$aur"
fi
