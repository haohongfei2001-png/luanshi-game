#!/usr/bin/env python3
"""Explicitly triggered native macOS CI probe. No game edits, signing, or permissions.

A captured viewport plus an on-screen window for the launched PID is required.
MovieWriter's fixed-step frames are rendering evidence, never an FPS benchmark.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import plistlib
import re
import signal
import struct
import subprocess
import sys
import time
import zlib

ERRORS = re.compile(r"SCRIPT ERROR|Parse Error|(?:^|\n)ERROR:")
RENDER_FAILURE = re.compile(
    r"(unable to|failed to|could not|couldn't|cannot|can't).{0,80}"
    r"(rendering device|rendering context|OpenGL context|pixel format|display server|Metal device)"
    r"|no (?:available |suitable |supported )?(?:rendering |Metal |Vulkan )devices?"
    r"|OpenGL.{0,80}(not supported|not available)", re.IGNORECASE)


def save_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def run_bounded(command, log_path, timeout, cwd=None, observer=None):
    """Use Python process groups, not GNU timeout (absent on stock macOS)."""
    started = time.monotonic()
    samples = []
    timed_out = False
    with log_path.open("w") as output:
        try:
            child = subprocess.Popen(command, cwd=cwd, stdout=output,
                                     stderr=subprocess.STDOUT, start_new_session=True)
        except OSError as exc:
            result = {"command": command, "launch_error": str(exc), "returncode": None,
                      "timed_out": False, "samples": []}
            save_json(log_path.with_suffix(".json"), result)
            output.write(str(exc) + "\n")
            return result
        try:
            while child.poll() is None:
                if time.monotonic() - started >= timeout:
                    timed_out = True
                    break
                if observer:
                    # Each native observation is also bounded and cannot prompt.
                    try:
                        observed = subprocess.run([str(observer), str(child.pid)],
                                                  capture_output=True, text=True, timeout=2)
                        sample = json.loads(observed.stdout)
                        sample["elapsed_seconds"] = round(time.monotonic() - started, 3)
                        samples.append(sample)
                    except (OSError, ValueError, subprocess.TimeoutExpired) as exc:
                        samples.append({"observer_error": str(exc)})
                time.sleep(0.25)
        finally:
            if child.poll() is None:
                try:
                    os.killpg(child.pid, signal.SIGTERM)
                    child.wait(timeout=3)
                except ProcessLookupError:
                    pass
                except subprocess.TimeoutExpired:
                    os.killpg(child.pid, signal.SIGKILL)
                    child.wait(timeout=3)
    result = {"command": command, "pid": child.pid, "returncode": child.returncode,
              "timed_out": timed_out, "elapsed_seconds": round(time.monotonic() - started, 3),
              "samples": samples}
    save_json(log_path.with_suffix(".json"), result)
    return result


def inspect_png(path):
    """Decode Godot's 8-bit non-interlaced RGB(A) PNG, with CRC/size checks."""
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("Invalid PNG signature")
    at, compressed, header, ended = 8, bytearray(), None, False
    while at < len(data):
        length = struct.unpack_from(">I", data, at)[0]
        kind = data[at + 4:at + 8]
        chunk = data[at + 8:at + 8 + length]
        crc = struct.unpack_from(">I", data, at + 8 + length)[0]
        if zlib.crc32(kind + chunk) & 0xFFFFFFFF != crc:
            raise ValueError("PNG CRC mismatch")
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", chunk)
        elif kind == b"IDAT":
            compressed.extend(chunk)
        elif kind == b"IEND":
            ended = True
            break
        at += length + 12
    if not header or not ended:
        raise ValueError("Incomplete PNG")
    width, height, depth, color, compression, filtering, interlace = header
    if not (64 <= width <= 4096 and 64 <= height <= 4096 and depth == 8 and
            color in (2, 6) and compression == 0 and filtering == 0 and interlace == 0):
        raise ValueError("Unsupported PNG dimensions/format")
    bpp = 3 if color == 2 else 4
    stride = width * bpp
    size = (stride + 1) * height
    decoder = zlib.decompressobj()
    raw = decoder.decompress(bytes(compressed), size + 1)
    if len(raw) != size or not decoder.eof:
        raise ValueError("Invalid decoded PNG size")
    previous = bytearray(stride)
    colors = set()
    for y in range(height):
        start = y * (stride + 1)
        mode = raw[start]
        row = bytearray(raw[start + 1:start + 1 + stride])
        if mode > 4:
            raise ValueError("Invalid PNG row filter")
        for i in range(stride):
            a, b, c = (row[i - bpp] if i >= bpp else 0), previous[i], (previous[i - bpp] if i >= bpp else 0)
            if mode == 1:
                predictor = a
            elif mode == 2:
                predictor = b
            elif mode == 3:
                predictor = (a + b) // 2
            elif mode == 4:
                p = a + b - c
                distances = (abs(p - a), abs(p - b), abs(p - c))
                predictor = (a, b, c)[distances.index(min(distances))]
            else:
                predictor = 0
            row[i] = (row[i] + predictor) & 255
        if y % 8 == 0:
            colors.update(bytes(row[x:x + 3]) for x in range(0, stride, bpp * 8))
        previous = row
    return {"width": width, "height": height, "sampled_colors": len(colors),
            "nonblank": len(colors) >= 16, "sha256": hashlib.sha256(data).hexdigest()}


def window_seen(result):
    return any(w.get("layer") == 0 and w.get("width", 0) >= 64 and w.get("height", 0) >= 64
               for sample in result["samples"] for w in sample.get("windows", []))


def classify(result, log, marker=None, image=None):
    if result.get("launch_error"):
        return "LAUNCH_FAILED"
    # Do not relabel script bugs as infrastructure merely because no window exists.
    if "SCRIPT ERROR" in log or "Parse Error" in log:
        return "GAME_FAILED"
    if result["timed_out"]:
        return "INCONCLUSIVE_TIMEOUT"
    if RENDER_FAILURE.search(log):
        return "RUNNER_RENDERER_UNAVAILABLE"
    display_samples = [s for s in result["samples"] if s.get("display_error") == 0]
    if (display_samples and all(not s.get("displays") for s in display_samples)
            and not window_seen(result) and not (image or {}).get("nonblank", False)):
        return "RUNNER_DISPLAY_UNAVAILABLE"
    if result["returncode"] != 0 or ERRORS.search(log):
        return "GAME_OR_ENGINE_FAILED"
    if marker and marker not in log:
        return "SMOKE_INCOMPLETE"
    if image is not None and not image.get("nonblank", False):
        return "CAPTURE_FAILED"
    if not window_seen(result):
        return "WINDOW_UNOBSERVED"
    return "PASS"


def verify_archive(archive, evidence, expected_sha256):
    """Verify the inner application ZIP, not GitHub's outer artifact wrapper."""
    if not re.fullmatch(r"[0-9a-f]{64}", expected_sha256):
        raise ValueError("Expected archive SHA-256 must be 64 lowercase hexadecimal characters")
    digest = hashlib.sha256()
    with archive.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    actual = digest.hexdigest()
    save_json(evidence / "archive.json", {"sha256": actual, "expected_sha256": expected_sha256,
                                          "matches": actual == expected_sha256})
    if actual != expected_sha256:
        raise RuntimeError("Inner application ZIP SHA-256 mismatch; no extraction or launch attempted")


def probe(archive, evidence, expected_sha256):
    if platform.system() != "Darwin":
        raise RuntimeError("Native launch is only allowed on the authorized macos-latest runner")
    if os.environ.get("GITHUB_ACTIONS") != "true" or os.environ.get("RUNNER_ENVIRONMENT") != "github-hosted":
        raise RuntimeError("This probe is limited to standard GitHub-hosted CI, not local Macs")
    evidence.mkdir(parents=True, exist_ok=True)
    verify_archive(archive, evidence, expected_sha256)
    temp = Path(os.environ["RUNNER_TEMP"]) / f"luanshi-graphics-{os.environ['GITHUB_RUN_ID']}"
    temp.mkdir(exist_ok=False)
    save_json(evidence / "host.json", {key: os.environ.get(key) for key in
              ["RUNNER_OS", "RUNNER_ARCH", "RUNNER_ENVIRONMENT", "ImageOS", "ImageVersion"]})
    for name, command in [
        ("os", ["sw_vers"]), ("architecture", ["uname", "-m"]),
        ("display-hardware", ["system_profiler", "SPDisplaysDataType", "-json"]),
    ]:
        run_bounded(command, evidence / f"{name}.log", 20)
    unpack = run_bounded(["ditto", "-x", "-k", str(archive), str(temp / "package")],
                         evidence / "unpack.log", 45)
    if unpack["returncode"] != 0:
        raise RuntimeError("Archive extraction failed; see unpack.log")
    apps = list((temp / "package").glob("*.app"))
    if len(apps) != 1:
        raise RuntimeError("Expected exactly one exported app")
    app = apps[0]
    signature = run_bounded(["codesign", "--verify", "--deep", "--strict", "--verbose=2", str(app)],
                           evidence / "codesign-before.log", 20)
    if signature["returncode"] != 0:
        raise RuntimeError("Unmodified bundle signature verification failed; no launch attempted")
    with (app / "Contents/Info.plist").open("rb") as stream:
        info = plistlib.load(stream)
    binary = app / "Contents/MacOS" / info["CFBundleExecutable"]
    observer = temp / "window-probe"
    compiled = run_bounded(["xcrun", "clang", "-std=c11", "-Wall", "-Wextra", "-Werror",
                            str(Path(__file__).with_name("macos_window_probe.c").resolve()),
                            "-framework", "CoreGraphics", "-framework", "CoreFoundation", "-o", str(observer)],
                           evidence / "observer-build.log", 60)
    if compiled["returncode"] != 0:
        raise RuntimeError("Native observer did not compile; see observer-build.log")
    run_bounded([str(observer)], evidence / "display-baseline.log", 5)
    results = []
    for mode, flag, marker in [("battle", "--smoke-scene", "SCENE_SMOKE_PASS"),
                                ("campaign", "--campaign-smoke", "CAMPAIGN_SMOKE_PASS")]:
        # Capture only 90 offline frames at 10 FPS (nine simulation seconds).
        # Absolute external MovieWriter paths avoid res:// writes inside the sealed app.
        # This early-exit render stage is explicitly not a completed smoke test.
        frames = temp / f"{mode}-frames"
        frames.mkdir()
        base = [str(binary), "--audio-driver", "Dummy", "--windowed", "--resolution", "1280x800"]
        save_id = f"graphics_{os.environ['GITHUB_RUN_ID']}_{mode}"
        capture = run_bounded(base + ["--fixed-fps", "10", "--max-fps", "10",
                                      "--write-movie", str(frames / "frame.png"), "--quit-after", "90",
                                      "--", flag, f"--campaign-save-id={save_id}_capture"],
                              evidence / f"{mode}-capture.log", 90, observer=observer)
        images = sorted(frames.glob("*.png"))
        image_stats = {"nonblank": False, "frame_count": len(images)}
        if images:
            chosen = images[-1]
            target = evidence / f"{mode}-viewport.png"
            target.write_bytes(chosen.read_bytes())
            try:
                image_stats.update(inspect_png(target))
            except (ValueError, OSError, struct.error, zlib.error) as exc:
                image_stats["error"] = str(exc)
        capture_log = (evidence / f"{mode}-capture.log").read_text(errors="replace")
        capture_status = classify(capture, capture_log, image=image_stats)
        renderer_lines = [line for line in capture_log.splitlines()
                          if any(word in line for word in ("OpenGL", "Metal", "Vulkan", "Rendering Device", "GPU"))]
        results.append({"stage": f"{mode}-viewport", "status": capture_status,
                        "image": image_stats, "renderer_log_lines": renderer_lines})
        if capture_status != "PASS":
            # No automatic alternate renderers, permissions, retries, or paid runners.
            results.append({"stage": f"{mode}-smoke", "status": "NOT_RUN_CAPTURE_UNVERIFIED"})
            break
        smoke = run_bounded(base + ["--fixed-fps", "60", "--max-fps", "60", "--", flag,
                                    f"--campaign-save-id={save_id}_smoke"],
                            evidence / f"{mode}-smoke.log", 150, observer=observer)
        smoke_log = (evidence / f"{mode}-smoke.log").read_text(errors="replace")
        results.append({"stage": f"{mode}-smoke", "status": classify(smoke, smoke_log, marker=marker)})
        if results[-1]["status"] != "PASS":
            break
    after = run_bounded(["codesign", "--verify", "--deep", "--strict", "--verbose=2", str(app)],
                        evidence / "codesign-after.log", 20)
    ok = len(results) == 4 and all(item["status"] == "PASS" for item in results) and after["returncode"] == 0
    result = {"status": "PASS_NATIVE_CI_GRAPHICS" if ok else "NOT_VERIFIED",
              "stages": results, "signature_after": after["returncode"],
              "limits": "Standard hosted VM only. Movie frames use offline fixed-step timing. No M5, real-time FPS, thermal, human-input, audio, Finder/Gatekeeper or notarization acceptance."}
    save_json(evidence / "result.json", result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("evidence", type=Path)
    parser.add_argument("--expected-archive-sha256", required=True)
    args = parser.parse_args()
    evidence = args.evidence.resolve()
    evidence.mkdir(parents=True, exist_ok=True)
    try:
        result = probe(args.archive.resolve(), evidence, args.expected_archive_sha256)
    except Exception as exc:
        result = {"status": "PROBE_SETUP_FAILED", "error": str(exc)}
        save_json(evidence / "result.json", result)
    print(json.dumps(result, indent=2))
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as summary:
            summary.write("## Native macOS graphical probe\n\n```json\n" + json.dumps(result, indent=2) + "\n```\n")
    return 0 if result["status"] == "PASS_NATIVE_CI_GRAPHICS" else 1


if __name__ == "__main__":
    sys.exit(main())
