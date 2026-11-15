#!/usr/bin/env python3
"""Linux-only resource guard for an explicitly supplied local command."""
import argparse
import json
import math
import os
from pathlib import Path
import signal
import subprocess
import time


def resources(paths):
    values = dict(line.split(":", 1) for line in Path("/proc/meminfo").read_text().splitlines())
    available = int(values["MemAvailable"].split()[0]) * 1024
    try:
        limit = Path("/sys/fs/cgroup/memory.max").read_text().strip()
        current = int(Path("/sys/fs/cgroup/memory.current").read_text())
        if limit != "max":
            available = min(available, max(0, int(limit) - current))
    except (OSError, ValueError):
        pass
    free = []
    for path in paths:
        stat = os.statvfs(path)
        free.append(stat.f_bavail * stat.f_frsize)
    return available, min(free)


def group_has_live_members(pgid):
    """Only inspect this child's group. Zombies cannot execute further work."""
    try:
        os.killpg(pgid, 0)
    except ProcessLookupError:
        return False
    found_member = False
    try:
        entries = list(Path("/proc").iterdir())
    except OSError:
        return True
    for entry in entries:
        if not entry.name.isdecimal():
            continue
        owned = False
        try:
            if os.getpgid(int(entry.name)) != pgid:
                continue
            owned = True
            # Only read task state after its group matches our own child group.
            state = (entry / "stat").read_text().rsplit(")", 1)[1].split()[0]
            found_member = True
            if state not in ("Z", "X"):
                return True
        except (ProcessLookupError, FileNotFoundError):
            continue
        except (OSError, ValueError, IndexError):
            if owned:
                return True
    # An existing but momentarily unobservable group is treated as live, not clean.
    return not found_member


def signal_owned_group(pgid, signum):
    if pgid == os.getpgrp():
        raise RuntimeError("Refusing to signal the guard's own process group.")
    try:
        os.killpg(pgid, signum)
        return True
    except ProcessLookupError:
        return False


def stop_owned_group(child, pgid, graces):
    """Leader exit does not end escalation while same-group descendants live."""
    sent = []
    for signum, grace in zip((signal.SIGINT, signal.SIGTERM, signal.SIGKILL), graces):
        child.poll()  # Reap the direct child when possible, not unrelated processes.
        if not group_has_live_members(pgid):
            return {"signals": sent, "live_group_remaining": False}
        if not signal_owned_group(pgid, signum):
            return {"signals": sent, "live_group_remaining": False}
        sent.append(signal.Signals(signum).name)
        deadline = time.monotonic() + grace
        while time.monotonic() < deadline:
            child.poll()
            if not group_has_live_members(pgid):
                return {"signals": sent, "live_group_remaining": False}
            time.sleep(min(0.05, max(0, deadline - time.monotonic())))
    child.poll()
    return {"signals": sent, "live_group_remaining": group_has_live_members(pgid)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True, help="Fresh directory; never reused.")
    parser.add_argument("--watch-path", type=Path, action="append", required=True)
    parser.add_argument("--cwd", type=Path)
    parser.add_argument("--min-memory-bytes", type=int, default=2 * 1024**3)
    parser.add_argument("--min-free-bytes", type=int, default=700 * 1024**2)
    parser.add_argument("--interval", type=float, default=2.0)
    parser.add_argument("--timeout", type=float, default=0.0)
    parser.add_argument("--interrupt-grace", type=float, default=20.0)
    parser.add_argument("--terminate-grace", type=float, default=5.0)
    parser.add_argument("--kill-grace", type=float, default=2.0)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    graces = (args.interrupt_grace, args.terminate_grace, args.kill_grace)
    if (not command or args.interval <= 0 or min(args.min_memory_bytes, args.min_free_bytes) < 0
            or any(not math.isfinite(value) or value < 0 for value in (args.interval, args.timeout, *graces))):
        parser.error("Supply a command, nonnegative finite limits/graces, and a positive interval.")
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=False)
    stop_requested = False

    def request_stop(_signum, _frame):
        nonlocal stop_requested
        stop_requested = True

    signal.signal(signal.SIGINT, request_stop)
    signal.signal(signal.SIGTERM, request_stop)
    start = time.monotonic()
    child = None
    pgid = None  # Only ever assigned the PID of our start_new_session child.
    minimum_memory = minimum_free = None
    result = {"status": "PRECHECK_BLOCKED", "child_exit_code": None}
    try:
        available, free = resources(args.watch_path)
        minimum_memory, minimum_free = available, free
        if available < args.min_memory_bytes or free < args.min_free_bytes:
            result.update(memory_available_bytes=available, free_bytes=free)
        else:
            with (output / "process.log").open("xb") as log, (output / "resources.jsonl").open("x") as samples:
                child = subprocess.Popen(command, cwd=args.cwd, stdout=log, stderr=subprocess.STDOUT,
                                         stdin=subprocess.DEVNULL, start_new_session=True)
                pgid = child.pid
                result["status"] = "RUNNING"
                while child.poll() is None:
                    available, free = resources(args.watch_path)
                    minimum_memory = min(minimum_memory, available)
                    minimum_free = min(minimum_free, free)
                    elapsed = time.monotonic() - start
                    samples.write(json.dumps({"elapsed_seconds": elapsed, "memory_available_bytes": available,
                                              "free_bytes": free}) + "\n")
                    samples.flush()
                    if available < args.min_memory_bytes or free < args.min_free_bytes:
                        result["status"] = "RESOURCE_STOP"
                    elif stop_requested or (output / "STOP").exists():
                        result["status"] = "REQUESTED_STOP"
                    elif args.timeout > 0 and elapsed > args.timeout:
                        result["status"] = "TIMEOUT"
                    if result["status"] != "RUNNING":
                        break
                    time.sleep(args.interval)
                if result["status"] == "RUNNING":
                    result["status"] = "PASS" if child.returncode == 0 else "CHILD_FAILED"
    except BaseException as error:
        result["status"] = "REQUESTED_STOP" if isinstance(error, KeyboardInterrupt) else "GUARD_ERROR"
        result["error"] = type(error).__name__ + ": " + str(error)
    finally:
        # Every exit path, including normal leader exit and monitoring/log exceptions,
        # checks and cleans only this invocation's session/process group.
        if child is not None:
            try:
                child.poll()
                if group_has_live_members(pgid):
                    if result["status"] in ("PASS", "CHILD_FAILED"):
                        result["status"] = "ORPHAN_CLEANUP"
                    result["cleanup"] = stop_owned_group(child, pgid, graces)
                    if result["cleanup"]["live_group_remaining"]:
                        result["status"] = "CLEANUP_INCOMPLETE"
                else:
                    result["cleanup"] = {"signals": [], "live_group_remaining": False}
                child.poll()
                result["child_exit_code"] = child.returncode
            except BaseException as error:
                result["status"] = "CLEANUP_ERROR"
                result["cleanup_error"] = type(error).__name__ + ": " + str(error)
        result.update(elapsed_seconds=time.monotonic() - start,
                      minimum_memory_available_bytes=minimum_memory, minimum_free_bytes=minimum_free)
    (output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result))
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
