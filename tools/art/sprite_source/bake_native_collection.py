import bpy,json,pathlib,sys,math,time,resource,hashlib
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];source,collection_name,out=args[:3]
out=pathlib.Path(out);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(source,link=False) as (a,b):
 assert collection_name in a.collections, a.collections
 b.collections=[collection_name]
col=b.collections[0];bpy.context.scene.collection.children.link(col)
lod_study=len(args)>3 and args[3]=='lod-study'
lod_edits=[]
if lod_study:
 for collection in list(bpy.data.collections):collection.make_local()
 for obj in list(bpy.data.objects):obj.make_local()
 for obj in list(bpy.data.objects):
  if obj.type!='MESH':continue
  name=obj.name
  ratio=.04 if name.startswith('GEO-leaves-oak') else (.2 if name.startswith('GEO-branch.') else (.3 if name=='GEO-tree' else .15))
  mod=obj.modifiers.new('EXPERIMENT_ONLY_native_index_LOD','DECIMATE');mod.ratio=ratio
  lod_edits.append({'object':name,'ratio':ratio})

s=bpy.context.scene;s.render.use_simplify=True;s.render.simplify_subdivision=1;s.render.simplify_subdivision_render=1
s.render.engine='CYCLES';s.cycles.samples=8;s.cycles.use_denoising=False
s.render.resolution_x=768;s.render.resolution_y=768;s.render.resolution_percentage=100
# Derivative rendering quality is explicit; source files are never saved.
deps=bpy.context.evaluated_depsgraph_get();bounds=[];triangles=0;count=0
for instance in deps.object_instances:
 o=instance.object
 if o.type!='MESH' or o.hide_render or not instance.show_self:continue
 mesh=o.to_mesh();triangles+=sum(len(p.vertices)-2 for p in mesh.polygons);count+=1
 if triangles>1500000:raise RuntimeError('EVALUATED_TRIANGLE_BUDGET_EXCEEDED')
 bounds.extend(instance.matrix_world@Vector(c) for c in o.bound_box);o.to_mesh_clear()
lo=Vector(tuple(min(v[i] for v in bounds) for i in range(3)));hi=Vector(tuple(max(v[i] for v in bounds) for i in range(3)));center=(lo+hi)/2;span=max(hi-lo)
cam_data=bpy.data.cameras.new('Source_structure_review');cam=bpy.data.objects.new('Source_structure_review',cam_data);s.collection.objects.link(cam)
cam.location=center+Vector((1,-1,.8)).normalized()*span*2;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam_data.type='ORTHO';cam_data.ortho_scale=span*1.3;s.camera=cam
sun_data=bpy.data.lights.new('Review_sun','SUN');sun=bpy.data.objects.new('Review_sun',sun_data);s.collection.objects.link(sun);sun.rotation_euler=(.4,-.6,-.4);sun_data.energy=2
world=bpy.data.worlds.new('Neutral_review_world');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.4,.45,.5,1);world.node_tree.nodes['Background'].inputs[1].default_value=.6;s.world=world
report={'source':source,'collection':collection_name,'evaluated_triangles':triangles,'evaluated_mesh_instances':count,'bounds_min':list(lo),'bounds_max':list(hi),'subdivision_render_cap':1,'geometry_nodes':'RETAINED','source_materials':'RETAINED','game_visual':'NOT_RUN','film_lighting':'NOT_USED','lod_study':lod_study,'lod_edits':lod_edits}
(out/'report.json').write_text(json.dumps(report,indent=2));print('AUDIT',json.dumps(report),flush=True)

# Derived mesh: realize only the admitted collection. Keep original source
# instances selected as bake rays; never rewrite their material graphs.
source_objects=list(col.all_objects)
realized=[]
for inst in deps.object_instances:
 if inst.object.type!='MESH' or inst.object.hide_render or not inst.show_self:continue
 mesh=bpy.data.meshes.new_from_object(inst.object,preserve_all_data_layers=True,depsgraph=deps)
 obj=bpy.data.objects.new('Derived_'+inst.object.name,mesh);s.collection.objects.link(obj);obj.matrix_world=inst.matrix_world.copy();realized.append(obj)
bpy.ops.object.select_all(action='DESELECT')
for obj in realized:obj.select_set(True)
bpy.context.view_layer.objects.active=realized[0];bpy.ops.object.join();target=bpy.context.object;target.name='Derived_complete_'+collection_name
# Original UV layers retained; add a distinct bake atlas rather than replacing.
original_uvs=[u.name for u in target.data.uv_layers]
atlas=target.data.uv_layers.new(name='Luanshi_BakeAtlas');target.data.uv_layers.active=atlas;atlas.active_render=True
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.151917,island_margin=.006);bpy.ops.object.mode_set(mode='OBJECT')
image=bpy.data.images.new('SourceDiffuseAtlas',width=1024,height=1024,alpha=False)
# Bake the visible derived surface with its original material slots. The
# source node trees are copied, not overwritten; no cage holes are permitted.
for slot in target.material_slots:
 source_mat=slot.material
 if not source_mat:continue
 slot.material=source_mat.copy();nodes=slot.material.node_tree.nodes
 # Original oak front/back closures deliberately turn the back face transparent.
 # A view-dependent diffuse pass therefore bakes black into valid leaf texels.
 # Bake the author's actual input color/normal/roughness, not that closure mask.
 for group in list(nodes):
  if group.type!='GROUP' or group.node_tree.name!='SH-TwoSidedTransimission':continue
  stable=nodes.new('ShaderNodeBsdfPrincipled');links=slot.material.node_tree.links
  for source_name,target_name in [('Diffuse Color','Base Color'),('Roughness','Roughness'),('Normal','Normal')]:
   inp=group.inputs[source_name];dst=stable.inputs[target_name]
   if inp.is_linked:links.new(inp.links[0].from_socket,dst)
   elif hasattr(inp,'default_value'):dst.default_value=inp.default_value
  for output in nodes:
   if output.type=='OUTPUT_MATERIAL' and output.is_active_output:links.new(stable.outputs['BSDF'],output.inputs['Surface'])
 texture=nodes.new('ShaderNodeTexImage');texture.image=image;nodes.active=texture
col.hide_render=True
bpy.ops.object.select_all(action='DESELECT');target.select_set(True);bpy.context.view_layer.objects.active=target
s.render.bake.use_selected_to_active=False;s.render.bake.margin=4
s.render.bake.use_pass_direct=False;s.render.bake.use_pass_indirect=False;s.render.bake.use_pass_color=True
bpy.ops.object.bake(type='DIFFUSE')
image.filepath_raw=str(out/'source-diffuse-atlas.png');image.file_format='PNG';image.save()
# Preserve source bump/tangent shading and roughness as separate maps.
normal_image=bpy.data.images.new('SourceNormalAtlas',width=1024,height=1024,alpha=False)
normal_image.colorspace_settings.name='Non-Color'
rough_image=bpy.data.images.new('SourceRoughnessAtlas',width=1024,height=1024,alpha=False)
rough_image.colorspace_settings.name='Non-Color'
for bake_type,baked in [('NORMAL',normal_image),('ROUGHNESS',rough_image)]:
 for slot in target.material_slots:
  if slot.material:slot.material.node_tree.nodes.active.image=baked
 bpy.ops.object.bake(type=bake_type)
 baked.filepath_raw=str(out/('source-'+bake_type.lower()+'-atlas.png'));baked.file_format='PNG';baked.save()
# Runtime UV0 is the atlas. Original source UV channels are kept after it,
# avoiding unsupported material-specific secondary UV interpretation in engines.
uv_data={layer.name:[tuple(loop.uv) for loop in layer.data] for layer in target.data.uv_layers}
while len(target.data.uv_layers):target.data.uv_layers.remove(target.data.uv_layers[0])
for name in ['Luanshi_BakeAtlas']+[k for k in uv_data if k!='Luanshi_BakeAtlas']:
 layer=target.data.uv_layers.new(name=name)
 for loop,value in zip(layer.data,uv_data[name]):loop.uv=value
assert all(tuple(loop.uv)==uv_data[name][i] for name in uv_data for i,loop in enumerate(target.data.uv_layers[name].data))
target.data.uv_layers.active=target.data.uv_layers['Luanshi_BakeAtlas'];target.data.uv_layers.active.active_render=True
material=bpy.data.materials.new('Derived_baked_source_diffuse');material.use_nodes=True
nodes=material.node_tree.nodes;tex=nodes.new('ShaderNodeTexImage');tex.image=image
uv=nodes.new('ShaderNodeUVMap');uv.uv_map='Luanshi_BakeAtlas';material.node_tree.links.new(uv.outputs['UV'],tex.inputs['Vector'])
bsdf=nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=.92
material.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
normal_tex=nodes.new('ShaderNodeTexImage');normal_tex.image=normal_image
material.node_tree.links.new(uv.outputs['UV'],normal_tex.inputs['Vector'])
normal_map=nodes.new('ShaderNodeNormalMap');normal_map.uv_map='Luanshi_BakeAtlas'
material.node_tree.links.new(normal_tex.outputs['Color'],normal_map.inputs['Color']);material.node_tree.links.new(normal_map.outputs['Normal'],bsdf.inputs['Normal'])
rough_tex=nodes.new('ShaderNodeTexImage');rough_tex.image=rough_image
material.node_tree.links.new(uv.outputs['UV'],rough_tex.inputs['Vector']);material.node_tree.links.new(rough_tex.outputs['Color'],bsdf.inputs['Roughness'])
target.data.materials.clear();target.data.materials.append(material)
for face in target.data.polygons:face.material_index=0
bpy.ops.object.select_all(action='DESELECT');target.select_set(True);bpy.context.view_layer.objects.active=target
# Put grounded instance origin at zero without touching evaluated mesh shape.
shift=Vector(col.instance_offset);target.location-=shift;cam.location-=shift
report['preserved_author_collection_offset']=list(shift)
report['grounding_policy']='author collection origin, not min-bound root lift'
report.update({'bake':'DIFFUSE_COLOR_VISIBLE_SURFACE_1024','bake_samples':8,'original_uv_layers':original_uvs,'derived_uv_layer':'Luanshi_BakeAtlas','normal_bake':'SOURCE_TANGENT_1024','roughness_bake':'SOURCE_ROUGHNESS_1024','runtime_uv0':'Luanshi_BakeAtlas','original_uv_values_preserved':True,'transmission_conversion':'SOURCE_COLOR_NORMAL_ROUGHNESS_INPUTS_EXTRACTED; realtime light transmission NOT_DONE','runtime_acceptance':'NOT_ACCEPTED','object_info_random':'joined source identity/object-space differ; must review','material_surfaces':1})
bpy.ops.export_scene.gltf(filepath=str(out/('derived-'+collection_name+'.glb')),export_format='GLB',use_selection=True,export_apply=False,export_texcoords=True,export_normals=True)
(out/'report.json').write_text(json.dumps(report,indent=2))
s.render.image_settings.file_format='PNG';s.render.filepath=str(out/('derived-'+collection_name+'-NOT-GAME.png'));bpy.ops.render.render(write_still=True)

report['peak_rss_kib_linux']=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
report['source_blend_sha256']=hashlib.sha256(pathlib.Path(source).read_bytes()).hexdigest()
report['outputs_sha256']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.iterdir() if p.suffix in ('.png','.glb')}
(out/'complete.json').write_text(json.dumps(report,indent=2))
