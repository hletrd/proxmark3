# proxmark3

A research workspace for the **Proxmark3** RFID platform (and its derivatives) and
**MIFARE** tags. The upstream firmware/client source is vendored here as a
**git subtree** so it stays fully buildable locally and can be refreshed from
upstream on demand.

## Repository layout

```
.
├── README.md                       # this file
├── docs/                           # research notes
│   ├── device-notes.md             # the specific device connected to this host
│   ├── proxmark3-and-derivatives.md# hardware/firmware landscape
│   └── mifare-tags.md              # MIFARE families + relevant PM3 workflows
└── upstream/
    └── proxmark3/                  # git subtree of RfidResearchGroup/proxmark3 (Iceman)
```

### Why a subtree (not a submodule)

The full upstream source lives *inside* this repo, so a fresh clone builds without
extra `git submodule` steps, and the vendored code is pinned to an exact commit.
Updates are pulled explicitly:

```sh
# refresh the Iceman source to upstream master
git subtree pull --prefix upstream/proxmark3 \
    https://github.com/RfidResearchGroup/proxmark3.git master --squash
```

The subtree was added with:

```sh
git subtree add --prefix upstream/proxmark3 \
    https://github.com/RfidResearchGroup/proxmark3.git master --squash
```

## The Iceman fork

We vendor the [**RfidResearchGroup/proxmark3**](https://github.com/RfidResearchGroup/proxmark3)
fork (the "Iceman" fork). It is the de-facto standard firmware for Proxmark3
devices — far more features, tag support, and attacks than the original
[Proxmark/proxmark3](https://github.com/Proxmark/proxmark3) mainline. The device
attached to this host already reports the `iceman` USB descriptor.

## Building (macOS, Apple Silicon)

Dependencies (Homebrew):

```sh
brew install readline coreutils pkgconf openssl@3 gd libusb
brew install arm-none-eabi-gcc        # ARM cross-compiler for the firmware
```

Build the client + firmware for a **generic / Easy** (non-RDV4) device. We pass the
platform on the command line to keep the subtree pristine for `git subtree pull`:

```sh
cd upstream/proxmark3
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
make clean && make -j"$(sysctl -n hw.ncpu)" PLATFORM=PM3GENERIC SKIPQT=1
```

- `PLATFORM=PM3GENERIC` — correct target for a Proxmark3 Easy / generic clone.
  (Default is `PM3RDV4`. Other values: `PM3ICOPYX`, `PM3ULTIMATE`.)
- `SKIPQT=1` — skip the optional Qt GUI plot window; the CLI is all that's needed
  for flashing and normal use.

The MCU flash size (256KB vs 512KB) is auto-detected at flash time.

## Flashing

Put the device in bootloader mode is usually automatic; if auto-detect fails, use the
**button trick**: unplug, hold the button, plug in, release — two LEDs stay lit.

```sh
cd upstream/proxmark3
./pm3-flash-all           # flashes bootrom.elf + fullimage.elf, auto-detects the port
```

If the client and firmware come from different source versions the flasher stops with
a mismatch warning; add `--force` only if you understand why.

## Running the client

```sh
cd upstream/proxmark3
./pm3                     # auto-detects the serial port
# or explicitly:
./client/proxmark3 /dev/tty.usbmodemiceman1
```

Handy first commands: `hw version`, `hw status`, `hw tune` (antenna health),
`hf search`, `lf search`.

## Research notes

- [`docs/device-notes.md`](docs/device-notes.md) — the connected device
- [`docs/proxmark3-and-derivatives.md`](docs/proxmark3-and-derivatives.md) — hardware & firmware landscape
- [`docs/mifare-tags.md`](docs/mifare-tags.md) — MIFARE tag families & PM3 workflows

## License / attribution

The vendored `upstream/proxmark3` tree retains its original license
(GPL-3.0, see `upstream/proxmark3/LICENSE.txt`) and authorship. This repository is a
research workspace only.
