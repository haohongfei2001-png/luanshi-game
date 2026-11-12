"""Exercise the exported macOS binary in an ephemeral, graphical GitHub-hosted session."""
import argparse
import contextlib
import errno
import hashlib
import json
import os
from pathlib import Path
import plistlib
import pty
import re
import select
import shutil
import signal
import struct
import subprocess
import tempfile
import time


PLANS = (
    ("compat-1", "gl_compatibility", 0),
    ("default-metal-1", "mobile", 0),
    ("default-metal-2", "mobile", 0),
    ("balanced-metal", "mobile", 1),
    ("performance-metal", "mobile", 2),
    ("compat-2", "gl_compatibility", 0),
)
CONTROL = ("focus-control", "gl_compatibility", 0)
SHIPPING = ("shipping-metal", "mobile", 0)


@contextlib.contextmanager
def empty_game_data(data_dir):
    # Preserve the native headless smoke saves. The package and the global
    # WindowServer/driver caches remain untouched for every launch.
    if os.environ.get("GITHUB_ACTIONS") != "true" or os.environ.get("RUNNER_OS") != "macOS":
        raise RuntimeError("Cold data rotation requires a disposable GitHub-hosted macOS runner")
    if any(part.is_symlink() for part in [data_dir, *data_dir.parents]):
        raise RuntimeError("Refusing to rotate symlinked game data")
    with tempfile.TemporaryDirectory(dir=os.environ["RUNNER_TEMP"]) as temporary:
        prior = Path(temporary) / "prior"
        if data_dir.exists():
            data_dir.rename(prior)
        try:
            yield
        finally:
            if data_dir.exists():
                data_dir.rename(Path(temporary) / "this-launch")
            if prior.exists():
                prior.rename(data_dir)


def observe(args, focus_helper, output, label):
    """A PTY keeps even a release executable's diagnostic prints line buffered."""
    master, slave = pty.openpty()
    started = time.monotonic()
    events, actors = [], []
    pending, promoted = b"", False
    log_file = output / (label + ".log")
    with log_file.open("w") as log, (output / (label + "-focus.log")).open("w") as actor_log:
        process = subprocess.Popen(args, stdout=slave, stderr=slave, stdin=subprocess.DEVNULL,
                                   start_new_session=True)
        os.close(slave)

        def line(raw):
            nonlocal promoted
            value = raw.decode(errors="replace").rstrip("\r")
            print(value, file=log, flush=True)
            if not value.startswith("FIELD_BOOT "):
                return
            event = json.loads(value.partition(" ")[2])
            event["launch_wall_ms"] = round((time.monotonic() - started) * 1000, 1)
            events.append(event)
            action = None
            if event["stage"] == "first_post_draw" and not event["focus"] and not promoted:
                promoted, action = True, "foreground"
            if event["stage"] == "control_armed":
                action = "interrupt"
            if action:
                print(action, event["pid"], file=actor_log, flush=True)
                actors.append(subprocess.Popen([focus_helper, action, str(event["pid"])],
                                               stdout=actor_log, stderr=actor_log))

        timeout = False
        try:
            while time.monotonic() - started < 75:
                ready, _, _ = select.select([master], [], [], 0.3)
                if not ready:
                    continue
                try:
                    data = os.read(master, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    data = b""
                if not data:
                    break
                chunks = (pending + data).split(b"\n")
                pending = chunks.pop()
                for chunk in chunks:
                    line(chunk)
            else:
                timeout = True
            if pending:
                line(pending)
        finally:
            os.close(master)
            if timeout or process.poll() is None:
                try:
                    process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            for actor in actors:
                try:
                    actor.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    actor.kill()
                    actor.wait()
    return 124 if timeout else process.returncode, events, promoted


def trial(executable, output, data_dir, helper, plan):
    label, method, quality = plan
    image = output / (label + ".png")
    args = ["/usr/bin/time", "-l", str(executable)]
    if method == "gl_compatibility":
        args += ["--rendering-method", method]
    if plan != SHIPPING:
        args += ["--resolution", "1000x600"]
    args += ["--audio-driver", "Dummy", "--disable-vsync", "--",
             "--field-check", "--field-profile", "--field-proof=" + str(image),
             "--field-quality=" + str(quality)]
    if label == "default-metal-2" or plan == SHIPPING:
        args.append("--field-window-tour")
    if label == CONTROL[0]:
        args.append("--field-focus-control")

    with empty_game_data(data_dir):
        empty_at_launch = not data_dir.exists()
        code, events, promoted = observe(args, helper, output, label)
        log = (output / (label + ".log")).read_text()
        for line in log.splitlines():
            if line.startswith("FIELD_PROFILE_FILE "):
                session = Path(line.partition(" ")[2])
                if session.is_file() and session.resolve().is_relative_to(data_dir.resolve()):
                    shutil.copy2(session, output / (label + "-session.jsonl"))
    (output / (label + "-boot.json")).write_text(json.dumps(events, indent=2))
    row = next((json.loads(line.partition(" ")[2]) for line in log.splitlines()
                if line.startswith("FIELD_HOST_WINDOW ")), {})
    rss = re.search(r"^\s*(\d+)\s+maximum resident set size", log, re.M)
    png_size = []
    if image.is_file():
        with image.open("rb") as stream:
            header = stream.read(24)
        if header[:8] == b"\x89PNG\r\n\x1a\n" and header[12:16] == b"IHDR":
            png_size = list(struct.unpack(">II", header[16:24]))
    stages = {event["stage"]: event for event in events}
    expected = ["scene_ready", "first_post_draw", "foreground_ready", "deployed", "first_tick",
                "first_hit", "contact_complete"]
    if label == CONTROL[0]:
        expected += ["control_armed", "focus_paused", "still_paused_after_foreground", "resume_pressed"]
    valid = (code == 0 and empty_at_launch and all(stage in stages for stage in expected)
             and all(Path(event["data_dir"]) == data_dir for event in events)
             and "FIELD_PACKAGE_PASS " in log and row.get("renderer") == method
             and image.is_file() and image.stat().st_size > 4096 and row.get("hits_in_window", 0) > 0
             and bool(png_size) and row.get("render_target_px") == png_size
             and row.get("preset") == quality and row.get("shadows") == (quality != 2)
             and abs(row.get("scale", 0) - [1.0, 0.85, 0.70][quality]) < 0.001
             and not any(marker in log for marker in ("SCRIPT ERROR", "SHADER ERROR", "ERROR:")))
    requested = [1280, 800] if plan == SHIPPING else [1000, 600]
    if plan == SHIPPING:
        valid = valid and png_size[0] >= 1000 and png_size[1] >= 600
    row.update(label=label, returncode=code, requested_method=method, validated=valid,
               requested_window_px=requested, png_ihdr_px=png_size, uses_default_window=(plan == SHIPPING),
               max_rss_bytes=int(rss.group(1)) if rss else None, app_data_absent_at_spawn=empty_at_launch,
               activation_requested=promoted, last_boot_stage=events[-1]["stage"] if events else None,
               launch_milestones_ms={key: stages[key]["launch_wall_ms"] for key in expected if key in stages})
    if not valid:
        print("DIAGNOSTIC", label, json.dumps(events[-2:]), log[-1200:], flush=True)
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("archive", "unpacked", "evidence"):
        parser.add_argument(name, type=Path)
    args = parser.parse_args()
    output = args.evidence.resolve()
    output.mkdir(parents=True, exist_ok=True)
    app, = args.unpacked.resolve().glob("*.app")
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    game = app / "Contents/MacOS" / info["CFBundleExecutable"]
    data_dir = Path.home() / "Library/Application Support/Godot/app_userdata/Luanshi - Border Skirmish"
    digest = hashlib.sha256(args.archive.read_bytes()).hexdigest()
    print("SOURCE_ARCHIVE_SHA256", digest, flush=True)
    report = {"archive_sha256": digest, "source_run": os.environ["GITHUB_RUN_ID"], "samples": [],
              "cold_scope": "New process and empty Godot game data each time; OS driver caches retained"}
    with tempfile.TemporaryDirectory(dir=os.environ["RUNNER_TEMP"]) as temporary:
        helper = Path(temporary) / "focus"
        subprocess.run(["clang", "-fobjc-arc", "-framework", "AppKit", "-o", helper,
                        Path(__file__).with_name("macos_probe_focus.m")], check=True)
        for plan in (*PLANS, CONTROL, SHIPPING):
            row = trial(game, output, data_dir, helper, plan)
            if plan == CONTROL:
                tag = "FOCUS_CONTROL"
                report["focus_control"] = row
            elif plan == SHIPPING:
                tag = "NATIVE_SHIPPING_WINDOW"
                report["shipping_window"] = row
            else:
                tag = "RENDERER_TRIAL"
                report["samples"].append(row)
            print(tag, json.dumps(row), flush=True)
            (output / "renderer-comparison.json").write_text(json.dumps(report, indent=2))
    if not all(row["validated"] for row in [*report["samples"], report["focus_control"], report["shipping_window"]]):
        raise SystemExit("Native startup or an exported window trial failed; individual logs retained.")


if __name__ == "__main__":
    main()
