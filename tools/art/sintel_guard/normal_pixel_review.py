"""Native 2K normal actor screen-scale authoring review; NOT Godot or owner PASS."""
import bpy,sys,pathlib,math,json
from mathutils import Vector
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True);bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
for o in list(bpy.data.objects):
 if o.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(o,do_unlink=True)
s=bpy.context.scene;s.use_nodes=False;s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.use_denoising=False;s.view_layers[0].material_override=None;s.world=bpy.data.worlds.new('Native pixel authoring review');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=5
pitch=math.radians(32);yaw=math.radians(-65);fov=math.radians(55);fraction=.10;depth=.55*abs(math.sin(yaw))+.35*abs(math.cos(yaw));span=1.8*math.cos(pitch)+depth*math.sin(pitch);distance=span/(2*math.tan(fov/2)*fraction);target=Vector((4,0,.8));position=target+Vector((math.sin(yaw)*math.cos(pitch),-math.cos(yaw)*math.cos(pitch),math.sin(pitch)))*distance
bpy.ops.object.camera_add(location=position);cam=bpy.context.object;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='PERSP';cam.data.sensor_fit='VERTICAL';cam.data.angle=fov;s.camera=cam;s.render.resolution_x=2560;s.render.resolution_y=1440;s.render.resolution_percentage=100;s.render.filepath=str(out/'normal-native2K-BLENDER-NOT-GODOT.png');bpy.ops.render.render(write_still=True)
(out/'camera.json').write_text(json.dumps({'renderer':'Blender Cycles authoring diagnostic','projection':'perspective','pitch_degrees':32,'yaw_degrees':-65,'vertical_fov_degrees':55,'nominal_fraction':fraction,'actual_camera_position':list(position),'target':list(target),'native_resolution':[2560,1440],'owner_camera_final':False,'art_pass':False},indent=2)+'\n')
