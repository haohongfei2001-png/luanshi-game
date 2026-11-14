"""Render every original 24fps authored pose: Blender diagnostic, NOT realtime Godot."""
import bpy,sys,pathlib,json
from mathutils import Vector
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
for o in list(bpy.data.objects):
 if o.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(o,do_unlink=True)
s=bpy.context.scene;s.use_nodes=False;s.render.engine='CYCLES';s.cycles.samples=8;s.cycles.use_denoising=False;s.view_layers[0].material_override=None
s.world=bpy.data.worlds.new('Whole hands authored motion');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=5
bpy.ops.object.camera_add(location=(3.5,-5,3.8));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.4,1.1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.5;s.camera=cam
s.render.resolution_x=640;s.render.resolution_y=720;s.render.resolution_percentage=100;s.render.fps=24
for i in range(37):
 s.frame_set(i);s.render.filepath=str(out/f'{i:04d}.png');bpy.ops.render.render(write_still=True)
(out/'timing.json').write_text(json.dumps({'kind':'Blender authored-time diagnostic, NOT real-time Godot','frames':37,'fps':24,'first_to_last_seconds':1.5,'interpolated_images':False,'art_pass':False})+'\n')
