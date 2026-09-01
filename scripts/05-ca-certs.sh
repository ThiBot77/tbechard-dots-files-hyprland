#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log_step "Trusted CA certificates"

# Avant l'installation des paquets : derriere un proxy TLS d'entreprise, les
# telechargements suivants echouent tant que son CA n'est pas approuve.
CERT_DIR="$REPO_DIR/certs"
ANCHOR_DIR="/etc/ca-certificates/trust-source/anchors"

shopt -s nullglob
certs=("$CERT_DIR"/*.crt)
shopt -u nullglob

if [[ ${#certs[@]} -eq 0 ]]; then
    log_info "No certificate in certs/ — nothing to trust."
    exit 0
fi

if ! command -v update-ca-trust >/dev/null 2>&1; then
    log_warn "update-ca-trust not found — skipping (it ships with ca-certificates-utils)."
    exit 0
fi

changed=0
for cert in "${certs[@]}"; do
    name="$(basename "$cert")"
    target="$ANCHOR_DIR/$name"

    # Compare le contenu, pas seulement la presence : un CA reemis garde son nom
    # de fichier, et c'est justement le cas ou il faut remplacer l'ancien.
    if [[ -f "$target" ]] && cmp -s "$cert" "$target"; then
        continue
    fi

    if ! openssl x509 -in "$cert" -noout >/dev/null 2>&1; then
        log_warn "$name is not a readable PEM certificate — skipping it."
        continue
    fi

    log_info "Trusting $name ($(openssl x509 -in "$cert" -noout -subject -nameopt multiline \
        | sed -n 's/^ *commonName *= //p'))"
    run sudo install -m 644 -D "$cert" "$target"
    changed=1
done

if [[ "$changed" == "1" ]]; then
    run sudo update-ca-trust
    log_info "System trust store rebuilt."
else
    log_info "Every certificate in certs/ is already trusted."
fi
