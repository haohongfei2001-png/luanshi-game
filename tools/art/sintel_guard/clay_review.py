"""Native source geometry review, material override only. Not game art or final source look."""
import bpy,pathlib,sys,json,hashlib
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];source,out=map(pathlib.Path,args[:2]);out.mkdir(parents=True,exist_ok=True);before=hashlib.sha256(source.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
pose_changes=[]
if len(args)>2 and args[2]=='--fk-probe':
 rig=bpy.data.objects['rig']
 for side,sign in [('L',1),('R',-1)]:
  ik=rig.pose.bones['hand_ik.'+side];ik['ik']=0.0
  for name,angle in [('upper_arm.',-.45*sign),('forearm.',.65*sign)]:
   bone=rig.pose.bones[name+side];bone.rotation_mode='XYZ';bone.rotation_euler[2]=angle
   pose_changes.append({'bone':bone.name,'local_z_radians':angle})
 bpy.context.view_layer.update()
scene=bpy.context.scene;scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False
scene.world=bpy.data.worlds.new('Geometry review world');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.22,.22,.22,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.4
mat=bpy.data.materials.new('Clay diagnostic not source material');mat.use_nodes=True;s=mat.node_tree.nodes.get('Principled BSDF');s.inputs['Base Color'].default_value=(.28,.34,.38,1);s.inputs['Roughness'].default_value=.8
scene.view_layers[0].material_override=mat
# Original mesh visibility, deformation, subdivision and multires remain untouched.
# Camera/light are independent review-only objects.
bpy.ops.object.light_add(type='AREA',location=(3,-4,5));bpy.context.object.data.energy=700;bpy.context.object.data.size=4
bpy.ops.object.camera_add(location=(3.5,-5,2.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.03))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.6;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
scene.render.filepath=str(out/'native-source-clay-not-game.png');bpy.ops.render.render(write_still=True)
cam.location=(2,-3,1.8);cam.rotation_euler=(Vector((0,-.12,1.45))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=1.25
scene.render.filepath=str(out/'native-torso-clay-not-game.png');bpy.ops.render.render(write_still=True)
assert hashlib.sha256(source.read_bytes()).hexdigest()==before
(out/'review.json').write_text(json.dumps({'source_sha256':before,'source_unchanged':True,'autoexec':False,'kind':'Blender native source clay geometry review','material_override':True,'mesh_modifiers_changed':False,'pose_changed':bool(pose_changes),'synthetic_fk_diagnostic':pose_changes,'game_art_pass':False},indent=2)+'\n')
