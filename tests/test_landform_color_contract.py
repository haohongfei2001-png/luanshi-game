"""Static interface audit only, not a GPU colour calibration result."""
from pathlib import Path
import re
import unittest
ROOT = Path(__file__).resolve().parents[1]
class LandformColourBoundary(unittest.TestCase):
    def test_encoded_albedo_and_data_channels_are_distinct(self):
        text = (ROOT/'shaders/experimental/surveyed_landform.gdshader').read_text()
        for name in ('earth_albedo','shoulder_albedo','sediment_albedo'):
            hint = re.search(r'uniform sampler2D '+name+r'\s*:\s*([^;]+);',text).group(1)
            self.assertIn('source_color',hint)
        for name in ('earth_normal','shoulder_normal','sediment_normal','earth_roughness'):
            hint = re.search(r'uniform sampler2D '+name+r'\s*:\s*([^;]+);',text).group(1)
            self.assertNotIn('source_color',hint)
        self.assertNotIn('srgb_to_linear',text)
        self.assertNotIn('linear_to_srgb',text)
    def test_authored_water_colour_not_blender_linear_export(self):
        text = (ROOT/'shaders/experimental/surveyed_water.gdshader').read_text()
        for name in ('shallow_water','deep_water'):
            self.assertRegex(text,r'uniform vec4 '+name+r'\s*:\s*source_color\s*=')
        loader = (ROOT/'tools/art/continuous_landform/earth_material.gd').read_text()
        self.assertNotIn('srgb_to_linear',loader)
        self.assertNotIn('linear_to_srgb',loader)
if __name__ == '__main__': unittest.main()
