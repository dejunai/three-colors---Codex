@echo off
setlocal
set "GODOT_STANDARD=C:\Portables\GodotStandard\Godot_v4.7.2-stable_win64.exe"
set "OUT=%~dp0build\web"
set "PORT=8060"

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

for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "$connections = Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue; if ($connections) { $connections | Select-Object -ExpandProperty OwningProcess -Unique }"`) do (
  echo Stopping existing server on port %PORT% ^(PID %%P^)...
  taskkill /PID %%P /T /F >nul 2>&1
)

echo Serving %OUT% at http://localhost:%PORT% ...
start "" http://localhost:%PORT%/index.html
python -m http.server %PORT% -d "%OUT%"
