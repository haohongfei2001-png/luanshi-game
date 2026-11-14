from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class CaptureReleaseSafety(unittest.TestCase):
 def test_effects_are_executed_outside_debug_assert(self):
  for name in ['tests/authored_architecture_capture.gd','tests/authored_roof_isolation.gd','scripts/review/traversal_review.gd','scripts/review/freeze_shader_clock.gd','scripts/review/author_unit_oracle.gd']:
   with self.subTest(source=name):
    self.assertNotRegex((ROOT/name).read_text(),r'assert\([^\n]*(?:\.save_png|\.compile|recorder\.start|\.configure_author_oracle|\.apply_author_phase)\(')
if __name__=='__main__':unittest.main()
