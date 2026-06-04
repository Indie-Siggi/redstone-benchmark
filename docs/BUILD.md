# Build Guide

These mods are source overlays/patches on top of AMD's **FidelityFX SDK 2.2 samples**. The samples are
**Windows / Visual Studio 2022 only** (`.sln` + vcpkg, no CMake/Linux). You build on Windows, then run the
`.exe`s on Linux under Proton (see [USAGE.md](USAGE.md)).

## 1. Prerequisites (Windows build host)

- **Visual Studio 2022** or **VS Build Tools 2022** with:
  - Workload **Desktop development with C++** (`Microsoft.VisualStudio.Workload.VCTools`, MSVC v143)
  - Component **vcpkg** (`Microsoft.VisualStudio.Component.Vcpkg`)
  - A **Windows 10 SDK ≥ 10.0.18362** (or Windows 11 SDK)
- **Git** (vcpkg fetches its registry over git).

Headless install of Build Tools (e.g. over SSH):
```powershell
# download https://aka.ms/vs/17/release/vs_buildtools.exe then:
vs_buildtools.exe --quiet --wait --norestart `
  --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended `
  --add Microsoft.VisualStudio.Component.Vcpkg `
  --add Microsoft.VisualStudio.Component.Windows11SDK.22621
```

## 2. Get the FidelityFX SDK 2.2 sample source

**Preferred — the bundled submodule** (`external/FidelityFX-SDK`, pinned to tag v2.2.0):
```bash
git submodule update --init --recursive     # or clone the repo with --recursive
```
This becomes your `FFX_ROOT` = `external/FidelityFX-SDK`.

**Alternative — the release zip:** download `FidelityFX-Samples-v2.2.0-source.zip` (AMD GPUOpen / GitHub
release v2.2.0, ~184 MB) and extract it; `FFX_ROOT` is the extracted root. Either way `FFX_ROOT` contains
`Kits/`, `Samples/`, `readme.md`.

## 3. Overlay these benchmark mods

Two equivalent options:

**a) Copy the modified files** (run from the repo root; `src/` mirrors the SDK layout):
```bash
cp -r src/. "$FFX_ROOT"/                     # Linux/macOS
#  or (Windows):  robocopy src "%FFX_ROOT%" /E
```
`scripts/overlay.sh <FFX_ROOT>` does this for you.

**b) Apply the patch** (against pristine v2.2.0 source), from the repo root:
```bash
git -C "$FFX_ROOT" apply -p1 "$PWD/patches/redstone-benchmark.patch"
#  or:  patch -d "$FFX_ROOT" -p1 < patches/redstone-benchmark.patch
```

Modified files (11): `framework.{cpp,h}` and `skydomerendermodule.cpp` in the Cauldron framework; the three
samples' `*rendermodule.cpp` / `D3DPipeline.cpp` / `RenderManager.cpp` / `Win32.cpp`; and two config files
that set the Full-HD default (`framework/config/cauldronconfig.json` and the NRC `config.json`).

## 4. First-time vcpkg init

Open a VS Developer Command Prompt (or run `vcvars64.bat`) once and:
```
vcpkg integrate install
```
MSBuild then auto-restores the manifest deps (`directx-dxc`, `directx-headers`, `directx12-agility`,
`winpixevent`, `directxmath`) on first build (~1 min, cached after).

## 5. Build

The three solutions:
- `Samples/Upscalers/FidelityFX_FSR/dx12/FidelityFX_FSR_2022.sln`
- `Samples/Denoisers/FidelityFX_Denoiser/dx12/FidelityFX_Denoiser_Sample_2022.sln`
- `Samples/RadianceCaches/FidelityFX_NRC/dx12/FidelityFX_NRC_2022.sln`

Open each in VS2022 and Build (Release | x64), **or** headless:
```bat
call "<VS>\VC\Auxiliary\Build\vcvars64.bat"
msbuild <solution>.sln /p:Configuration=Release /p:Platform=x64 /m
```
`scripts/build-all.bat` builds all three. Outputs land in each sample's `dx12\x64\Release\`.

> ### ⚠️ Build gotcha — stale incremental builds on shared Cauldron files
> `framework.cpp`/`framework.h`/`skydomerendermodule.cpp` are compiled into a per-solution copy of
> `Cauldron.lib`. After editing them, an **incremental** rebuild can *silently skip recompiling them*
> (MSBuild's `.tlog` tracker goes stale, especially if source files were copied in with older mtimes) —
> it prints "Build succeeded" but your change isn't in the exe. **Verify** with
> `strings -el <exe> | grep '<a new string you added>'`. If it's missing, do a **clean rebuild**:
> ```bat
> msbuild <solution>.sln /t:Rebuild /p:Configuration=Release /p:Platform=x64 /m
> ```
> `scripts/rebuild-all.bat` does the clean rebuild of the two Cauldron samples.

## 6. Deploy to Linux (Proton / vkd3d-proton)

Copy the built `…\x64\Release\` folder to the Linux box, then make the D3D12 Agility loader use
vkd3d-proton:

1. Replace the sample's bundled **`D3D12Core.dll`** with vkd3d-proton's `d3d12core.dll`, and add its
   `d3d12.dll`, from
   `…/compatibilitytools.d/<proton>/files/lib/wine/vkd3d-proton/x86_64-windows/`.
   (NRC also loads a local `d3d12.dll`; add `dxil.dll` too.)
2. Provide the scene media the sample expects (the Cauldron samples reference `media/cauldronmedia/…`
   relative to the Release dir; obtain it via the SDK's `MediaDelivery` tool). NRC's scene is shader-defined
   and ships with the sample.

Then run via `umu-run` — see [USAGE.md](USAGE.md).

## Tested toolchain

VS Build Tools 2022, MSVC **v143 14.44.x**, Windows 10 SDK 10.0.19041 + Windows 11 SDK 22621, vcpkg
(bundled). Target/runtime: RX 9070 XT (RDNA4), Proton-CachyOS (vkd3d-proton 3.1.0), Mesa 26.0.5 (host) /
26.1.1 (Arch distrobox).
