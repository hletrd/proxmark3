# Workflows & scripts

End-to-end operational playbook for this workspace, plus the reusable scripts in
[`scripts/`](../scripts). All scripts resolve repo paths themselves and connect to
the device via the built `pm3` client under `upstream/proxmark3`.

> Card dumps and recovered keys are **gitignored** (`dumps/`, `*.dump`, `hf-mf-*`,
> `*-key.bin`) and never pushed. Keep it that way.

## Scripts at a glance

| Script | Purpose |
|---|---|
| `scripts/build.sh` | Build client + firmware (`PLATFORM=PM3GENERIC`, `SKIPQT=1`); auto-finds a newlib ARM toolchain. |
| `scripts/flash.sh` | `pm3-flash-all` (bootrom + fullimage), port auto-detected. |
| `scripts/mfc-dump.sh [name]` | Recover keys + dump a MIFARE Classic (autopwn); optional `dumps/<name>.dump` copy. |
| `scripts/mfc-clone.sh <dump> [key]` | Write a dump to a Gen1a magic card + verify byte-for-byte (auto-retries 3×). |
| `scripts/mfc-verify.sh <dump> [key]` | Read the card on the reader and compare to a reference dump. |
| `scripts/mfc-clone-watch.sh <dump> [key]` | Hands-free batch: swap cards, each auto-clones+verifies. |
| `scripts/common.sh` | Shared helpers (`pm3run` with retry-on-transient-disconnect). |

## Build

```sh
scripts/build.sh                 # PLATFORM=PM3GENERIC by default
PLATFORM=PM3RDV4 scripts/build.sh
```

**Toolchain gotcha (macOS):** homebrew-core's `arm-none-eabi-gcc` ships **without
newlib**, so the firmware build dies on `fatal error: stdint.h` (`#include_next`).
Use a newlib-equipped toolchain — the official ARM GNU toolchain:

```sh
brew install --cask gcc-arm-embedded          # installs to /Applications/ArmGNUToolchain/...
# or extract the tarball under ~/opt (no sudo):
#   https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
```

`build.sh` auto-detects either location.

## Flash

```sh
scripts/flash.sh                 # add --force only if you understand the version-mismatch warning
```

Button trick if auto-detect fails: unplug, hold button, plug in, release — two LEDs stay lit.

## Identify a card

```sh
cd upstream/proxmark3
./pm3 -c "hf mf info"            # type, size, keys, magic capabilities, PRNG
./pm3 -c "hf 14a info"           # raw ISO14443-A (ATQA/SAK/UID/ATS)
```

Key fields: **SAK 08 / ATQA 0004 → MIFARE Classic 1K**; the **PRNG** line tells you
which attack family applies (see below); the **Magic** line tells you if it's a
writable clone target.

## Dump a MIFARE Classic

```sh
scripts/mfc-dump.sh WEAREHERE_109      # runs autopwn, copies to dumps/WEAREHERE_109.dump
```

`autopwn` runs staged recovery — **dictionary → darkside → nested → hardnested →
static-nested** — stopping as soon as it has every key, then dumps to
`~/hf-mf-<UID>-dump.{bin,json}` and keys to `~/hf-mf-<UID>-key.bin`.

Which attack applies (from the PRNG line):

| PRNG | Attack (the "nested" family) |
|---|---|
| `weak` | plain **nested** (needs 1 known key) or **darkside** (needs none) |
| `hardened` | **hardnested** |
| `static nonce` | **static-nested** (`hf mf staticnested`) — plain nested does *not* apply |

> In this workspace's card, every sector used the default key `FFFFFFFFFFFF`, so the
> dictionary stage recovered all keys instantly and no nonce attack was needed —
> even though the card reports a **static nonce**.

## Clone to a magic card

```sh
scripts/mfc-clone.sh ~/hf-mf-5A07EC08-dump.bin        # key file auto-found as ...-key.bin
```

Writes all 64 blocks (incl. **block 0 / UID**) via the **Gen1a backdoor** (`hf mf
cload`), then reads back and `cmp`s against the source. Retries 3× on transient RF
drops (a mid-write "Can't set magic card block: N" is almost always poor coupling —
reseat the card flat and centered on the HF coil).

### Magic card types

| Type | Block-0 write | Command |
|---|---|---|
| **Gen1a** (UID-changeable, backdoor) | backdoor, no keys | `hf mf cload` |
| **Gen2 / CUID / FUID** | direct write after auth | `hf mf restore` |
| **Gen3** | APDU to set UID | `hf mf gen3*` |
| **Gen4 / GTU / USCUID / GDM** | configurable "ultimate" magic | `hf mf cload --gdm`, `hf mf gview`, etc. |

The cards used here report **Gen1a + Gen4 GDM/USCUID**, so `cload` (Gen1a) is the most
reliable path and guarantees block 0 is written. For strict Gen2/CUID cards use
`hf mf restore --1k -f <dump>` instead.

## Verify

```sh
scripts/mfc-verify.sh ~/hf-mf-5A07EC08-dump.bin       # ✅ MATCH / ⚠️ DIFFER
```

## Batch / hands-free

Run in your own terminal and just swap cards — it detects each blank, clones,
verifies, then waits for removal:

```sh
scripts/mfc-clone-watch.sh ~/hf-mf-5A07EC08-dump.bin
```

It skips a card whose UID already equals the gold dump's (an already-cloned card left
on the reader), so it won't double-write.

## Gotchas seen in practice

- **Exclusive serial port** — only one client at a time. An interactive `./pm3` in
  another terminal holds `/dev/tty.usbmodemiceman1`; quit it before scripting.
- **Transient "cannot communicate"** right after handling the device / swapping a
  card — `pm3run` retries automatically.
- **`.dump` extension** — `hf mf cload`/`dump` detect format by extension
  (`bin`/`eml`/`json`); pass the `.bin` to the scripts, not the renamed `.dump`.
