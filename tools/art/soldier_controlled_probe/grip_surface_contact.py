"""Measure actual evaluated hand surface against finite wood shaft, not wrist targets."""
import bpy,sys,pathlib,json,numpy as np,hashlib
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False)
scene=bpy.context.scene;rig=bpy.data.objects['rig'];action=rig.animation_data.action if rig.animation_data else None
first,last=action.frame_range if action else (scene.frame_current,scene.frame_current)
shaft=bpy.data.objects['SPEAR whole unbroken wood shaft no tassel'];rows=[]
for phase in np.linspace(0,1,9):
 f=first+(last-first)*phase;scene.frame_set(int(f),subframe=float(f%1));bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get()
 se=shaft.evaluated_get(dg);sm=se.to_mesh();v=np.array([tuple(se.matrix_world@p.co) for p in sm.vertices]);se.to_mesh_clear()
 center=v.mean(axis=0);_,_,vh=np.linalg.svd(v-center,full_matrices=False);axis=vh[0];along=(v-center)@axis;lo,hi=along.min(),along.max();radius=float(np.median(np.linalg.norm(v-center-along[:,None]*axis,axis=1)))
 for obj in scene.objects:
  if obj.type!='MESH' or 'Hand' not in obj.name or not obj.visible_get():continue
  ev=obj.evaluated_get(dg);me=ev.to_mesh();points=np.array([tuple(ev.matrix_world@p.co) for p in me.vertices]);ev.to_mesh_clear()
  a=(points-center)@axis;radial=np.linalg.norm(points-center-a[:,None]*axis,axis=1);inside=(a>=lo)&(a<=hi);clearance=radial-radius
  rows.append({'phase':float(phase),'mesh':obj.name,'evaluated_vertices':len(points),'shaft_radius_m':radius,'surface_vertices_inside_shaft':int(np.sum(inside&(clearance<-.001))),'worst_surface_radial_penetration_m':float(max(0,-clearance[inside].min())) if inside.any() else 0,'vertices_within_2mm_of_shaft_surface':int(np.sum(inside&(abs(clearance)<=.002)))})
out.write_text(json.dumps({'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'method':'Evaluated full hand vertices vs finite actual evaluated wood cylinder; not triangle intersection proof or pressure/contact acceptance','art_pass':False,'grip_pass':False,'samples':rows},indent=2)+'\n');print('HAND_SURFACE_CONTACT_WRITTEN',len(rows))
