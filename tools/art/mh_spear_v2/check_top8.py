"""Four actual complete-character poses: full source weights versus exporter top8.
Vertex displacement + fixed180px body-height silhouette proxy, not game/art acceptance.
"""
import bpy,sys,json,hashlib,math
from pathlib import Path
from mathutils import Vector
import numpy as np
args=sys.argv[sys.argv.index('--')+1:];source,out=map(Path,args[:2]);no_render='--no-render' in args[2:];out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(source),use_scripts=False,load_ui=False)
rig=bpy.data.objects['MH163'];rig.data.pose_position='POSE';scene=bpy.context.scene
objects=[o for o in scene.objects if o.type=='MESH' and not o.hide_render]
poses=[('idle','Spear_Idle_V2_DRAFT',0),('thrust','Spear_Thrust_V2_DRAFT',28),('walk','Spear_Walk_V2_DRAFT',40),('hit','Hit_Chest',12),('jog','Spear_Jog_V2_DRAFT',56),('death','Death01',144)]
def coords():
 deps=bpy.context.evaluated_depsgraph_get();result={}
 for obj in objects:
  evaluated=obj.evaluated_get(deps);mesh=evaluated.to_mesh();a=np.empty(len(mesh.vertices)*3,dtype=np.float32);mesh.vertices.foreach_get('co',a)
  a=a.reshape(-1,3);m=np.array(evaluated.matrix_world,dtype=np.float64);result[obj.name]=a@m[:3,:3].T+m[:3,3];evaluated.to_mesh_clear()
 return result
# Diagnostic neutral mask; textures/material variation cannot conceal topology error.
scene.render.engine='BLENDER_WORKBENCH';scene.display.shading.light='FLAT';scene.display.shading.color_type='SINGLE';scene.display.shading.single_color=(.08,.08,.08);scene.display.shading.show_shadows=False;scene.display.shading.show_cavity=False
scene.render.film_transparent=True;scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.world=bpy.data.worlds.new('Top8ProxyWorld') if scene.world is None else scene.world
bpy.ops.object.camera_add(location=(3.2,-4.5,3.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.25,.85))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';scene.camera=cam
rig.animation_data.action=bpy.data.actions['Spear_Idle_V2_DRAFT'];scene.frame_set(0);bpy.context.view_layer.update();baseline=coords();up=cam.matrix_world.to_quaternion()@Vector((0,1,0));body=np.concatenate([a for n,a in baseline.items() if not n.startswith('Spear_')]);dots=body@np.array(up);span=float(dots.max()-dots.min());cam.data.ortho_scale=span*512/180
original={};summaries=[]
for label,action,frame in poses:
 rig.animation_data.action=bpy.data.actions[action];scene.frame_set(frame);bpy.context.view_layer.update();original[label]=coords();np.savez_compressed(out/f'{label}-full.npz',**original[label]);scene.render.filepath=str(out/f'{label}-full.png')
 if not no_render:bpy.ops.render.render(write_still=True)
assert max(float(np.linalg.norm(original['walk'][n]-original['idle'][n],axis=1).max()) for n in original['idle'] if n.startswith('Body_'))>.02, 'Body was not actually deformed; REST pose is invalid comparison'
losses=[];extra_groups=set()
for obj in objects:
 for v in obj.data.vertices:
  gs=sorted([(g.group,g.weight) for g in v.groups if g.weight>0],key=lambda q:-q[1])
  extra_groups.update(obj.vertex_groups[i].name for i,w in gs if obj.vertex_groups[i].name not in rig.data.bones)
  if len(gs)>8:
   losses.append(sum(w for _,w in gs[8:]))
   for idx,w in gs[8:]:obj.vertex_groups[idx].remove([v.index])
  total=sum(w for _,w in gs[:8])
  if total:
   for idx,w in gs[:8]:obj.vertex_groups[idx].add([v.index],w/total,'REPLACE')
for obj in objects:obj.data.update();obj.update_tag(refresh={'DATA'})
for label,action,frame in poses:
 rig.animation_data.action=bpy.data.actions[action];scene.frame_set(frame);bpy.context.view_layer.update();now=coords();np.savez_compressed(out/f'{label}-top8.npz',**now)
 for name,a in now.items():
  before=original[label][name];assert a.shape==before.shape,(name,'topology changed')
  d=np.linalg.norm(a-before,axis=1)
  summaries.append({'pose':label,'mesh':name,'vertices':len(a),'max_m':float(d.max(initial=0)),'p95_m':float(np.percentile(d,95)) if len(d) else 0,'rms_m':float(np.sqrt(np.mean(d*d))) if len(d) else 0,'max_linear_pixel_proxy':float(d.max(initial=0)*180/span)})
 scene.render.filepath=str(out/f'{label}-top8.png')
 if not no_render:bpy.ops.render.render(write_still=True)
report={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'source_unchanged':True,'affected_vertices':len(losses),'maximum_discarded_weight':max(losses,default=0),'nonbone_groups':sorted(extra_groups),'camera':{'resolution':[512,512],'orthographic_scale':cam.data.ortho_scale,'body_reference_projected_pixels':180,'basis':[list(r) for r in cam.matrix_world],'body_projected_world_span':span},'silhouette_rendered':not no_render,'scope':'actual evaluated source pose vertex errors; silhouettes only when silhouette_rendered=true; no GPU/game/art or thousand-unit acceptance','poses':poses,'meshes':summaries}
(out/'vertex-comparison.json').write_text(json.dumps(report,indent=2));print('TOP8_ACTUAL_POSE_MEASUREMENTS_SAVED_NOT_ART_ACCEPTANCE')
