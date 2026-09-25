import subprocess
import sys
import json

def kill_headless_godot():
    if sys.platform != "win32":
        print("This tool is designed for Windows process management.")
        return

    ps_cmd = (
        'Get-CimInstance Win32_Process | '
        'Where-Object { $_.Name -like "*godot*" -and $_.CommandLine -like "*--headless*" } | '
        'Select-Object ProcessId, Name, CommandLine | '
        'ConvertTo-Json -Compress'
    )

    try:
        res = subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_cmd],
            capture_output=True,
            text=True,
            check=True
        )
        raw = res.stdout.strip()
        if not raw:
            print("No orphaned headless Godot processes found.")
            return

        data = json.loads(raw)
        if isinstance(data, dict):
            procs = [data]
        elif isinstance(data, list):
            procs = data
        else:
            procs = []

        if not procs:
            print("No orphaned headless Godot processes found.")
            return

        print(f"Found {len(procs)} headless Godot process(es) to terminate:")
        for p in procs:
            pid = p.get("ProcessId")
            cmd = p.get("CommandLine", "")[:100]
            print(f"  - Terminating PID {pid}: {cmd}...")
            subprocess.run(["taskkill", "/F", "/T", "/PID", str(pid)], capture_output=True)

        print("All headless Godot test processes have been forcefully terminated.")

    except Exception as e:
        print(f"Error querying/killing processes: {e}")

if __name__ == "__main__":
    kill_headless_godot()
