"""Exact same-phase original vs constrained source rig knee diagnostics."""
import bpy,json,sys,pathlib
from mathutils import Vector
original,candidate,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:3])
def sample(path):
 bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False,use_scripts=False);r=bpy.data.objects['rig'];first,last=map(float,r.animation_data.action.frame_range);rows=[]
 for i in range(65):
  f=first+(last-first)*i/64;bpy.context.scene.frame_set(int(f),subframe=f%1);bpy.context.view_layer.update();record={}
  for s in 'LR':
   h=r.matrix_world@r.pose.bones['DEF-thigh.'+s+'.01'].head;k=r.matrix_world@r.pose.bones['DEF-shin.'+s+'.01'].head;a=r.matrix_world@r.pose.bones['DEF-foot.'+s].head
   axis=(a-h).normalized();bend=k-h-axis*(k-h).dot(axis);record[s]={'knee':list(k),'bend':list(bend.normalized()),'bend_distance':bend.length}
  rows.append(record)
 return rows
a=sample(original);b=sample(candidate);report={'art_pass':False,'samples':65,'source_comparison':'Same phase complete original deformation bones, no camera inference','sides':{}}
for s in 'LR':
 report['sides'][s]={'minimum_bend_direction_dot':min(Vector(x[s]['bend']).dot(Vector(y[s]['bend'])) for x,y in zip(a,b)),'maximum_knee_displacement_m':max((Vector(x[s]['knee'])-Vector(y[s]['knee'])).length for x,y in zip(a,b)),'minimum_candidate_knee_bend_distance_m':min(x[s]['bend_distance'] for x in b),'maximum_original_step_m':max((Vector(a[i][s]['knee'])-Vector(a[i-1][s]['knee'])).length for i in range(1,65)),'maximum_candidate_step_m':max((Vector(b[i][s]['knee'])-Vector(b[i-1][s]['knee'])).length for i in range(1,65))}
out.write_text(json.dumps(report,indent=2));print('KNEE_CONTINUITY',report['sides'],flush=True)
