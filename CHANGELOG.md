# Changelog

All notable changes to this project are documented here. Versioning follows
[Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`); `0.x` = pre-1.0 / API may still change.

## [0.10.0] — 2026-06-05

### Added
- **`-nolimit`** — disable the FPS limiter for true GPU-bound benchmarking. Overrides the `-benchmark`
  forced-60 GPU cap (and any config / `-cpulimiter` / `-gpulimiter` setting), regardless of argument order,
  and drops the limiter's own GPU pass from the per-pass breakdown. The `-benchmark` CSV now reports the
  uncapped rate directly (no external overlay needed).
- **`-vsync 0|1`** — override vertical sync from the CLI (default on). Pair `-vsync 0` with `-nolimit` for a
  fully uncapped run.

Both flags apply to the two Cauldron samples (FSR + Ray Regen). NRC already presents uncapped (no vsync, no
limiter) and is unaffected.

## [0.9.0] — 2026-06-04

Initial public release. CLI-driven benchmark builds of AMD's FidelityFX SDK 2.2 "Redstone" samples for
automated, repeatable benchmarking on Linux/Proton (RDNA4) — and Windows.

### Added
- **Every UI knob exposed as a CLI flag** across all three benchmarks (FSR upscaling, ML Frame Generation,
  FSR Ray Regeneration, Neural Radiance Cache). See `docs/CLI_REFERENCE.md`.
- **`Display Avg FPS`** in the benchmark output — the presented frame rate (incl. frame-generation's
  interpolated frames) alongside the rendered `Avg FPS`, so frame-gen uplift is measurable from the CSV.
- **CLI resolution** (`-resolution <W> <H>`) for all three samples.
- **NRC benchmark mode** (`-benchmark duration=N`, per-pass CSV writer) + `-forcewmma` backend selection —
  the custom NRC harness had no benchmark before.
- **Skydome / scene-look CLI flags** (time-of-day, luminance, etc.).
- **Timestamped output files** (`YYYY_MM_DD_HHMMSS_…`) so runs never overwrite.
- AMD FidelityFX SDK linked as a **git submodule** pinned to tag v2.2.0.
- **`licenses/`** with the dual-tier breakdown; **binary-release packaging** (`scripts/package-binaries.sh`,
  `scripts/setup-linux.sh`).

### Changed
- **Defaults** set to **1920×1080** and FSR **Quality (1.5×)** preset (the FSR sample now applies its
  Quality default at startup instead of silently running at 2.0×).

[0.10.0]: https://github.com/Indie-Siggi/redstone-benchmark/releases/tag/v0.10.0
[0.9.0]: https://github.com/Indie-Siggi/redstone-benchmark/releases/tag/v0.9.0
