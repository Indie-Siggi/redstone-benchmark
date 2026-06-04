@echo off
REM CLEAN rebuild (/t:Rebuild) of the two Cauldron solutions. Use this after editing shared Cauldron
REM files (framework.cpp/.h, skydomerendermodule.cpp) - the incremental build can silently skip them.
REM Usage: rebuild-all.bat [FFX_ROOT]   (see build-all.bat for FFX_ROOT)
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
  echo ===== CLEAN REBUILD %%~nxS =====
  msbuild "%BASE%\%%~S" /t:Rebuild /p:Configuration=Release /p:Platform=x64 /m /v:minimal
  if not !ERRORLEVEL!==0 set ANYFAIL=1
)
echo ANYFAIL=!ANYFAIL!
exit /b !ANYFAIL!
