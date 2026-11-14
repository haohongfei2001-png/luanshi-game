"""Validate whole gateway bearing contacts, not lighting or art acceptance."""
import bpy,json,sys
from pathlib import Path
source,output=map(Path,sys.argv[sys.argv.index('--')+1:]);bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
def bounds(o):
 points=[o.matrix_world@v.co for v in o.data.vertices]
 return ([min(p[k] for p in points) for k in range(3)],[max(p[k] for p in points) for k in range(3)])
bearings=[o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('GateGalleryBearing')]
walls=[o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('GateContinuousSpandrel')]
records=[]
for beam in bearings:
 lo,hi=bounds(beam)
 for wall in walls:
  wl,wh=bounds(wall);overlap=[max(0.,min(hi[k],wh[k])-max(lo[k],wl[k])) for k in range(3)]
  if all(v>1e-5 for v in overlap):raise RuntimeError('Overlapping bearing masonry: '+beam.name+' / '+wall.name)
  records.append({'bearing':beam.name,'wall':wall.name,'overlap_axes_m':overlap})
wood=bpy.data.objects['HallFloorJoists'];wl,wh=bounds(wood);contacts=[]
for stone in bearings+walls:
 lo,hi=bounds(stone);penetration=hi[2]-wl[2]
 if penetration>1e-5:raise RuntimeError('Timber penetrates masonry '+stone.name+' '+str(penetration))
 contacts.append({'stone':stone.name,'stone_top_m':hi[2],'timber_bottom_m':wl[2],'contact_gap_m':wl[2]-hi[2]})
report={'masonry_pairs':records,'timber_bearing_contacts':contacts,'scope':'specific source solid interface contract, not global intersection absence or graphical acceptance'};output.write_text(json.dumps(report,indent=2));print('PORTAL_INTERFACE_PASS',json.dumps(report))
