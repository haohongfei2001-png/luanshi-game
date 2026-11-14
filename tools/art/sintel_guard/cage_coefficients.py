"""Recover fixed native cage linear response; reject inaccurate reconstruction.
Not ordinary LBS weights, not a high-detail/normal solution, no shipping change.
"""
import bpy,pathlib,sys,json,hashlib,numpy as np
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];src,out=map(pathlib.Path,args[:2]);out.mkdir(parents=True,exist_ok=True);sha=hashlib.sha256(src.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
rig=bpy.data.objects['rig'];top=bpy.data.objects['GEO-topLT'];mdef=next(m for m in top.modifiers if m.type=='MESH_DEFORM');cage=mdef.object;arm=next(m for m in cage.modifiers if m.type=='ARMATURE');mr=next(m for m in top.modifiers if m.type=='MULTIRES');mr.levels=0
original=np.array([v.co[:] for v in cage.data.vertices]);
def pose(u,f):
 for side,sign in [('L',1),('R',-1)]:
  rig.pose.bones['hand_ik.'+side]['ik']=0.
  for prefix,value in [('upper_arm.',u),('forearm.',f)]:
   p=rig.pose.bones[prefix+side];p.rotation_mode='XYZ';p.rotation_euler=(0,0,value*sign)
 bpy.context.view_layer.update()
def pts(ob):
 dg=bpy.context.evaluated_depsgraph_get();ev=ob.evaluated_get(dg);me=ev.to_mesh();a=np.array([v.co[:] for v in me.vertices],dtype=np.float64);ev.to_mesh_clear();return a

def write(coords):
 cage.data.vertices.foreach_set('co',np.asarray(coords,dtype=np.float32).reshape(-1));cage.data.update();bpy.context.view_layer.update()
pose(0,0);c0=pts(cage);p0=pts(top);arm.show_viewport=False;write(c0)
transform=np.array((top.matrix_world.inverted()@cage.matrix_world).to_3x3(),dtype=np.float64);direction=transform@np.array([1.,0,0]);step=.05
H=np.zeros((len(p0),len(c0)))
for i in range(len(c0)):
 altered=c0.copy();altered[i,0]+=step;write(altered);delta=pts(top)-p0
 H[:,i]=delta@direction/(step*np.dot(direction,direction))
 if i%100==0:print('CAGE_RESPONSE',i,len(c0),flush=True)
write(original);arm.show_viewport=True;rows=[]
for name,u,f in [('elbow',-.25,.9),('shoulder',-.8,.3),('combined',-.55,1.2),('heldout',-.9,.65)]:
 pose(u,f);cp=pts(cage);truth=pts(top);predicted=p0+(H@(cp-c0))@transform.T;error=np.linalg.norm(truth-predicted,axis=1)
 rows.append({'name':name,'max_m':float(error.max()),'rms_m':float(np.sqrt(np.mean(error**2)))})
report={'source_sha256':sha,'source_unchanged':hashlib.sha256(src.read_bytes()).hexdigest()==sha,'matrix_shape':list(H.shape),'finite_difference_step_m':step,'coefficient_min':float(H.min()),'coefficient_max':float(H.max()),'row_sum_min':float(H.sum(axis=1).min()),'row_sum_max':float(H.sum(axis=1).max()),'validation':rows,'scope':'original1373-point top cage only; no Multires or normals preservation claim','runtime':'OFF','accepted_numerical_reconstruction':max(r['max_m'] for r in rows)<.0001}
np.savez_compressed(out/'fixed-cage-response.npz',coefficients=H,cage_rest=c0,top_rest=p0,cage_to_top_linear=transform)
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(report,flush=True)
