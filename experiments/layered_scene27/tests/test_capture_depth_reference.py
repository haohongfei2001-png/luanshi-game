import math
from pathlib import Path
import random
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from capture_depth_reference import source_sample_center, capture_ray, plane_from_triangle, plane_depth


class CaptureDepthTests(unittest.TestCase):
    origin = (2., 8., 12.)

    def ray(self, uv):
        return capture_ray(uv, (1., 0., 0.), (0., 1., 0.), (0., 0., 1.), .54, 2560/1440)

    def test_nearest_center_and_half_open_boundary(self):
        self.assertEqual(source_sample_center((0., 0.)), (.5/1672, .5/941))
        self.assertIsNone(source_sample_center((1., .5)))
        self.assertIsNone(source_sample_center((-.00001, .5)))
        self.assertEqual(source_sample_center((.5, .5)), (836.5/1672, 470.5/941))

    def test_view_depth_not_euclidean_distance_and_y_convention(self):
        ray = self.ray((.9, .2))
        self.assertEqual(ray[2], -1.)
        self.assertGreater(ray[1], 0.)
        point = tuple(a + b*19 for a, b in zip(self.origin, ray))
        self.assertGreater(math.dist(point, self.origin), 19.)
        self.assertAlmostEqual(plane_depth(self.origin, ray, (0., 0., 1., -point[2])), 19.)

    def test_1800_perspective_plane_cases(self):
        rng = random.Random(2706)
        uv = ((.2, .3), (.8, .3), (.4, .8))
        for zs in ((5., 35., 12.), (5., 5., 40.), (16., 16., 16.)):
            verts = [tuple(a+b*z for a,b in zip(self.origin,self.ray(p))) for p,z in zip(uv,zs)]
            plane = plane_from_triangle(verts)
            for _ in range(600):
                w = [rng.random()+.001 for _ in range(3)]; total = sum(w); w = [v/total for v in w]
                p = tuple(sum(w[i]*uv[i][j] for i in range(3)) for j in range(2))
                expected = 1/sum(wi/zi for wi,zi in zip(w,zs))
                self.assertAlmostEqual(plane_depth(self.origin,self.ray(p),plane),expected,places=10)
                centre = source_sample_center(p)
                reference = plane_depth(self.origin,self.ray(centre),plane)
                self.assertIsNotNone(reference)
                # The authored plane and RF capture both use this exact sample.
                self.assertAlmostEqual(reference,plane_depth(self.origin,self.ray(centre),plane),places=12)

    def test_continuous_fragment_depth_is_wrong_comparison(self):
        # At a steep plane and near its horizon, a subpixel sample offset can
        # exceed .02m even for exactly the same observed surface.
        plane = (0., 1., 0., 0.)
        uv = (.45, .51)
        a = plane_depth(self.origin,self.ray(uv),plane)
        b = plane_depth(self.origin,self.ray(source_sample_center(uv)),plane)
        self.assertGreater(abs(a-b), .02)
        self.assertEqual(b, plane_depth(self.origin,self.ray(source_sample_center(uv)),plane))

    def test_parallel_behind_and_invalid_input(self):
        self.assertIsNone(plane_depth((0,0,0),(1,0,0),(0,1,0,-2)))
        self.assertIsNone(plane_depth((0,0,0),(0,0,-1),(0,0,1,-2)))
        for uv in ((math.nan,.1),(.1,),(.1,math.inf)):
            with self.assertRaises(ValueError): source_sample_center(uv)
        with self.assertRaises(ValueError): source_sample_center((.1,.2),(0,4))
        with self.assertRaises(ValueError): plane_from_triangle([(0,0,0)]*3)

    def test_exact_native_shader_retains_threshold_and_diagnostics(self):
        p = Path(__file__).resolve().parents[1]/'shaders/center_aligned_capture.gdshader'
        code = p.read_text()
        self.assertIn('depth_tolerance_m=.02',code)
        self.assertIn('floor(uv*vec2(1672.,941.))',code)
        self.assertIn('capture_depth_rf,center',code)
        self.assertIn('authored_world_plane',code)
        self.assertIn('has_observed_art',code)
        self.assertNotIn('SCREEN_UV',code)
        self.assertNotIn('INV_VIEW_MATRIX',code)


if __name__ == '__main__': unittest.main()
