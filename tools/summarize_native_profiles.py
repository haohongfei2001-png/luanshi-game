"""Summarize native real-time frames, independently of Movie Maker capture."""
from pathlib import Path
import json
import math
import os
import re
import sys

def percentile(values, fraction):
    ordered = sorted(values)
    return ordered[max(0, math.ceil(len(ordered) * fraction) - 1)]

def resource_value(text, name):
    match = re.search(r"(\d+)\s+" + re.escape(name), text)
    return int(match[1]) if match else None

root = Path(sys.argv[1])
profiles = []
for directory in sorted(root.glob("profile-qhd-*")):
    rows = []
    for path in sorted((directory / "frame-times").glob("*.jsonl")):
        rows.extend(json.loads(line) for line in path.read_text().splitlines() if line.strip())
    host = next(row for row in rows if row["kind"] == "host")
    frames = [row for row in rows if row["kind"] == "frames"]
    intervals = [value for row in frames for value in row["raw_wall_ms"]]
    assert intervals, directory
    assert all(row["render_target_px"] == [2560, 1440] and row["internal_scale"] == 1 for row in frames)
    facts = json.loads((directory / "input-and-camera.json").read_text())
    resources = (directory / "resource-time.log").read_text()
    phases = {}
    for row in frames:
        for key, value in row.get("step_phase_ms", {}).items():
            phases[key] = phases.get(key, 0) + value
    snapshots = [row["last_reported_render_counters"] for row in frames
                 if "last_reported_render_counters" in row]
    gpu_present = any(row["render_gpu"] is not None for row in frames)
    profiles.append({
        "scenario": directory.name,
        "source_sha": os.environ["GITHUB_SHA"],
        "host": host,
        "ordinary": facts["ordinary"],
        "render_px": [2560, 1440],
        "internal_scale": 1,
        "sample_frames": len(intervals),
        "engaged_seconds": sum(intervals) / 1000.,
        "elapsed_play_seconds": facts["wall_seconds"],
        "average_fps": len(intervals) * 1000. / sum(intervals),
        "p50_ms": percentile(intervals, .50),
        "p95_ms": percentile(intervals, .95),
        "p99_ms": percentile(intervals, .99),
        "max_ms": max(intervals),
        "frames_over_16_67ms": sum(value > 1000. / 60 for value in intervals),
        "sim_cpu_ms": sum(row["sim_cpu_ms"] for row in frames),
        "view_script_ms": sum(row["view_script_ms"] for row in frames),
        "step_phase_ms": phases,
        "last_reported_render_counters": snapshots,
        "gpu_timestamps_available": gpu_present,
        "maximum_rss_bytes": resource_value(resources, "maximum resident set size"),
        "peak_memory_footprint_bytes": resource_value(resources, "peak memory footprint"),
        "last_battle_state": facts["last"],
        "camera_tour": facts.get("camera_tour", False),
        "status": "MEASURED_HOSTED_ONLY",
        "real_M5": "DEVICE_NOT_RUN",
        "note": "Raw frame intervals cover recent live contact. Monitor snapshots may lag by one second. These are instrumented real-time runs.",
    })
report = {"source_sha": os.environ["GITHUB_SHA"], "run": os.environ["GITHUB_RUN_ID"],
          "profiles": profiles, "movie_frame_cadence_used_for_fps": False,
          "art_acceptance": "ART_REBUILD_REQUIRED", "real_M5": "DEVICE_NOT_RUN"}
(root / "native-performance.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
for row in profiles:
    print("NATIVE_REALTIME_PROFILE", json.dumps({key: value for key, value in row.items()
          if key not in ("host", "last_reported_render_counters")}), flush=True)
