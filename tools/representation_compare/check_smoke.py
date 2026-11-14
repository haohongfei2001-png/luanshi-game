"""Small recovery matrix, explicitly not a full performance/quality pass."""
import pathlib,json,sys
root=pathlib.Path(sys.argv[1]);seen=set();signature=None
expected={(2560,1440,m,0) for m in ['shared3d','sprite8','sprite16','hybrid']}|{(2560,1440,'shared3d',2),(3840,2160,'sprite16',0)}
for f in root.glob('smoke-*/report.json'):
 p=json.loads(f.read_text());lod=p['explicit_lod_inventory'];tier=lod[0]['tier'] if lod else 0
 key=(*p['viewport'],p['mode'],tier);assert key in expected and key not in seen;seen.add(key)
 assert p['capture_run_not_performance'] and p['end_tick']==300 and p['per_side']==100 and p['camera_ortho_size']==12 and p['internal_scale']==1
 assert p['end_snapshot_sha']==p['independent_simulation_oracle_sha']
 if signature is None:signature=p['end_snapshot_sha']
 else:assert signature==p['end_snapshot_sha']
assert seen==expected,(seen,expected)
(root/'smoke-check.json').write_text(json.dumps({'six_captures_completed':True,'same_real_battle':True,'performance_tested':False,'art_pass':False,'texture_pixel_visual_review':'REQUIRED'},indent=2)+'\n')
