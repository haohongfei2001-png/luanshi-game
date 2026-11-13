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
import sys
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
NATIVE_NO_AA = ("native-single-sample", "mobile", 3)
STARTUP_CONTROL = ("startup-focus-control", "mobile", 0)


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


def sample_game_startup(wrapper, executable, output, label, phase):
    """Capture only the direct, verified game child of this probe's /usr/bin/time."""
    children = subprocess.run(["/usr/bin/pgrep", "-P", str(wrapper.pid)], capture_output=True, text=True)
    for child in children.stdout.split():
        if not child.isdecimal():
            continue
        command = subprocess.run(["/bin/ps", "-p", child, "-o", "comm="], capture_output=True, text=True)
        if os.path.realpath(command.stdout.strip()) != os.path.realpath(executable):
            continue
        target = output / (label + "-" + phase + ".sample.txt")
        return subprocess.Popen(["/usr/bin/sample", child, "1", "10", "-file", str(target)],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return None


def observe(args, focus_helper, output, label):
    """A PTY keeps even a release executable's diagnostic prints line buffered."""
    master, slave = pty.openpty()
    started = time.monotonic()
    events, actors = [], []
    interrupter = None
    sample_attempts = set()
    # Bound both initial renderer startup and each distinct, confirmed phase.
    deadline = started + 75
    hard_stop = started + 145
    seen = set()
    pending, promoted = b"", False
    log_file = output / (label + ".log")
    with log_file.open("w") as log, (output / (label + "-focus.log")).open("w") as actor_log:
        process = subprocess.Popen(args, stdout=slave, stderr=slave, stdin=subprocess.DEVNULL,
                                   start_new_session=True)
        os.close(slave)

        def line(raw):
            nonlocal promoted, deadline, interrupter
            value = raw.decode(errors="replace").rstrip("\r")
            print(value, file=log, flush=True)
            if not value.startswith("FIELD_BOOT "):
                return
            event = json.loads(value.partition(" ")[2])
            event["launch_wall_ms"] = round((time.monotonic() - started) * 1000, 1)
            events.append(event)
            stage = event["stage"]
            if stage not in seen and stage in {"scene_ready", "first_post_draw", "deployed", "first_tick", "first_hit", "contact_complete"}:
                seen.add(stage)
                # A tour needs 24 s of real rendering after contact; a quick
                # capture needs 3.5 s plus readback/compression/exit. No repeated
                # focus event or heartbeat can extend this clock.
                budget = (43 if "--field-window-tour" in args else 22) if stage == "contact_complete" else 30
                deadline = min(hard_stop, max(deadline, time.monotonic() + budget))
            action = None
            if event["stage"] == "first_post_draw" and not event["focus"] and not promoted:
                promoted, action = True, "foreground"
            if event["stage"] in {"control_armed", "startup_interruption_armed"}:
                action = "interrupt"
            if stage in {"focus_paused", "startup_paused_zero"} and interrupter and interrupter.stdin:
                try:
                    interrupter.stdin.write(b"1")
                    interrupter.stdin.flush()
                except BrokenPipeError:
                    pass
                interrupter.stdin.close()
                interrupter = None
            if action:
                print(action, event["pid"], file=actor_log, flush=True)
                actor = subprocess.Popen([focus_helper, action, str(event["pid"])],
                                         stdin=subprocess.PIPE if action=="interrupt" else subprocess.DEVNULL,
                                         stdout=actor_log, stderr=actor_log)
                actors.append(actor)
                if action=="interrupt":
                    interrupter = actor

        timeout = False
        try:
            while time.monotonic() < deadline:
                if ("first_post_draw" not in seen and os.environ.get("GITHUB_ACTIONS")=="true"
                        and sys.platform=="darwin"):
                    phase = "before-frame" if "scene_ready" in seen else "before-scene"
                    scene_seen = next((event for event in events if event["stage"]=="scene_ready"), None)
                    since_phase = time.monotonic() - started
                    if scene_seen is not None:
                        since_phase -= scene_seen["launch_wall_ms"]/1000
                    if phase not in sample_attempts and since_phase >= (12 if scene_seen else 23):
                        sample_attempts.add(phase)
                        profiler = sample_game_startup(process, args[2], output, label, phase)
                        if profiler is not None:
                            actors.append(profiler)
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
    default_size = plan in (SHIPPING, NATIVE_NO_AA)
    if not default_size:
        args += ["--resolution", "1000x600"]
    args += ["--audio-driver", "Dummy", "--disable-vsync", "--",
             "--field-check", "--field-profile", "--field-proof=" + str(image),
             "--field-quality=" + str(quality)]
    if label == "default-metal-2" or default_size:
        args.append("--field-window-tour")
    if label in (CONTROL[0],"focus-control-2"):
        args.append("--field-focus-control")
    if label == STARTUP_CONTROL[0]:
        args.append("--field-startup-focus-control")

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
        if len(header) == 24 and header[:8] == b"\x89PNG\r\n\x1a\n" and header[12:16] == b"IHDR":
            png_size = list(struct.unpack(">II", header[16:24]))
    session_file = output / (label + "-session.jsonl")
    session_rows = [json.loads(line) for line in session_file.read_text().splitlines()] if session_file.is_file() else []
    attachments = [sample.get("actual_px") for sample in session_rows if sample.get("kind") == "render_attachment"]
    frame_rows = [sample for sample in session_rows if sample.get("kind") == "frames"]
    session_matches_image = bool(attachments and frame_rows) and attachments[-1] == png_size and all(
        sample.get("render_target_px") == png_size for sample in frame_rows
    )
    longest = row.get("longest_frame_context", {})
    trace_path = output / (label + "-frames.json")
    trace = json.loads(trace_path.read_text()) if trace_path.is_file() else {}
    frames = trace.get("raw_wall_ms", [])
    peak_index = longest.get("frame_zero_based", -1)
    matched_peak = (isinstance(peak_index, int) and 0 <= peak_index < len(frames)
                    and abs(frames[peak_index] - max(frames)) < 0.001
                    and abs(frames[peak_index] - longest.get("wall_ms", -1)) < 0.001)
    phase_names = {"grid_and_input", "officers_and_orders", "target_selection", "unit_actions_and_density",
                   "projectiles", "siege", "objectives"}
    totals = row.get("step_phase_totals_ms", {})
    phases = longest.get("step_phases_ms", {})
    phase_match = (set(totals) == phase_names and set(phases) == phase_names
                   and all(value >= 0 for value in [*totals.values(), *phases.values()])
                   and sum(totals.values()) <= row.get("sim_cpu_total_ms", 0) + .2
                   and sum(phases.values()) <= longest.get("sim_cpu_ms", 0) + .1)
    stages = {event["stage"]: event for event in events}
    expected = ["scene_ready", "first_post_draw", "foreground_ready", "deployed", "first_tick",
                "first_hit", "contact_complete"]
    if label in (CONTROL[0],"focus-control-2"):
        expected += ["control_armed", "focus_paused", "still_paused_after_foreground", "resume_pressed"]
    if label == STARTUP_CONTROL[0]:
        expected += ["startup_interruption_armed", "startup_paused_zero", "focus_restored_at_zero", "startup_resume_pressed"]
    valid = (code == 0 and empty_at_launch and matched_peak and phase_match and all(stage in stages for stage in expected)
             and all(Path(event["data_dir"]) == data_dir for event in events)
             and "FIELD_PACKAGE_PASS " in log and row.get("renderer") == method
             and image.is_file() and image.stat().st_size > 4096 and row.get("hits_in_window", 0) > 0
             and bool(png_size) and row.get("render_target_px") == png_size and session_matches_image
             and row.get("preset") == quality and row.get("shadows") == (quality != 2)
             and row.get("requested_msaa_samples") == (4 if quality == 0 else 1)
             and abs(row.get("scale", 0) - [1.0, 0.85, 0.70, 1.0][quality]) < 0.001
             and not any(marker in log for marker in ("SCRIPT ERROR", "SHADER ERROR", "ERROR:")))
    if label == STARTUP_CONTROL[0]:
        sequence = [r["stage"] for r in events]
        required = ["deployed", "startup_interruption_armed", "startup_paused_zero", "focus_restored_at_zero", "startup_resume_pressed", "first_tick", "first_hit", "contact_complete"]
        valid = valid and all(stage in sequence for stage in required) and [sequence.index(s) for s in required] == sorted(sequence.index(s) for s in required) and sum(stage == "startup_resume_pressed" for stage in sequence) == 1
        valid = valid and stages["startup_paused_zero"]["paused"] and stages["startup_paused_zero"]["tick"] == 0 and not stages["startup_resume_pressed"]["paused"]
    requested = [1280, 800] if default_size else [1000, 600]
    if default_size:
        valid = valid and png_size[0] >= 1000 and png_size[1] >= 600
    row.update(label=label, session_matches_image=session_matches_image, returncode=code, requested_method=method, validated=valid,
               requested_window_px=requested, png_ihdr_px=png_size, uses_default_window=default_size,
               max_rss_bytes=int(rss.group(1)) if rss else None, app_data_absent_at_spawn=empty_at_launch,
               pre_scene_sample=(output/(label+"-before-scene.sample.txt")).is_file(),
               pre_frame_sample=(output/(label+"-before-frame.sample.txt")).is_file(),
               startup_resume_count=sum(e["stage"] == "startup_resume_pressed" for e in events),
               activation_requested=promoted, last_boot_stage=events[-1]["stage"] if events else None,
               launch_milestones_ms={key: stages[key]["launch_wall_ms"] for key in expected if key in stages})
    if not valid:
        print("DIAGNOSTIC", label, json.dumps(events[-2:]), log[-1200:], flush=True)
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("archive", "unpacked", "evidence"):
        parser.add_argument(name, type=Path)
    parser.add_argument("--startup-regression", action="store_true",
                        help="Only the two natural default Metal launches plus one deliberate pre-tick focus interruption")
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
        plans = (CONTROL, ("focus-control-2","gl_compatibility",0), STARTUP_CONTROL)
        for plan in plans:
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
    observed = [report["focus_control"],*report["samples"]]
    if not all(row["validated"] for row in observed):
        raise SystemExit("Native startup or an exported window trial failed; individual logs retained.")


if __name__ == "__main__":
    main()
