from pathlib import Path
import copy,hashlib,io,json,sys,tarfile,tempfile,unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools/native_region'))
from restore_complete import ACTOR_SOURCE,restore_actor,safe_relative

def fixture(root,unsafe=False):
    data={'character.json':b'{"art_pass":false}', 'mesh.bin':b'real-pose-fixture'}
    arc=io.BytesIO()
    with tarfile.open(fileobj=arc,mode='w:gz') as t:
        for n,v in data.items():
            i=tarfile.TarInfo(('cache/../' if unsafe else 'cache/')+n);i.size=len(v);t.addfile(i,io.BytesIO(v))
    raw=arc.getvalue();h=lambda b:hashlib.sha256(b).hexdigest()
    (root/'cache.part00').write_bytes(raw)
    m={'source_commit':ACTOR_SOURCE,'art_pass':False,'archive_sha256':h(raw),'archive_bytes':len(raw),
       'parts':[{'file':'cache.part00','bytes':len(raw),'sha256':h(raw)}],
       'files':[{'path':n,'bytes':len(v),'sha256':h(v)} for n,v in data.items()],
       'character_json_sha256':h(data['character.json']),'source_files':{'walk':{'sha256':'a'*64}}}
    (root/'manifest.json').write_text(json.dumps(m));return m

class CompleteRestore(unittest.TestCase):
    def setUp(self):self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name);self.groups=self.root/'groups';self.groups.mkdir();self.dest=self.root/'cache'
    def tearDown(self):self.tmp.cleanup()
    def test_valid_idempotent(self):
        m=fixture(self.groups)
        for _ in range(2):self.assertEqual(restore_actor(self.groups,self.dest,m['archive_sha256'])['members_verified'],2)
        self.assertEqual((self.dest/'mesh.bin').read_bytes(),b'real-pose-fixture')
    def test_corrupt_part(self):
        m=fixture(self.groups);(self.groups/'cache.part00').write_bytes(b'corrupt')
        with self.assertRaises(ValueError):restore_actor(self.groups,self.dest,m['archive_sha256'])
        self.assertFalse(self.dest.exists())
    def test_traversal(self):
        m=fixture(self.groups,unsafe=True)
        with self.assertRaises(ValueError):restore_actor(self.groups,self.dest,m['archive_sha256'])
        self.assertFalse(self.dest.exists())
    def test_wrong_existing_preserved(self):
        m=fixture(self.groups);self.dest.mkdir();(self.dest/'mesh.bin').write_bytes(b'preserve')
        with self.assertRaises(ValueError):restore_actor(self.groups,self.dest,m['archive_sha256'])
        self.assertEqual((self.dest/'mesh.bin').read_bytes(),b'preserve')
    def test_missing_member(self):
        m=fixture(self.groups);m['files'].append({'path':'absent.bin','bytes':0,'sha256':hashlib.sha256(b'').hexdigest()});(self.groups/'manifest.json').write_text(json.dumps(m))
        with self.assertRaises(ValueError):restore_actor(self.groups,self.dest,m['archive_sha256'])
        self.assertFalse(self.dest.exists())
    def test_bad_paths(self):
        for p in ['../x','/root/x','cache/../../x','a\\b']:
            with self.assertRaises(ValueError):safe_relative(p)
if __name__=='__main__':unittest.main()
