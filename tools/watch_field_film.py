#!/usr/bin/env python3
"""Record one 1,020-frame Godot movie with real progress and bounded runner time."""
import os
import re
import signal
import subprocess
import sys
import threading
import time

FRAME_COUNT = 1020
FIRST_OR_NEXT_PROGRESS_SECONDS = 240
HARD_LIMIT_SECONDS = 3000


def record(command):
    started = time.monotonic()
    last = [0, -1, started]
    timed_out = threading.Event()
    finished = threading.Event()
    lock = threading.Lock()
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, errors="replace", start_new_session=True)

    def watchdog():
        while not finished.wait(1):
            now = time.monotonic()
            with lock:
                frame, tick, latest = last
            if now - latest < FIRST_OR_NEXT_PROGRESS_SECONDS and now - started < HARD_LIMIT_SECONDS:
                continue
            print(f"FIELD_FILM_TIMEOUT last_frame={frame} last_tick={tick} elapsed={now-started:.1f}", flush=True)
            timed_out.set()
            try:
                os.killpg(process.pid, signal.SIGTERM)
                if not finished.wait(4):
                    os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            return

    guard = threading.Thread(target=watchdog, daemon=True)
    guard.start()
    try:
        for line in process.stdout:
            print(line, end="", flush=True)
            match = re.fullmatch(r"FIELD_FILM_ADVANCE (\d+) (\d+)\s*", line)
            if match:
                frame, tick = map(int, match.groups())
                with lock:
                    if last[0] < frame <= FRAME_COUNT and tick > last[1]:
                        last[:] = [frame, tick, time.monotonic()]
        code = process.wait()
    finally:
        finished.set()
        guard.join()
    return 124 if timed_out.is_set() else code


if __name__ == "__main__":
    raise SystemExit(record(sys.argv[1:]))
