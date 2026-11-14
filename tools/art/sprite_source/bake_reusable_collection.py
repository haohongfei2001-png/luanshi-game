"""Bake unique author geometry once, then reuse its atlas across native instances.
Derived experiment only; no source .blend is written. Blender --disable-autoexec.
"""
import bpy, pathlib, sys, math, json, hashlib, resource
from array import array
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];source,collection_name,out=args[:3]
out=pathlib.Path(out);out.mkdir(parents=True,exist_ok=True)
lod_policy=json.loads(pathlib.Path(args[3]).read_text()) if len(args)>3 else None
if lod_policy:
 assert 0<float(lod_policy['default_ratio'])<=1
 assert all(0<float(rule['ratio'])<=1 for rule in lod_policy['rules'])
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(source,link=False) as (a,b):
 assert collection_name in a.collections
 b.collections=[collection_name]
col=b.collections[0];s=bpy.context.scene;s.collection.children.link(col)
for c in list(bpy.data.collections):c.make_local()
for o in list(bpy.data.objects):o.make_local()
lod_edits=[]
for o in list(bpy.data.objects):
 if o.type!='MESH':continue
 name=o.name
 ratio=.04 if name.startswith('GEO-leaves-oak') else (.2 if name.startswith('GEO-branch.') else (.3 if name=='GEO-tree' else .15))
 if lod_policy:
  ratio=float(lod_policy['default_ratio'])
  for rule in lod_policy['rules']:
   if name.startswith(rule['prefix']):ratio=float(rule['ratio']);break
 mod=o.modifiers.new('DERIVED_STUDY_native_LOD','DECIMATE');mod.ratio=ratio;lod_edits.append({'name':name,'ratio':ratio})
s.render.use_simplify=True;s.render.simplify_subdivision=1;s.render.simplify_subdivision_render=1
s.render.engine='CYCLES';s.cycles.samples=8;s.cycles.use_denoising=False
s.render.resolution_x=768;s.render.resolution_y=768;s.render.resolution_percentage=100
def geometry_signature(mesh):
 h=hashlib.sha256()
 def field(data,name,width,code='f'):
  values=array(code,[0])*(len(data)*width);data.foreach_get(name,values);h.update(values.tobytes())
 field(mesh.vertices,'co',3);field(mesh.loops,'vertex_index',1,'i')
 for prop in ['loop_start','loop_total','material_index']:field(mesh.polygons,prop,1,'i')
 field(mesh.polygons,'use_smooth',1,'b')
 for layer in mesh.uv_layers:
  h.update(layer.name.encode());field(layer.data,'uv',2)
 formats={'FLOAT':('value',1,'f'),'INT':('value',1,'i'),'INT8':('value',1,'b'),'BOOLEAN':('value',1,'b'),'FLOAT_VECTOR':('vector',3,'f'),'FLOAT2':('vector',2,'f'),'FLOAT_COLOR':('color',4,'f'),'BYTE_COLOR':('color',4,'f'),'QUATERNION':('value',4,'f'),'FLOAT4X4':('value',16,'f')}
 for attr in mesh.attributes:
  if attr.name.startswith('.') or attr.data_type not in formats:continue
  h.update((attr.name+attr.domain+attr.data_type).encode());field(attr.data,*formats[attr.data_type])
 h.update(json.dumps([(m.name,m.library.filepath if m.library else None) if m else None for m in mesh.materials]).encode())
 return h.hexdigest()
# Snapshot before operator calls can invalidate the dependency graph. The
# original object NAME is not a geometry identity (GeometryNodes can vary it).
deps=bpy.context.evaluated_depsgraph_get();unique={};instances=[];bounds=[];triangles=0;name_signatures={}
for inst in deps.object_instances:
 o=inst.object
 if o.hide_render or not inst.show_self:continue
 if o.type in ['CURVE','CURVES','SURFACE','META','FONT','VOLUME','POINTCLOUD']:raise RuntimeError('UNCONVERTED_VISIBLE_GEOMETRY:'+o.name+':'+o.type)
 if o.type!='MESH':continue
 mesh=bpy.data.meshes.new_from_object(o,preserve_all_data_layers=True,depsgraph=deps)
 signature=geometry_signature(mesh);key=o.original.name+':'+signature
 name_signatures.setdefault(o.original.name,set()).add(signature)
 if key not in unique:
  unique[key]={'mesh':mesh,'matrix':inst.matrix_world.copy(),'triangles':sum(len(p.vertices)-2 for p in mesh.polygons)}
 else:bpy.data.meshes.remove(mesh)
 triangles+=unique[key]['triangles'];assert triangles<=1500000,'DERIVED_TRIANGLE_BUDGET_EXCEEDED'
 instances.append((key,inst.matrix_world.copy()));bounds.extend(inst.matrix_world@v.co for v in unique[key]['mesh'].vertices)
instance_counts={}
for key,matrix in instances:instance_counts[key]=instance_counts.get(key,0)+1
geometry_costs=sorted([{'source_geometry':k.split(':')[0],'instances':instance_counts[k],'triangles_each':v['triangles'],'total_triangles':instance_counts[k]*v['triangles']} for k,v in unique.items()],key=lambda x:-x['total_triangles'])
lo=Vector(tuple(min(v[i] for v in bounds) for i in range(3)));hi=Vector(tuple(max(v[i] for v in bounds) for i in range(3)))
col.hide_render=True
# Each source type gets its own tile; thousands of leaf instances share it.
n=math.ceil(math.sqrt(len(unique)));canonical=[]
for index,(key,entry) in enumerate(unique.items()):
 obj=bpy.data.objects.new('AtlasSource_'+key,entry['mesh']);s.collection.objects.link(obj)
 bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
 atlas=obj.data.uv_layers.new(name='LuanshiSharedAtlas');obj.data.uv_layers.active=atlas;atlas.active_render=True
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.151917,island_margin=.004);bpy.ops.object.mode_set(mode='OBJECT')
 # Edit-mode roundtrip may replace RNA layer storage; never retain its pointer.
 atlas=obj.data.uv_layers['LuanshiSharedAtlas']
 for loop in atlas.data:loop.uv=(loop.uv+Vector((index%n,index//n)))/n
 canonical.append(obj)
# Join copies for baking, preserving cached source meshes/UVs for all instances.
for obj,(key,entry) in zip(canonical,unique.items()):
 obj.data=obj.data.copy();obj.data.transform(entry['matrix'])
 if entry['matrix'].determinant()<0:obj.data.flip_normals()
bpy.ops.object.select_all(action='DESELECT')
for obj in canonical:obj.select_set(True)
bpy.context.view_layer.objects.active=canonical[0];bpy.ops.object.join();baker=bpy.context.object;baker.name='UniqueGeometryAtlasBaker'
for slot in baker.material_slots:
 if not slot.material:continue
 slot.material=slot.material.copy();nodes=slot.material.node_tree.nodes;links=slot.material.node_tree.links
 for group in list(nodes):
  if group.type!='GROUP' or not group.node_tree.name.startswith('SH-TwoSidedTransimission'):continue
  stable=nodes.new('ShaderNodeBsdfPrincipled')
  for a,b in [('Diffuse Color','Base Color'),('Roughness','Roughness'),('Normal','Normal')]:
   src=group.inputs[a];dst=stable.inputs[b]
   if src.is_linked:links.new(src.links[0].from_socket,dst)
   else:dst.default_value=src.default_value
  for node in nodes:
   if node.type=='OUTPUT_MATERIAL' and node.is_active_output:links.new(stable.outputs['BSDF'],node.inputs['Surface'])
 texture=nodes.new('ShaderNodeTexImage');nodes.active=texture
s.render.bake.use_selected_to_active=False;s.render.bake.margin=4
s.render.bake.use_pass_direct=False;s.render.bake.use_pass_indirect=False;s.render.bake.use_pass_color=True
images={}
for kind in ['DIFFUSE','NORMAL','ROUGHNESS']:
 image=bpy.data.images.new('Shared_'+kind,width=2048,height=2048,alpha=False)
 if kind!='DIFFUSE':image.colorspace_settings.name='Non-Color'
 for slot in baker.material_slots:
  if slot.material:slot.material.node_tree.nodes.active.image=image
 bpy.ops.object.bake(type=kind);image.filepath_raw=str(out/(kind.lower()+'.png'));image.file_format='PNG';image.save();images[kind]=image
baker.hide_render=True;baker.hide_set(True)
# Retain full author placement but collapse material surfaces/draw organization.
parts=[]
for key,matrix in instances:
 mesh=unique[key]['mesh'].copy();mesh.transform(matrix)
 if matrix.determinant()<0:mesh.flip_normals()
 obj=bpy.data.objects.new('Instance_'+key,mesh);s.collection.objects.link(obj);parts.append(obj)
# Do not mutate cached shared mesh data during join.
parts[0].data=parts[0].data.copy()
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:obj.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();target=bpy.context.object;target.name='Derived_'+collection_name
# Validate actual flattened world positions before any root offset/export.
actual=[target.matrix_world@v.co for v in target.data.vertices]
actual_lo=Vector(tuple(min(v[i] for v in actual) for i in range(3)));actual_hi=Vector(tuple(max(v[i] for v in actual) for i in range(3)))
assert max((actual_lo-lo).length,(actual_hi-hi).length)<.0001,'WORLD_GEOMETRY_BOUNDS_MISMATCH'
uv_data={layer.name:[tuple(loop.uv) for loop in layer.data] for layer in target.data.uv_layers}
while target.data.uv_layers:target.data.uv_layers.remove(target.data.uv_layers[0])
for name in ['LuanshiSharedAtlas']+[x for x in uv_data if x!='LuanshiSharedAtlas']:
 layer=target.data.uv_layers.new(name=name)
 for loop,value in zip(layer.data,uv_data[name]):loop.uv=value
assert all(tuple(loop.uv)==uv_data[name][i] for name in uv_data for i,loop in enumerate(target.data.uv_layers[name].data))
target.data.uv_layers.active_index=0;target.data.uv_layers[0].active_render=True
mat=bpy.data.materials.new('SharedNativeFamilyPBR');mat.use_nodes=True;nodes=mat.node_tree.nodes;links=mat.node_tree.links
uv=nodes.new('ShaderNodeUVMap');uv.uv_map='LuanshiSharedAtlas';bsdf=nodes.get('Principled BSDF')
for kind in images:
 tex=nodes.new('ShaderNodeTexImage');tex.image=images[kind];links.new(uv.outputs['UV'],tex.inputs['Vector'])
 if kind=='NORMAL':
  normal=nodes.new('ShaderNodeNormalMap');normal.uv_map='LuanshiSharedAtlas';links.new(tex.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])
 else:links.new(tex.outputs['Color'],bsdf.inputs['Base Color' if kind=='DIFFUSE' else 'Roughness'])
target.data.materials.clear();target.data.materials.append(mat)
for p in target.data.polygons:p.material_index=0
shift=Vector(col.instance_offset);target.location-=shift
center=(lo+hi)/2-shift;span=max(hi-lo)
camdata=bpy.data.cameras.new('NativeStructureCompare');cam=bpy.data.objects.new('NativeStructureCompare',camdata);s.collection.objects.link(cam)
cam.location=center+Vector((1,-1,.8)).normalized()*span*2;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=span*1.3;s.camera=cam
sun_data=bpy.data.lights.new('Review_sun','SUN');sun=bpy.data.objects.new('Review_sun',sun_data);s.collection.objects.link(sun);sun.rotation_euler=(.4,-.6,-.4);sun_data.energy=2
world=bpy.data.worlds.new('Review_world');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.4,.45,.5,1);world.node_tree.nodes['Background'].inputs[1].default_value=.6;s.world=world
bpy.ops.object.select_all(action='DESELECT');target.select_set(True);bpy.context.view_layer.objects.active=target
bpy.ops.export_scene.gltf(filepath=str(out/'derived.glb'),export_format='GLB',use_selection=True,export_apply=False,export_texcoords=True,export_normals=True)
s.render.image_settings.file_format='PNG';s.render.filepath=str(out/'derived-NOT-GAME.png');bpy.ops.render.render(write_still=True)
report={'source_blend_sha256':hashlib.sha256(pathlib.Path(source).read_bytes()).hexdigest(),'collection':collection_name,'triangles':triangles,'geometry_costs':geometry_costs,'source_instances':len(instances),'unique_source_geometry':len(unique),'geometry_signature_policy':'vertices/topology/smoothing/UV/attributes/material identity','same_name_geometry_variants':{k:len(v) for k,v in name_signatures.items() if len(v)>1},'atlas_size':2048,'atlas_grid':n,'original_uv_values_preserved':True,'material_surfaces':1,'lod_edits':lod_edits,'lod_policy':lod_policy,'author_origin_offset':list(shift),'source_world_min':list(lo),'source_world_max':list(hi),'derived_world_bounds_error':max((actual_lo-lo).length,(actual_hi-hi).length),'bounds_error_definition':'flattened mesh vs evaluated LOD instances; NOT original high-resolution fidelity','source_to_lod_geometric_error':'NOT_QUANTIFIED','peak_rss_kib_linux':resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,'outputs_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.iterdir() if p.suffix in ('.png','.glb')},'limits':['Source per-instance object/random variation is canonicalized by source type','Realtime transmission not implemented','Godot graphics and draw calls NOT_RUN','Not battlefield or art acceptance']}
(out/'complete.json').write_text(json.dumps(report,indent=2));print('REUSABLE_ATLAS_COMPLETE',json.dumps(report))
