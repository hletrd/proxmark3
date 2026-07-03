#!/usr/bin/env bash
# Read the card on the reader and compare it against a reference dump.
# Usage: mfc-verify.sh <dumpfile> [keyfile]
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SRC="${1:?usage: mfc-verify.sh <dumpfile> [keyfile]}"
KEY="${2:-}"
[ -f "$SRC" ] || { echo "reference not found: $SRC"; exit 1; }
[ -z "$KEY" ] && { g="${SRC%-dump.bin}-key.bin"; [ -f "$g" ] && KEY="$g"; }

mkdir -p "$REPO_ROOT/dumps"; tmp="$REPO_ROOT/dumps/.verify-$$"
kopt=""; [ -n "$KEY" ] && kopt="-k $KEY"

pm3run "hf mf dump --1k $kopt -f $tmp" >/dev/null || { echo "no device"; exit 1; }
if cmp -s "$tmp.bin" "$SRC"; then
  echo "✅ MATCH — card equals $(basename "$SRC")"; rm -f "$tmp.bin" "$tmp.json"
else
  echo "⚠️ DIFFER from $(basename "$SRC")"; rm -f "$tmp.bin" "$tmp.json"; exit 4
fi
