# GBA for Analogue Pocket

LLM assisted port of [MiSTer GBA core](https://github.com/MiSTer-devel/GBA_MiSTer) with **Auto-RTC Detection**.

## Features

- **Filters**
- **Save States**
- **Fast Forward (Bound to Y button)**
- **Button Turbo (Bound to X button)**
- **Automatic RTC Detection** (Retail games, SDK homebrew, & ROM hacks)
- **Link Cable** - 2/3/4p Multiplayer, GCN link, GBA wireless, Single Pak download
- **Rumble (DS Rumble Pak)**

## Fast Forward

You can change fast forward behavior with the "Fast Forward Render" setting in the menu. Choices are:

- Fastest: core runs as fast as possible, highest possible fast forward speed but can show tearing/mixed/corrupted frames in some games.
- Stable: wait for full frames. video during fast forward is MUCH more stable, however max fast forward speed is decreased.

## RTC and Save Compatibility

- **Dedicated Sidecar Slot (0.8.0+):** RTC timestamp is saved as an external `.rtc` file next to the `.sav`. This ensures the `.sav` remains standard-sized (64KB/128KB) and 100% compatible with mGBA, EverDrive, and physical hardware.
- **Legacy Footers:** Older releases appended RTC data to the `.sav`. The core includes backwards-compatible downgrade and migration flows.

## Auto-RTC & RTC Mode

Unlike vanilla GBA cores that either lacked RTC or required manual menu toggling, this core features **triple-layer automatic RTC detection**:

1. **Quirk Database:** Automatic detection for retail games (*Pokémon Ruby, Sapphire, Emerald*, *Boktai* series, *Rockman EXE 4*, etc.).
2. **Signature Scanning:** Scans the incoming ROM stream during APF loading for the Nintendo SDK `"SIIRTC_V"` driver signature.
3. **ROM Hack Recognition:** Inspects header titles and game codes to automatically recognize popular RTC ROM hacks (*Pokémon Unbound*, *Radical Red*, *Liquid Crystal*, *Inclement Emerald*, CFRU builds).

### RTC Mode Setting (in Core Menu)
- **Auto (Default):** Automatically enables RTC for detected games/hacks and leaves it disabled for games without an RTC (preventing GPIO address collision crashes).
- **Force On:** Manual override that forces RTC and GPIO on (useful for unlisted custom ROM hacks).
- **Force Off:** Manual override that forces RTC off.

## Accuracy

This core replicates the current accuracy of the MiSTer GBA core master branch. It scores similarly to the MiSTer core in the mGBA test suite. If you encounter a game that works on MiSTer but not here, please open an issue.

## Installation

1. Download the latest release.
2. Copy the 3 folders `Cores/`, `Platforms/`, `Assets/` to the root of your SD card.
   - **macOS users:** Note: macOS Finder replaces folders instead of merging them so merge manually.
3. Place your ROMs and `gba_bios.bin` in `/Assets/gba/common/`.

## Known Issues

- **Fast forward speed varies by game** — Games that make heavy use of the GBA's slower external RAM will not fast-forward as quickly as games that primarily use internal RAM.
- **Fast forward creates visible screen tearing** — Tear-free fast forward requires a full double frame buffer.
- **64MB Video carts do not work** (GBA Video carts).

## Building from Source

### Prerequisites

- Docker
- `raetro/quartus:21.1` Docker image

### Build

```bash
./scripts/build.sh
```

## Credits

- **[MiSTer GBA core](https://github.com/MiSTer-devel/GBA_MiSTer)** — original FPGA GBA implementation
- **[mincer-ray/openfpga-GBA](https://github.com/mincer-ray/openfpga-GBA)** — openFPGA GBA port for Analogue Pocket
- **[budude2/openfpga-GBC](https://github.com/budude2/openfpga-GBC)** — reference for MiSTer-to-Pocket porting patterns
- **[agg23](https://github.com/agg23)** — analogue-pocket-utils and reference SNES/NES Pocket cores

## License

GPL-2.0 — see [GBA_MiSTer LICENSE](https://github.com/MiSTer-devel/GBA_MiSTer/blob/master/LICENSE) for details.
