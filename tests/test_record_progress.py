"""Real subprocess checks for bounded progress, including closed-output children."""
from pathlib import Path
import subprocess
import sys
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ProgressWatchdogTests(unittest.TestCase):
    def run_child(self, source, idle=.5, limit=3):
        began = time.monotonic()
        result = subprocess.run(
            [sys.executable, str(ROOT / "tools/record-progress.py"),
             "--idle", str(idle), "--limit", str(limit),
             "--progress-marker", "FIELD_ENDING_PROGRESS tick=", "--",
             sys.executable, "-u", "-c", source],
            capture_output=True, text=True, timeout=limit + 6,
        )
        self.assertLess(time.monotonic() - began, limit + 5)
        return result

    def test_actual_progress_extends_idle_but_not_total(self):
        result = self.run_child("import time\nfor i in range(6):\n print('FIELD_ENDING_PROGRESS tick='+str(i));time.sleep(.15)")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("tick=5", result.stdout)

    def test_repeated_ticks_do_not_keep_a_stall_alive(self):
        result = self.run_child("import time\nfor i in range(20):\n print('FIELD_ENDING_PROGRESS tick=4');time.sleep(.15)")
        self.assertEqual(result.returncode, 124)
        self.assertIn("progress=4", result.stderr)

    def test_regressing_ticks_do_not_keep_a_stall_alive(self):
        result = self.run_child("import time\nfor i in range(20):\n print('FIELD_ENDING_PROGRESS tick='+str(100-i));time.sleep(.15)")
        self.assertEqual(result.returncode, 124)
        self.assertIn("progress=100", result.stderr)

    def test_increasing_ticks_cannot_bypass_total_cap(self):
        result = self.run_child("import time\nfor i in range(40):\n print('FIELD_ENDING_PROGRESS tick='+str(i));time.sleep(.1)", limit=.8)
        self.assertEqual(result.returncode, 124)

    def test_silence_is_stopped(self):
        self.assertEqual(self.run_child("import time;time.sleep(10)").returncode, 124)

    def test_closing_output_does_not_bypass_deadline(self):
        result = self.run_child("import os,time;os.close(1);os.close(2);time.sleep(10)")
        self.assertEqual(result.returncode, 124)
        self.assertIn("Gameplay recorder expired", result.stderr)

    def test_exit_code_is_preserved(self):
        result = self.run_child("print('diagnostic');raise SystemExit(7)")
        self.assertEqual(result.returncode, 7)
        self.assertIn("diagnostic", result.stdout)

    def test_split_output_reassembles_progress(self):
        result = self.run_child("import sys,time\nfor i in range(5):\n sys.stdout.write('FIELD_ENDING_PROGRESS ');sys.stdout.flush();time.sleep(.1);print('tick='+str(i));time.sleep(.1)")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_unrelated_logs_do_not_keep_a_stall_alive(self):
        result = self.run_child("import time\nfor i in range(20):\n print('renderer heartbeat '+str(i));time.sleep(.15)")
        self.assertEqual(result.returncode, 124)


if __name__ == "__main__":
    unittest.main()
