"""Offline structure inspection only. Never label this as gameplay evidence."""
import bpy,sys,math
from pathlib import Path
from mathutils import Vector
source,output=map(Path,sys.argv[sys.argv.index('--')+1:]);bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
scene=bpy.context.scene
world=bpy.data.worlds.new('Neutral structural inspection');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.45,.48,.52,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7;scene.world=world
sun=bpy.data.objects.new('Structure review key',bpy.data.lights.new('Structure review key','SUN'));scene.collection.objects.link(sun);sun.data.energy=3.;sun.rotation_euler=(.4,-.65,-.5)
camera=bpy.data.objects.new('Structure review camera',bpy.data.cameras.new('Structure review camera'));scene.collection.objects.link(camera);scene.camera=camera
camera.location=(32,-12,9);target=Vector((48.2,0,3.4));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=13.8
scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=False;scene.render.resolution_x=900;scene.render.resolution_y=900;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.filepath=str(output);bpy.ops.render.render(write_still=True)
print('OFFLINE_PORTAL_STRUCTURE_PREVIEW_NOT_GAME')
