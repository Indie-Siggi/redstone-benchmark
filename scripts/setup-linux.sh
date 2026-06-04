#!/usr/bin/env bash
# Prepare the Redstone Benchmark binaries to run on Linux via Proton / vkd3d-proton.
# Swaps Microsoft's bundled D3D12Core.dll for vkd3d-proton's (LGPL-2.1 — intentionally NOT shipped in the
# bundle; copied here from YOUR Proton install) so the D3D12 Agility loader uses the Vulkan translation layer.
#
# Run this from the bundle root (the dir containing the FidelityFX_* folders).
# Usage:  PROTONPATH=/path/to/proton  ./setup-linux.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${PROTONPATH:?set PROTONPATH to a Proton build bundling vkd3d-proton (e.g. Proton-CachyOS)}"
VKD3D="$PROTONPATH/files/lib/wine/vkd3d-proton/x86_64-windows"
[ -f "$VKD3D/d3d12core.dll" ] || { echo "ERROR: vkd3d-proton DLLs not found under $VKD3D" >&2; exit 1; }

patched=0
for rel in "$HERE"/*/x64/Release; do
  [ -d "$rel" ] || continue
  if [ -f "$rel/D3D12Core.dll" ] && [ ! -f "$rel/D3D12Core.dll.agility-bak" ]; then
    cp "$rel/D3D12Core.dll" "$rel/D3D12Core.dll.agility-bak"   # keep the MS Agility original
  fi
  cp -f "$VKD3D/d3d12core.dll" "$rel/D3D12Core.dll"
  cp -f "$VKD3D/d3d12.dll"     "$rel/d3d12.dll"
  echo "patched: $rel"
  patched=$((patched+1))
done
echo "Patched $patched sample(s) with vkd3d-proton."
echo
echo "NOTE: scene media is NOT included (per-asset licensing). Before running the Cauldron samples"
echo "(FSR / Ray Regeneration) fetch it with AMD's MediaDelivery tool (the SDK's UpdateMedia)."
echo "Then, with your Proton env set (GAMEID, PROTONPATH, WINEPREFIX, DISPLAY/WAYLAND, etc.):"
echo "  cd FidelityFX_FSR/x64/Release && umu-run FidelityFX_FSR.exe -benchmark duration=2000"
