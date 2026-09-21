@echo off
set "TARGET=C:\Users\Dejunai\projects\three colors — Codex — ClaudeCode2"
git -C "%TARGET%" log -n 5 --stat > "%~dp0claude_diff.txt"
git -C "%TARGET%" show e1d806a >> "%~dp0claude_diff.txt"
