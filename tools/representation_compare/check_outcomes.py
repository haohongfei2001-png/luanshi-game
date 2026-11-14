"""Renderer choice must not alter seeded real battle; captures are not FPS runs."""
import pathlib,sys,json
root=pathlib.Path(sys.argv[1]);groups={};rows=[]
for f in sorted(root.glob('*/report.json')):
 p=json.loads(f.read_text());key=(p['per_side'],p['start_tick'],p['end_tick'],p['capture_run_not_performance'])
 sig=(p['start_snapshot_sha'],p['end_snapshot_sha'],p['hits'],p['losses'],p['roster'])
 if key in groups:assert sig==groups[key],f'combat divergence: {f}'
 else:groups[key]=sig
 assert p['battle_unchanged_by_renderer'] and p['internal_scale']==1.
 if not p['capture_run_not_performance']:assert p['frames']>0 and p['end_tick']==500
 rows.append({'path':str(f.relative_to(root)),**p})
assert len(rows)==32,len(rows)
(root/'verified-comparison.json').write_text(json.dumps({'same_seeded_battle':True,'samples':rows,'art_accepted':False,'M5':'NOT_TESTED'},indent=2)+'\n')
