"""Blender working preview only, explicitly not Godot evidence."""
import bpy,pathlib,sys
from mathutils import Vector
out=pathlib.Path(sys.argv[sys.argv.index('--')+1]);out.mkdir(parents=True,exist_ok=True)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False
scene.world=bpy.data.worlds.new('Working preview world');scene.world.color=(.28,.28,.28)
bpy.ops.object.light_add(type='AREA',location=(3,-4,5));bpy.context.object.data.energy=600;bpy.context.object.data.size=5
bpy.ops.object.camera_add(location=(2.5,-4,2));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.85))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.15;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
if '--clips' in sys.argv:
 rig=bpy.data.objects['MH163']
 for name,time in [('Idle_Loop',.125),('Walk_Loop',.4),('Sword_Attack',.7),('Death01',1.2)]:
  rig.animation_data.action=bpy.data.actions[name];scene.frame_set(round(time*scene.render.fps))
  scene.render.filepath=str(out/(name+'-blender-not-game.png'));bpy.ops.render.render(write_still=True)
else:
 scene.render.filepath=str(out/'natural-master-blender-not-game.png');bpy.ops.render.render(write_still=True)
