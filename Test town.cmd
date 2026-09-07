@echo off
setlocal
set "APPDATA=%~dp0.runtime-data"
if not exist "%APPDATA%" mkdir "%APPDATA%"
"C:\Portables\Godot4\Godot_v4.7.2-stable_mono_win64_console.exe" --headless --path "%~dp0." --fixed-fps 60 -- --qa-town
pause
