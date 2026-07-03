# Proxmark3 and derivatives

## What the Proxmark3 is

The Proxmark3 is an open-source RFID research/attack tool that can operate on both
low-frequency (**125/134 kHz**) and high-frequency (**13.56 MHz**) bands. It can act
as a **reader**, a **tag/emulator**, and a **sniffer**, with the FPGA + ARM
architecture giving it low-level control over the RF signal that consumer readers
don't expose. It was created by **Jonathan Westhues** (~2007).

Architecture (all variants share this shape):

- **ARM MCU** (AT91SAM7S) — runs the firmware, talks USB to the host client.
- **FPGA** (Xilinx Spartan-II family) — does the real-time signal
  modulation/demodulation for LF and HF.
- **Analog front-end + two antenna ports** (one LF, one HF).

The host **client** (`proxmark3` / `pm3`) and the device **firmware** must be built
from the **same source version** — the flasher warns and stops on a mismatch.

## Hardware variants

| Variant | Notes |
|---|---|
| **Original Proxmark3** | Westhues' design; the reference the rest descend from. |
| **Proxmark3 RDV1 / RDV2** | Elechouse commercial revisions; RDV2 was widely cloned. |
| **Proxmark3 Easy** | Cheap RDV2-style clone (the common "generic" device). Older units 256KB flash, most modern ones **512KB**. No SIM slot, no onboard SPI flash, no FPC. Build target `PM3GENERIC`. |
| **Proxmark3 RDV4 / RDV4.01** | The flagship, maintained by RfidResearchGroup. 512KB ARM, **256KB onboard SPI flash**, **SIM/smartcard** module, **FPC** connector, and the **Blue Shark** Bluetooth/battery add-on (`PLATFORM_EXTRAS=BTADDON`). Build target `PM3RDV4` (the repo default). |
| **iCopy-X** | Turnkey automated cloner built on a Proxmark3 core. Build target `PM3ICOPYX`. |
| **Proxmark3 Ultimate** | Variant with XC2S50 FPGA. Build target `PM3ULTIMATE`. |
| **PM3 Evo / Proxmark Pro** | Different LED/button pinouts / FPGA; poorly or un-supported by the Iceman fork. |

Flash-size caveat: the Iceman firmware has grown past the 256KB limit, so 256KB
devices may not fit the full image (parts can be trimmed — see the STANDALONE and
options sections of the advanced-compilation doc). The MCU size (256/512) is
**auto-detected at flash time**.

## Firmware forks

- **Proxmark/proxmark3** (mainline) — the original upstream. Conservative, less
  actively developed.
- **RfidResearchGroup/proxmark3** ("**Iceman**" fork) — the de-facto standard. Vastly
  more tag support, attacks, standalone modes, and active maintenance. This is what
  we vendor and flash. The device on this host already identifies as `iceman`.

## Related / "derivative" tooling

Not Proxmark3 hardware, but part of the same RFID-research ecosystem and often used
alongside it:

- **ChameleonMini / ChameleonUltra** (the Ultra is an RfidResearchGroup project) —
  card **emulators** for 13.56 MHz (and LF on Ultra), good for replaying dumps a PM3
  extracted.
- **Flipper Zero** — consumer multi-tool with LF/HF RFID + NFC; weaker than a PM3 for
  deep attacks but convenient.
- **libnfc / ACR122U + mfoc/mfcuk/nfc-tools** — the "classic" MIFARE attack stack; PM3
  supersedes most of it for Crypto1 attacks.

## Key client entry points

```
hw version        # firmware/client versions, must match
hw status         # device self-report (flash size, FPGA, etc.)
hw tune           # antenna tuning — verify LF/HF antennas are healthy
lf search         # identify an LF tag
hf search         # identify an HF tag
hf 14a info       # ISO14443-A tag details (ATQA/SAK/UID/ATS)
```

## References

- Iceman fork: <https://github.com/RfidResearchGroup/proxmark3>
- Mainline: <https://github.com/Proxmark/proxmark3>
- Advanced compilation parameters: `upstream/proxmark3/doc/md/Use_of_Proxmark/4_Advanced-compilation-parameters.md`
- Command reference: `upstream/proxmark3/doc/commands.md` and the `_Commands-and-Features` docs.
