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
directories = set(root.glob("profile-qhd-*")) | set(root.glob("profile-uhd-*"))
if (root/"expected-profiles.json").exists():
    directories.update(root/name for name in json.loads((root/"expected-profiles.json").read_text()))
for directory in sorted(directories):
    try:
        rows = []
        for path in sorted((directory / "frame-times").glob("*.jsonl")):
            rows.extend(json.loads(line) for line in path.read_text().splitlines() if line.strip())
        attempt_file=directory/"attempt.json"
        if attempt_file.exists() and json.loads(attempt_file.read_text())["status"]!="COMPLETE":
            raise ValueError("Capture attempt failed; partial raw data retained, not promoted to measured PASS")
        host = next(row for row in rows if row["kind"] == "host")
        frames = [row for row in rows if row["kind"] == "frames"]
        intervals = [value for row in frames for value in row["raw_wall_ms"]]
        assert intervals, directory
        if not all(isinstance(v,(int,float)) and not isinstance(v,bool) and math.isfinite(v) and v>0 for v in intervals):
            raise ValueError("Frame intervals must be finite positive numeric values, not bool")
        expected_px = [3840, 2160] if directory.name.startswith("profile-uhd-") else [2560, 1440]
        assert all(row["render_target_px"] == expected_px and row["internal_scale"] == 1 for row in frames)
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
            "render_px": expected_px,
            "internal_scale": 1,
            "sample_frames": len(intervals),
            "sampling_status": "SUFFICIENT_WINDOW" if len(intervals) >= 120 and sum(intervals) >= 10000 else "INSUFFICIENT_WINDOW",
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
            "scene_composition": facts.get("scene_composition", {"layout": "not_recorded"}),
            "sampled_offscreen_contacts": sum(row.get("sampled_offscreen_contacts", 0) for row in facts.get("frames", [])),
            "coverage_limits": facts.get("coverage_limits", {}),
            "camera_tour": facts.get("camera_tour", False),
            "status": "MEASURED_HOSTED_ONLY",
            "real_M5": "DEVICE_NOT_RUN",
            "note": "Raw frame intervals cover recent live contact. Monitor snapshots may lag by one second. These are instrumented real-time runs.",
        })
    except (ValueError, KeyError, StopIteration, AssertionError, OSError, TypeError) as exc:
        profiles.append({"scenario":directory.name,"status":"FAILED" if directory.exists() else "MISSING",
                         "error_type":type(exc).__name__,"error":str(exc),"real_M5":"DEVICE_NOT_RUN"})
report = {"source_sha": os.environ["GITHUB_SHA"], "run": os.environ["GITHUB_RUN_ID"],
          "profiles": profiles, "movie_frame_cadence_used_for_fps": False,
          "profile_coverage": "COMPLETE" if profiles and all(r.get("sampling_status")=="SUFFICIENT_WINDOW" for r in profiles) else "NOT_ACCEPTED",
          "art_acceptance": "ART_REBUILD_REQUIRED", "real_M5": "DEVICE_NOT_RUN"}
(root / "native-performance.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
for row in profiles:
    print("NATIVE_REALTIME_PROFILE", json.dumps({key: value for key, value in row.items()
          if key not in ("host", "last_reported_render_counters")}), flush=True)

if report["profile_coverage"] != "COMPLETE":
    raise SystemExit(1)
