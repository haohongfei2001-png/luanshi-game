"""Evaluated full-actor authoring oracle for one Godot visual probe, not crowd skinning."""
import bpy,numpy as np,json,sys,pathlib,hashlib,shutil
from mathutils import Matrix
walk,thrust,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:3]);out.mkdir(parents=True,exist_ok=True)
C=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))
meta={'kind':'single-actor evaluated source cache, NOT runtime crowd architecture','default_enabled':False,'art_pass':False,'materials_equivalent_to_blender':False,'clips':[],'meshes':[],'frames':[],'source_files':{},'limitations':['Diffuse/roughness/metal only; no source SSS/transmission equivalence','No claim of foot contact, exact grip, terrain clearance or art acceptance','All mesh positions evaluated from author rig, not 471 CPU skeletons per crowd actor','No normal maps in this probe; no false rest-tangent lighting','Indexed seam-preserving vertices: exact UV/position, all70 poses assert corner normal merge error below2e-5','Derived Multires1/Subsurf0/no post-skin Bevel LOD, complete masters retained; new thin plate caps use explicit flat normals instead of smoothing across sidewalls']}
records={};names=None;frame_index=0
for clip,source,samples in [('walk',walk,33),('thrust',thrust,37)]:
 meta['source_files'][clip]={'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'bytes':source.stat().st_size}
 bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False);scene=bpy.context.scene
 meshes=sorted([o for o in scene.objects if o.type=='MESH' and o.visible_get() and not o.hide_render],key=lambda o:o.name)
 if names is None:names=[o.name for o in meshes]
 assert names==[o.name for o in meshes], 'Source clips changed visible geometry identity'
 for o in meshes:
  # Bevel-free LOD must not smooth thin cap normals with its sidewalls.
  # These newly authored plate faces are flat metal, not inflated pillows.
  if o.name.startswith('REBUILD ') and any(x in o.name for x in ['lamellar','tasset','overlapping rows']):
   for face in o.data.polygons:face.use_smooth=False
   o.data.update()
  for m in o.modifiers:
   if m.type=='MULTIRES':m.levels=1
   elif m.type=='SUBSURF':m.levels=0
   elif m.type=='BEVEL':m.show_viewport=False # posed overlap clamp changes topology; explicit derived LOD only
   elif m.type=='PARTICLE_SYSTEM':m.show_viewport=False
 armatures={o.name:{'bones':len(o.data.bones),'deform_bones':sum(b.use_deform for b in o.data.bones)} for o in scene.objects if o.type=='ARMATURE' and o.name in ['rig','MH163']}
 meta.setdefault('source_author_rigs',armatures);assert meta['source_author_rigs']==armatures
 action=bpy.data.objects['rig'].animation_data.action;first,last=map(float,action.frame_range);duration=(last-first)/scene.render.fps
 meta['clips'].append({'name':clip,'first_frame':frame_index,'frames':samples,'duration_seconds':duration,'source_action':action.name})
 for si in range(samples):
  f=first+(last-first)*si/(samples-1);scene.frame_set(int(f),subframe=f%1);bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();footmin={'L':None,'R':None}
  for k,o in enumerate(meshes):
   ev=o.evaluated_get(dg);me=ev.to_mesh();me.calc_loop_triangles();ids=np.array([l.vertex_index for l in me.loops],dtype=np.int32);world=C@ev.matrix_world;normalworld=world.to_3x3().inverted().transposed()
   p=np.array([tuple(world@v.co) for v in me.vertices],dtype=np.float32);pos=p[ids];normal=np.array([tuple((normalworld@n.vector).normalized()) for n in me.corner_normals],dtype=np.float32)
   if 'bootsLT' in o.name:
    for v,point in zip(me.vertices,p):
     sums={s:sum(g.weight for g in v.groups if o.vertex_groups[g.group].name.endswith('.'+s)) for s in ['L','R']};side=max(sums,key=sums.get)
     if sums[side]>.5:footmin[side]=float(point[1]) if footmin[side] is None else min(footmin[side],float(point[1]))
   if frame_index==0:
    uv=[list(x.uv) for x in me.uv_layers.active.data] if me.uv_layers.active else [[0,0]]*len(ids)
    unique={};representatives=[];remap=[]
    for li,vi in enumerate(ids):
     key=(int(vi),*uv[li],*np.round(normal[li],6))
     if key not in unique:unique[key]=len(representatives);representatives.append(li)
     remap.append(unique[key])
    representatives=np.array(representatives,dtype=np.int32);remap=np.array(remap,dtype=np.int32)
    surfaces=[]
    for mi in sorted({p.material_index for p in me.polygons}):
     mat=o.data.materials[mi] if mi<len(o.data.materials) else None;entry={'color':[.4,.4,.4,1],'roughness':.8,'metallic':0,'alpha_texture':False}
     if mat and mat.use_nodes:
      bs=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
      if bs:
       entry.update(color=list(bs.inputs['Base Color'].default_value),roughness=float(bs.inputs['Roughness'].default_value),metallic=float(bs.inputs['Metallic'].default_value),alpha_texture=bs.inputs['Alpha'].is_linked)
       links=list(bs.inputs['Base Color'].links)
       if links and links[0].from_node.type=='TEX_IMAGE':
        im=links[0].from_node.image;dest=f'material-{k}-{mi}.png';path=pathlib.Path(bpy.path.abspath(im.filepath,library=im.library))
        if im.packed_file:(out/dest).write_bytes(im.packed_file.data)
        elif path.is_file():shutil.copy2(path,out/dest)
        else:raise FileNotFoundError(im.filepath)
        entry['texture']=dest;entry['color']=[1,1,1,1] # linked image replaces BSDF default, not multiplies it
     entry['indices']=[int(remap[i]) for tri in me.loop_triangles if me.polygons[tri.polygon_index].material_index==mi for i in [tri.loops[0],tri.loops[2],tri.loops[1]]];surfaces.append(entry)
    meta['meshes'].append({'name':o.name,'vertices':len(representatives),'source_loops':len(ids),'uv':[uv[i] for i in representatives],'surfaces':surfaces,'positions':f'mesh-{k}-positions.rgba32f','normals':f'mesh-{k}-normals.rgba32f'})
    records[k]={'ids':ids.copy(),'representatives':representatives,'remap':remap,'pos':[],'normal':[]}
   assert np.array_equal(records[k]['ids'],ids) and np.isfinite(pos).all() and np.isfinite(normal).all(),o.name
   reps=records[k]['representatives'];remap=records[k]['remap']
   assert np.max(np.abs(normal-normal[reps][remap]))<2e-5, 'Animated hard-edge normals cannot merge '+o.name
   assert np.array_equal(pos,pos[reps][remap]), 'Position split cannot merge'
   pos=pos[reps];normal=normal[reps]
   records[k]['pos'].append(np.column_stack((pos,np.ones(len(pos),dtype=np.float32))).astype('<f4'));records[k]['normal'].append(np.column_stack((normal,np.ones(len(pos),dtype=np.float32))).astype('<f4'));ev.to_mesh_clear()
  meta['frames'].append({'clip':clip,'source_frame':f,'flat_diagnostic_boot_surface_min_y':footmin})
  frame_index+=1
  if si%8==0:print('COMPLETE_ACTOR_SAMPLE',clip,si,flush=True)
for k,r in records.items():
 np.stack(r['pos']).tofile(out/meta['meshes'][k]['positions']);np.stack(r['normal']).tofile(out/meta['meshes'][k]['normals'])
meta['cache_bytes']=sum(p.stat().st_size for p in out.glob('*.rgba32f'));meta['vertices']=sum(m['vertices'] for m in meta['meshes']);meta['triangles']=sum(len(s['indices'])//3 for m in meta['meshes'] for s in m['surfaces'])
(out/'character.json').write_text(json.dumps(meta,separators=(',',':'))+'\n');print('CACHE_DONE',meta['cache_bytes'],meta['vertices'],meta['triangles'],flush=True)
