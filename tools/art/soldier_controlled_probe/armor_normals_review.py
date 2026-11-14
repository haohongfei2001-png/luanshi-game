"""Same-source LOD normal isolation, not a material/art acceptance render."""
import bpy,sys,pathlib,json,math
from mathutils import Vector
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False)
for o in list(bpy.data.objects):
 if o.type in {'LIGHT','CAMERA'}:bpy.data.objects.remove(o,do_unlink=True)
armor=[]
for o in bpy.context.scene.objects:
 if o.type!='MESH':continue
 for m in o.modifiers:
  if m.type=='BEVEL':m.show_render=False;m.show_viewport=False
  elif m.type=='MULTIRES':m.render_levels=1;m.levels=1
  elif m.type=='SUBSURF':m.render_levels=0;m.levels=0
 if o.name.startswith('REBUILD ') and any(x in o.name for x in ['lamellar','tasset','overlapping rows']):armor.append(o)
s=bpy.context.scene;s.use_nodes=False;s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.use_denoising=False;s.view_layers[0].material_override=None
s.world=bpy.data.worlds.new('Controlled LOD normal study');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=5
bpy.ops.object.camera_add(location=(2.5,-5,3.2));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.05))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.7;s.camera=cam;s.render.resolution_x=960;s.render.resolution_y=1100;s.render.resolution_percentage=100
for name,smooth in [('source-smooth-without-bevel',True),('explicit-flat-plate-caps',False)]:
 for o in armor:
  for p in o.data.polygons:p.use_smooth=smooth
  o.data.update()
 s.render.filepath=str(out/(name+'-BLENDER-NOT-GODOT.png'));bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps({'art_pass':False,'objects':[o.name for o in armor],'geometry_identical':True,'only_polygon_smoothing_changed':True,'normal_maps':False,'Blender_not_Godot':True},indent=2))
