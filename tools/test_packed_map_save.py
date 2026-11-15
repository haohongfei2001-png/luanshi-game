#!/usr/bin/env python3
"""Private minimal-PCK test using an existing template and existing typed saves."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--editor", required=True)
p.add_argument("--template", required=True)
p.add_argument("--source", required=True, type=Path)
p.add_argument("--source-evidence", required=True, type=Path)
p.add_argument("--output", required=True, type=Path)
p.add_argument("--frozen-commit", default="HEAD", help="Git revision to freeze; resolved to an exact commit before checking any inputs")
a = p.parse_args()
repo = Path(__file__).resolve().parents[1]
requested_frozen_ref = a.frozen_commit
# Pin even HEAD immediately. Invalid refs or dirty dependencies fail closed;
# never fall back to a local historical checkpoint or skip the freeze check.
a.frozen_commit = subprocess.check_output(
    ["git", "rev-parse", "--verify", "--end-of-options", f"{requested_frozen_ref}^{{commit}}"],
    cwd=repo, text=True,
).strip()
for key in ["source", "source_evidence"]:
    setattr(a, key, getattr(a, key).resolve(strict=True))
a.output = a.output.resolve()
a.output.mkdir(parents=True, exist_ok=True)
empty = a.output / "empty-cwd"
empty.mkdir(exist_ok=True)
if list(empty.iterdir()):
    raise RuntimeError("Empty working directory required")


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def run(command, log, cwd, env, expected):
    start = time.monotonic_ns()
    with log.open("w") as stream:
        process = subprocess.Popen(command, cwd=cwd, env=env, stdout=stream, stderr=subprocess.STDOUT)
        try:
            code = process.wait(timeout=120)
        except subprocess.TimeoutExpired:
            process.terminate()
            process.wait(timeout=15)
            raise
    text = log.read_text()
    if code != expected or "ERROR:" in text:
        raise RuntimeError(f"Unexpected exit/error in {log}: {code}")
    return {"command": command, "cwd": str(cwd), "pid": process.pid, "exit_code": code,
            "start_monotonic_ns": start, "end_monotonic_ns": time.monotonic_ns(),
            "log_sha256": sha(log)}


# Exact static dependency closure only. No large asset or external install fallback.
queue = ["scripts/field/experimental_map_save.gd"]
closure = set()
while queue:
    relative = queue.pop()
    if relative in closure:
        continue
    path = repo / relative
    if path.suffix != ".gd" or not path.is_file():
        raise RuntimeError(f"Unexpected minimum dependency: {relative}")
    contents = path.read_bytes()
    frozen = subprocess.check_output(["git", "show", f"{a.frozen_commit}:{relative}"], cwd=repo)
    if contents != frozen:
        raise RuntimeError(f"Frozen save dependency changed: {relative}")
    closure.add(relative)
    queue.extend(re.findall(r'["\']res://([^"\']+)["\']', contents.decode()))

expected_file = a.source_evidence / "expected.bin"
xdg = a.source_evidence / "save5-xdg"
user_dir = xdg / "data/godot/app_userdata/Luanshi - Border Skirmish"
slot = user_dir / "experimental_map_v5/test_512.bin"
protected = [slot, user_dir / "river_gate_quick_v1.bin", user_dir / "campaign_sentinel.bin"]
protected_before = {str(path): sha(path) for path in protected}
project = a.output / "project.godot"
project.write_text('config_version=5\n[application]\nconfig/name="Luanshi - Border Skirmish"\nrun/main_scene="res://main.tscn"\n')
scene = a.output / "main.tscn"
scene.write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://tests/map_runtime/packed_save_resume_probe.gd" id="1"]\n[node name="SaveResumeProbe" type="Node"]\nscript=ExtResource("1")\n')
classes = a.output / "classes.cfg"
classes.write_text('list=Array[Dictionary]([])\n')
config = a.output / "config.json"
config.write_text(json.dumps({"schema": 1, "source_sha256": sha(a.source), "expected_sha256": sha(expected_file),
                             "slot_sha256": sha(slot), "slot": "test_512", "saved_tick": 400,
                             "ordinary_per_side": 512}) + "\n")
files = {"res://" + path: repo / path for path in sorted(closure)}
files.update({"res://project.godot": project, "res://main.tscn": scene,
              "res://.godot/global_script_class_cache.cfg": classes,
              "res://tests/map_runtime/packed_save_resume_probe.gd": repo / "tests/map_runtime/packed_save_resume_probe.gd",
              "res://test_data/config.json": config, "res://test_data/hf08-source.json": a.source,
              "res://test_data/expected.bin": expected_file})
manifest = {"packs": []}
for name, omitted in [("complete", None), ("missing-source", "res://test_data/hf08-source.json"),
                      ("missing-oracle", "res://test_data/expected.bin")]:
    manifest["packs"].append({"output": str(a.output / (name + ".pck")),
                              "files": [{"resource": res, "path": str(path)}
                                        for res, path in files.items() if res != omitted]})
descriptor = a.output / "pack-inputs.json"
descriptor.write_text(json.dumps(manifest, indent=2) + "\n")
env = os.environ.copy()
for kind in ["DATA", "CONFIG", "CACHE"]:
    env[f"XDG_{kind}_HOME"] = str(xdg / kind.lower())
receipts = []
result = {"status": "FAIL", "requested_frozen_ref": requested_frozen_ref,
          "frozen_commit": a.frozen_commit, "receipts": receipts,
          "dependency_sha256": {path: sha(repo / path) for path in sorted(closure)},
          "template_sha256": sha(a.template), "source_sha256": sha(a.source),
          "scope": "PRIVATE_TEMPLATE_CPU_TEST_NOT_RELEASE_GPU_M5_UI_OR_ART_ACCEPTANCE"}
try:
    command = [a.editor, "--headless", "--path", str(repo), "--script",
               "res://tests/map_runtime/build_save_resume_pack.gd", "--", str(descriptor)]
    receipts.append(run(command, a.output / "build.log", repo, env, 0))
    result["packs"] = {}
    for name, missing in [("complete", None), ("missing-source", "res://test_data/hf08-source.json"),
                          ("missing-oracle", "res://test_data/expected.bin")]:
        pack = a.output / (name + ".pck")
        if pack.stat().st_size > 4 * 1024 * 1024:
            raise RuntimeError("Minimal pack exceeded4MiB; do not add large assets")
        env["LUANSHI_SAVE5_PACK_REPORT"] = str(a.output / (name + ".json"))
        command = [a.template, "--headless", "--main-pack", str(pack)]
        receipts.append(run(command, a.output / (name + ".log"), empty, env, 0 if missing is None else 2))
        report = json.loads((a.output / (name + ".json")).read_text())
        if missing is None:
            assert report["status"] == "PASS" and not report["failures"]
            assert report["final"]["tick"] == 420 and report["final"]["roster"] == 1057
        else:
            assert report["status"] == "REFUSED"
            assert report["failures"] == ["REQUIRED_RESOURCE_MISSING " + missing]
        result["packs"][name] = {"bytes": pack.stat().st_size, "sha256": sha(pack), "report": report}
    assert protected_before == {str(path): sha(path) for path in protected}
    assert not list(empty.iterdir())
    result["protected_files_unchanged"] = protected_before
    result["empty_cwd_before_and_after"] = True
    result["status"] = "PASS"
finally:
    (a.output / "summary.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"status": result["status"], "reports": str(a.output / "summary.json")}))
