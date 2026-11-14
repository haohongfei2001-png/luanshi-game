"""Independent bounded matrix/PNG/timing gate. No final art or stable-tail claim."""
from pathlib import Path
import json,sys,math,re
from PIL import Image
root=Path(sys.argv[1]);rows=[];signatures={}
for capture in [True,False]:
 for mode in ['shared3d','sprite8']:
  d=root/(('capture-' if capture else 'profile-')+mode);r=json.loads((d/'report.json').read_text());raw=json.loads((d/'raw-intervals.json').read_text());p=json.loads((d/'process.json').read_text())
  assert p['exit']==0 and p['failure'] is None and p['focused_own_pid']
  assert not re.search(r'SCRIPT ERROR|SHADER ERROR|ERROR:',(d/'actual-metal.log').read_text())
  assert r['mode']==mode and r['per_side']==20 and r['seed']==61112 and r['capture_run_not_performance']==capture
  assert r['driver']=='metal' and r['method']=='mobile' and r['internal_scale']==1 and r['viewport']==[2560,1440]
  assert r['camera_ortho_size']==12 and r['start_tick']==300 and r['end_tick']==(300 if capture else 620)
  assert r['end_snapshot_sha']==r['independent_simulation_oracle_sha'] and r['battle_unchanged_by_renderer']
  sig=[r[k] for k in ['start_snapshot_sha','end_snapshot_sha','hits','losses','roster','camera_transform']]
  if capture in signatures:assert sig==signatures[capture],'Mode comparison state/camera differs'
  else:signatures[capture]=sig
  assert r['source_model_sha256']=='64705ebc4a20650b79f863bae4b6ec47df06dfefe0ed451fe73a04ebc46295c0'
  if mode=='sprite8':assert not r['unnecessary_3d_source_loaded'] and r['palette_bytes']==0 and r['atlas_compressed_mip_bytes']>0
  else:assert r['explicit_lod_inventory'] and all(x['tier']==1 for x in r['explicit_lod_inventory'])
  if capture:
   im=Image.open(d/'same-tick-native.png').convert('RGB');assert im.size==(2560,1440)
   small=im.resize((256,144));pixels=list(small.getdata());assert len(set(pixels))>1000,'Empty or flat image'
   assert sum(a>180 and b<60 and c>180 for a,b,c in pixels)/len(pixels)<.01,'Magenta missing textures'
   r['image_technical_gate']='nonempty native resolution; alpha/occlusion/body quality requires human pixel review'
  else:
   values=raw['frame_ms'];assert len(values)==r['frames'] and len(values)>=120 and sum(values)>=10000,'Existing minimum120frames/10seconds not met'
   assert all(isinstance(x,(int,float)) and not isinstance(x,bool) and math.isfinite(x) and x>0 for x in values)
   assert len(raw['simulation_ms'])==len(values)==len(raw['presentation_ms'])
   r['independently_measured']={'average_fps':len(values)*1000/sum(values),'p50_ms':sorted(values)[math.ceil(.50*len(values))-1],'p95_ms':sorted(values)[math.ceil(.95*len(values))-1],'p99_ms':sorted(values)[math.ceil(.99*len(values))-1],'samples':len(values),'wall_seconds':sum(values)/1000,'stable_p99_or_device_qualification':False}
   resources=(d/'resource-time.log').read_text();m=re.search(r'(\d+)\s+maximum resident set size',resources);assert m
   r['maximum_rss_bytes']=int(m.group(1))
  rows.append(r)
(root/'bounded-comparison.json').write_text(json.dumps({'technical_gates_passed':True,'route_winner':None,'art_pass':False,'M5':'DEVICE_NOT_RUN','cases':rows},indent=2))
print('BOUNDED_METAL_MATRIX_TECHNICAL_PASS; image self-review still required; no route winner')
