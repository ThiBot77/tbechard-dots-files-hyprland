#!/usr/bin/env bash
set -euo pipefail

TARGET="$HOME/.config/hypr/config/monitors.lua"

LAPTOP="LG Display 0x0764"
LEFT="HP Inc. HP E24 G4 CN41512CCR"
RIGHT="HP Inc. HP E24 G4 CN42023N27"

ok()   { printf '\033[32m[ ok ]\033[0m %s\n' "$1"; }
skip() { printf '\033[90m[ -- ]\033[0m %s\n' "$1"; }
die()  { printf '\033[31m[ !! ]\033[0m %s\n' "$1" >&2; exit 1; }

layout() {
    cat <<EOF
hl.monitor({
  output = "desc:$LAPTOP",
  mode = "1920x1080@60.02",
  position = "0x0",
  scale = 1.0,
})

hl.monitor({
  output = "desc:$LEFT",
  mode = "1920x1080@60",
  position = "1920x0",
  scale = 1.0,
})

hl.monitor({
  output = "desc:$RIGHT",
  mode = "1920x1080@60",
  position = "3840x0",
  scale = 1.0,
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
for desc in "$LEFT" "$RIGHT"; do
    case "$CONNECTED" in
        *"$desc"*) ;;
        *) skip "Not the Auchan desk: $desc is not connected"; exit 0 ;;
    esac
done

if [ -f "$TARGET" ] && layout | cmp -s - "$TARGET"; then
    skip "Layout already in place"
    exit 0
fi

[ -f "$TARGET" ] && cp -a "$TARGET" "$TARGET.overwritten-$(date +%Y%m%d-%H%M%S)"
layout > "$TARGET"
ok "Layout written: laptop left, HP CN41512CCR centre, HP CN42023N27 right"

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null && ok "Hyprland reloaded"
else
    skip "Hyprland not running, applied on next start"
fi
