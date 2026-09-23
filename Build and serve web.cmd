@echo off
setlocal
set "GODOT_STANDARD=C:\Portables\GodotStandard\Godot_v4.7.2-stable_win64.exe"
set "OUT=%~dp0build\web"
set "PORT=5173"

echo %date% %time% 1
rem Stop any server currently running on the port
for /f "tokens=5" %%p in ('netstat -ano -p tcp ^| findstr ":%PORT% " ^| findstr "LISTENING"') do (
  echo Stopping existing server on port %PORT% [PID %%p] ...
  taskkill /F /PID %%p >nul 2>&1
)
echo %date% %time% 2
if not exist "%GODOT_STANDARD%" (
  echo Standard non-Mono Godot not found at %GODOT_STANDARD%.
  echo Web export requires the standard editor; the Mono/.NET build cannot export to Web.
  if exist "%OUT%\index.html" (
    echo Serving existing Web build from %OUT% ...
    goto :serve
  )
  pause
  exit /b 1
)
echo %date% %time% 3
if not exist "%OUT%" mkdir "%OUT%"

echo Exporting Web build ...
"%GODOT_STANDARD%" --headless --path "%~dp0." --export-release "Web" "build/web/index.html"
if errorlevel 1 (
  echo Export failed.
  pause
  exit /b 1
)

echo %date% %time% 4
:serve
echo Serving %OUT% at http://localhost:5173 ...
start "" http://localhost:5173/index.html
python "%~dp0tools\serve_web.py" --port 5173 --dir "%OUT%"
