"""Regression tests for audit blind spots; rejected artwork must stay rejected."""
import json
from pathlib import Path
import sys
import subprocess
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools' / 'art'))
from check_spear_transitions import address, regressions, world

FIXTURE = Path(__file__).parent / 'fixtures' / 'native-spear-rejected'

class SpearTransitionTests(unittest.TestCase):
    def setUp(self):
        self.sequence = json.loads((FIXTURE / 'after.json').read_text())
        self.old = json.loads((FIXTURE / 'actual-ankles.json').read_text())
        for label in ('before', 'after'):
            for step, previous, current in zip(self.old[label]['steps'], self.sequence['index'], self.sequence['index'][1:]):
                a, b = address(previous, 'rc25'), address(current, 'rc25')
                step['clip_changed'] = a['clip'] != b['clip']

    def test_same_state_reentry_is_rejected(self):
        failures = regressions(self.old['before'], self.old['after'])
        reentry = [r for r in failures if r['tick'] == 32]
        self.assertEqual(len(reentry), 2)
        self.assertTrue(all(r['same_state'] for r in reentry))
        self.assertAlmostEqual(reentry[0]['after_m'], .4397152408503887)
        self.assertAlmostEqual(reentry[1]['after_m'], .7290244332840297)

    def test_authored_swing_is_not_mislabeled_slip(self):
        failures = regressions(self.old['before'], self.old['after'])
        self.assertEqual({r['tick'] for r in failures}, {16, 32})

    def test_self_comparison_does_not_imply_art_acceptance(self):
        self.assertEqual(regressions(self.old['before'], self.old['before']), [])

    def test_idle_to_directional_walk_with_same_state(self):
        a, b = self.sequence['index'][-2:]
        self.assertEqual(a['state'], b['state'])
        self.assertEqual(address(a, 'rc25')['clip'], 1)
        self.assertEqual(address(b, 'rc25')['clip'], 22)

    def test_dense_only_for_grounded_regular_spear(self):
        row = self.sequence['index'][8] # real windup
        self.assertGreaterEqual(address(row, 'rejected-native-pike')['strip'], 423)
        self.assertLess(address(row, 'rc25')['strip'], 421)
        row['instance']['custom'][0] += 32 / 128 # stock strike selects kit 2
        self.assertLess(address(row, 'rejected-native-pike')['strip'], 279)

    def test_mounted_requires_different_sampler(self):
        row = self.sequence['index'][0]
        row['instance']['custom'][0] += 64 / 128
        with self.assertRaises(ValueError):
            address(row, 'rc25')

    def test_packed_approach_zero_clip_not_idle(self):
        row = self.sequence['index'][0]
        row['instance']['custom'][1] = .5 / 1024
        self.assertEqual(address(row, 'rc25')['clip'], 0)

    def test_world_uses_basis_and_translation(self):
        self.assertEqual(world([[0,0,2],[0,3,0],[-4,0,0],[10,20,30]], [1,2,3]), [-2,26,32])

    def test_fixture_audit_has_no_image_authoring_dependency(self):
        art = str(Path(__file__).resolve().parents[1] / "tools" / "art")
        code = "import sys; sys.path.insert(0, " + repr(art) + "); import check_spear_transitions; assert 'PIL' not in sys.modules"
        result = subprocess.run([sys.executable, "-S", "-c", code], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_input_identity_preserved(self):
        self.assertEqual(json.loads((FIXTURE/'before.json').read_text()), self.sequence)

if __name__ == '__main__': unittest.main()
