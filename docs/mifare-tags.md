# MIFARE tags

**MIFARE** is NXP's family of 13.56 MHz smartcard products built on **ISO/IEC 14443
Type A**. They span from cheap fixed-memory tokens to full crypto smartcards. This
note maps the families to their security model and the relevant Proxmark3 (Iceman)
workflows.

## Family overview

| Family | Crypto | Memory / structure | Status |
|---|---|---|---|
| **MIFARE Classic 1K** | **Crypto1** (proprietary, 48-bit) | 16 sectors × 4 blocks (1KB); 2 keys (A/B) + access bits per sector; sector 0 block 0 holds UID + manufacturer data | **Broken** |
| **MIFARE Classic 4K** | Crypto1 | 32 sectors × 4 blocks + 8 sectors × 16 blocks (4KB) | **Broken** |
| **MIFARE Classic EV1 / Plus in SL1** | Crypto1 (+ hardened PRNG / static nonce on some) | as Classic | Broken, but harder (hardnested / static-nested) |
| **MIFARE Ultralight** | none | 64 bytes, no auth | Trivial to read/clone |
| **Ultralight C** | **3DES** auth | 192 bytes | Auth can be brute-forced offline in some cases |
| **Ultralight EV1 / NTAG21x** | 32-bit password (PWD/PACK) | small | Password sniffable/bruteforceable |
| **MIFARE Plus** | **AES**; security levels SL0–SL3 | Classic-compatible | SL3 = AES, considered sound; SL1 falls back to Crypto1 |
| **MIFARE DESFire EV1/EV2/EV3** | **AES / 3DES**, per-application keys | app + file filesystem (DF/EF) | Considered sound when configured well |

## Why MIFARE Classic is broken

Crypto1 is a 48-bit stream cipher with a weak nonce/PRNG. Practical attacks
recover keys and let you clone a card:

- **Darkside** — recovers a first key with no prior key, exploiting parity leaks
  (works on cards with a weak PRNG).
- **Nested** — once one sector key is known, recover the rest from the predictable
  nonce.
- **Hardnested** — for cards with a hardened (non-predictable) PRNG; needs one known
  key and more traces.
- **Static / static-encrypted nested** — for cards that emit a fixed nonce.
- **Nonce/key dictionary + fast check** — try known default keys en masse.

## Proxmark3 (Iceman) MIFARE workflow

Identify first:

```
hf search              # or:
hf 14a info            # ATQA/SAK/UID → hints at Classic vs UL vs DESFire
```

### MIFARE Classic

```
hf mf autopwn          # the one-shot: dict check → darkside/nested/hardnested →
                       # dumps all keys + data, writes a .bin/.json/.eml dump
hf mf fchk  --1k -f mfc_default_keys   # fast dictionary key check
hf mf nested / hardnested / darkside   # run a specific attack
hf mf dump / restore                   # read out / write back a full dump
hf mf cload / csetuid                  # write to "magic" (gen1a) cards
```

### "Magic" cards (for cloning targets)

- **Gen1a** — backdoor commands, UID + block 0 rewritable (`hf mf c*` commands).
- **Gen2 / CUID / FUID** — block 0 writable via normal write; behaves like a real card.
- **Gen3 / Gen4 (GTU / "ultimate magic")** — advanced, configurable behavior, APDU
  control of UID/ATQA/SAK, shadow modes.

### Ultralight / NTAG

```
hf mfu info            # identify UL / UL-C / EV1 / NTAG
hf mfu dump            # read pages
hf mfu restore         # write back (to writable/magic UL)
```

### MIFARE Plus / DESFire

```
hf mfp info / auth     # Plus
hf mfdes info / enum   # DESFire application & file enumeration
```

## Legal / ethical note

These techniques are for **authorized** research, testing systems you own or have
permission to assess, and education. Cloning credentials you don't own may be illegal.

## References

- Iceman command docs: `upstream/proxmark3/doc/md/Use_of_Proxmark/3_Commands-and-Features.md`
- MIFARE Classic cheat sheet: `upstream/proxmark3/doc/cheatsheet.md`
- Magic card notes: `upstream/proxmark3/doc/magic_cards_notes.md`
