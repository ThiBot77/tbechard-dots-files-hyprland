#!/usr/bin/env bash
# JSON status for the waybar custom/vpn module: shows an icon only when a
# VPN/WireGuard/OpenVPN connection is actually up.
set -euo pipefail

active="$(nmcli -t -f name,type,active con show \
    | awk -F: '($2=="vpn" || $2=="wireguard" || $2=="openvpn") && $3=="yes"{print $1}')"

if [[ -n "$active" ]]; then
    names="$(paste -sd, - <<< "$active")"
    printf '{"text":"󰞃","tooltip":"VPN: %s","class":"connected"}\n' "$names"
else
    printf '{"text":"","tooltip":"No VPN active","class":"disconnected"}\n'
fi
