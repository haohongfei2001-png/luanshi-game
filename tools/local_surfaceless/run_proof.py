#!/usr/bin/env python3
"""Run the normal-scene fixture in a fresh, separate output directory."""
import argparse
import ctypes
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent


def isolated_environment(output):
    env = os.environ.copy()
    for name in ["DISPLAY", "WAYLAND_DISPLAY", "XAUTHORITY"]:
        env.pop(name, None)
    for key, subdirectory in [("HOME", "home"), ("XDG_DATA_HOME", "data"),
                              ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")]:
        directory = output / "xdg" / subdirectory
        directory.mkdir(parents=True, exist_ok=True)
        env[key] = str(directory)
    env["LP_NUM_THREADS"] = "2"
    return env


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--check-only", action="store_true")
    parser.add_argument("--timeout", type=float, default=180)
    args = parser.parse_args()
    engine = args.engine.resolve()
    if not engine.is_file() or not os.access(engine, os.X_OK):
        parser.error("Provide the executable produced by this checkpoint's build.")
    for module in ["PIL", "numpy"]:
        if importlib.util.find_spec(module) is None:
            parser.error(f"Missing installed QA dependency: {module}. Nothing is installed automatically.")
    try:
        ctypes.CDLL("libEGL.so.1")
    except OSError:
        parser.error("Installed libEGL.so.1 with Mesa llvmpipe is required.")
    if args.check_only:
        print("PASS dependency/path checks only; no engine process or rendering was started.")
        return 0
    if not args.output_dir:
        parser.error("Use a fresh --output-dir, or --check-only.")
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=False)
    # Never overwrite an existing hardlinked executable or a previous proof.
    target = output / "godot-surfaceless"
    with engine.open("rb") as src, target.open("xb") as dst:
        shutil.copyfileobj(src, dst)
    target.chmod(0o755)
    for name in ["project.godot", "main.tscn", "proof.gd"]:
        shutil.copyfile(ROOT / "proof" / name, output / name)
    (output / ".godot").mkdir()
    # This fixture has no class_name declarations. Never use this empty cache for a real game.
    (output / ".godot/global_script_class_cache.cfg").write_text("list=[]\n")
    env = isolated_environment(output)
    command = [str(target), "--display-driver", "surfaceless", "--rendering-driver", "opengl3",
               "--rendering-method", "gl_compatibility", "--render-thread", "safe", "--audio-driver", "Dummy",
               "--disable-crash-handler", "--verbose"]
    guard = [sys.executable, str(ROOT / "resource_guard.py"), "--output-dir", str(output / "guard"),
             "--watch-path", str(output), "--cwd", str(output), "--timeout", str(args.timeout), "--", *command]
    guarded = subprocess.run(guard, env=env, check=False)
    result = json.loads((output / "guard/result.json").read_text())
    code = result["child_exit_code"]
    (output / "exit_code.txt").write_text(str(code if code is not None else 125) + "\n")
    log = output / "guard/process.log"
    if log.exists():
        shutil.copyfile(log, output / "runtime.log")
    (output / "binary_identity.json").write_text(json.dumps({
        "bytes": target.stat().st_size, "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
        "guard_status": result["status"], "engine_exit_code": code}, indent=2) + "\n")
    if guarded.returncode != 0:
        print("Engine/guard did not pass. Preserve this output and inspect before starting a fresh retry.")
        return 1
    return subprocess.run([sys.executable, str(ROOT / "pixel_qa.py"), "--run-dir", str(output)], check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
