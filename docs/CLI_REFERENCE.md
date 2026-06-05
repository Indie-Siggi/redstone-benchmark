# CLI Reference

Every benchmark knob is reachable from the command line. There are two flag styles:

| Style | Form | Who uses it |
|---|---|---|
| **Added by these mods** | `-key=value` (e.g. `-scalepreset=3`) | the per-effect knobs we exposed |
| **Built into AMD's Cauldron framework** | space-separated `-key value` (e.g. `-resolution 1920 1080`) | resolution, display mode, scene/camera/exposure/IBL |

Flags can be combined freely. The **full command line is recorded** in every output file
(`CmdLine` field), so each result is self-describing.

The three executables:

| Benchmark | Executable | Framework |
|---|---|---|
| FSR upscaling + ML Frame Generation | `FidelityFX_FSR.exe` | Cauldron |
| FSR Ray Regeneration (denoiser) | `FidelityFX_Denoiser_Sample_2022.exe` | Cauldron |
| Neural Radiance Cache | `FidelityFX_NRC.exe` | custom harness |

---

## 1. Framework built-ins — both Cauldron samples (FSR + Ray Regen)

These were already in AMD's framework; documented here for completeness. **Space-separated args.**

### Benchmark control
| Flag | Meaning |
|---|---|
| `-benchmark duration=N` | Run N measured frames, write a results file, then exit. Force-enables a GPU FPS limiter at **60 fps by default** — pass `-nolimit` for an uncapped (GPU-bound) run. |
| `-nolimit` | Disable the FPS limiter entirely. Overrides the `-benchmark` forced-60 cap **and** any config / `-cpulimiter` / `-gpulimiter` setting, regardless of argument order, so the run is GPU-bound. Also removes the limiter's own GPU pass from the per-pass breakdown. |
| `-benchmark ... json` | Emit a `.json` instead of the default vertical `.csv` (richer; per-pass labels, `CmdLine`, `DisplayAvgFPS`). |
| `-benchmark ... append` | Append one row to a single horizontal CSV instead of a timestamped per-run file. |
| `-benchmark ... path=DIR` | Write the results file into `DIR`. |

`duration`, `json`, `append`, `path=` are sub-tokens of `-benchmark` (space-separated after it).

### Resolution / display
| Flag | Meaning |
|---|---|
| `-resolution <W> <H>` | Display (output) resolution. **Default 1920×1080** (config). Render res = display ÷ scale-preset ratio. |
| `-displaymode <MODE>` | `DISPLAYMODE_LDR` (default), `DISPLAYMODE_HDR10_2084`, `DISPLAYMODE_HDR10_SCRGB`, `DISPLAYMODE_FSHDR_2084`, `DISPLAYMODE_FSHDR_SCRGB`. |
| `-vsync <0\|1>` | Vertical sync. **Default on** (config). `-vsync 0` disables it (no refresh-rate pacing — pair with `-nolimit` for a fully uncapped run); `-vsync 1` forces it on. |

### Scene / lighting (built-in)
| Flag | Meaning |
|---|---|
| `-camera <name>` | Select a camera defined in the scene. |
| `-loadcontent <path.gltf>` | Load additional content at startup. |
| `-exposure <value>` | Scene exposure. |
| `-iblfactor <value>` | Image-based-lighting factor. |
| `-diffuseibl <path.dds>` | Diffuse IBL cubemap. |
| `-specularibl <path.dds>` | Specular IBL cubemap. |
| `-skymap <path.dds>` | Sky/environment map. |

The active **scene** is chosen by the sample's JSON config (`Content.Scenes`) or `-config <file>`.

---

## 2. Skydome / procedural sky — both Cauldron samples (added)

Only effective when the procedural sky is active (both samples ship with it on). `-key=value`.

| Flag | Range | Meaning |
|---|---|---|
| `-sky-procedural=0/1` | bool | Procedural sky on/off |
| `-sky-hour=F` | 0–24 | Time of day — hour (drives the sun direction) |
| `-sky-minute=F` | 0–60 | Time of day — minute |
| `-sky-luminance=F` | ≥0 | Sky/sun luminance (brightness) |
| `-sky-rayleigh=F` | ≥0 | Rayleigh scattering coefficient |
| `-sky-turbidity=F` | ≥0 | Atmospheric turbidity (haze) |
| `-sky-mie=F` | ≥0 | Mie scattering coefficient |
| `-sky-miedir=F` | 0–1 | Mie directional G |

---

## 3. FSR sample (`FidelityFX_FSR.exe`) — upscaling + ML Frame Generation

`-key=value`. Every F1-panel knob is exposed.

### Upscaling
| Flag | Values | Meaning |
|---|---|---|
| `-upscalemethod=N` | 0=Native, 1=FSR (FFXAPI) | Upscaler backend |
| `-scalepreset=N` | 0 NativeAA 1.0×, **1 Quality 1.5× (default)**, 2 Balanced 1.7×, 3 Performance 2×, 4 UltraPerf 3×, 5 Custom, 6 Custom(DRS) | Upscale ratio preset |
| `-upscaleratio=F` | 1.0–3.0 | Custom ratio (preset 5/6) |
| `-mipbias=F` | -5…0 | Texture mip LOD bias |
| `-letterbox=F` | 0.1–1.0 | Letterbox/render scale |
| `-colorspace=N` | 0 Linear, 1 Non-linear, 2 sRGB, 3 PQ | Upscaler color-space hint |
| `-rcas=0/1` | bool | RCAS sharpening |
| `-sharpness=F` | 0–1 | Sharpness (when RCAS on) |
| `-maskmode=N` | 0 Disabled, 1 Manual, 2 Auto | Reactive-mask mode |
| `-usemask=0/1` | bool | Use transparency/composition mask |
| `-overrideversion=0/1` · `-fsrversion=N` | | Override / pick the FSR upscaler version |

### Frame Generation
| Flag | Values | Meaning |
|---|---|---|
| `-framegen=0/1` | bool | Enable ML Frame Generation |
| `-fgversion=N` | index | Frame-generation version |
| `-asynccompute=0/1` · `-allowasynccompute=0/1` | bool | Async-compute path for FG |
| `-usecallback=0/1` | bool | FG present callback |
| `-uicompmode=N` | 0 None, 1 UiTexture, 2 UiCallback, 3 Pre-UI backbuffer | UI composition mode |
| `-doublebufferui=0/1` | bool | Double-buffer the UI resource |
| `-presentinterponly=0/1` | bool | Present only interpolated frames |
| `-distortionfield=0/1` | bool | Use distortion-field input |
| `-fgtearlines=0/1` · `-fgpacinglines=0/1` · `-fgresetindicators=0/1` · `-fgdebugview=0/1` | bool | FG debug overlays |
| `-drawupscalerdebug=0/1` | bool | Upscaler debug view |

### Frame pacing (FG swapchain)
| Flag | Range | Meaning |
|---|---|---|
| `-fp-safety=F` | 0–1 | Safety margin (ms) |
| `-fp-variance=F` | 0–1 | Variance factor |
| `-fp-hybridspin=0/1` | bool | Allow hybrid spin |
| `-fp-hybridspintime=N` | 0–10 | Hybrid spin time |
| `-fp-waitsingleobject=0/1` | bool | Wait on single object on fence |
| `-waitcallbackmode=N` | 0 nullptr, 1 logging | Swapchain wait-callback |

### Other
| Flag | Values | Meaning |
|---|---|---|
| `-upscalercbkey=N` · `-upscalercbvalue=F` | 0–4 / float | Upscaler constant-buffer key/value tweak |
| `-debugchecker=N` | 0–6 | FFX global debug checker level |
| `-cameraanim=N` | 0 None, 1 Sinusoidal | Camera animation mode |
| `-cameraanimdir=0/1` · `-cameraanimnoise=0/1` | bool | Camera animation direction / noise |

> `-fiswapchain` (frame-interpolation swapchain on/off) is intentionally **not** exposed — the sample
> force-enables it and disabling needs a windowed-mode switch (not benchmark-safe).

---

## 4. Ray Regeneration sample (`FidelityFX_Denoiser_Sample_2022.exe`)

`-key=value`. Denoiser knobs + the shared FSR upscale knob.

### Denoiser
| Flag | Values | Meaning |
|---|---|---|
| `-denoisermode=N` | 0 = 4 signals, 1 = 2 signals, 2 = 1 signal | Ray-regen denoiser signal count (affects GPU cost) |
| `-rrversion=N` | index | Denoiser version |
| `-dominantlight=0/1` | bool | Denoise dominant-light visibility |
| `-rrdebug=0/1` | bool | Enable denoiser debugging path |

### Denoiser tuning floats
| Flag | Range |
|---|---|
| `-crossbilateral=F` | 0–1 |
| `-disocclusion=F` | 0.01–0.05 |
| `-gaussiankernel=F` | 0–1 |
| `-maxradiance=F` | 0–65504 |
| `-radianceclip=F` | 0–65504 |
| `-stabilitybias=F` | 0–1 |

### Display / debug-view
| Flag | Values |
|---|---|
| `-viewmode=N` | 0–20 (Default, Direct, Indirect, Normals, Motion vectors, … Skip signal) |
| `-showdebugview=0/1` · `-debugviewmode=0/1` (overview/fullscreen) · `-debugviewport=N` | |
| `-debugchannels=N` | 4-bit mask: R=1, G=2, B=4, A=8 |

### Upscale (shared FSR module)
| Flag | Values |
|---|---|
| `-scalepreset=N` | 0 NativeAA 1.0×, **1 Quality 1.5× (default)**, 2 Balanced 1.7×, 3 Performance 2×, 4 UltraPerf 3× |

This sample has **no** frame generation, so `Display Avg FPS` == `Avg FPS` in its output.

---

## 5. Neural Radiance Cache sample (`FidelityFX_NRC.exe`)

Custom (non-Cauldron) harness — benchmark + resolution + all config knobs added by these mods. `-key=value`
except `-resolution` (space-separated, matches the Cauldron syntax).

### Benchmark / output
| Flag | Meaning |
|---|---|
| `-benchmark duration=N` | Run N measured frames, write a timestamped CSV, then exit. |
| `-warmup=K` | Frames to skip before measuring (default 60). |
| `-out=PATH` | Explicit output CSV path (otherwise timestamped default). |
| `-resolution <W> <H>` | Render/window resolution (overrides `config.json`). |

### Backend
| Flag | Meaning |
|---|---|
| `-forcewmma=0/1` | `0` forces the FP32 **reference** backend; default tries **WMMA** (cooperative-matrix) with reference fallback. CSV `Backend` column shows which ran. |

### Cache / renderer / animation
| Flag | Meaning |
|---|---|
| `-learningrate=F` · `-weightsmoothing=F` | Radiance-cache training params |
| `-accumblur=F` · `-indirectroughening=F` · `-locknoise=0/1` | Renderer params |
| `-splitpartition=F` · `-demomode=0/1` | Split-view position / demo auto-animate |
| `-animate=0/1` | Master animate toggle |
| `-animate-materials=0/1` · `-animate-geometry=0/1` · `-animate-lights=0/1` · `-animate-camera=0/1` | Per-axis animation |
| `-resetcache=0/1` | Reset the radiance cache |

---

## Examples

```bash
# FSR: Quality preset, frame-gen on, 1440p, JSON output
umu-run FidelityFX_FSR.exe -benchmark duration=2000 json -resolution 2560 1440 -scalepreset=1 -framegen=1

# FSR: frame-gen A/B at native 4K (compare Avg FPS vs Display Avg FPS in the CSV)
umu-run FidelityFX_FSR.exe -benchmark duration=1000 -resolution 3840 2160 -scalepreset=0 -framegen=0
umu-run FidelityFX_FSR.exe -benchmark duration=1000 -resolution 3840 2160 -scalepreset=0 -framegen=1

# Uncapped, GPU-bound (no FPS limiter, no vsync) — true max throughput straight from the CSV
umu-run FidelityFX_Denoiser_Sample_2022.exe -benchmark duration=1000 -nolimit -vsync 0

# Ray Regen: 2-signal denoiser, Balanced upscale, evening sky, brighter exposure
umu-run FidelityFX_Denoiser_Sample_2022.exe -benchmark duration=2000 \
  -denoisermode=1 -scalepreset=2 -sky-hour=18 -sky-luminance=2.5 -exposure 2.0

# NRC: WMMA vs reference backend at 1440p
umu-run FidelityFX_NRC.exe -benchmark duration=2000 -resolution 2560 1440
umu-run FidelityFX_NRC.exe -benchmark duration=2000 -resolution 2560 1440 -forcewmma=0
```
