@echo off
setlocal
set "APPDATA=%~dp0.runtime-data"
if not exist "%APPDATA%" mkdir "%APPDATA%"
start "" "C:\Portables\Godot4\Godot_v4.7.2-stable_mono_win64.exe" --path "%~dp0." --scene res://scenes/chapter_one_demo.tscn
