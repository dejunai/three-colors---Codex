$repo = 'C:\Users\Dejunai\projects\three colors — Codex — ClaudeCode2'
git -C $repo show e1d806a --stat
Write-Output "--- COMMIT MESSAGE ---"
git -C $repo log -1 --pretty=fuller e1d806a
