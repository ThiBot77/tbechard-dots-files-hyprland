#!/usr/bin/env bash
set -euo pipefail

TARGET="$HOME/.config/hypr/config/monitors.lua"

MAIN="AOC Q27G2WG4 0x0000B1BA"
SIM="AOC Q32G2WG3 PSAP6JA003894"
LEFT="ViewSonic Corporation VX2452 Series TVT163200713"

ok()   { printf '\033[32m[ ok ]\033[0m %s\n' "$1"; }
skip() { printf '\033[90m[ -- ]\033[0m %s\n' "$1"; }
die()  { printf '\033[31m[ !! ]\033[0m %s\n' "$1" >&2; exit 1; }

layout() {
    cat <<EOF
hl.monitor({
  output = "desc:$LEFT",
  mode = "1920x1080@60",
  position = "0x180",
  scale = 1.0,
})

hl.monitor({
  output = "desc:$MAIN",
  mode = "2560x1440@143.91",
  position = "1920x0",
  scale = 1.0,
})

hl.monitor({
  output = "desc:$SIM",
  mode = "2560x1440@143.91",
  position = "1920x0",
  scale = 1.0,
  mirror = "desc:$MAIN",
})

hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1.0,
})
EOF
}

command -v hyprctl >/dev/null || die "hyprctl missing, this is not the Hyprland machine"

CONNECTED="$(hyprctl monitors all -j)"
for desc in "$MAIN" "$SIM" "$LEFT"; do
    case "$CONNECTED" in
        *"$desc"*) ;;
        *) skip "Not this machine: $desc is not connected"; exit 0 ;;
    esac
done

if [ -f "$TARGET" ] && layout | cmp -s - "$TARGET"; then
    skip "Layout already in place"
    exit 0
fi

[ -f "$TARGET" ] && cp -a "$TARGET" "$TARGET.overwritten-$(date +%Y%m%d-%H%M%S)"
layout > "$TARGET"
ok "Layout restored: ViewSonic left, AOC 27 main, AOC 32 mirroring it"

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null && ok "Hyprland reloaded"
else
    skip "Hyprland not running, applied on next start"
fi
