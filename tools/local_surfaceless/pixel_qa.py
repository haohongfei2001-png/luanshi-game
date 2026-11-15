#!/usr/bin/env python3
"""Check this tiny engineering fixture, never judge a game's visual quality."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import numpy as np
from PIL import Image

EXPECTED = [(768, 432), (768, 432), (1280, 720), (2560, 1440), (3840, 2160)]
FRAMES = [8, 48, 64, 80, 96]


def image_path(directory, filename):
    if not isinstance(filename, str) or not re.fullmatch(r"scenetree_frame_[0-9]+\.png", filename):
        raise ValueError("Capture must name one relative fixture PNG, not another local file.")
    candidate = directory / filename
    if candidate.is_symlink() or candidate.resolve().parent != directory.resolve():
        raise ValueError("Capture escapes the fresh run directory.")
    return candidate


def check_input(data):
    press, release = data["press"], data["release"]
    for record, expected in [(press, True), (release, False)]:
        if (record["requested_pointer"] != [123, 234] or record["observed_pointer"] != [123, 234]
                or record["physical_key_J_state"] is not expected or record["action_state"] is not expected
                or record["requested_pressed"] is not expected or record["pass"] is not True):
            return False
    return (press["input_callback_count"] >= 3 and press["unhandled_callback_count"] >= 1
            and release["input_callback_count"] > press["input_callback_count"]
            and release["unhandled_callback_count"] > press["unhandled_callback_count"])


def evaluate(directory):
    directory = Path(directory).resolve()
    runtime = json.loads((directory / "runtime_report.json").read_text())
    captures = runtime["captures"]
    if len(captures) != len(EXPECTED):
        raise ValueError("Expected exactly five captures from the fixture.")
    rows, motion_arrays = [], []
    for index, capture in enumerate(captures):
        path = image_path(directory, capture["png"])
        with Image.open(path) as source:
            if source.size != EXPECTED[index]:
                raise ValueError("Unexpected PNG dimensions before decoding pixels.")
            image = source.convert("RGB")
            stride = 1 if index < 2 else 8
            sample = np.asarray(image)[::stride, ::stride].astype(np.int16)
        if index < 2:
            motion_arrays.append(sample)
        orange = ((sample[:, :, 0] > 90) & (sample[:, :, 0] > 1.35 * sample[:, :, 1])
                  & (sample[:, :, 0] > 1.8 * sample[:, :, 2]))
        blue = ((sample[:, :, 2] > 90) & (sample[:, :, 2] > 1.4 * sample[:, :, 0])
                & (sample[:, :, 1] > 1.4 * sample[:, :, 0]))
        yy, xx = np.nonzero(orange)
        rows.append({"filename": path.name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                     "size": list(EXPECTED[index]), "sample_stride": stride,
                     "unique_colors": int(np.unique(sample.reshape(-1, 3), axis=0).shape[0]),
                     "orange_pixels": int(orange.sum()), "blue_pixels": int(blue.sum()),
                     "orange_centroid": [float(xx.mean()), float(yy.mean())] if len(xx) else None})
    difference = np.max(np.abs(motion_arrays[0] - motion_arrays[1]), axis=2)
    changed = int((difference > 10).sum())
    area_reference = min(row["orange_pixels"] for row in rows[:2])
    centroids = [row["orange_centroid"] for row in rows[:2]]
    shift = centroids[1][0] - centroids[0][0] if all(centroids) else None
    log = (directory / "runtime.log").read_text()
    errors = re.findall(r"(?m)^(?:ERROR|SCRIPT ERROR|FATAL):.*$", log)
    queries = [tuple(map(int, match)) for match in re.findall(
        r"SURFACELESS_EGL_PBUFFER actual=(\d+)x(\d+) requested=(\d+)x(\d+)", log)]
    elapsed = [capture["scene_elapsed_seconds"] for capture in captures]
    checks = {
        "engine_exit_zero": (directory / "exit_code.txt").read_text().strip() == "0",
        "actual_software_renderer": (runtime["display_driver"] == "surfaceless"
            and runtime["rendering_method"] == "gl_compatibility" and "llvmpipe" in runtime["renderer"]
            and not runtime["DISPLAY_present"] and not runtime["WAYLAND_DISPLAY_present"]),
        "native_dimensions_and_scale": all(
            capture["frame"] == FRAMES[index] and capture["root_size"] == list(EXPECTED[index])
            and capture["requested_size"] == list(EXPECTED[index]) and capture["scaling_3d_scale"] == 1.0
            and [capture["width"], capture["height"]] == list(EXPECTED[index])
            for index, capture in enumerate(captures)),
        "queried_egl_sizes": queries == [(w, h, w, h) for w, h in [EXPECTED[0], *EXPECTED[2:]]],
        "process_timestep_advances": elapsed[0] > 0 and all(a < b for a, b in zip(elapsed, elapsed[1:])),
        "real_draw_counters": all(c["visible_draw_calls"] > 0 and c["visible_primitives"] > 0
                                   and c["canvas_draw_calls"] > 0 for c in captures),
        "synthetic_input_press_release": check_input(runtime["synthetic_input_proof"]),
        "nonuniform_geometry_pixels": all(r["unique_colors"] > (500 if r["sample_stride"] == 1 else 50)
                                          and r["orange_pixels"] > 20 and r["blue_pixels"] > 20 for r in rows),
        "visible_object_motion": changed >= area_reference > 0 and shift is not None and abs(shift) > 5,
        "no_runtime_errors": not errors,
    }
    return {"status": "PASS" if all(checks.values()) else "FAIL", "checks": checks,
            "scope": "Synthetic Godot engineering fixture only; not game/art/device acceptance.",
            "runtime_errors": errors, "changed_pixels_gt10": changed,
            "motion_object_area_reference": area_reference, "orange_centroid_shift_x": shift, "images": rows}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    args = parser.parse_args()
    try:
        result = evaluate(args.run_dir)
    except (ValueError, OSError, KeyError, TypeError, IndexError) as error:
        result = {"status": "FAIL", "reason": str(error)}
    (args.run_dir / "pixel_qa.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
