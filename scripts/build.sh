#!/usr/bin/env bash
# Build the Proxmark3 client + firmware for a generic/Easy device.
# Env: PLATFORM (default PM3GENERIC). Extra args are passed to make.
#
# Note: homebrew-core's `arm-none-eabi-gcc` ships WITHOUT newlib and fails on
# `#include_next <stdint.h>`. We look for a newlib-equipped toolchain instead
# (the official ARM GNU toolchain, e.g. the `gcc-arm-embedded` cask, or a tarball
# extracted under ~/opt).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CROSS=""
for gcc in "$HOME"/opt/arm-gnu-toolchain-*/bin/arm-none-eabi-gcc \
           /Applications/ArmGNUToolchain/*/arm-none-eabi/bin/arm-none-eabi-gcc; do
  if [ -x "$gcc" ] && [ -f "$(dirname "$gcc")/../arm-none-eabi/include/stdint.h" ]; then
    CROSS="${gcc%gcc}"; break
  fi
done
if [ -z "$CROSS" ]; then
  echo "error: no newlib-equipped ARM toolchain found." >&2
  echo "  fix: brew install --cask gcc-arm-embedded   (see docs/workflows.md)" >&2
  exit 1
fi

echo "Using CROSS=$CROSS"
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
cd "$PM3_DIR"
make -j"$(sysctl -n hw.ncpu)" PLATFORM="${PLATFORM:-PM3GENERIC}" SKIPQT=1 CROSS="$CROSS" "$@"
