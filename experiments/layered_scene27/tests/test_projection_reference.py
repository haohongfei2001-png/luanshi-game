import math
from pathlib import Path
import random
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from projection_reference import capture_uv, perspective_interpolate, transform


class FrozenProjectionTests(unittest.TestCase):
    def assertVectorAlmostEqual(self, a, b):
        for x, y in zip(a, b):
            self.assertAlmostEqual(x, y, places=11)

    def test_top_left_source_convention(self):
        self.assertEqual(capture_uv((-2, 2, 0, 2)), (0, 0))
        self.assertEqual(capture_uv((2, -2, 0, 2)), (1, 1))

    def test_projective_triangle_matches_geometric_reconstruction(self):
        rng = random.Random(27)
        source = ((1.2, 0, .1, 0), (0, 1.5, 0, .1),
                  (0, 0, 1, 0), (0, 0, 1, 0))
        for _ in range(200):
            world = [(rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(2, 12), 1)
                     for _ in range(3)]
            bary = [rng.random() for _ in range(3)]
            bary = [b / sum(bary) for b in bary]
            # The raster/current camera need not equal the frozen source camera.
            current_w = [v[2] + .3 * v[0] + .7 for v in world]
            captured = [transform(source, v) for v in world]
            interpolated_clip = perspective_interpolate(captured, bary, current_w)
            reconstructed_world = perspective_interpolate(world, bary, current_w)
            expected = capture_uv(transform(source, reconstructed_world))
            self.assertVectorAlmostEqual(capture_uv(interpolated_clip), expected)

    def test_naive_uv_is_not_homogeneous_projection(self):
        clip = [(-1, -.5, 0, 2), (5, -.5, 0, 10), (0, 3, 0, 6)]
        bary = (.2, .4, .4)
        w = (2, 10, 6)
        correct = capture_uv(perspective_interpolate(clip, bary, w))
        wrong = perspective_interpolate([capture_uv(v) for v in clip], bary, w)
        self.assertGreater(math.dist(correct, wrong) * 2560, 100)

    def test_frozen_camera_does_not_track_current_view(self):
        point = (1, 2, 8, 1)
        fixed = ((1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0), (0, 0, 1, 0))
        moved = ((1, 0, 0, -.5), (0, 1, 0, 0), (0, 0, 1, 0), (0, 0, 1, 0))
        fixed_uv = capture_uv(transform(fixed, point))
        self.assertNotEqual(fixed_uv, capture_uv(transform(moved, point)))
        self.assertEqual(fixed_uv, capture_uv(transform(fixed, point)))

    def test_reject_invalid_clip(self):
        for value in [(0, 0, 0, 0), (0, 0, 0, -1), (math.nan, 0, 0, 1)]:
            with self.assertRaises(ValueError):
                capture_uv(value)

    def test_reject_invalid_triangle(self):
        with self.assertRaises(ValueError):
            perspective_interpolate([(0, 0)] * 3, (.2, .3, .4), (1, 2, 3))
        with self.assertRaises(ValueError):
            perspective_interpolate([(0, 0)] * 3, (.2, .3, .5), (1, 0, 3))

    def test_published_shaders_keep_frozen_projection_and_single_albedo(self):
        root = Path(__file__).resolve().parents[1] / 'shaders'
        for shader in root.glob('*.gdshader'):
            source = shader.read_text()
            self.assertIn('capture_world_to_clip*MODEL_MATRIX', source)
            self.assertIn('source_projected.xy/source_projected.w', source)
            self.assertNotIn('SCREEN_UV', source)
        shadow = (root / 'source_ground_shadow.gdshader').read_text()
        self.assertNotIn('ALBEDO', shadow.split('void light()')[1])


if __name__ == '__main__':
    unittest.main()
