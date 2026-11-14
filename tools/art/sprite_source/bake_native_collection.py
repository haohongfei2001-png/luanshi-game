import bpy,json,pathlib,sys,math,time,resource,hashlib
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];source,collection_name,out=args
out=pathlib.Path(out);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(source,link=False) as (a,b):
 assert collection_name in a.collections, a.collections
 b.collections=[collection_name]
col=b.collections[0];bpy.context.scene.collection.children.link(col)
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
report={'source':source,'collection':collection_name,'evaluated_triangles':triangles,'evaluated_mesh_instances':count,'bounds_min':list(lo),'bounds_max':list(hi),'subdivision_render_cap':1,'geometry_nodes':'RETAINED','source_materials':'RETAINED','game_visual':'NOT_RUN','film_lighting':'NOT_USED'}
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
bpy.context.view_layer.objects.active=realized[0];bpy.ops.object.join();target=bpy.context.object;target.name='Derived_complete_bush01'
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
 texture=nodes.new('ShaderNodeTexImage');texture.image=image;nodes.active=texture
col.hide_render=True
bpy.ops.object.select_all(action='DESELECT');target.select_set(True);bpy.context.view_layer.objects.active=target
s.render.bake.use_selected_to_active=False;s.render.bake.margin=4
s.render.bake.use_pass_direct=False;s.render.bake.use_pass_indirect=False;s.render.bake.use_pass_color=True
bpy.ops.object.bake(type='DIFFUSE')
image.filepath_raw=str(out/'source-diffuse-atlas.png');image.file_format='PNG';image.save()
material=bpy.data.materials.new('Derived_baked_source_diffuse');material.use_nodes=True
nodes=material.node_tree.nodes;tex=nodes.new('ShaderNodeTexImage');tex.image=image
uv=nodes.new('ShaderNodeUVMap');uv.uv_map='Luanshi_BakeAtlas';material.node_tree.links.new(uv.outputs['UV'],tex.inputs['Vector'])
bsdf=nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=.92
material.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
target.data.materials.clear();target.data.materials.append(material)
for face in target.data.polygons:face.material_index=0
bpy.ops.object.select_all(action='DESELECT');target.select_set(True);bpy.context.view_layer.objects.active=target
# Put grounded instance origin at zero without touching evaluated mesh shape.
shift=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z));target.location-=shift;cam.location-=shift
report.update({'bake':'DIFFUSE_COLOR_VISIBLE_SURFACE_1024','bake_samples':8,'original_uv_layers':original_uvs,'derived_uv_layer':'Luanshi_BakeAtlas','normal_bake':'NOT_DONE','transmission_conversion':'NOT_DONE','runtime_acceptance':'NOT_ACCEPTED','object_info_random':'joined source identity/object-space differ; must review','material_surfaces':1})
bpy.ops.export_scene.gltf(filepath=str(out/'derived-bush01.glb'),export_format='GLB',use_selection=True,export_apply=False,export_texcoords=True,export_normals=True)
(out/'report.json').write_text(json.dumps(report,indent=2))
s.render.image_settings.file_format='PNG';s.render.filepath=str(out/'derived-bush01-NOT-GAME.png');bpy.ops.render.render(write_still=True)

report['peak_rss_kib_linux']=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
report['source_blend_sha256']=hashlib.sha256(pathlib.Path(source).read_bytes()).hexdigest()
report['outputs_sha256']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.iterdir() if p.suffix in ('.png','.glb')}
(out/'complete.json').write_text(json.dumps(report,indent=2))
