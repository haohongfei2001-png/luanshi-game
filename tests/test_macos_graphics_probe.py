"""Portable harness tests; these do not execute macOS or render the game."""
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest import mock
import zlib

spec = importlib.util.spec_from_file_location("probe", Path(__file__).resolve().parents[1] / "tools/probe_macos_graphics.py")
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)


def png(width=64, height=64, colored=True, filter_mode=0, channels=3):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    rows, previous = bytearray(), bytes(width * channels)
    for y in range(height):
        row = b"".join(bytes([x * 4, y * 4, 80] if colored else [0, 0, 0]) + (b"\xff" if channels == 4 else b"") for x in range(width))
        filtered = bytearray(row)
        for i in range(len(row)):
            a, b, c = (row[i - channels] if i >= channels else 0), previous[i], (previous[i - channels] if i >= channels else 0)
            p = a + b - c
            distances = (abs(p - a), abs(p - b), abs(p - c))
            predictor = (0, a, b, (a + b) // 2, (a, b, c)[distances.index(min(distances))])[filter_mode]
            filtered[i] = (row[i] - predictor) & 255
        rows.extend(bytes([filter_mode]) + filtered)
        previous = row
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2 if channels == 3 else 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b"")


class ProbeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.result = {"returncode": 0, "timed_out": False,
                       "samples": [{"windows": [{"layer": 0, "width": 1280, "height": 800}]}]}

    def test_png_all_five_filters_rgb_and_rgba(self):
        for mode in range(5):
            for channels in (3, 4):
                with self.subTest(mode=mode, channels=channels):
                    path = self.root / "proof.png"
                    path.write_bytes(png(filter_mode=mode, channels=channels))
                    image = probe.inspect_png(path)
                    self.assertTrue(image["nonblank"])
                    self.assertEqual(image["sampled_colors"], 64)

    def test_blank_image_rejected(self):
        path = self.root / "blank.png"
        path.write_bytes(png(colored=False))
        self.assertFalse(probe.inspect_png(path)["nonblank"])

    def test_bad_crc_rejected(self):
        path = self.root / "broken.png"
        data = bytearray(png())
        data[50] ^= 1
        path.write_bytes(data)
        with self.assertRaises(ValueError):
            probe.inspect_png(path)

    def test_non_png_rejected(self):
        path = self.root / "not.png"
        path.write_text("not an image")
        with self.assertRaises(ValueError):
            probe.inspect_png(path)

    def test_smoke_pass_needs_marker_and_visible_window(self):
        self.assertEqual(probe.classify(self.result, "SCENE_SMOKE_PASS", "SCENE_SMOKE_PASS"), "PASS")
        self.assertEqual(probe.classify(self.result, "", "SCENE_SMOKE_PASS"), "SMOKE_INCOMPLETE")
        self.result["samples"] = []
        self.assertEqual(probe.classify(self.result, "SCENE_SMOKE_PASS", "SCENE_SMOKE_PASS"), "WINDOW_UNOBSERVED")

    def test_blank_capture_cannot_pass(self):
        self.assertEqual(probe.classify(self.result, "", image={"nonblank": False}), "CAPTURE_FAILED")

    def test_script_error_never_becomes_runner_limitation(self):
        self.assertEqual(probe.classify(self.result, "SCRIPT ERROR: bad. Failed to initialize rendering device"), "GAME_FAILED")

    def test_renderer_initialization_error(self):
        self.result["returncode"] = 1
        self.assertEqual(probe.classify(self.result, "Failed to initialize rendering device"), "RUNNER_RENDERER_UNAVAILABLE")

    def test_no_active_display_is_explicit(self):
        self.result["samples"] = [{"display_error": 0, "displays": [], "windows": []}]
        self.assertEqual(probe.classify(self.result, "", image={"nonblank": False}), "RUNNER_DISPLAY_UNAVAILABLE")

    def test_generic_error_is_not_misclassified(self):
        self.assertEqual(probe.classify(self.result, "ERROR: gameplay state invalid"), "GAME_OR_ENGINE_FAILED")

    def test_timeout_not_declared_missing_gpu(self):
        self.result["timed_out"] = True
        self.assertEqual(probe.classify(self.result, ""), "INCONCLUSIVE_TIMEOUT")

    def test_launch_error(self):
        self.result["launch_error"] = "permission denied"
        self.assertEqual(probe.classify(self.result, ""), "LAUNCH_FAILED")

    def test_bounded_command_retains_output_exit_and_json(self):
        result = probe.run_bounded([sys.executable, "-c", "print('evidence'); raise SystemExit(7)"], self.root / "run.log", 3)
        self.assertEqual(result["returncode"], 7)
        self.assertIn("evidence", (self.root / "run.log").read_text())
        self.assertTrue((self.root / "run.json").exists())

    def test_missing_executable_retains_launch_error(self):
        result = probe.run_bounded([str(self.root / "absent")], self.root / "absent.log", 1)
        self.assertIn("launch_error", result)
        self.assertTrue((self.root / "absent.json").exists())
        self.assertTrue((self.root / "absent.log").read_text())

    def test_timeout_terminates_child(self):
        result = probe.run_bounded([sys.executable, "-c", "import time; time.sleep(30)"], self.root / "wait.log", 0.2)
        self.assertTrue(result["timed_out"])
        self.assertIsNotNone(result["returncode"])
        self.assertLess(result["elapsed_seconds"], 5)

    def test_exact_inner_zip_hash_is_required(self):
        archive = self.root / "app.zip"
        archive.write_bytes(b"test inner application ZIP")
        expected = hashlib.sha256(archive.read_bytes()).hexdigest()
        probe.verify_archive(archive, self.root, expected)
        self.assertTrue(json.loads((self.root / "archive.json").read_text())["matches"])
        with self.assertRaisesRegex(RuntimeError, "no extraction or launch"):
            probe.verify_archive(archive, self.root, "0" * 64)
        self.assertFalse(json.loads((self.root / "archive.json").read_text())["matches"])

    def test_hash_mismatch_blocks_all_native_commands(self):
        archive = self.root / "app.zip"
        archive.write_bytes(b"wrong archive")
        with mock.patch.object(probe.platform, "system", return_value="Darwin"), \
                mock.patch.dict(probe.os.environ, {"GITHUB_ACTIONS": "true", "RUNNER_ENVIRONMENT": "github-hosted"}), \
                mock.patch.object(probe, "run_bounded") as native:
            with self.assertRaisesRegex(RuntimeError, "SHA-256 mismatch"):
                probe.probe(archive, self.root, "0" * 64)
            native.assert_not_called()

    def test_malformed_archive_hash_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "64 lowercase"):
            probe.verify_archive(self.root / "absent.zip", self.root, "not a hash")

    def test_refuses_non_macos_before_launch(self):
        if sys.platform == "darwin":
            self.skipTest("Linux-only guard assertion")
        with self.assertRaisesRegex(RuntimeError, "Native launch"):
            probe.probe(self.root / "absent.zip", self.root / "evidence", "0" * 64)


if __name__ == "__main__":
    unittest.main()
