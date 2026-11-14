"""Compute projected control-body occupancy from actual Godot alpha bounds.
Only the weapon-free UBC control: not an armored/armed character body detector.
This is orthographic KEEP_HEIGHT math at the exact atlas elevation, not a Riot
camera specification. Native capture inspection remains required.
"""
import json,sys,statistics
from pathlib import Path
p=json.loads(Path(sys.argv[1]).read_text())
ppm=p['pixels_per_metre'];rows=[r for r in p['alpha_pixel_bounds'] if r[0]=='Idle' and r[1]==0]
assert len(rows)==16
heights=[r[6]/ppm for r in rows]
result={'source_sha256':p['source_sha256'],'method':'Godot baked alpha extent divided by bake pixels/metre; body-only UBC Idle frame0, all16 directions; same-elevation orthographic KEEP_HEIGHT','alpha_boundary_note':'any nonzero alpha as reported by Image.get_used_rect; no shadow or weapon-body separation needed for this limited control','height_world_min':min(heights),'height_world_median':statistics.median(heights),'height_world_max':max(heights),'candidate_cameras':[],'camera_for_median_body_occupancy':{str(f):statistics.median(heights)/f for f in [.10,.12,.14]},'not_riot_numeric_spec':True,'art_accepted':False}
for size in [22,16,14,12,10]:
 result['candidate_cameras'].append({'size':size,'fraction_min':min(heights)/size,'fraction_max':max(heights)/size,'native_1440p_range':[round(h/size*1440,2) for h in [min(heights),max(heights)]],'native_2160p_range':[round(h/size*2160,2) for h in [min(heights),max(heights)]]})
text=json.dumps(result,indent=2)+'\n'
if len(sys.argv)>2:Path(sys.argv[2]).write_text(text)
print(text)
