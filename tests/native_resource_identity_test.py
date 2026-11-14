from pathlib import Path
import copy, hashlib, sys, tempfile, unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools/native_region'))
from resource_identity import collect, runtime_rows, verify_runtime_observation

class ResourceIdentity(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name)
  (self.root/'assets').mkdir();(self.root/'.godot/imported').mkdir(parents=True)
  (self.root/'assets/gate.glb').write_bytes(b'original GLB');(self.root/'.godot/imported/gate.scn').write_bytes(b'actual packed scene')
  (self.root/'assets/gate.glb.import').write_text('[remap]\npath="res://.godot/imported/gate.scn"\n')
  self.hashes={'assets/gate.glb':hashlib.sha256(b'original GLB').hexdigest()}
 def tearDown(self):self.tmp.cleanup()
 def test_source_distinct_from_imported(self):
  r=collect(self.root,self.hashes);i=r['res://assets/gate.glb']
  self.assertNotEqual(i['original_source_sha256'],i['packed_resource_sha256'])
  self.assertEqual(i['packed_resource_sha256'],hashlib.sha256(b'actual packed scene').hexdigest())
  verify_runtime_observation(runtime_rows(r),r)
 def test_bad_original_rejected(self):
  (self.root/'assets/gate.glb').write_bytes(b'wrong')
  with self.assertRaises(ValueError):collect(self.root,self.hashes)
 def test_missing_import_rejected(self):
  (self.root/'.godot/imported/gate.scn').unlink()
  with self.assertRaises(ValueError):collect(self.root,self.hashes)
 def test_missing_or_corrupt_observation_rejected(self):
  r=collect(self.root,self.hashes);v=runtime_rows(r)
  for wrong in ({},None,{**v,'unexpected':{}}):
   with self.assertRaises(ValueError):verify_runtime_observation(wrong,r)
  v['res://assets/gate.glb']['packed_resource_sha256']='0'*64
  with self.assertRaises(ValueError):verify_runtime_observation(v,r)
 def test_direct_resource(self):
  (self.root/'assets/ground.scn').write_bytes(b'ground');h=hashlib.sha256(b'ground').hexdigest()
  i=collect(self.root,{'assets/ground.scn':h})['res://assets/ground.scn']
  self.assertEqual(i['identity_method'],'direct_resource');self.assertEqual(i['original_source_sha256'],i['packed_resource_sha256'])
 def test_no_import_traversal(self):
  (self.root/'assets/gate.glb.import').write_text('[remap]\npath="res://.godot/imported/../../../other"\n')
  with self.assertRaises(ValueError):collect(self.root,self.hashes)
if __name__=='__main__':unittest.main()
