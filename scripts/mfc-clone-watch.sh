#!/usr/bin/env bash
# Hands-free batch cloning. Run it in your own terminal, then just swap cards:
#   place a blank magic card -> auto clone+verify -> remove it -> place the next -> ...
# Usage: mfc-clone-watch.sh <dumpfile> [keyfile]      (Ctrl-C to stop)
#
# It skips a card whose UID already equals the gold dump's UID (i.e. an
# already-cloned card left on the reader), so you won't double-write.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

SRC="${1:?usage: mfc-clone-watch.sh <dumpfile> [keyfile]}"
KEY="${2:-}"
[ -f "$SRC" ] || { echo "dump not found: $SRC"; exit 1; }
[ -z "$KEY" ] && { g="${SRC%-dump.bin}-key.bin"; [ -f "$g" ] && KEY="$g"; }

# Gold UID guessed from the dump filename (hf-mf-<UID>-dump.bin), else read block 0.
TARGET_UID="$(basename "$SRC" | grep -oiE '[0-9a-f]{8}' | head -1 | tr 'a-f' 'A-F')"

uid_now() {
  pm3run "hf 14a info" | awk -F'UID:' '/UID:/{gsub(/[^0-9A-Fa-f]/,"",$2); print toupper($2); exit}'
}

echo "Watch mode (gold UID=${TARGET_UID:-?}). Place a blank magic card; remove after PASS. Ctrl-C to stop."
n=0
while true; do
  uid="$(uid_now)"
  [ -z "$uid" ] && { sleep 1; continue; }                # no card present
  [ -n "$TARGET_UID" ] && [ "$uid" = "$TARGET_UID" ] && { sleep 1; continue; }  # already cloned
  echo "[*] blank card $uid detected -> cloning..."
  if "$(dirname "${BASH_SOURCE[0]}")/mfc-clone.sh" "$SRC" "$KEY"; then
    n=$((n + 1)); echo "[#$n] done — remove the card for the next one"
  else
    echo "  clone failed — remove & re-place to retry"
  fi
  while [ -n "$(uid_now)" ]; do sleep 1; done            # wait for card removal
done
