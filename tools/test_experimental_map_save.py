#!/usr/bin/env python3
"""Manual CPU-only integration proof. No asset copying, CI, uploads or GUI."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--godot", required=True)
p.add_argument("--source", required=True, type=Path)
p.add_argument("--output", required=True, type=Path)
p.add_argument("--count", default=512, type=int)
p.add_argument("--ticks", default=400, type=int)
a = p.parse_args()
repo = Path(__file__).resolve().parents[1]
a.output = a.output.resolve()
a.source = a.source.resolve(strict=True)
a.output.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
for kind in ["DATA", "CONFIG", "CACHE"]:
    env[f"XDG_{kind}_HOME"] = str(a.output / "save5-xdg" / kind.lower())
receipts = []
try:
    for phase in ["write", "read"]:
        command = [a.godot, "--headless", "--path", str(repo), "--script",
                   "res://tests/map_runtime/experimental_save_resume.gd", "--",
                   phase, str(a.source), str(a.count), str(a.ticks), str(a.output)]
        start = time.monotonic_ns()
        with (a.output / f"{phase}.log").open("w") as log:
            process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT)
            try:
                code = process.wait(timeout=900)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=15)
                raise
        receipt = {"phase": phase, "pid": process.pid, "exit_code": code,
                   "start_monotonic_ns": start, "end_monotonic_ns": time.monotonic_ns(),
                   "command": command}
        receipts.append(receipt)
        text = (a.output / f"{phase}.log").read_text()
        if code != 0 or "ERROR:" in text or "FAIL" in text:
            raise RuntimeError(f"{phase} failed, inspect {phase}.log")
        report = json.loads((a.output / f"{phase}.json").read_text())
        if report["failures"]:
            raise RuntimeError(f"{phase} reported failures")
    assert receipts[0]["end_monotonic_ns"] < receipts[1]["start_monotonic_ns"]
    result = {"status": "PASS", "separate_processes": True, "ordinary_per_side": a.count,
              "saved_tick": a.ticks, "receipts": receipts,
              "scope": "CPU_SAVE_RESUME_ONLY_NO_ART_GPU_M5_OR_CAMPAIGN_CLAIM"}
except Exception as error:
    result = {"status": "FAIL", "error": str(error), "receipts": receipts}
    raise
finally:
    (a.output / "process-restart.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result))
