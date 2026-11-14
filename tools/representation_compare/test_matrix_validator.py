"""Synthetic failure injection for matrix validation, not a graphics test."""
import tempfile,pathlib,json,subprocess,itertools
script=pathlib.Path(__file__).with_name('check_outcomes.py')
modes=['shared3d','sprite8','sprite16','hybrid']
keys=[(True,w,h,c,m,100) for (w,h),c,m in itertools.product([(2560,1440),(3840,2160)],[22,16],modes)]+[(False,2560,1440,16,m,n) for m,n in itertools.product(modes,[20,100,250,512])]
with tempfile.TemporaryDirectory() as tmp:
 root=pathlib.Path(tmp)
 for i,(cap,w,h,c,m,n) in enumerate(keys):
  p={'seed':61112,'viewport':[w,h],'capture_run_not_performance':cap,'camera_ortho_size':c,'mode':m,'per_side':n,'start_tick':300,'end_tick':300 if cap else 500,'start_snapshot_sha':str(n),'end_snapshot_sha':str(n)+str(cap),'hits':[1,2],'losses':[0,1],'roster':n*2,'independent_simulation_oracle_sha':str(n)+str(cap),'battle_unchanged_by_renderer':True,'internal_scale':1.,'frames':10,'unnecessary_3d_source_loaded':not m.startswith('sprite'),'palette_bytes':0}
  (root/str(i)).mkdir();(root/str(i)/'report.json').write_text(json.dumps(p))
 def run():return subprocess.run(['python',str(script),str(root)],capture_output=True).returncode
 assert run()==0
 f=root/'31/report.json';orig=f.read_text();f.unlink();assert run()!=0;f.write_text(orig)
 (root/'extra').mkdir();(root/'extra/report.json').write_text(orig);assert run()!=0;(root/'extra/report.json').unlink()
 p=json.loads(orig);p['end_snapshot_sha']='mutated';f.write_text(json.dumps(p));assert run()!=0;f.write_text(orig)
 p=json.loads(orig);p['viewport']=[1280,720];f.write_text(json.dumps(p));assert run()!=0
 print('5 matrix fixtures passed: exact accepted; missing, duplicate, changed simulation, wrong native resolution rejected. Synthetic validator tests only.')
