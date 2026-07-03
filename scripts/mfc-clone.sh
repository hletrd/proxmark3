#!/usr/bin/env bash
# Clone a dump onto a Gen1a magic card and verify byte-for-byte.
# Auto-retries the write+verify up to 3x on transient RF/comm drops.
# Usage: mfc-clone.sh <dumpfile> [keyfile]
#   dumpfile  a .bin/.eml/.json dump (a raw 1024/4096-byte .bin works too)
#   keyfile   optional; defaults to <base>-key.bin next to the dump if present
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SRC="${1:?usage: mfc-clone.sh <dumpfile> [keyfile]}"
KEY="${2:-}"
[ -f "$SRC" ] || { echo "dump not found: $SRC"; exit 1; }
[ -z "$KEY" ] && { g="${SRC%-dump.bin}-key.bin"; [ -f "$g" ] && KEY="$g"; }

mkdir -p "$REPO_ROOT/dumps"; tmp="$REPO_ROOT/dumps/.verify-$$"
kopt=""; [ -n "$KEY" ] && kopt="-k $KEY"

for try in 1 2 3; do
  w="$(pm3run "hf mf cload -f $SRC --1k")"
  if printf '%s' "$w" | grep -qi "Card loaded 64 blocks"; then
    pm3run "hf mf dump --1k $kopt -f $tmp" >/dev/null
    if cmp -s "$tmp.bin" "$SRC"; then
      echo "✅ PASS — clone byte-for-byte identical to $(basename "$SRC")"
      rm -f "$tmp.bin" "$tmp.json"; exit 0
    fi
  fi
  echo "  attempt $try failed; retrying..."; sleep 1
done
echo "⚠️ FAIL after 3 attempts — reseat the card flat & centered on the HF coil"
rm -f "$tmp.bin" "$tmp.json"; exit 4
