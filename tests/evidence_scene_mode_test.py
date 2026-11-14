from pathlib import Path
import sys,tempfile,unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools/art/gate_structure'))
from check_evidence_dependencies import scan,GENERATED
class SceneDependencies(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name)
  for name in ['tools/evidence_steps.py','scenes/game.tscn','tests/authored_architecture_capture.gd','tools/native_evidence_bundle.py','tools/bounded_artifact_groups.py','tools/encode_wall_clock_capture.py','tools/prepare-font.sh','.github/workflows/dot-architecture-review.yml',*GENERATED]:
   p=self.root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text('')
  (self.root/'tests/authored_architecture_capture.gd').write_text('\n'.join('"res://'+p+'"' for p in GENERATED))
  (self.root/'assets/river_authored/shore/region.scn').unlink()
 def tearDown(self):self.tmp.cleanup()
 def test_historical_basin_still_requires_shore(self):self.assertEqual(scan(self.root,True)['missing'],['assets/river_authored/shore/region.scn'])
 def test_road03_only_retires_shore(self):
  r=scan(self.root,True,scene_mode='road-section');self.assertEqual(r['missing'],[])
  optional=[v['path'] for v in r['generated_resources'] if not v['required_in_selected_scene']]
  self.assertEqual(optional,['assets/river_authored/shore/region.scn'])
 def test_missing_active_grass_fails(self):
  (self.root/'assets/river_authored/grass/region.scn').unlink()
  self.assertEqual(scan(self.root,True,scene_mode='road-section')['missing'],['assets/river_authored/grass/region.scn'])
 def test_python3_entry_is_checked(self):
  (self.root/'.github/workflows/dot-architecture-review.yml').write_text('run: python3 tools/missing.py')
  self.assertIn('tools/missing.py',scan(self.root,True,scene_mode='road-section')['missing'])
 def test_unknown_mode_fails(self):
  with self.assertRaises(ValueError):scan(self.root,scene_mode='ignore-everything')
if __name__=='__main__':unittest.main()
