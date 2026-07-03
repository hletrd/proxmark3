#!/usr/bin/env bash
# Recover keys and dump a MIFARE Classic card via autopwn
# (dictionary -> darkside/nested/hardnested/static-nested as needed).
# Usage: mfc-dump.sh [name]
#   name  optional; also copies the .bin to dumps/<name>.dump
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
name="${1:-}"

out="$(pm3run "hf mf autopwn")" || { echo "no device"; exit 1; }
printf '%s\n' "$out" | grep -iE "static nonce|Found keys|Saved .*bytes|dumped|Autopwn execution" || true

bin="$(printf '%s' "$out" | grep -oE '/[^ `]+-dump\.bin' | head -1)"
[ -n "$bin" ] || { echo "no dump produced (see output above)"; exit 2; }
echo "dump: $bin"

if [ -n "$name" ]; then
  mkdir -p "$REPO_ROOT/dumps"
  cp "$bin" "$REPO_ROOT/dumps/$name.dump"
  echo "copy: $REPO_ROOT/dumps/$name.dump"
fi
