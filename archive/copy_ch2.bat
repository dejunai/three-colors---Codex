@echo off
set "SRC=C:\Users\Dejunai\projects\three colors — Codex — ClaudeCode2"
set "DEST=C:\Users\Dejunai\projects\three colors — Codex — Antigravity2"
if not exist "%DEST%\scripts\shared" mkdir "%DEST%\scripts\shared"
copy /Y "%SRC%\scripts\shared\trinket_generator.gd" "%DEST%\scripts\shared\trinket_generator.gd"
copy /Y "%SRC%\tests\trinket_generator.gd" "%DEST%\tests\trinket_generator.gd"
