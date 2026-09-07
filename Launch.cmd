@echo off
setlocal
set "APPDATA=%~dp0.runtime-data"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "C:\Portables\Godot4\Godot_v4.7.2-stable_mono_win64.exe" (
  echo Godot was not found at C:\Portables\Godot4. Update the engine path in Launch.cmd.
  pause
  exit /b 1
)
start "" "C:\Portables\Godot4\Godot_v4.7.2-stable_mono_win64.exe" --path "%~dp0."
