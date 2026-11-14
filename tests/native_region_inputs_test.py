from pathlib import Path
import hashlib, importlib.util, json, sys, tempfile, unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools/native_region'))
from restore_inputs import verified_copy, FILES
from run_native import validate_engine
from validate_route import validate

class NativeRegionInputs(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory();self.path = Path(self.temp.name)
    def tearDown(self):self.temp.cleanup()
    def test_copy_and_idempotent(self):
        s=self.path/'source';t=self.path/'dest';s.write_bytes(b'original');h=hashlib.sha256(s.read_bytes()).hexdigest()
        verified_copy(s,t,h);verified_copy(s,t,h);self.assertEqual(t.read_bytes(),b'original')
    def test_input_corruption_rejected(self):
        s=self.path/'source';s.write_bytes(b'wrong')
        with self.assertRaises(ValueError):verified_copy(s,self.path/'dest','0'*64)
        self.assertFalse((self.path/'dest').exists())
    def test_existing_wrong_target_preserved(self):
        s=self.path/'source';t=self.path/'dest';s.write_bytes(b'original');t.write_bytes(b'existing')
        with self.assertRaises(ValueError):verified_copy(s,t,hashlib.sha256(s.read_bytes()).hexdigest())
        self.assertEqual(t.read_bytes(),b'existing')
    def test_symlink_source_rejected(self):
        s=self.path/'source';link=self.path/'link';s.write_bytes(b'original');link.symlink_to(s)
        with self.assertRaises(ValueError):verified_copy(link,self.path/'dest',hashlib.sha256(s.read_bytes()).hexdigest())
    def test_pinned_lengths(self):
        self.assertEqual(len(FILES),3)
        for v in FILES.values():self.assertRegex(v,r'^[0-9a-f]{64}$')
    def test_engine_hash_rejected(self):
        (self.path/'provenance.json').write_text(json.dumps({'engine_source':'35e80b3a8822a9df9be390814b62f44c0a9c69e8','angle_archive_sha256':'9eadd2055f66507e9d74655e7683e068e7e4a9dade5a84bc03d3f5affdfb7b9d','patched_binary_sha256':'0'*64}))
        (self.path/'godot.macos.template_release.arm64').write_bytes(b'incorrect')
        with self.assertRaises(ValueError):validate_engine(self.path)
    def test_incomplete_route_not_capture_success(self):
        p=self.path/'frames';p.write_text(json.dumps({'kind':'end','reason':'review_complete'})+'\n'+json.dumps({'kind':'traversal_result','status':'NOT_COMPLETED','reached':1,'required':2}))
        with self.assertRaises(ValueError):validate(p)
    def test_route_only_not_art_acceptance(self):
        p=self.path/'frames';p.write_text(json.dumps({'kind':'traversal_result','status':'ROUTE_COMPLETED_REQUIRES_VISUAL_REVIEW','reached':2,'required':2}))
        self.assertEqual(validate(p)['art_status'],'NOT_ACCEPTED')
    def test_duplicate_result_rejected(self):
        p=self.path/'frames';row=json.dumps({'kind':'traversal_result','status':'ROUTE_COMPLETED_REQUIRES_VISUAL_REVIEW','reached':2,'required':2});p.write_text(row+'\n'+row)
        with self.assertRaises(ValueError):validate(p)

if __name__=='__main__':unittest.main()
