"""Native-pixel authoring screen-scale review, explicitly NOT Godot/gameplay."""
import bpy,sys,pathlib,math,json,hashlib
from mathutils import Vector
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False)
for o in list(bpy.data.objects):
 if o.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(o,do_unlink=True)
s=bpy.context.scene;s.use_nodes=False;s.render.engine='CYCLES';s.cycles.samples=48;s.cycles.use_denoising=False;s.view_layers[0].material_override=None
s.world=bpy.data.worlds.new('MOBA scale neutral review');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.5
bpy.ops.object.light_add(type='AREA',location=(-4,-6,8));bpy.context.object.data.energy=900;bpy.context.object.data.size=5
bpy.ops.mesh.primitive_plane_add(size=40,location=(0,0,-.015));floor=bpy.context.object;floor.name='DIAGNOSTIC neutral ground not battlefield';m=bpy.data.materials.new('Neutral matte earth');m.diffuse_color=(.2,.19,.15,1);m.use_nodes=True;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.2,.19,.15,1);m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.95;floor.data.materials.append(m)
yaw=math.radians(25);pitch=math.radians(50);target=Vector((0,-.05,1.05));offset=Vector((math.sin(yaw)*math.cos(pitch),-math.cos(yaw)*math.cos(pitch),math.sin(pitch)))*20
bpy.ops.object.camera_add(location=target+offset);cam=bpy.context.object;cam.rotation_euler=(-offset).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=16;s.camera=cam
s.render.resolution_x=2560;s.render.resolution_y=1440;s.render.resolution_percentage=100;s.render.filepath=str(out/'native2k-moba-candidate-BLENDER-NOT-GODOT.png');bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps({'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'native_resolution':[2560,1440],'camera_orthographic_width_m':16,'pitch_deg':50,'yaw_deg':25,'actual_game_camera':False,'engine':'Blender Cycles CPU authoring','art_pass':False},indent=2)+'\n')
