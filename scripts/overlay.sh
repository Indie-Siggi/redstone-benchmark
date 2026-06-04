#!/usr/bin/env bash
# Overlay the Redstone Benchmark modified source onto an extracted FidelityFX SDK 2.2 tree.
# Usage: scripts/overlay.sh <FFX_ROOT>
#   <FFX_ROOT> = the extracted FidelityFX-Samples-v2.2.0-source root (contains Kits/ and Samples/)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Default to the bundled submodule (external/FidelityFX-SDK, pinned to SDK v2.2.0).
FFX_ROOT="${1:-$HERE/external/FidelityFX-SDK}"
if [ ! -d "$FFX_ROOT/Kits" ] || [ ! -d "$FFX_ROOT/Samples" ]; then
  echo "FFX_ROOT '$FFX_ROOT' has no Kits/ + Samples/." >&2
  echo "If using the submodule, fetch it first:  git submodule update --init --recursive" >&2
  echo "Or pass a path to an extracted FidelityFX SDK 2.2 source tree: $0 <FFX_ROOT>" >&2
  exit 1
fi
cp -rv "$HERE/src/." "$FFX_ROOT/"
echo "Overlay complete. Now build (see docs/BUILD.md)."
