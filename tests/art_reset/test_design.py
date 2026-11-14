import copy, importlib.util, json, pathlib, unittest
P=pathlib.Path(__file__).resolve().parents[2]/'tools/art/authored_reset'
spec=importlib.util.spec_from_file_location('design_check',P/'design_check.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Contract(unittest.TestCase):
 def setUp(self): self.p=json.loads((P/'layout.json').read_text())
 def test_design(self): self.assertEqual(m.check(self.p)['assemblies'],13)
 def test_tree_blocking_lane_is_rejected(self):
  a=next(a for a in self.p['assemblies'] if a['kind']=='canopy_mass');a['bounds_xz']=[32,-2,38,2]
  with self.assertRaises(AssertionError):m.check(self.p)
 def test_no_claim_of_art_acceptance(self):
  self.p['status']='PASS'
  with self.assertRaises(AssertionError):m.check(self.p)
 def test_camera_cannot_hide_design(self):
  self.p['camera']['orthographic_vertical']=45
  with self.assertRaises(AssertionError):m.check(self.p)
if __name__=='__main__':unittest.main()
