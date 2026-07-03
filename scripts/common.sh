#!/usr/bin/env bash
# Shared helpers for the Proxmark3 workflow scripts. Source this from the others.
# Resolves repo paths and provides pm3run() with retry-on-transient-disconnect.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PM3_DIR="$REPO_ROOT/upstream/proxmark3"
PM3="$PM3_DIR/pm3"

# Run a single pm3 command and echo its output.
# Retries on the transient USB-CDC "cannot communicate" that often follows a card swap.
pm3run() {
  local out i
  for i in 1 2 3 4 5 6; do
    out="$("$PM3" -c "$1" 2>&1)" || true
    if printf '%s' "$out" | grep -qiE "cannot communicate"; then sleep 2; continue; fi
    printf '%s' "$out"
    return 0
  done
  printf '%s' "$out"
  return 1
}
