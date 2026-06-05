# Unofficial AMD Redstone Benchmark

**Version 0.10.0** · [CHANGELOG](CHANGELOG.md) · Semantic Versioning (`0.x` = pre-1.0)

> **Disclaimer:** Independent community project — **not affiliated with, endorsed by, or sponsored by AMD**.
> "AMD", "FidelityFX", and "Redstone" are trademarks of Advanced Micro Devices, Inc., used here only
> descriptively to identify the benchmarked technology.

An unofficial CLI benchmark for AMD FidelityFX "Redstone" — built from AMD's FidelityFX SDK 2.2 samples
(FSR upscaling + ML Frame Generation, FSR Ray Regeneration, Neural Radiance Cache) and modified for
**automated, repeatable** benchmarking: every setting is reachable from the command line, no manual F1-panel
interaction. Built for **Linux / Proton (vkd3d-proton) on RDNA4** (RX 9070 XT); the source also builds and
runs on Windows.

## The three benchmarks

| Benchmark | Executable | Measures |
|---|---|---|
| **FSR** | `FidelityFX_FSR.exe` | FSR 4.x upscaling **and** ML Frame Generation |
| **Ray Regeneration** | `FidelityFX_Denoiser_Sample_2022.exe` | FSR Ray Regen ML denoiser (+ FSR upscale) |
| **Neural Radiance Cache** | `FidelityFX_NRC.exe` | NRC inference/training (WMMA vs FP32 reference) |

## What these mods add

- **Every UI knob → CLI flag** — scale preset, frame-gen, denoiser mode + tuning, NRC cache/animation,
  skydome time-of-day, etc. (full list: [docs/CLI_REFERENCE.md](docs/CLI_REFERENCE.md)).
- **`Display Avg FPS`** in the benchmark output — the *presented* frame rate (incl. frame-generation's
  interpolated frames), alongside the rendered `Avg FPS`. Makes the frame-gen uplift measurable straight
  from the CSV (e.g. 74 → 148 FPS with FG on). No external overlay needed.
- **Uncapped, GPU-bound benchmarking** (`-nolimit`, `-vsync 0`) — by default `-benchmark` force-enables a
  60 fps GPU limiter; `-nolimit` removes it (and its profiler pass) so the CSV reports true max throughput,
  and `-vsync 0` drops refresh-rate pacing.
- **Resolution from the CLI** for all three samples (`-resolution <W> <H>`).
- **CLI benchmark mode for NRC** — the custom (non-Cauldron) NRC sample had no benchmark; now it has
  `-benchmark duration=N` with a per-pass CSV writer + `-forcewmma` backend selection.
- **Timestamped output filenames** (`YYYY_MM_DD_HHMMSS_…`) so runs never overwrite; the full command line
  is recorded in each file.

## Layout

```
redstone-benchmark/
├── README.md
├── docs/
│   ├── BUILD.md           # build (Windows/VS2022) + Linux/Proton deploy
│   ├── USAGE.md           # how the benchmarks work, how to run, output format
│   └── CLI_REFERENCE.md   # every CLI flag, per sample
├── external/FidelityFX-SDK   # git submodule → AMD FidelityFX SDK, pinned to tag v2.2.0 (the base source)
├── src/                   # modified source files, mirroring the FFX SDK 2.2 layout (overlay)
├── patches/
│   └── redstone-benchmark.patch   # the same changes as a unified diff vs pristine v2.2.0
├── licenses/             # all applicable license texts + component→license map (licenses/README.md)
└── scripts/
    ├── overlay.sh         # copy src/ onto an extracted FFX SDK 2.2 tree
    ├── build-all.bat      # Windows: build all 3 solutions (Release|x64)
    ├── rebuild-all.bat    # Windows: clean rebuild (use after editing shared Cauldron files)
    └── run-sweep.sh       # Linux: labelled FG/preset/denoiser sweep across the 3 samples
```

## The AMD SDK as a submodule

The base source (AMD's FidelityFX SDK 2.2) is **not** copied into this repo — it's linked as a **git
submodule** at `external/FidelityFX-SDK`, pinned to tag **v2.2.0**
([github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK](https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK)).
A submodule is just a recorded pointer (URL + exact commit); the content is fetched on demand:

```bash
git clone --recursive <this-repo>           # clone + fetch the SDK in one step
# or, in an existing clone:
git submodule update --init --recursive     # populates external/FidelityFX-SDK @ v2.2.0
```

Our `src/`/patch overlays cleanly because the submodule's tree at v2.2.0 has the same `Kits/` + `Samples/`
layout. (Prefer the official release zip? Download `FidelityFX-Samples-v2.2.0-source.zip` and point the
scripts at it instead — both work.)

## Quick start

1. **Fetch the SDK submodule:** `git submodule update --init --recursive` (or `git clone --recursive`).
2. **Overlay the mods:** `scripts/overlay.sh` (defaults to the submodule), or apply
   `patches/redstone-benchmark.patch` inside `external/FidelityFX-SDK`.
3. **Build on Windows (VS2022):** see [docs/BUILD.md](docs/BUILD.md) — open the three `.sln`s or run
   `scripts/build-all.bat external/FidelityFX-SDK`.
4. **Deploy to Linux:** copy the `Release/` folders, swap in vkd3d-proton's `D3D12Core.dll`, run via
   `umu-run` — see [docs/USAGE.md](docs/USAGE.md).
5. **Run:** e.g. compare frame generation —
   ```bash
   umu-run FidelityFX_FSR.exe -benchmark duration=1000 -resolution 3840 2160 -scalepreset=0 -framegen=0
   umu-run FidelityFX_FSR.exe -benchmark duration=1000 -resolution 3840 2160 -scalepreset=0 -framegen=1
   # FG off: Avg 74.8 / Display 74.8   |   FG on: Avg 74.1 / Display 148.3
   ```

## Defaults

Out of the box (no flags), the benchmarks run at **1920×1080 (Full HD)** with FSR on the **Quality (1.5×)**
preset:

- Resolution — `Presentation.Width/Height` in `Kits/Cauldron2/dx12/framework/config/cauldronconfig.json`
  (FSR + Ray Regen) and `window.dimensions` in the NRC `config.json`, both set to `1920 × 1080`.
- FSR preset — both Cauldron samples default `m_ScalePreset = Quality` and now apply it at startup
  (previously the FSR sample fell back to a 2.0× ratio). At 1080p, Quality renders at **1280×720**.

Override either from the CLI: `-resolution <W> <H>` and `-scalepreset=0..6` (see
[docs/CLI_REFERENCE.md](docs/CLI_REFERENCE.md)).

## Examples — the four use cases

All four assume the Linux/Proton env from [docs/USAGE.md](docs/USAGE.md) is set and you're in the sample's
`…/x64/Release` directory. Each writes a timestamped CSV; the metric to read is noted.

**1. FSR — upscaling** (FidelityFX_FSR; frame-gen off to isolate the upscaler)
```bash
umu-run FidelityFX_FSR.exe -benchmark duration=2000 -framegen=0
#   defaults: 1080p, Quality (1.5x, render 1280x720). Try -scalepreset=0..4 to sweep quality/perf.
#   read: per-pass "FFX API FSR Upscaler" GPU time, and Avg FPS.
```

**2. FG — ML Frame Generation** (FidelityFX_FSR; frame-gen on)
```bash
umu-run FidelityFX_FSR.exe -benchmark duration=2000 -framegen=1
#   read: "Display Avg FPS" vs "Avg FPS" — with FG on, Display is ~2x the rendered rate.
```

**3. RR — FSR Ray Regeneration** (FidelityFX_Denoiser; ML denoiser)
```bash
umu-run FidelityFX_Denoiser_Sample_2022.exe -benchmark duration=2000 -denoisermode=0
#   defaults: 1080p, Quality. denoisermode 0=4 signals,1=2,2=1 (fewer = cheaper).
#   read: per-pass "FSR Ray Regeneration" GPU time.
```

**4. RC — Neural Radiance Cache** (FidelityFX_NRC)
```bash
umu-run FidelityFX_NRC.exe -benchmark duration=2000
#   defaults: 1080p, WMMA backend. Add -forcewmma=0 for the FP32 reference backend to compare.
#   read: "Radiance cache" per-pass GPU time + AvgFPS + the Backend column.
```

## Benchmark results

Reference numbers at 4K / FSR Quality (uncapped) for all four benchmarks are in
[`benchmarks/`](benchmarks/) — a graph-ready summary CSV, a per-pass breakdown CSV, and the raw
per-run output. See [benchmarks/README.md](benchmarks/README.md).

## Binary release

**Use prebuilt binaries (no build needed).** Download `redstone-benchmark-<version>.zip` from the project's
GitHub Releases, unzip, and follow the bundled `README.txt`:

```bash
unzip redstone-benchmark-<version>.zip && cd redstone-benchmark-<version>
PROTONPATH=/path/to/proton ./setup-linux.sh        # copies vkd3d-proton's D3D12Core from your Proton install
# fetch scene media via AMD MediaDelivery, set your Proton env, then run a sample (see docs/USAGE.md)
```

The archive holds the three sample `.exe`s + their redistributable runtime DLLs (AMD FidelityFX + ags/acs,
Microsoft Agility/PIX, DXC) + configs/shaders + [`licenses/`](licenses/README.md) + `setup-linux.sh`. It
deliberately **excludes** vkd3d-proton (LGPL) and scene media (per-asset licensing).

**Maintainers — build a release bundle** from a built SDK tree. The script writes to `dist/` (gitignored —
publish the zip as a GitHub Release asset, not in the git tree):

```bash
scripts/package-binaries.sh <FFX_ROOT>/Samples     # -> dist/redstone-benchmark-<version>.zip
```

## Licensing

- **This repo (`src/`, `patches/`, docs, scripts):** MIT — see `LICENSE`. The AMD framework/sample files we
  modify are in AMD's **MIT tier** (an 843-file exception list in the SDK license that includes every file
  we touch), so redistributing the modified source is permitted.
- **The AMD SDK is dual-licensed per file:** MIT for the Cauldron framework + samples (everything we touch),
  and a separate **binary-redistribution-only, no-reverse-engineering** license for the proprietary
  FidelityFX effect/ML DLLs (`amd_fidelityfx_*.dll`) and SDK core (`Kits/FidelityFX/`).
- **Binary releases** additionally bundle Microsoft (Agility SDK, PIX), DXC, and other components, each
  under its own license. Full component→license breakdown and all license texts:
  [`licenses/`](licenses/README.md).
- **Not redistributed:** vkd3d-proton (LGPL, fetched from your Proton install) and scene media
  (per-asset; fetched via AMD MediaDelivery).

FidelityFX is a trademark of Advanced Micro Devices, Inc. This repo does not vendor the SDK (see the
submodule above); see `NOTICE` for attribution.

## Acknowledgements

Created and maintained by **[Indie-Siggi](https://github.com/Indie-Siggi)**.

Developed with significant help from **Anthropic's Claude (Opus 4.8)**, used as an AI pair-programmer across
the source modifications, build/benchmark automation, hands-on testing on RDNA4 + Proton, and the
documentation — all under human direction, review, and validation on real hardware.
