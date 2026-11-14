"""Require the exact unique experiment matrix and independent real-combat oracle."""
import pathlib,sys,json,itertools
root=pathlib.Path(sys.argv[1]);groups={};rows=[];seen=set();modes=['shared3d','sprite8','sprite16','hybrid']
expected={(True,w,h,camera,mode,100) for (w,h),camera,mode in itertools.product([(2560,1440),(3840,2160)],[22,16],modes)}
expected|={(False,2560,1440,16,mode,count) for mode,count in itertools.product(modes,[20,100,250,512])}
for f in sorted(root.glob('*/report.json')):
 p=json.loads(f.read_text());assert p['seed']==61112
 w,h=map(int,p['viewport']);key=(p['capture_run_not_performance'],w,h,int(p['camera_ortho_size']),p['mode'],p['per_side'])
 assert key in expected and key not in seen,(f,key);seen.add(key)
 combat_key=(p['per_side'],p['start_tick'],p['end_tick'],p['capture_run_not_performance'])
 sig=(p['start_snapshot_sha'],p['end_snapshot_sha'],p['hits'],p['losses'],p['roster'])
 if combat_key in groups:assert sig==groups[combat_key],f'combat divergence: {f}'
 else:groups[combat_key]=sig
 assert p['end_snapshot_sha']==p['independent_simulation_oracle_sha']
 assert p['battle_unchanged_by_renderer'] and p['internal_scale']==1.
 if not p['capture_run_not_performance']:assert p['frames']>0 and p['end_tick']==500
 if p['mode'].startswith('sprite'):assert not p['unnecessary_3d_source_loaded'] and p['palette_bytes']==0
 rows.append({'path':str(f.relative_to(root)),**p})
assert seen==expected,{'missing':sorted(expected-seen),'extra':sorted(seen-expected)}
(root/'verified-comparison.json').write_text(json.dumps({'same_seeded_battle':True,'exact_unique_matrix':True,'samples':rows,'art_accepted':False,'M5':'NOT_TESTED'},indent=2)+'\n')
