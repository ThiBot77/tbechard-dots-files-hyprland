#!/usr/bin/env bash
set -euo pipefail

HYPR_LUA="$HOME/.config/hypr/hyprland.lua"
BEGIN="-- >>> desk layout (monitors.sh)"
END="-- <<< desk layout (monitors.sh)"

MAIN="AOC Q27G2WG4 0x0000B1BA"
SIM="AOC Q32G2WG3 PSAP6JA003894"
LEFT="ViewSonic Corporation VX2452 Series TVT163200713"

ok()   { printf '\033[32m[ ok ]\033[0m %s\n' "$1"; }
skip() { printf '\033[90m[ -- ]\033[0m %s\n' "$1"; }
die()  { printf '\033[31m[ !! ]\033[0m %s\n' "$1" >&2; exit 1; }

block() {
    cat <<EOF
$BEGIN
hl.monitor({ output = "desc:$LEFT", mode = "1920x1080@60", position = "0x180", scale = 1.0 })
hl.monitor({ output = "desc:$MAIN", mode = "2560x1440@143.91", position = "1920x0", scale = 1.0 })
hl.monitor({ output = "desc:$SIM", mode = "2560x1440@143.91", position = "1920x0", scale = 1.0, mirror = "desc:$MAIN" })
$END
EOF
}

command -v hyprctl >/dev/null || die "hyprctl missing, this is not the Hyprland machine"
[ -f "$HYPR_LUA" ] || die "Missing $HYPR_LUA. Run post-install.sh first."

CONNECTED="$(hyprctl monitors all -j)"
for desc in "$MAIN" "$SIM" "$LEFT"; do
    case "$CONNECTED" in
        *"$desc"*) ;;
        *) skip "Not the desk machine: $desc is not connected"; exit 0 ;;
    esac
done

if block | python3 -c '
import sys
begin, end, target = sys.argv[1], sys.argv[2], sys.argv[3]
want = sys.stdin.read().strip()
s = open(target).read()
if begin in s and end in s:
    have = s[s.index(begin):s.index(end) + len(end)].strip()
    sys.exit(0 if have == want else 1)
sys.exit(1)
' "$BEGIN" "$END" "$HYPR_LUA"; then
    skip "Layout already in place"
    exit 0
fi

cp -a "$HYPR_LUA" "$HYPR_LUA.avant-monitors-$(date +%Y%m%d-%H%M%S)"
block | python3 -c '
import sys
begin, end, target = sys.argv[1], sys.argv[2], sys.argv[3]
new = sys.stdin.read().rstrip("\n")
s = open(target).read()
if begin in s and end in s:
    s = s[:s.index(begin)] + new + s[s.index(end) + len(end):]
else:
    s = s.rstrip("\n") + "\n\n" + new + "\n"
open(target, "w").write(s)
' "$BEGIN" "$END" "$HYPR_LUA"
ok "Layout written: ViewSonic left, AOC 27 main, AOC 32 mirroring it"

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null && ok "Hyprland reloaded"
else
    skip "Hyprland not running, applied on next start"
fi
