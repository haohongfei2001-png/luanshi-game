"""Complete four-part head: original nine weights plus Blender evaluated oracle.
No native Skin/eight-slot export is used as reference. No garment support claim.
"""
import bpy,sys,pathlib,json,hashlib,shutil,numpy as np
from mathutils import Matrix
src,expected,out=sys.argv[sys.argv.index('--')+1:];src=pathlib.Path(src);out=pathlib.Path(out);out.mkdir(parents=True,exist_ok=True)
assert hashlib.sha256(src.read_bytes()).hexdigest()==expected
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False)
C=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)));Ci=C.inverted();scene=bpy.context.scene;action=bpy.data.objects['rig'].animation_data.action;first,last=map(float,action.frame_range)
names=['Eyes','Young complete author face module','eyebrow001','eyelashes01'];meshes=[];internal=[]
for k,name in enumerate(names):
 o=bpy.data.objects[name];mods=[m for m in o.modifiers if m.show_viewport];assert len(mods)==1 and mods[0].type=='ARMATURE' and not mods[0].use_deform_preserve_volume and not o.data.shape_keys
 assert len(o.data.materials)==1,'All authored material surfaces must be preserved, not silently merged'
 arm=mods[0].object;bones=list(arm.data.bones);lookup={b.name:i for i,b in enumerate(bones)};groups=[[(lookup[o.vertex_groups[g.group].name],float(g.weight)) for g in v.groups if o.vertex_groups[g.group].name in lookup and bones[lookup[o.vertex_groups[g.group].name]].use_deform and g.weight>0] for v in o.data.vertices];slots=max(map(len,groups));assert slots<=16
 o.data.calc_loop_triangles();uv=o.data.uv_layers.active;assert uv is not None
 reps=[];remap=[];unique={}
 for li,loop in enumerate(o.data.loops):
  key=(loop.vertex_index,*uv.data[li].uv,*np.round(o.data.corner_normals[li].vector,6))
  if key not in unique:unique[key]=len(reps);reps.append(li)
  remap.append(unique[key])
 ids=[o.data.loops[li].vertex_index for li in reps];weights=[];joints=[]
 for vi in ids:
  gs=groups[vi];weights.extend([g[1] for g in gs]+[0.]*(slots-len(gs)));joints.extend([g[0] for g in gs]+[0]*(slots-len(gs)))
 mat=o.data.materials[0];bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');material={'source_name':mat.name,'linear_color':list(bs.inputs['Base Color'].default_value),'roughness':float(bs.inputs['Roughness'].default_value),'metallic':float(bs.inputs['Metallic'].default_value),'alpha_linked':bs.inputs['Alpha'].is_linked,'mapping':'same documented reduced diffuse PBR as whole-actor oracle, not Blender SSS/transmission equivalence'}
 links=list(bs.inputs['Base Color'].links)
 if links:
  tex=links[0].from_node;assert tex.type=='TEX_IMAGE';im=tex.image;dest=out/f'material-{k}.png'
  if im.packed_file:dest.write_bytes(im.packed_file.data)
  else:shutil.copyfile(pathlib.Path(bpy.path.abspath(im.filepath,library=im.library)),dest)
  material.update(texture=dest.name,texture_sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),linear_color=[1.,1.,1.,1.])
 part={'name':name,'bones':[b.name for b in bones],'rest_matrices':[list(map(list,b.matrix_local)) for b in bones],'slots':slots,'weights':weights,'joints':joints,'source_vertex_ids':ids,'over8_original_vertices':sum(len(gs)>8 for gs in groups),'position':[list(C@o.data.vertices[vi].co) for vi in ids],'normal':[list((C.to_3x3()@o.data.corner_normals[li].vector).normalized()) for li in reps],'active_uv':uv.name,'uv':[list(uv.data[li].uv) for li in reps],'all_uv_layers':{layer.name:[list(layer.data[li].uv) for li in reps] for layer in o.data.uv_layers},'indices':[remap[li] for tri in o.data.loop_triangles for li in [tri.loops[0],tri.loops[2],tri.loops[1]]],'material':material}
 meshes.append(part);internal.append((o,arm,bones,reps,ids,groups))
poses=[]
for pi,phase in enumerate([0.,.13,.47,.83,.5,1.,.5]):
 f=first+(last-first)*phase;scene.frame_set(int(f),subframe=f%1);stress=[]
 if pi==6:
  for o,arm,bones,reps,ids,groups in internal:
   for gs in groups:
    if len(gs)>8:
     name=bones[gs[8][0]].name;p=arm.pose.bones[name];p.rotation_mode='XYZ';p.rotation_euler=(.12,-.08,.06);p.location=(.015,-.007,.011)
     if name not in stress:stress.append(name)
 bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();parts=[]
 for o,arm,bones,reps,ids,groups in internal:
  ev=o.evaluated_get(dg);ae=arm.evaluated_get(dg);M=ae.matrix_world.inverted()@ev.matrix_world;me=ev.to_mesh();assert len(me.vertices)==len(o.data.vertices)
  normalworld=(C@ev.matrix_world).to_3x3().inverted().transposed()
  parts.append({'name':o.name,'object_transform':list(map(list,C@ev.matrix_world@Ci)),'palette':[list(map(list,C@M.inverted()@ae.pose.bones[b.name].matrix@b.matrix_local.inverted()@M@Ci)) for b in bones],'reference_positions':[list(C@ev.matrix_world@me.vertices[vi].co) for vi in ids],'reference_normals':[list((normalworld@me.corner_normals[li].vector).normalized()) for li in reps]});ev.to_mesh_clear()
 poses.append({'name':('tail-stress' if pi==6 else 'walk-'+str(int(round(phase*100)))),'phase':phase,'source_frame':f,'authored_motion':pi!=6,'synthetic_bones':stress,'parts':parts})
report={'source_sha256':expected,'blender':bpy.app.version_string,'meshes':meshes,'poses':poses,'default_enabled':False,'art_pass':False,'source_weights_truncated':False,'native8_reference_used':False,'reference':'Actual evaluated Blender full-nine source positions and corner normals; rest mesh/UV/weights retained','material_limitations':['Current source diffuse/roughness/metal values and original RGBA images preserved','No source SSS/transmission match claimed','Alpha reference uses existing whole-actor Godot scissor .25; not claiming exact Blender DITHERED coverage'],'runtime_scope':'Only four plain-LBS head parts, no clothing, complete actor or army performance'}
(out/'head-source.json').write_text(json.dumps(report,separators=(',',':'))+'\n');print('HEAD_ORACLE_EXPORTED',[(m['name'],len(m['position']),m['slots'],m['over8_original_vertices']) for m in meshes],flush=True)
