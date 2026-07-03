# Device notes — the Proxmark3 on this host

The physical device connected to this Mac while setting up the workspace.

## Identity

| Property | Value |
|---|---|
| Type | **Proxmark3 Easy / generic** (build target `PM3GENERIC`) |
| USB vendor | `proxmark.org` (VID `0x9AC4`) |
| USB product | `proxmark3` (PID `0x4B8F`) |
| USB serial | `iceman` |
| Serial port (macOS) | `/dev/tty.usbmodemiceman1` (a.k.a. `/dev/cu.usbmodemiceman1`) |

## Hardware (from `hw version`)

- MCU: **Atmel AT91SAM7S512 Rev B** (ARM7TDMI)
- Internal SRAM: 64 KB
- **Embedded flash: 512 KB** (~74% used after flashing) — comfortably fits the full
  Iceman image
- FPGA: Xilinx Spartan-II **2s30vq100** (`xc2s30`)
- Installed standalone mode: **LF HID26 / SamyRun**

## Firmware history

| When | Bootrom / OS | Compiler |
|---|---|---|
| As received | `Iceman v4.21128-461-g84bc06865` (2026-04-12) | GCC 13.3.1 |
| **After flash** | `Iceman/main/b4fc4a59e` (2026-07-03) | GCC 15.2.1 |

Before flashing, the client warned:
`ARM firmware does not match the source at the time the client was compiled`.
After flashing the freshly built images, bootrom + OS + client are all in sync and the
warning is gone. The `-dirty` build suffix reflects one local source patch (see below).

## How it was built & flashed on this host

macOS 26 (Apple Silicon, arm64). The homebrew-core `arm-none-eabi-gcc` bottle lacks
newlib (fails on `#include_next <stdint.h>`), so the **official ARM GNU toolchain**
(`arm-gnu-toolchain-15.2.rel1-darwin-arm64-arm-none-eabi`, the same build the
`gcc-arm-embedded` cask installs, which bundles newlib) was used via an explicit
`CROSS=` path — no sudo, subtree left pristine except one fix.

```sh
cd upstream/proxmark3
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
CROSS="$HOME/opt/arm-gnu-toolchain-15.2.rel1-darwin-arm64-arm-none-eabi/bin/arm-none-eabi-"
make clean && make -j"$(sysctl -n hw.ncpu)" PLATFORM=PM3GENERIC SKIPQT=1 CROSS="$CROSS"
./pm3-flash-all        # bootrom + fullimage, port auto-detected
```

### Local patch carried on the subtree

Upstream `master` at the vendored commit had a missing semicolon in
`client/src/cmdhfjooki.c` (`uint8_t blockwidth = 4` → `= 4;`) that broke the client
build. It's fixed as a local commit on top of the subtree and will merge away when
upstream fixes it (or on the next `git subtree pull`).

## Quick sanity checks

```sh
cd upstream/proxmark3
./pm3 -c "hw version"   # versions must match between client and ARM
./pm3 -c "hw status"    # board self-report
./pm3 -c "hw tune"      # antenna health (LF/HF voltages)
```
