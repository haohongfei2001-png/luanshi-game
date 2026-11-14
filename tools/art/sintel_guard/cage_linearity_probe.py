"""Test native cage replay and affine blend law, no production runtime change."""
import bpy,pathlib,sys,json,hashlib,numpy as np
args=sys.argv[sys.argv.index('--')+1:];src,out=map(pathlib.Path,args[:2]);out.parent.mkdir(parents=True,exist_ok=True);sha=hashlib.sha256(src.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
rig=bpy.data.objects['rig'];top=bpy.data.objects['GEO-topLT'];mdef=next(m for m in top.modifiers if m.type=='MESH_DEFORM');cage=mdef.object;arm=next(m for m in cage.modifiers if m.type=='ARMATURE');mr=next(m for m in top.modifiers if m.type=='MULTIRES');original=np.array([v.co[:] for v in cage.data.vertices]);rows=[]
def pose(upper,fore):
 for side,sign in [('L',1),('R',-1)]:
  rig.pose.bones['hand_ik.'+side]['ik']=0.
  for prefix,value in [('upper_arm.',upper),('forearm.',fore)]:
   p=rig.pose.bones[prefix+side];p.rotation_mode='XYZ';p.rotation_euler=(0,0,value*sign)
 bpy.context.view_layer.update()
def points(ob):
 dg=bpy.context.evaluated_depsgraph_get();ev=ob.evaluated_get(dg);me=ev.to_mesh();a=np.array([v.co[:] for v in me.vertices],dtype=np.float64);ev.to_mesh_clear();return a

def write_cage(coords):
 cage.data.vertices.foreach_set('co',np.asarray(coords,dtype=np.float32).reshape(-1));cage.data.update();bpy.context.view_layer.update()
def stats(a,b):
 e=np.linalg.norm(a-b,axis=1);return {'max_m':float(e.max()),'rms_m':float(np.sqrt(np.mean(e**2))),'p95_m':float(np.quantile(e,.95))}
for level in [0,1]:
 mr.levels=level;arm.show_viewport=True;write_cage(original);pose(0,0);c0=points(cage);p0=points(top)
 for label,upper,fore in [('elbow',-.25,.9),('shoulder',-.8,.3),('combined',-.55,1.2)]:
  arm.show_viewport=True;write_cage(original);pose(upper,fore);cp=points(cage);pp=points(top)
  pose(0,0);arm.show_viewport=False;write_cage(cp);replay=points(top)
  write_cage((c0+cp)*.5);mid=points(top)
  rows.append({'multires_level':level,'pose':label,'vertices':len(pp),'cage_replay_error':stats(replay,pp),'midpoint_affine_error':stats(mid,(p0+pp)*.5)})
arm.show_viewport=True;write_cage(original);pose(0,0)
report={'source_sha256':sha,'source_unchanged':hashlib.sha256(src.read_bytes()).hexdigest()==sha,'cage_vertices':len(original),'cage_modifiers':[m.type for m in cage.modifiers],'bound':mdef.is_bound,'dynamic_bind':mdef.use_dynamic_bind,'tests':rows,'claim':'Measured cage replay and midpoint linearity only, not runtime LBS fitting or normals validation','runtime_enabled':False}
out.write_text(json.dumps(report,indent=2)+'\n');print(report,flush=True)
