"""Fixed 32-degree whole-character normal-pixel source review, not game evidence."""
import bpy,sys,pathlib,json,math
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True);bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
rig=bpy.data.objects['MH163'];rig.data.pose_position='POSE';rig.animation_data_create();s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=32;s.use_nodes=False;s.render.resolution_x=512;s.render.resolution_y=512;s.render.resolution_percentage=100
s.world=bpy.data.worlds.new('Normal pixel review');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.18,.18,.18,1)
for loc,power,size in [((3,-4,5),400,4),((-3,-1,3),200,3)]:
 bpy.ops.object.light_add(type='AREA',location=loc);bpy.context.object.data.energy=power;bpy.context.object.data.size=size
look=Vector((0,0,.8));bpy.ops.object.camera_add(location=look+Vector((3,-4,5*math.tan(math.radians(32)))));c=bpy.context.object;c.rotation_euler=(look-c.location).to_track_quat('-Z','Y').to_euler();c.data.type='ORTHO';c.data.ortho_scale=4.0;s.camera=c
records=[]
for name,t in [('Idle_Loop',.35),('Walk_Loop',.28)]:
 a=bpy.data.actions[name];rig.animation_data.action=a;lo,hi=a.frame_range;s.frame_set(int(lo+(hi-lo)*t));bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();ys=[]
 for o in bpy.context.scene.objects:
  if o.type=='MESH' and not o.hide_render:
   ev=o.evaluated_get(dg);m=ev.to_mesh()
   ys.extend(world_to_camera_view(s,c,ev.matrix_world@v.co).y for v in m.vertices);ev.to_mesh_clear()
 s.render.filepath=str(out/(name+'-180px-NOT-GAME.png'));bpy.ops.render.render(write_still=True);records.append({'action':name,'frame':s.frame_current,'projected_geometry_height_px':(max(ys)-min(ys))*512,'file':pathlib.Path(s.render.filepath).name})
(out/'normal-pixel-review.json').write_text(json.dumps({'source_fps':s.render.fps,'view':'fixed orthographic, 32-degree downward pitch','resolution':[512,512],'ortho_scale':4.0,'nominal_body_target_px':180,'records':records,'actual_game':False,'art_accepted':False},indent=2)+'\n')
