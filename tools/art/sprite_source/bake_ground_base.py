"""Derive the complete authored ground base, preserving its UV/attribute masks.
This is explicitly the hidden author BASE, not the film highres/render object.
"""
import bpy,json,pathlib,sys,math,hashlib,resource
from mathutils import Vector
source,survey_path,out=sys.argv[sys.argv.index('--')+1:];out=pathlib.Path(out);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(source,link=False) as (a,b):
 assert 'GEO-grove_ground.base' in a.objects
 b.objects=['GEO-grove_ground.base']
obj=b.objects[0];s=bpy.context.scene;s.collection.objects.link(obj)
assert obj.type=='MESH' and len(obj.modifiers)==0
source_hidden=obj.hide_render;obj.hide_render=False;obj.hide_viewport=False;obj.hide_select=False;obj.hide_set(False);obj.data=obj.data.copy()
bpy.context.view_layer.update()
source_uv={layer.name:[tuple(p.uv) for p in layer.data] for layer in obj.data.uv_layers}
attributes=[(a.name,a.data_type,a.domain) for a in obj.data.attributes]
assert 'ground_moss_mask' in source_uv and any(a[0]=='ground_blend' for a in attributes)
coords=[v.co.copy() for v in obj.data.vertices]
lo=Vector(tuple(min(v[i] for v in coords) for i in range(3)));hi=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
original_active_uv=obj.data.uv_layers.active.name
atlas=obj.data.uv_layers.new(name='GroundRuntimeAtlas');obj.data.uv_layers.active=atlas;atlas.active_render=True
for poly in obj.data.polygons:
 for li in poly.loop_indices:
  co=obj.data.vertices[obj.data.loops[li].vertex_index].co
  atlas.data[li].uv=((co.x-lo.x)/(hi.x-lo.x),(co.y-lo.y)/(hi.y-lo.y))
for slot in obj.material_slots:
 slot.material=slot.material.copy();node=slot.material.node_tree.nodes.new('ShaderNodeTexImage');slot.material.node_tree.nodes.active=node
s.render.engine='CYCLES';s.cycles.samples=8;s.cycles.use_denoising=False
s.render.resolution_x=1280;s.render.resolution_y=720;s.render.resolution_percentage=100
world=bpy.data.worlds.new('Ground_review_world');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[1].default_value=.6;s.world=world
sun_data=bpy.data.lights.new('Ground_sun','SUN');sun=bpy.data.objects.new('Ground_sun',sun_data);s.collection.objects.link(sun);sun.rotation_euler=(.4,-.6,-.4);sun_data.energy=2
camdata=bpy.data.cameras.new('Ground_native_compare');cam=bpy.data.objects.new('Ground_native_compare',camdata);s.collection.objects.link(cam);s.camera=cam;camdata.type='ORTHO'
def camera(center,span):
 cam.location=center+Vector((1,-1,1.6)).normalized()*span*2;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();camdata.ortho_scale=span*1.35
obj.data.uv_layers.active=obj.data.uv_layers[original_active_uv];obj.data.uv_layers[original_active_uv].active_render=True
bpy.context.view_layer.update()
camera(obj.matrix_world@((lo+hi)/2),max(hi-lo));s.render.image_settings.file_format='PNG';s.render.filepath=str(out/'native-hidden-base-NOT-GAME.png');bpy.ops.render.render(write_still=True)
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
s.render.bake.use_selected_to_active=False;s.render.bake.margin=4;s.render.bake.use_pass_direct=False;s.render.bake.use_pass_indirect=False;s.render.bake.use_pass_color=True
images={}
for kind in ['DIFFUSE','NORMAL','ROUGHNESS']:
 image=bpy.data.images.new('Ground_'+kind,width=2048,height=2048,alpha=False)
 if kind!='DIFFUSE':image.colorspace_settings.name='Non-Color'
 for slot in obj.material_slots:slot.material.node_tree.nodes.active.image=image
 bpy.ops.object.bake(type=kind,uv_layer='GroundRuntimeAtlas');image.filepath_raw=str(out/(kind.lower()+'.png'));image.file_format='PNG';image.save();images[kind]=image
# Preserve every source UV value, promote only the derived atlas to runtime UV0.
uv_data={layer.name:[tuple(p.uv) for p in layer.data] for layer in obj.data.uv_layers}
while obj.data.uv_layers:obj.data.uv_layers.remove(obj.data.uv_layers[0])
for name in ['GroundRuntimeAtlas']+[x for x in uv_data if x!='GroundRuntimeAtlas']:
 layer=obj.data.uv_layers.new(name=name)
 for p,value in zip(layer.data,uv_data[name]):p.uv=value
obj.data.uv_layers.active_index=0;obj.data.uv_layers[0].active_render=True
assert all(tuple(p.uv)==source_uv[name][i] for name in source_uv for i,p in enumerate(obj.data.uv_layers[name].data))
mat=bpy.data.materials.new('Derived_native_ground_PBR');mat.use_nodes=True;nodes=mat.node_tree.nodes;links=mat.node_tree.links
uv=nodes.new('ShaderNodeUVMap');uv.uv_map='GroundRuntimeAtlas';bsdf=nodes.get('Principled BSDF')
for kind,image in images.items():
 tex=nodes.new('ShaderNodeTexImage');tex.image=image;links.new(uv.outputs['UV'],tex.inputs['Vector'])
 if kind=='NORMAL':
  normal=nodes.new('ShaderNodeNormalMap');normal.uv_map='GroundRuntimeAtlas';links.new(tex.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])
 else:links.new(tex.outputs['Color'],bsdf.inputs['Base Color' if kind=='DIFFUSE' else 'Roughness'])
obj.data.materials.clear();obj.data.materials.append(mat)
for poly in obj.data.polygons:poly.material_index=0
survey=json.loads(pathlib.Path(survey_path).read_text())
def height(x,z):
 fx=max(0,min(survey['nx']-1-1e-7,(x-survey['x0'])/survey['step']));fz=max(0,min(survey['nz']-1-1e-7,(z-survey['z0'])/survey['step']))
 ix,iz=int(fx),int(fz);u,v=fx-ix,fz-iz;rows=survey['heights']
 return (rows[iz][ix]*(1-u)+rows[iz][ix+1]*u)*(1-v)+(rows[iz+1][ix]*(1-u)+rows[iz+1][ix+1]*u)*v
obj.location=(0,0,0);obj.rotation_euler=(0,0,0);obj.scale=(1,1,1)
for vertex,co in zip(obj.data.vertices,coords):
 u=(co.x-lo.x)/(hi.x-lo.x);v=(co.y-lo.y)/(hi.y-lo.y);x=29.6+17*u;z=24-48*v
 vertex.co=(x,-z,height(x,z))
obj.data.update();obj.name='AuthoredGroundApproach_DERIVED'
bpy.ops.export_scene.gltf(filepath=str(out/'ground-approach.glb'),export_format='GLB',use_selection=True,export_apply=False,export_texcoords=True,export_normals=True)
camera(Vector((38.1,0,0)),48);s.render.filepath=str(out/'retargeted-ground-NOT-GAME.png');bpy.ops.render.render(write_still=True)
report={'source_blend_sha256':hashlib.sha256(pathlib.Path(source).read_bytes()).hexdigest(),'source_object':'GEO-grove_ground.base','source_original_hide_render':source_hidden,'source_modifiers':0,'source_vertices':len(coords),'source_polygons':len(obj.data.polygons),'source_uv_layers':list(source_uv),'source_attributes':attributes,'original_uv_values_preserved':True,'ground_blend_retained_during_bake':True,'source_highres_loaded':False,'runtime_region_xz':[29.6,-24,46.6,24],'survey_sha256':hashlib.sha256(pathlib.Path(survey_path).read_bytes()).hexdigest(),'peak_rss_kib_linux':resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,'outputs_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.iterdir() if p.suffix in ('.png','.glb')},'limits':['Retargeted original base topology, not original film render/highres','Original terrain material masks retained; military road painting still to review','Source material normal, not high-to-low geometric normal bake','Godot actual graphics NOT_RUN','Not art acceptance']}
(out/'complete.json').write_text(json.dumps(report,indent=2));print('GROUND_COMPLETE',json.dumps(report))
