"""Full uniform source-animation self-review. Blender evidence, NOT game/GPU QA."""
import bpy,sys,pathlib,json
from mathutils import Vector
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True);bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
rig=bpy.data.objects['MH163'];rig.data.pose_position='POSE';rig.animation_data_create();s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=24;s.use_nodes=False;s.render.resolution_x=700;s.render.resolution_y=900;s.render.resolution_percentage=100
s.world=bpy.data.worlds.new('Uniform neutral review');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.18,.18,.18,1)
for loc,power,size in [((3,-4,5),400,4),((-3,-1,3),200,3)]:
 bpy.ops.object.light_add(type='AREA',location=loc);bpy.context.object.data.energy=power;bpy.context.object.data.size=size
bpy.ops.object.camera_add(location=(2.4,-4,2.3));c=bpy.context.object;c.rotation_euler=(Vector((0,0,.8))-c.location).to_track_quat('-Z','Y').to_euler();c.data.type='ORTHO';c.data.ortho_scale=1.9;s.camera=c
records=[]
for name,t in [('Idle_Loop',.35),('Walk_Loop',.28),('Jog_Fwd_Loop',.4),('Hit_Chest',.45),('Death01',.8)]:
 a=bpy.data.actions[name];rig.animation_data.action=a;lo,hi=a.frame_range;s.frame_set(int(lo+(hi-lo)*t));bpy.context.view_layer.update();s.render.filepath=str(out/(name+'-NOT-GAME.png'));bpy.ops.render.render(write_still=True);records.append({'action':name,'frame':s.frame_current,'range':list(a.frame_range),'file':s.render.filepath})
(out/'source-action-review.json').write_text(json.dumps({'source':str(src.name),'renders':records,'godot':'NOT_RUN','acceptance':'REQUIRES_VISUAL_REVIEW'},indent=2)+'\n')
