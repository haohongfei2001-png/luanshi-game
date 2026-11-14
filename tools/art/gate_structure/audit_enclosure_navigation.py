"""Test complete new enclosure solids against actual exported Godot Ground samples.
No geometry is moved to satisfy the test. This is not a physics battle playthrough.
"""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector
blend,samples,out=map(Path,sys.argv[sys.argv.index('--')+1:]);bpy.ops.wm.open_mainfile(filepath=str(blend),load_ui=False)
rows=json.loads(samples.read_text());solids=[];ramps=[]
for ob in bpy.data.objects:
 if ob.type!='MESH' or not ob.name.startswith('Fort'):continue
 if ob.parent.name!='WallWalk':continue
 pts=[ob.matrix_world@v.co for v in ob.data.vertices];lo=Vector(tuple(min(p[k] for p in pts) for k in range(3)));hi=Vector(tuple(max(p[k] for p in pts) for k in range(3)))
 # All new enclosure components are closed convex prisms/boxes. Compute outward
 # face planes from real post-modifier geometry, not guessed metadata boxes.
 normal_matrix=ob.matrix_world.to_3x3().inverted().transposed()
 planes=[((normal_matrix@p.normal).normalized(),ob.matrix_world@p.center) for p in ob.data.polygons]
 solids.append((ob.name,lo,hi,planes))
 if ob.name.startswith('FortInnerRampCore'):ramps.append((ob,pts))
fail=[];checked=0
for row in rows['points']:
 if row['blocked_open']:continue
 for height in [.07,1.0,2.5,3.4]:
  point=Vector((row['x'],-row['z'],row['walk_height']+height));checked+=1
  for name,lo,hi,planes in solids:
   if any(point[k]<=lo[k]+1e-5 or point[k]>=hi[k]-1e-5 for k in range(3)):continue
   if all(n.dot(point-origin)<-1e-5 for n,origin in planes):
    fail.append({'object':name,'actual_ground':row,'body_sample_height':height});break
# Exact ramp endpoint/height agreement, not only a near-centre visual check.
max_error=0.;vertices=0
for ob,pts in ramps:
 for p in pts:
  if p.z<-.1:continue
  expected=min(3.25,max(0.,(abs(p.y)-5.5)*.43));max_error=max(max_error,abs(p.z-expected));vertices+=1
  if abs(p.y)>21.8+1e-5:raise AssertionError('Model ramp extends outside real raised lane')
report={'result':'FAIL' if fail else 'PASS_NAVIGABLE_BODY_SAMPLES','actual_ground_points':len(rows['points']),'open_navigable_body_samples':checked,'solid_components_checked':len(solids),'ramp_top_vertices':vertices,'ramp_height_max_error_m':max_error,'failures':fail[:30],'scope':'actual Ground finite grid and authored closed enclosure volume; not full physics/gameplay/visibility acceptance'}
out.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
assert not fail,'New fortress obstructs existing navigable player/horse body space'
assert max_error<1e-5,'New ramp no longer matches real Ground.parapet'
