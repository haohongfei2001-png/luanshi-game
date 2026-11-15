#!/usr/bin/env python3
"""Small local tooling tests. No engine build, rendering, network or game assets."""
import argparse
import json
import os
from pathlib import Path, PurePosixPath
import re
import signal
import subprocess
import sys
import tarfile
import tempfile
import time
import unittest
from prepare_source import ROOT, SOURCE_ROOT, verified_archive, validate_member, patch_command


class ToolTests(unittest.TestCase):
    def test_archive_path_rejection(self):
        for name in ["/escape", "../escape", SOURCE_ROOT + "/../escape", "other/file"]:
            member = tarfile.TarInfo(name)
            with self.assertRaises(ValueError):
                validate_member(member)
        member = tarfile.TarInfo(SOURCE_ROOT + "/file")
        validate_member(member)
        member.type = tarfile.SYMTYPE
        with self.assertRaises(ValueError):
            validate_member(member)

    def test_guard_success_and_precheck(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            command = [sys.executable, str(ROOT / "resource_guard.py"), "--watch-path", temporary,
                       "--interval", "0.02"]
            success = subprocess.run([*command, "--output-dir", str(base / "success"), "--",
                                      sys.executable, "-c", "print('fixture child')"], check=False)
            self.assertEqual(success.returncode, 0)
            self.assertEqual(json.loads((base / "success/result.json").read_text())["status"], "PASS")
            marker = base / "must-not-exist"
            blocked = subprocess.run([*command, "--output-dir", str(base / "blocked"),
                                      "--min-free-bytes", str(2**63), "--", sys.executable, "-c",
                                      "from pathlib import Path; Path(%r).touch()" % str(marker)], check=False)
            self.assertNotEqual(blocked.returncode, 0)
            self.assertFalse(marker.exists())
            self.assertEqual(json.loads((base / "blocked/result.json").read_text())["status"], "PRECHECK_BLOCKED")

    def test_capture_paths(self):
        from pixel_qa import image_path
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            self.assertEqual(image_path(base, "scenetree_frame_08.png"), base / "scenetree_frame_08.png")
            for name in ["../other.png", "/other.png", "folder/scenetree_frame_08.png"]:
                with self.assertRaises(ValueError):
                    image_path(base, name)

    def test_guard_requested_stop(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            output = base / "stopped"
            command = [sys.executable, str(ROOT / "resource_guard.py"), "--watch-path", temporary,
                       "--interval", "0.02", "--output-dir", str(output), "--",
                       sys.executable, "-c", "import time; time.sleep(10)"]
            guard = subprocess.Popen(command)
            deadline = time.monotonic() + 3
            while not (output / "process.log").exists() and guard.poll() is None and time.monotonic() < deadline:
                time.sleep(0.02)
            self.assertTrue((output / "process.log").exists())
            (output / "STOP").touch()
            self.assertNotEqual(guard.wait(timeout=5), 0)
            self.assertEqual(json.loads((output / "result.json").read_text())["status"], "REQUESTED_STOP")

    def test_isolated_home_and_xdg(self):
        from run_proof import isolated_environment
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            env = isolated_environment(output)
            for key, directory in [("HOME", "home"), ("XDG_DATA_HOME", "data"),
                                   ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")]:
                self.assertEqual(env[key], str(output / "xdg" / directory))
                self.assertTrue(Path(env[key]).is_dir())
            self.assertNotIn("DISPLAY", env)
            self.assertNotIn("WAYLAND_DISPLAY", env)
            self.assertNotIn("XAUTHORITY", env)

    def test_live_descendants_are_cleaned_on_every_exit(self):
        for mode, expected in [("timeout", "TIMEOUT"), ("stop", "REQUESTED_STOP"),
                               ("normal", "ORPHAN_CLEANUP"), ("exception", "GUARD_ERROR")]:
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as temporary:
                base = Path(temporary)
                watch = base / "watch"
                watch.mkdir()
                output = base / "guard"
                leader_pid = base / "leader.pid"
                descendant_pid = base / "descendant.pid"
                heartbeat = base / "heartbeat"
                descendant = (
                    "import os,signal,time; from pathlib import Path; "
                    "signal.signal(signal.SIGINT,signal.SIG_IGN); "
                    "signal.signal(signal.SIGTERM,signal.SIG_IGN); "
                    f"Path({str(descendant_pid)!r}).write_text(str(os.getpid()))\n"
                    "while True:\n"
                    f" with Path({str(heartbeat)!r}).open('a') as stream: stream.write('x')\n"
                    " time.sleep(0.01)\n"
                )
                leader = (
                    "import os,signal,subprocess,sys,time; from pathlib import Path\n"
                    "signal.signal(signal.SIGINT,lambda *_: sys.exit(0))\n"
                    f"Path({str(leader_pid)!r}).write_text(str(os.getpid()))\n"
                    f"subprocess.Popen([sys.executable,'-c',{descendant!r}])\n"
                    f"while not Path({str(descendant_pid)!r}).exists(): time.sleep(0.01)\n"
                    + ("sys.exit(0)\n" if mode == "normal" else "time.sleep(10)\n")
                )
                command = [sys.executable, str(ROOT / "resource_guard.py"), "--watch-path", str(watch),
                           "--output-dir", str(output), "--interval", "0.02", "--timeout", "1",
                           "--interrupt-grace", "0.05", "--terminate-grace", "0.05", "--kill-grace", "0.5",
                           "--", sys.executable, "-c", leader]
                unrelated = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(10)"],
                                             start_new_session=True)
                guard = subprocess.Popen(command, start_new_session=True)
                try:
                    deadline = time.monotonic() + 3
                    while not descendant_pid.exists() and guard.poll() is None and time.monotonic() < deadline:
                        time.sleep(0.01)
                    self.assertTrue(descendant_pid.exists(), "Descendant fixture did not start")
                    if mode == "stop":
                        (output / "STOP").touch()
                    elif mode == "exception":
                        watch.rmdir()  # Force a monitoring exception after the child group exists.
                    self.assertNotEqual(guard.wait(timeout=5), 0)
                    result = json.loads((output / "result.json").read_text())
                    self.assertEqual(result["status"], expected)
                    self.assertEqual(result["child_exit_code"], 0)
                    self.assertEqual(result["cleanup"]["signals"], ["SIGINT", "SIGTERM", "SIGKILL"])
                    self.assertFalse(result["cleanup"]["live_group_remaining"])
                    pid = int(descendant_pid.read_text())
                    stat = Path("/proc") / str(pid) / "stat"
                    if stat.exists():
                        # An orphan zombie may await PID 1's reap; it cannot perform work.
                        self.assertIn(stat.read_text().rsplit(")", 1)[1].split()[0], ["Z", "X"])
                    size = heartbeat.stat().st_size if heartbeat.exists() else 0
                    time.sleep(0.04)
                    self.assertEqual(heartbeat.stat().st_size if heartbeat.exists() else 0, size)
                    self.assertIsNone(unrelated.poll(), "Guard signaled unrelated work")
                finally:
                    if leader_pid.exists():
                        try:
                            os.killpg(int(leader_pid.read_text()), signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                    if guard.poll() is None:
                        guard.kill()
                    guard.wait()
                    unrelated.terminate()
                    unrelated.wait()


def check_patches(archive):
    archive = verified_archive(archive)
    # Extract only the handful of text files touched by the two patches, not full source.
    names = set()
    for patch in [ROOT / "surfaceless.patch", ROOT / "gles3-tangent.patch"]:
        for name in re.findall(r"(?m)^--- a/(.+)$", patch.read_text()):
            path = PurePosixPath(name)
            if path.is_absolute() or ".." in path.parts:
                raise ValueError("Unsafe patch path")
            names.add(name)
    with tempfile.TemporaryDirectory() as temporary:
        destination = Path(temporary)
        with tarfile.open(archive, "r:gz") as package:
            for name in names:
                member = package.getmember(SOURCE_ROOT + "/" + name)
                validate_member(member)
                output = destination / name
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_bytes(package.extractfile(member).read())
        for name in ["surfaceless.patch", "gles3-tangent.patch"]:
            patch = ROOT / name
            if patch_command(destination, patch, dry_run=True) or patch_command(destination, patch):
                raise ValueError("Exact upstream patch fixture failed: " + name)
            if patch_command(destination, patch, dry_run=True, reverse=True):
                raise ValueError("Applied patch could not be cleanly reversed: " + name)
    print("PASS both patches apply to exact upstream text with zero fuzz; no compilation performed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, help="Also verify exact upstream patch application.")
    args = parser.parse_args()
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ToolTests)
    if not unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful():
        raise SystemExit(1)
    if args.archive:
        check_patches(args.archive)
