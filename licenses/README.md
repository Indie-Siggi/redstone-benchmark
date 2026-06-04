# Licenses

This project modifies AMD's FidelityFX SDK 2.2 samples. The base SDK is **dual-licensed per file**, and
the runnable binaries pull in several third-party components. This folder holds every applicable license.

## AMD FidelityFX SDK — two tiers (see `AMD-FidelityFX-SDK-LICENSE.md`)

| Tier | What | What you may do |
|---|---|---|
| **MIT** | The Cauldron2 framework, **all the samples**, render modules, most docs (an 843-file exception list in AMD's license) — **everything this project modifies** | use, copy, **modify**, publish, **distribute source or binaries**, sublicense, sell — keep the notice |
| **AMD binary-only** | The FidelityFX SDK core (`Kits/FidelityFX/…`) and the prebuilt effect/ML DLLs (`amd_fidelityfx_*.dll`) | install, copy, **distribute binaries only** (no source), keep the notice — **no reverse-engineering, decompilation, or disassembly** |

→ The files in this repo's `src/` and `patches/` are all in the **MIT** tier, so redistributing them
(as modified source) is permitted. Our own additions are MIT (`../LICENSE`).

## Component → license map (for the binary release)

| Binary / component | License file | Notes |
|---|---|---|
| `FidelityFX_*.exe` (our build) | `../LICENSE` + AMD MIT tier | MIT (AMD sample code + our MIT mods) |
| `amd_fidelityfx_loader/upscaler/denoiser/framegeneration/radiancecache_dx12.dll` | `AMD-FidelityFX-SDK-LICENSE.md` | **AMD binary-only tier** — binary redist OK with notice; no RE |
| `amd_ags_x64.dll` | `amd-ags-LICENSE.txt` | MIT |
| `amd_acs_x64.dll` | `amd-acs-LICENSE.txt` | MIT |
| `D3D12Core.dll` (DirectX Agility SDK) | `msft-directx12-agility-LICENSE.txt` | Microsoft Software License Terms (redistributable with apps) |
| `WinPixEventRuntime.dll` | `msft-winpixeventruntime-LICENSE.txt` | MIT (Microsoft) |
| `dxcompiler.dll`, `dxil.dll` | `directx-dxc-LICENSE.txt` | DirectX Shader Compiler (LLVM/NCSA); `dxil.dll` is Microsoft-signed |
| statically linked in the exes: Dear ImGui, nlohmann/json, vectormath, AMD memory allocator | `imgui-LICENSE.txt`, `nlohmann-json-LICENSE.txt`, `vectormath-LICENSE.txt`, `amd-memoryallocator-LICENSE.txt` | MIT/permissive |

## NOT redistributed here (get them from their source)

- **vkd3d-proton** (`d3d12core.dll` / `d3d12.dll`, used for the Linux/Proton swap) — **LGPL-2.1**. To avoid
  LGPL relink obligations we don't bundle it; `setup-linux.sh` copies it from your Proton install.
- **Scene media** (`cauldronmedia`, ~1.5 GB textures/models/HDRIs) — per-asset licenses, not freely
  redistributable. Fetch it with AMD's MediaDelivery tool (the SDK's `UpdateMedia`).
