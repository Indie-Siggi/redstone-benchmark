# Usage Guide — how the benchmarks work and how to run them

## What these are

Three benchmark executables derived from AMD's FidelityFX SDK 2.2 "Redstone" samples, modified so every
setting is driveable from the command line for **automated, repeatable** benchmarking — no manual F1-panel
interaction required.

| Benchmark | Exe | Measures |
|---|---|---|
| **FSR** | `FidelityFX_FSR.exe` | FSR 4.x upscaling **and** ML Frame Generation |
| **Ray Regeneration** | `FidelityFX_Denoiser_Sample_2022.exe` | FSR Ray Regen ML denoiser (+ FSR upscale) |
| **Neural Radiance Cache** | `FidelityFX_NRC.exe` | NRC inference/training (WMMA vs reference) |

Full flag list: [CLI_REFERENCE.md](CLI_REFERENCE.md). Build instructions: [BUILD.md](BUILD.md).

## How a benchmark run works

### FSR & Ray Regen (Cauldron framework)
`-benchmark duration=N` runs N measured frames then **exits automatically**, writing a results file to the
working directory. The framework:
- forces a GPU FPS limiter on at 60 fps by default (so runs are comparable) — pass **`-nolimit`** to run uncapped/GPU-bound, and **`-vsync 0`** to drop refresh-rate pacing,
- records per-pass **GPU and CPU** timings (min/max/mean) via timestamp queries,
- captures both the **rendered** and **presented** frame counts (see *Render vs Display FPS* below),
- snapshots the resolution at benchmark start (it changes during teardown).

### NRC (custom harness)
NRC is not a Cauldron sample, so it has a purpose-built benchmark: `-benchmark duration=N` skips `-warmup=K`
frames (default 60, lets the cache train), then accumulates per-pass GPU timestamps (*Path tracer, Radiance
cache, Composite, Display*) and CPU frame time over N frames, writes a CSV, and exits.

## Render vs Display FPS (Frame Generation)

This is the key metric for frame generation:

- **`Avg FPS`** = *rendered* frames / runtime — the GPU's real throughput.
- **`Display Avg FPS`** = *presented* frames / runtime — what actually reaches the screen, including
  frame-generation's interpolated frames (sourced from the swapchain present count, i.e. the F1 HUD's
  "Display FPS").

With Frame Generation **off**, `Display Avg FPS == Avg FPS`. With FG **on**, `Display Avg FPS` is up to
**2× `Avg FPS`**. Example (FSR, 4K NativeAA):

```
FG off:  Avg FPS 74.83   Display Avg FPS 74.83    (1.00x)
FG on:   Avg FPS 74.15   Display Avg FPS 148.30   (2.00x)
```

Read **per-pass GPU times** for the cost of individual effects, **Avg FPS** for render throughput, and
**Display Avg FPS** for the on-screen rate. (FG's interpolation runs in the swapchain present path, so its
cost is *not* in the per-pass GPU breakdown — only a tiny "Frame Generation Prepare" pass shows there.)

## Output files

Every run writes a **timestamped** file (`YYYY_MM_DD_HHMMSS_…`) so runs never overwrite:

| Sample | File | Notes |
|---|---|---|
| FSR / Ray Regen | `<ts>_<AppName>-perf.csv` (or `.json` with `json`) | vertical `Info,Value` then per-pass `CPU/GPU,Label,Min,Max,Mean` table |
| FSR / Ray Regen | `<ts>_Cauldron.log` | engine log |
| NRC | `<ts>_FidelityFX_NRC.csv` | one header + one row: per-pass GPU + AvgFPS + backend |

CSV (Cauldron, vertical) key rows: `CmdLine`, `GPU`, `Display Resolution`, `Render Resolution`,
`Runtime [s]`, `Avg FPS`, `Display Avg FPS`, then the per-pass table. JSON adds `DisplayAvgFPS` and
per-pass label objects. `CmdLine` echoes the exact flags, so each file is self-describing.

NRC CSV columns: `Sample,GPU,Backend,Width,Height,MeasuredFrames,AvgFPS,CPUframe_{avg,min,max}_ms`, then
`<pass>_{avg,min,max}_ms` for Path tracer / Radiance cache / Composite / Display.

## Running on Linux (Proton / vkd3d-proton, RDNA4)

The samples are Windows D3D12 exes run through Proton. Use a **matched** Proton stack via `umu-run`
(Proton-CachyOS bundles vkd3d-proton 3.1.0). Replace the bundled `D3D12Core.dll` with vkd3d-proton's
(see [BUILD.md](BUILD.md) → *Linux deploy*). Then:

```bash
export GAMEID=0
export PROTONPATH="$HOME/.local/share/Steam/compatibilitytools.d/<proton-with-vkd3d-proton>"  # e.g. a recent Proton-CachyOS (vkd3d-proton 3.x)
export WINEPREFIX=/path/to/umu-prefix
export DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000
export XAUTHORITY=/run/user/1000/xauth_XXXXXX DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
cd <sample>/dx12/x64/Release
umu-run <Sample>.exe -benchmark duration=2000 -scalepreset=3 -framegen=1
```

Newer Mesa: run the same `umu-run` **inside an Arch distrobox** that has a newer Mesa + `umu-launcher`
(`pacman -S umu-launcher`); pressure-vessel nests and uses the container's Mesa.

`scripts/run-sweep.sh` automates a labelled FG/preset/denoiser sweep across the three samples and collects
timestamped CSVs.

## GPU safety

The ML/RT workloads stress the GPU hard. Run at **stock voltage** — an applied undervolt has triggered hard
GPU hangs (a MODE1 reset) on RDNA4 under sustained ML load — set a sane power cap, and keep first runs short
(`-benchmark duration=600`, ~10 s).

## Independent cross-check (optional)

`Display Avg FPS` makes MangoHud unnecessary, but for an external check you can run a sample **interactively**
(no `-benchmark`, so no auto-exit) with MangoHud logging the presented frame rate:
```bash
MANGOHUD=1 MANGOHUD_CONFIG="fps,frametime,output_folder=DIR,autostart_log=5,log_duration=10" \
  umu-run FidelityFX_FSR.exe -resolution 3840 2160 -scalepreset=0 -framegen=1
```
