"""Explicit current author-source dependency boundary, not runtime support claims."""
import bpy,json,pathlib,sys,hashlib
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False);parts=[]
for o in sorted(bpy.context.scene.objects,key=lambda x:x.name):
 if o.type!='MESH' or o.hide_render or not o.visible_get():continue
 mods=[];nonlinear=[]
 for m in o.modifiers:
  d={'name':m.name,'type':m.type,'enabled':m.show_viewport}
  if m.type=='ARMATURE':
   r=m.object;d.update(object=r.name,bones=len(r.data.bones),deform_bones=sum(b.use_deform for b in r.data.bones),preserve_volume_DQ=m.use_deform_preserve_volume)
  if m.type=='MESH_DEFORM':
   cage=m.object;d.update(cage=cage.name,cage_vertices=len(cage.data.vertices),bound=m.is_bound,precision=m.precision,cage_modifiers=[{'type':x.type,'object':x.object.name if x.type=='ARMATURE' else None,'DQ':x.use_deform_preserve_volume if x.type=='ARMATURE' else None} for x in cage.modifiers]);nonlinear.append('MeshDeform binding is not ordinary Skin weights; requires independent source response/shape verification')
  if m.type=='MULTIRES':d.update(levels=m.levels,render_levels=m.render_levels,total_levels=m.total_levels);nonlinear.append('Multires evaluated shape/normals are not preserved merely by exporting base mesh plus Skin')
  mods.append(d)
 weights=[sum(g.weight>0 for g in v.groups) for v in o.data.vertices]
 parts.append({'object':o.name,'source_vertices':len(o.data.vertices),'source_polygons':len(o.data.polygons),'uv_layers':[x.name for x in o.data.uv_layers],'max_author_influences':max(weights,default=0),'vertices_over8':sum(w>8 for w in weights),'shape_keys':list(o.data.shape_keys.key_blocks.keys()) if o.data.shape_keys else [],'modifiers':mods,'runtime_boundary':nonlinear or ['Armature/static path potentially exportable; actual constraints/attachments/bind/influences/normal preservation still must be verified'],'runtime_ready':False})
r={'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'source_scope':'grip3 editable complete actor; same original garment/face stacks as layer8, not claiming identical armor geometry or latest pose cache SHA','art_pass':False,'runtime_ready':False,'army_cache_per_actor_permitted':False,'parts':parts}
out.write_text(json.dumps(r,indent=2));print('RUNTIME_BOUNDARY',len(parts),[(p['object'],[m['type'] for m in p['modifiers']]) for p in parts if not p['object'].startswith(('Helmet','REBUILD'))],flush=True)
