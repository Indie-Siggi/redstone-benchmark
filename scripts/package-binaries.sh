#!/usr/bin/env bash
# Assemble a redistributable binary bundle of the built Redstone benchmarks.
#
# Usage:  scripts/package-binaries.sh <built-Samples-dir> [out-dir]
#   <built-Samples-dir>  the FFX SDK 'Samples/' dir AFTER building on Windows (contains the x64/Release dirs)
#   [out-dir]            where to write the bundle (default: ./dist, which is gitignored)
#
# Ships: the exes + redistributable runtime DLLs (AMD FidelityFX + AMD ags/acs + MS Agility/PIX + DXC) +
#        configs + shaders + licenses/ + setup-linux.sh. EXCLUDES: build artifacts, scene media (per-asset
#        licensing) and vkd3d-proton DLLs (LGPL — added at the user end by setup-linux.sh).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # repo root
SAMPLES="${1:?usage: package-binaries.sh <built-Samples-dir> [out-dir]}"
OUTDIR="${2:-$HERE/dist}"
VERSION="$(tr -d '[:space:]' < "$HERE/VERSION" 2>/dev/null || echo 0.0.0)"
NAME="redstone-benchmark-$VERSION"
STAGE="$OUTDIR/$NAME"
rm -rf "$STAGE"; mkdir -p "$STAGE"

samples="FidelityFX_FSR:Upscalers/FidelityFX_FSR \
         FidelityFX_Denoiser:Denoisers/FidelityFX_Denoiser \
         FidelityFX_NRC:RadianceCaches/FidelityFX_NRC"
for entry in $samples; do
  name="${entry%%:*}"; sub="${entry##*:}"
  src="$SAMPLES/$sub/dx12/x64/Release"; dst="$STAGE/$name/x64/Release"
  [ -d "$src" ] || { echo "skip $name (missing $src)"; continue; }
  mkdir -p "$dst"
  rsync -a \
    --exclude='*.pdb' --exclude='*.obj' --exclude='*.ipdb' --exclude='*.iobj' \
    --exclude='*.exp' --exclude='*.lib' --exclude='*.recipe' --exclude='*.tlog' \
    --exclude='*.FileListAbsolute.txt' --exclude='*.agility-bak' --exclude='*.log' \
    --exclude='d3d12.dll' --exclude='*.csv' --exclude='imgui.ini' \
    "$src/" "$dst/"
  echo "staged $name"
done

cp -r "$HERE/licenses" "$STAGE/licenses"
cp "$HERE/scripts/setup-linux.sh" "$STAGE/setup-linux.sh"; chmod +x "$STAGE/setup-linux.sh"

cat > "$STAGE/README.txt" <<'EOF'
Unofficial AMD Redstone Benchmark — prebuilt binaries
=====================================================
Independent community project — NOT affiliated with or endorsed by AMD. "AMD", "FidelityFX" and
"Redstone" are trademarks of Advanced Micro Devices, Inc. CLI-driven benchmarks built from AMD's
FidelityFX SDK 2.2 samples (FSR upscaling + ML Frame Generation, FSR Ray Regeneration, Neural
Radiance Cache). See the project repo for full docs (BUILD / USAGE / CLI_REFERENCE) and source.

RUN ON LINUX (Proton / vkd3d-proton, RDNA4):
  1) PROTONPATH=/path/to/proton ./setup-linux.sh    # swaps in vkd3d-proton's D3D12Core (LGPL, not bundled)
  2) Fetch scene media via AMD's MediaDelivery (not included — per-asset licensing).
  3) Set your Proton env (GAMEID, PROTONPATH, WINEPREFIX, DISPLAY/WAYLAND_DISPLAY, XDG_RUNTIME_DIR,
     XAUTHORITY, DBUS_SESSION_BUS_ADDRESS), then:
       cd FidelityFX_FSR/x64/Release && umu-run FidelityFX_FSR.exe -benchmark duration=2000

LICENSING: see licenses/ . The amd_fidelityfx_*.dll are redistributed under AMD's binary-only license
(no reverse engineering). MS Agility/PIX, DXC, and the MIT components have their own licenses (licenses/).
Defaults: 1920x1080, FSR Quality preset. Output: timestamped CSV with Avg FPS + Display Avg FPS.
EOF

( cd "$OUTDIR" && rm -f "$NAME.zip" && zip -qr "$NAME.zip" "$NAME" )
echo "bundle: $OUTDIR/$NAME.zip ($(du -h "$OUTDIR/$NAME.zip" | cut -f1))"
