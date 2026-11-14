import bpy,json,pathlib,sys,math,time,resource
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];source,collection_name,out=args[:3]
review_budget=int(args[3]) if len(args)>3 else 1500000
out=pathlib.Path(out);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(source,link=False) as (a,b):
 assert collection_name in a.collections, a.collections
 b.collections=[collection_name]
col=b.collections[0];bpy.context.scene.collection.children.link(col)
lod_study=len(args)>4 and args[4]=='lod-study'
lod_edits=[]
if lod_study:
 # Separate offline derivative only. Original .blend files stay immutable.
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
 if triangles>review_budget:raise RuntimeError('EVALUATED_TRIANGLE_BUDGET_EXCEEDED')
 bounds.extend(instance.matrix_world@Vector(c) for c in o.bound_box);o.to_mesh_clear()
lo=Vector(tuple(min(v[i] for v in bounds) for i in range(3)));hi=Vector(tuple(max(v[i] for v in bounds) for i in range(3)));center=(lo+hi)/2;span=max(hi-lo)
if len(args)>5:
 reference=json.loads(pathlib.Path(args[5]).read_text());cam_lo=Vector(reference['bounds_min']);cam_hi=Vector(reference['bounds_max']);center=(cam_lo+cam_hi)/2;span=max(cam_hi-cam_lo)
cam_data=bpy.data.cameras.new('Source_structure_review');cam=bpy.data.objects.new('Source_structure_review',cam_data);s.collection.objects.link(cam)
cam.location=center+Vector((1,-1,.8)).normalized()*span*2;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam_data.type='ORTHO';cam_data.ortho_scale=span*1.3;s.camera=cam
sun_data=bpy.data.lights.new('Review_sun','SUN');sun=bpy.data.objects.new('Review_sun',sun_data);s.collection.objects.link(sun);sun.rotation_euler=(.4,-.6,-.4);sun_data.energy=2
world=bpy.data.worlds.new('Neutral_review_world');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.4,.45,.5,1);world.node_tree.nodes['Background'].inputs[1].default_value=.6;s.world=world
report={'source':source,'collection':collection_name,'evaluated_triangles':triangles,'evaluated_mesh_instances':count,'bounds_min':list(lo),'bounds_max':list(hi),'subdivision_render_cap':1,'geometry_nodes':'RETAINED','source_materials':'RETAINED','game_visual':'NOT_RUN','film_lighting':'NOT_USED','lod_study':lod_study,'lod_edits':lod_edits}
(out/'report.json').write_text(json.dumps(report,indent=2));print('AUDIT',json.dumps(report),flush=True)
s.render.image_settings.file_format='PNG';s.render.filepath=str(out/'source-collection-NOT-GAME.png');bpy.ops.render.render(write_still=True)
# Do not pack or export before independently reviewing material conversion.

report["peak_rss_kib_linux"]=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
report["source_review_triangle_ceiling"]=review_budget
(out/"complete.json").write_text(json.dumps(report,indent=2))
