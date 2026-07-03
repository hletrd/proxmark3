#!/usr/bin/env bash
# Flash bootrom + fullimage to the connected Proxmark3 (auto-detects the port).
# Any extra args are forwarded (e.g. --force).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
cd "$PM3_DIR"
exec ./pm3-flash-all "$@"
