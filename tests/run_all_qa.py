import subprocess
import os
import sys
import shutil

# Locate Godot executable
def find_godot():
    override = os.environ.get("GODOT_BIN")
    if override and os.path.isfile(override):
        return override

    candidates = [
        r"C:\Portables\GodotStandard\Godot_v4.7.2-stable_win64_console.exe",
        r"C:\Portables\Godot4\Godot_v4.7.2-stable_mono_win64_console.exe",
        "godot4",
        "godot"
    ]
    for c in candidates:
        if os.path.isabs(c) and os.path.isfile(c):
            return c
        resolved = shutil.which(c)
        if resolved:
            return resolved
    return "godot"

repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
godot = find_godot()

env = os.environ.copy()
runtime_dir = os.path.join(repo_root, ".runtime-data")
os.makedirs(runtime_dir, exist_ok=True)
env["APPDATA"] = runtime_dir

tests = [
    (["--headless", "-s", "tests/object_lang_flow.gd"], "object_lang_flow"),
    (["--headless", "-s", "tests/object_template_flow.gd"], "object_template_flow"),
    (["--headless", "-s", "tests/dialogue_lang_flow.gd"], "dialogue_lang_flow"),
    (["--headless", "-s", "tests/dialogue_template_flow.gd"], "dialogue_template_flow"),
    (["--headless", "-s", "tests/dialogue_content_flow.gd"], "dialogue_content_flow"),
    (["--headless", "-s", "tests/portal_lang_flow.gd"], "portal_lang_flow"),
    (["--headless", "-s", "tests/portal_template_flow.gd"], "portal_template_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/portal_content_flow.gd"], "portal_content_flow"),
    (["--headless", "--path", ".", "--fixed-fps", "60", "--", "--qa"], "qa_flow"),
    (["--headless", "--path", ".", "--fixed-fps", "60", "--", "--qa-town"], "qa_town_flow"),
    (["--headless", "--path", ".", "--fixed-fps", "60", "--", "--qa-loop"], "qa_loop_flow"),
    (["--headless", "--path", ".", "--fixed-fps", "60", "--", "--qa-usability"], "qa_usability"),
    (["--headless", "--path", ".", "--script", "res://tests/break_flow.gd"], "break_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/behan_model_flow.gd"], "behan_model_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/boy_model_flow.gd"], "boy_model_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/odell_model_flow.gd"], "odell_model_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/coroner_model_flow.gd"], "coroner_model_flow"),
    (["--headless", "--path", ".", "--fixed-fps", "60", "--script", "res://tests/coroner_model_integration_flow.gd"], "coroner_model_integration_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/steward_model_flow.gd"], "steward_model_flow"),
    (["--headless", "--path", ".", "--fixed-fps", "60", "--script", "res://tests/steward_model_integration_flow.gd"], "steward_model_integration_flow"),
    (["--headless", "--path", ".", "--fixed-fps", "60", "--script", "res://tests/walter_pickup_flow.gd"], "walter_pickup_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/cast_model_flow.gd"], "cast_model_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/victim_model_flow.gd"], "victim_model_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/covered_body_model_flow.gd"], "covered_body_model_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/exterior_prop_assets_flow.gd"], "exterior_prop_assets_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/pickman_exterior_model_flow.gd"], "pickman_exterior_model_flow"),
    (["--headless", "--path", ".", "--fixed-fps", "60", "--script", "res://tests/lower_exterior_model_flow.gd"], "lower_exterior_model_flow"),
    (["--headless", "--path", ".", "--script", "res://tests/check_model_textures.gd"], "check_model_textures"),
]

sys.path.insert(0, os.path.join(repo_root, "tools"))
try:
    from kill_headless_godot import kill_headless_godot
    kill_headless_godot()
except Exception:
    pass

print(f"Running {len(tests)} QA suites using: {godot}")
failed = []

for args, name in tests:
    cmd = [godot] + args
    print(f"\n=== {name} ===")
    proc = subprocess.Popen(cmd, cwd=repo_root, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    try:
        out, err = proc.communicate(timeout=30)
        out = out.strip()
        err = err.strip()
        has_error = (
            proc.returncode != 0
            or "SCRIPT ERROR:" in out or "SCRIPT ERROR:" in err
            or "Assertion failed" in out or "Assertion failed" in err
            or "Parse Error:" in out or "Parse Error:" in err
        )
        print("EXIT:", proc.returncode)
        lines = out.splitlines()
        for l in lines[-4:]:
            print("  ", l)
        if has_error:
            print("FAILURE DETECTED")
            if err:
                print("STDERR:\n" + err)
            failed.append(name)
    except subprocess.TimeoutExpired:
        print("TIMEOUT: Suite exceeded limit (30s) - terminating process tree")
        if sys.platform == "win32":
            subprocess.run(["taskkill", "/F", "/T", "/PID", str(proc.pid)], capture_output=True)
        else:
            proc.kill()
        proc.communicate()
        failed.append(f"{name} (timeout)")

if failed:
    print(f"\nQA FAILED ({len(failed)} suites failed): {', '.join(failed)}")
    sys.exit(1)
else:
    print(f"\nALL {len(tests)} QA SUITES PASSED CLEANLY.")
    sys.exit(0)
