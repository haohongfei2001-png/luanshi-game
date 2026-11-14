"""Bounded real graphical execution on existing ephemeral GitHub macOS runners."""
import argparse, hashlib, json, os, pty, re, select, signal, subprocess, sys, time
from pathlib import Path

def validate_engine(patch):
    receipt = json.loads((patch / "provenance.json").read_text())
    executable = patch / "godot.macos.template_release.arm64"
    if receipt["engine_source"] != "35e80b3a8822a9df9be390814b62f44c0a9c69e8":
        raise ValueError("Unexpected engine source")
    if receipt["angle_archive_sha256"] != "9eadd2055f66507e9d74655e7683e068e7e4a9dade5a84bc03d3f5affdfb7b9d":
        raise ValueError("Unexpected ANGLE source")
    if hashlib.sha256(executable.read_bytes()).hexdigest() != receipt["patched_binary_sha256"]:
        raise ValueError("Native engine checksum mismatch")
    return executable, receipt

def run(project, patch, output, helper):
    if os.environ.get("GITHUB_ACTIONS") != "true" or os.environ.get("RUNNER_OS") != "macOS" or sys.platform != "darwin":
        raise RuntimeError("Only disposable authorized GitHub macOS runner; never the owner's computer")
    executable, engine_receipt = validate_engine(patch)
    output.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(ARCHITECTURE_CAPTURE_OUT=str(output / "pixels"), LUANSHI_AUTHORED_LANDFORM="1",
               RIVER_SOURCE_SHA=env["GITHUB_SHA"])
    master, slave = pty.openpty()
    args = ["/usr/bin/time", "-l", "-o", str(output / "resource-time.log"), str(executable),
            "--path", str(project), "--rendering-method", "mobile", "--rendering-driver", "metal",
            "--audio-driver", "Dummy", "--disable-vsync", "--script", "res://tests/native_region_capture.gd",
            "--", "--wall-clock-action", "--traversal-review", "--shadow-diagnostic"]
    process = subprocess.Popen(args, env=env, cwd=project, stdout=slave, stderr=slave,
                               stdin=subprocess.DEVNULL, start_new_session=True)
    os.close(slave)
    started = time.monotonic(); pending = b""; failure = None; focus = None
    with (output / "actual-game.log").open("w") as log:
        def line(raw):
            nonlocal failure, focus
            value = re.sub(r"\x1b\[[0-9;]*m", "", raw.decode(errors="replace").rstrip("\r"))
            print(value, file=log, flush=True)
            if any(x in value for x in ("SCRIPT ERROR", "SHADER ERROR", "ERROR:")):
                failure = "GODOT_ERROR"
            if value.startswith("NATIVE_REGION_FOCUS ") and focus is None:
                row = json.loads(value.partition(" ")[2])
                # Only this probe's child; no global keyboard or accessibility input.
                child = subprocess.run(["/bin/ps", "-p", str(row["pid"]), "-o", "comm="], capture_output=True, text=True, check=True)
                if os.path.realpath(child.stdout.strip()) != os.path.realpath(executable):
                    failure = "UNVERIFIED_PROCESS_FOR_FOCUS"; return
                result = subprocess.run([str(helper), "foreground", str(row["pid"])], capture_output=True, text=True, timeout=8)
                focus = {"pid":row["pid"],"exit":result.returncode,"stdout":result.stdout,"stderr":result.stderr}
                (output / "focus.json").write_text(json.dumps(focus, indent=2))
                if result.returncode: failure = "NATIVE_WINDOW_FOCUS_FAILED"
            if value.startswith(("NATIVE_REGION_FOCUS", "REGION_SETUP_", "ARCHITECTURE_CAPTURE_")):
                print(value, flush=True)
        try:
            while time.monotonic() - started < 240:
                ready, _, _ = select.select([master], [], [], .5)
                if ready:
                    try: data = os.read(master, 65536)
                    except OSError: data = b""
                    if not data: break
                    chunks = (pending + data).split(b"\n"); pending = chunks.pop()
                    for chunk in chunks: line(chunk)
                    if failure: break
                elif process.poll() is not None: break
            else: failure = "NATIVE_CAPTURE_TIMEOUT"
            if pending: line(pending)
        finally:
            os.close(master)
            if process.poll() is None and failure: os.killpg(process.pid, signal.SIGTERM)
            try: process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL); process.wait(); failure = failure or "EXIT_TIMEOUT"
    receipt = {"source":env["GITHUB_SHA"],"command":args,"exit":process.returncode,"failure":failure,
               "elapsed_seconds":time.monotonic()-started,"focus":focus,"engine":engine_receipt,
               "M5":"DEVICE_NOT_RUN","art_status":"NOT_ACCEPTED",
               "scope":"Real native Metal execution, readback-instrumented, not performance acceptance"}
    (output / "process.json").write_text(json.dumps(receipt, indent=2))
    if failure or process.returncode: raise RuntimeError(json.dumps(receipt))
    if focus is None: raise RuntimeError("No verified actual native window")
    return receipt

if __name__ == "__main__":
    p=argparse.ArgumentParser()
    for name in ("project", "patch", "output", "helper"): p.add_argument(name, type=Path)
    a=p.parse_args();print(json.dumps(run(*(getattr(a,n).resolve() for n in ("project","patch","output","helper")))))
