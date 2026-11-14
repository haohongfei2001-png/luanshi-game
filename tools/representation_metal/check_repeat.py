"""512-only counterbalanced no-readback repeat. No new image/attachment proof."""
from pathlib import Path
import json,sys,math,re
root=Path(sys.argv[1]);rows=[];signature=None
for index,mode in enumerate(['sprite8','shared3d','shared3d','sprite8'],1):
 d=root/f'profile-{mode}-512-repeat{index}'
 r=json.loads((d/'report.json').read_text());raw=json.loads((d/'raw-intervals.json').read_text());p=json.loads((d/'process.json').read_text())
 assert p['exit']==0 and p['failure'] is None and p['focused_own_pid'] and not p['capture_readback']
 log=(d/'actual-metal.log').read_text()
 assert not re.search(r'SCRIPT ERROR|SHADER ERROR|ERROR:',log)
 assert re.search(r'Metal .*Forward Mobile.*Apple',log)
 assert not (d/'same-tick-native.png').exists(),'No screenshot readback in repeat'
 assert r['mode']==mode and r['per_side']==512 and r['seed']==61112 and not r['capture_run_not_performance']
 assert r['driver']=='metal' and r['method']=='mobile' and r['internal_scale']==1 and r['viewport']==[2560,1440]
 assert r['camera_ortho_size']==12 and r['start_tick']==250 and r['end_tick']==570
 assert r['end_snapshot_sha']==r['independent_simulation_oracle_sha'] and r['battle_unchanged_by_renderer']
 assert r['camera_tracking']=='actual_contact_fixed_lens'
 sig=[r[k] for k in ['start_snapshot_sha','end_snapshot_sha','hits','losses','roster','camera_transform','camera_track_sha256']]
 if signature is None:signature=sig
 else:assert sig==signature,'Real Battle/camera differs across repeat'
 assert r['source_model_sha256']=='64705ebc4a20650b79f863bae4b6ec47df06dfefe0ed451fe73a04ebc46295c0'
 if mode=='sprite8':assert not r['unnecessary_3d_source_loaded'] and r['palette_bytes']==0 and r['atlas_compressed_mip_bytes']==308134592
 else:assert r['explicit_lod_inventory'] and all(x['tier']==1 for x in r['explicit_lod_inventory'])
 assert len(raw['visibility_and_camera'])==r['frames'] and len(raw['fixed_tick_contact_camera'])==321 and r['alive_screen_centers_summary']['min']>0
 values=raw['frame_ms']
 assert len(values)==r['frames'] and len(values)>=120 and sum(values)>=10000,'Required120frames/10s'
 assert all(isinstance(x,(int,float)) and not isinstance(x,bool) and math.isfinite(x) and x>0 for x in values)
 assert len(raw['simulation_ms'])==len(values)==len(raw['presentation_ms'])
 for moment in ['before','after']:
  for kind in ['vm','swap','pressure','processes']:assert (d/f'{kind}-{moment}.txt').stat().st_size>0
 def stats(v):
  s=sorted(v)
  return {'mean_ms':sum(v)/len(v),'p50_ms':s[math.ceil(.5*len(s))-1],'p95_ms':s[math.ceil(.95*len(s))-1],'p99_ms':s[math.ceil(.99*len(s))-1]}
 independent=stats(values);independent.update(average_fps=len(values)*1000/sum(values),samples=len(values),wall_seconds=sum(values)/1000,simulation=stats(raw['simulation_ms']),presentation=stats(raw['presentation_ms']))
 rss=re.search(r'(\d+)\s+maximum resident set size',(d/'resource-time.log').read_text());assert rss
 rows.append({'order':index,'mode':mode,'independent':independent,'maximum_rss_bytes':int(rss.group(1)),'original_report':r})
(root/'repeat-comparison.json').write_text(json.dumps({'technical_gates_passed':True,'cases':rows,'art_pass':False,'M5':'DEVICE_NOT_RUN','order':'sprite3D3Dsprite','readback':False,'new_native_attachment_pixel_proof':False,'prior_pixel_proof_run':43651982237,'warning':'Four short fixed-order processes are not thermal/device qualification or proof of GPU causality. Resource snapshots are before/after, not continuous residency.'},indent=2))
print('BOUNDED512_COUNTERBALANCED_REPEAT_PASS; no new image acceptance or final route choice')
