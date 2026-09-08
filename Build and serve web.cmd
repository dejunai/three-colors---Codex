@echo off
setlocal
set "GODOT_STANDARD=C:\Portables\GodotStandard\Godot_v4.7.2-stable_win64.exe"
set "OUT=%~dp0build\web"

if not exist "%GODOT_STANDARD%" (
  echo Standard (non-Mono) Godot not found at %GODOT_STANDARD%.
  echo Web export requires the standard editor; the Mono/.NET build cannot export to Web.
  pause
  exit /b 1
)

if not exist "%OUT%" mkdir "%OUT%"

echo Exporting Web build...
"%GODOT_STANDARD%" --headless --path "%~dp0." --export-release "Web" "build/web/index.html"
if errorlevel 1 (
  echo Export failed.
  pause
  exit /b 1
)

echo Serving %OUT% at http://localhost:8060 ...
start "" http://localhost:8060/index.html
python -m http.server 8060 -d "%OUT%"
