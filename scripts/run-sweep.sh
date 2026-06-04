#!/usr/bin/env bash
# Labelled FG / scale-preset / denoiser sweep across the three Redstone benchmarks (Linux / Proton).
# Each run writes a timestamped, labelled CSV into $RESULTS.
#
# Configure via env vars (or edit the defaults below):
#   RELEASE_BASE  dir containing the three samples' x64/Release dirs (the SDK Samples/ root, deployed)
#   PROTONPATH    Proton build with vkd3d-proton (Proton-CachyOS recommended)
#   WINEPREFIX    umu/wine prefix
#   RESULTS       output dir (default ./results)
#   DUR           measured frames per run (default 600 ~ short/GPU-safe)
# Requires umu-launcher on PATH and the samples already deployed (vkd3d-proton D3D12Core.dll swapped).
set -u

RELEASE_BASE="${RELEASE_BASE:?set RELEASE_BASE to the deployed Samples/ root}"
export GAMEID="${GAMEID:-0}"
export PROTONPATH="${PROTONPATH:?set PROTONPATH to a vkd3d-proton Proton build}"
export WINEPREFIX="${WINEPREFIX:?set WINEPREFIX}"
# Graphical env (Wayland/X) — adjust XAUTHORITY to your session if needed.
export DISPLAY="${DISPLAY:-:0}" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

RESULTS="${RESULTS:-$PWD/results}"; mkdir -p "$RESULTS"
TS="$(date +%Y_%m_%d_%H%M%S)"
DUR="${DUR:-600}"; TO=180

FSR="$RELEASE_BASE/Upscalers/FidelityFX_FSR/dx12/x64/Release"
DEN="$RELEASE_BASE/Denoisers/FidelityFX_Denoiser/dx12/x64/Release"
NRC="$RELEASE_BASE/RadianceCaches/FidelityFX_NRC/dx12/x64/Release"

run_cauldron() {  # $1=dir $2=exe $3=label $4..=flags  (collects newest CSV)
  local dir="$1" exe="$2" label="$3"; shift 3
  cd "$dir" || return 1
  rm -f ./*-perf*.csv 2>/dev/null
  echo ">>> $label : $exe -benchmark duration=$DUR $*"
  timeout "$TO" umu-run "$exe" -benchmark duration=$DUR "$@" > "$RESULTS/${TS}_${label}.log" 2>&1
  local csv; csv=$(ls -t ./*-perf*.csv 2>/dev/null | head -1)
  [ -n "$csv" ] && cp "$csv" "$RESULTS/${TS}_${label}.csv" && echo "    -> ${TS}_${label}.csv" || echo "    !! no CSV ($label)"
}

echo "=== FSR (upscaling + ML Frame Generation) ==="
run_cauldron "$FSR" FidelityFX_FSR.exe fsr-fg-off -scalepreset=3 -framegen=0
run_cauldron "$FSR" FidelityFX_FSR.exe fsr-fg-on  -scalepreset=3 -framegen=1

echo "=== Ray Regeneration (denoiser) ==="
run_cauldron "$DEN" FidelityFX_Denoiser_Sample_2022.exe rr-4signals -denoisermode=0 -scalepreset=3
run_cauldron "$DEN" FidelityFX_Denoiser_Sample_2022.exe rr-1signal  -denoisermode=2 -scalepreset=3

echo "=== Neural Radiance Cache ==="
cd "$NRC" || exit 1
for be in default ref; do
  [ "$be" = ref ] && fw="-forcewmma=0" || fw=""
  echo ">>> nrc-$be : -benchmark duration=$DUR $fw"
  timeout "$TO" umu-run FidelityFX_NRC.exe -benchmark duration=$DUR $fw > "$RESULTS/${TS}_nrc-$be.log" 2>&1
  csv=$(ls -t ./*_FidelityFX_NRC.csv 2>/dev/null | head -1)
  [ -n "$csv" ] && cp "$csv" "$RESULTS/${TS}_nrc-$be.csv" && echo "    -> ${TS}_nrc-$be.csv"
done

echo "=== done -> $RESULTS ==="; ls -t "$RESULTS"/${TS}_*.csv 2>/dev/null
