# Benchmark results — 4K / FSR Quality

Reference numbers for the four Redstone benchmarks at **3840×2160 display, FSR Quality (1.5×)
preset** (render 2560×1440), run **uncapped** (`-nolimit -vsync 0`) so the figures reflect true
GPU-bound throughput. **One run per benchmark** (no averaging — single-run variance applies).

Neural Radiance Cache is not an upscaler, so "FSR Quality" does not apply to it; it is run at
**native 4K** instead.

## Environment

| | |
|---|---|
| GPU | AMD Radeon RX 9070 XT (RDNA4, RADV `GFX1201`) |
| Translation | vkd3d-proton 3.1.0 (Proton-CachyOS `cachyos-11.0-20260521-slr`) via `umu-run` |
| Mesa | 26.1.1 (Arch `rayregen` distrobox) |
| GPU power | stock voltage, 250 W cap |
| Build | redstone-benchmark v0.10.0 |
| Date | 2026-06-05 |

## Results

| Benchmark | Render res | Avg FPS (rendered) | Display FPS (presented) | Total GPU (ms) | Key pass (ms) |
|---|---|---|---|---|---|
| FSR upscaling | 2560×1440 | 145.9 | 145.9 | 6.15 | FSR Upscaler 1.97 |
| FSR Frame Generation | 2560×1440 | 104.9 | **209.7** | 6.63 | FSR Upscaler 1.97 |
| FSR Ray Regeneration | 2560×1440 | 50.7 | 50.7 | 19.23 | FSR Ray Regeneration 9.20 |
| Neural Radiance Cache | 3840×2160 | 36.8 | 36.8 | 26.75 | Radiance cache 5.15 |

- **Display FPS** counts presented frames (incl. frame-generation's interpolated frames). With FG on it
  is ~2× the rendered rate here (the GPU has headroom at 1440p render → clean interpolation).
- **Total GPU** is the sum of all profiled per-pass GPU times for that frame.

## Files (for graphing)

| File | Shape | Use |
|---|---|---|
| `4k-fsr-quality.csv` | one row per benchmark | bar charts: FPS, total GPU, key-pass cost |
| `4k-fsr-quality-passes.csv` | long: `benchmark, pass, gpu_ms` | stacked bar of per-pass GPU breakdown |
| `raw/*.csv` | the unmodified per-run sample output | full detail / reproducibility |

`4k-fsr-quality.csv` columns: `benchmark, sample, display_resolution, render_resolution, preset,
frame_generation, avg_fps, display_avg_fps, total_gpu_ms, key_pass, key_pass_ms`.

## Reproduce

In each sample's `…/x64/Release` directory, with the Proton env set (see [../docs/USAGE.md](../docs/USAGE.md)):

```bash
# 1. FSR upscaling           2. FSR Frame Generation
umu-run FidelityFX_FSR.exe -benchmark duration=1000 -nolimit -vsync 0 -resolution 3840 2160 -scalepreset=1 -framegen=0
umu-run FidelityFX_FSR.exe -benchmark duration=1000 -nolimit -vsync 0 -resolution 3840 2160 -scalepreset=1 -framegen=1
# 3. FSR Ray Regeneration
umu-run FidelityFX_Denoiser_Sample_2022.exe -benchmark duration=1000 -nolimit -vsync 0 -resolution 3840 2160 -scalepreset=1
# 4. Neural Radiance Cache (native 4K)
umu-run FidelityFX_NRC.exe -benchmark duration=1000 -resolution 3840 2160
```
