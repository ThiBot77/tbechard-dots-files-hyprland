#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--dry-run" ]]; then
    export DRY_RUN=1
fi

for step in "$SCRIPT_DIR"/scripts/[0-9][0-9]-*.sh; do
    bash "$step"
done
