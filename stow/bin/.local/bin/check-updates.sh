#!/usr/bin/env bash
# JSON status for the waybar custom/updates module.
set -euo pipefail

official="$(checkupdates 2>/dev/null | wc -l)"
aur="$(yay -Qua 2>/dev/null | wc -l)"
total=$((official + aur))

printf '{"text":"%d","tooltip":"%d officiel(s), %d AUR"}\n' "$total" "$official" "$aur"
