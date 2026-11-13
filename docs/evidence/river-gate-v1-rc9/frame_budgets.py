#!/usr/bin/env python3
"""Summarise already recorded frames at 60, 90, and 120 Hz, without running the game."""
import json
import math
import statistics
import sys
from pathlib import Path


def budgets(frame_ms):
    ordered = sorted(frame_ms)
    if not ordered or any(not math.isfinite(ms) or ms <= 0 for ms in ordered):
        raise ValueError("Frame capture is missing or contains an invalid wall interval")
    count = len(ordered)
    over = {str(hz): sum(ms > 1000.0 / hz for ms in ordered) for hz in (60, 90, 120)}
    return {
        "frames": count, "fps": 1000 / statistics.mean(ordered),
        "p50_ms": ordered[math.ceil(.50 * count) - 1],
        "p95_ms": ordered[math.ceil(.95 * count) - 1],
        "p99_ms": ordered[math.ceil(.99 * count) - 1],
        "max_ms": ordered[-1], "frames_over_budget": over,
    }


def one(root, pattern):
    path, = root.rglob(pattern)
    return json.loads(path.read_text())


def profile(native, software):
    row = one(native, "shipping-metal-frames.json")
    if row["per_side"] != 512 or row["hits_in_window"] <= 0 or not row["tour"]:
        raise ValueError("Expected the 512v512 native live combat camera tour")
    full = budgets(row["raw_wall_ms"])
    if full["frames"] != row["frames"]:
        raise ValueError("Native frame trace is incomplete")
    rounds = {}
    for size in (20, 100, 250, 512):
        capture = one(software, f"field-frame-times-{size}.json")
        data, sample = capture["sorted_frame_ms"], capture["sample"]
        if sample["ordinary_rosters"] != [size, size] or sample["hits_during_sample"] <= 0:
            raise ValueError(f"Missing roster or contact in {size}v{size}")
        if sample["frame_samples"] != len(data):
            raise ValueError(f"Truncated frame log in {size}v{size}")
        rounds[str(size)] = {
            **budgets(data), "gpu": sample["device"], "pixels": sample["viewport_px"],
            "scale": sample["render_scale"], "rss_kib": sample["resident_kib"],
            "new_hits": sample["hits_during_sample"],
        }
    return {
        "native": {**full, "host": row["processor"], "gpu": row["adapter"],
                   "pixels": row["render_target_px"], "scale": row["scale"], "seconds": row["seconds"],
                   "new_hits": row["hits_in_window"], "msaa": row["requested_msaa_samples"],
                   "gpu_timestamps": row["gpu_timer_status"]},
        "linux_software": rounds,
    }


if __name__ == "__main__":
    print("FRAME_BUDGET " + json.dumps(profile(Path(sys.argv[1]), Path(sys.argv[2])), separators=(",", ":")))
