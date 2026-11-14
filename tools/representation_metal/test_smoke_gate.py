import tempfile,json,subprocess,sys,pathlib,unittest,shutil
from PIL import Image
ROOT=pathlib.Path(__file__).resolve().parent
class SmokeGate(unittest.TestCase):
 def fixture(self,path):
  im=Image.frombytes('RGB',(256,144),bytes(v for y in range(144) for x in range(256) for v in (x,y,0))).resize((2560,1440),Image.Resampling.NEAREST)
  # Synthetic nonempty gate fixture, never a real source-quality claim.
  for capture in [True,False]:
   for mode in ['shared3d','sprite8']:
    d=path/(('capture-' if capture else 'profile-')+mode);d.mkdir()
    r={'mode':mode,'per_side':20,'seed':61112,'capture_run_not_performance':capture,'driver':'metal','method':'mobile','internal_scale':1,'viewport':[2560,1440],'camera_ortho_size':12,'start_tick':300,'end_tick':300 if capture else 620,'start_snapshot_sha':'start','end_snapshot_sha':'end','independent_simulation_oracle_sha':'end','battle_unchanged_by_renderer':True,'hits':[1,2],'losses':[0,1],'roster':42,'camera_transform':'same','source_model_sha256':'64705ebc4a20650b79f863bae4b6ec47df06dfefe0ed451fe73a04ebc46295c0','unnecessary_3d_source_loaded':mode=='shared3d','palette_bytes':100 if mode=='shared3d' else 0,'atlas_compressed_mip_bytes':1000,'explicit_lod_inventory':[{'tier':1}],'frames':200}
    (d/'report.json').write_text(json.dumps(r));(d/'raw-intervals.json').write_text(json.dumps({'frame_ms':[60]*200,'simulation_ms':[1]*200,'presentation_ms':[2]*200}));(d/'actual-metal.log').write_text('actual test log');(d/'process.json').write_text(json.dumps({'exit':0,'failure':None,'focused_own_pid':True}));(d/'resource-time.log').write_text('2000000 maximum resident set size')
    if capture:im.save(d/'same-tick-native.png')
 def run_gate(self,p):return subprocess.run([sys.executable,str(ROOT/'check_smoke.py'),str(p)],capture_output=True).returncode
 def test_gate(self):
  with tempfile.TemporaryDirectory() as t:
   p=pathlib.Path(t);self.fixture(p);self.assertEqual(self.run_gate(p),0)
   f=p/'profile-sprite8/raw-intervals.json';original=f.read_text();d=json.loads(original);d['frame_ms']=[60]*119;f.write_text(json.dumps(d));self.assertNotEqual(self.run_gate(p),0);f.write_text(original)
   f=p/'profile-sprite8/report.json';original=f.read_text();d=json.loads(original);d['end_snapshot_sha']='wrong';f.write_text(json.dumps(d));self.assertNotEqual(self.run_gate(p),0);f.write_text(original)
   f=p/'capture-sprite8/same-tick-native.png';Image.new('RGB',(2560,1440),(255,0,255)).save(f);self.assertNotEqual(self.run_gate(p),0)
if __name__=='__main__':unittest.main()
