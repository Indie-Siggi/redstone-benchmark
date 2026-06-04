@echo off
REM Build all three Redstone benchmark solutions (Release ^| x64).
REM Usage: build-all.bat [FFX_ROOT]
REM   FFX_ROOT = extracted FidelityFX SDK 2.2 source root with these mods overlaid
REM              (defaults to the FFX_ROOT env var, else C:\ffx)
setlocal enabledelayedexpansion
if not "%~1"=="" set "FFX_ROOT=%~1"
if "%FFX_ROOT%"=="" set "FFX_ROOT=C:\ffx"
if not exist "%FFX_ROOT%\Samples" ( echo ERROR: FFX_ROOT "%FFX_ROOT%" has no Samples\ - pass it as arg 1 & exit /b 2 )

set "VSWHERE=C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSINSTALL=%%i"
call "!VSINSTALL!\VC\Auxiliary\Build\vcvars64.bat" >nul

set BASE=%FFX_ROOT%\Samples
set ANYFAIL=0
for %%S in (
  "Upscalers\FidelityFX_FSR\dx12\FidelityFX_FSR_2022.sln"
  "Denoisers\FidelityFX_Denoiser\dx12\FidelityFX_Denoiser_Sample_2022.sln"
  "RadianceCaches\FidelityFX_NRC\dx12\FidelityFX_NRC_2022.sln"
) do (
  echo ===== Building %%~nxS =====
  msbuild "%BASE%\%%~S" /p:Configuration=Release /p:Platform=x64 /m /v:minimal
  if not !ERRORLEVEL!==0 set ANYFAIL=1
)
echo ANYFAIL=!ANYFAIL!
exit /b !ANYFAIL!
