#!/usr/bin/env bash
# Quick rofi menu for wifi + VPN, bound to the waybar network module (left-click).
set -euo pipefail

active_wifi="$(nmcli -t -f active,ssid dev wifi list | awk -F: '$1=="yes"{print $2; exit}')"

mapfile -t wifi_lines < <(nmcli -t -f ssid,signal dev wifi list \
    | awk -F: '$1!=""' | sort -t: -k2 -rn | awk -F: '!seen[$1]++')

mapfile -t vpn_names < <(nmcli -t -f name,type con show \
    | awk -F: '$2=="vpn" || $2=="wireguard" || $2=="openvpn" {print $1}')
mapfile -t active_vpns < <(nmcli -t -f name,type,active con show \
    | awk -F: '($2=="vpn" || $2=="wireguard" || $2=="openvpn") && $3=="yes"{print $1}')

is_active_vpn() {
    local name="$1"
    for v in "${active_vpns[@]:-}"; do [[ "$v" == "$name" ]] && return 0; done
    return 1
}

menu="Wi-Fi\n"
for line in "${wifi_lines[@]}"; do
    ssid="${line%%:*}"
    signal="${line##*:}"
    mark=" "
    [[ "$ssid" == "$active_wifi" ]] && mark="x"
    menu+="  [$mark] $ssid ($signal%)\n"
done
if [[ ${#vpn_names[@]} -gt 0 ]]; then
    menu+="VPN\n"
    for v in "${vpn_names[@]}"; do
        mark=" "
        is_active_vpn "$v" && mark="x"
        menu+="  [$mark] $v\n"
    done
fi
menu+="Network settings...\n"

chosen="$(printf '%b' "$menu" | rofi -dmenu -i -p "Network")"
[[ -z "$chosen" ]] && exit 0

case "$chosen" in
    "Network settings...")
        exec nm-connection-editor
        ;;
    "Wi-Fi"|"VPN")
        exit 0
        ;;
esac

name="$(sed -E 's/^  \[.\] //; s/ \([0-9]+%\)$//' <<< "$chosen")"

is_vpn=0
for v in "${vpn_names[@]:-}"; do [[ "$v" == "$name" ]] && is_vpn=1; done

if [[ "$is_vpn" -eq 1 ]]; then
    if is_active_vpn "$name"; then
        nmcli con down id "$name" && notify-send "VPN" "$name désactivé"
    else
        nmcli con up id "$name" && notify-send "VPN" "$name activé"
    fi
    exit 0
fi

if [[ "$name" == "$active_wifi" ]]; then
    exit 0
fi

if nmcli con up id "$name" >/dev/null 2>&1; then
    notify-send "Wi-Fi" "Connecté à $name"
else
    password="$(rofi -dmenu -password -p "Mot de passe pour $name")"
    [[ -z "$password" ]] && exit 0
    if nmcli dev wifi connect "$name" password "$password" >/dev/null 2>&1; then
        notify-send "Wi-Fi" "Connecté à $name"
    else
        notify-send "Wi-Fi" "Échec de connexion à $name"
    fi
fi
