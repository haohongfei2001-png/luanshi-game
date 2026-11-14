"""Offline source inspection; never game footage or visual acceptance."""
import bpy,sys,json,pathlib,math
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];source=pathlib.Path(args[0]);out=pathlib.Path(args[1]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source/'island_tree_01_2k.gltf'))
objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];rows=[];points=[]
for o in objects:
 o.data.calc_loop_triangles();rows.append({'name':o.name,'vertices':len(o.data.vertices),'triangles':len(o.data.loop_triangles),'materials':[m.name for m in o.data.materials]})
 points += [o.matrix_world@Vector(c) for c in o.bound_box]
lo=Vector([min(v[i] for v in points) for i in range(3)]);hi=Vector([max(v[i] for v in points) for i in range(3)]);center=(lo+hi)/2;size=hi-lo
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=False
scene.render.resolution_x=640;scene.render.resolution_y=768;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('NeutralSourceDiagnostic');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.24,.26,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
bpy.ops.object.light_add(type='AREA',location=center+Vector((4,-6,7)));bpy.context.object.data.energy=1100;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=5
bpy.context.object.rotation_euler=(center-bpy.context.object.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=center+Vector((8,-10,5)));cam=bpy.context.object;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=max(size.z,size.x)*1.4;scene.camera=cam
scene.view_settings.view_transform='Standard';scene.view_settings.look='Medium High Contrast' if 'Medium High Contrast' in [i.name for i in bpy.types.ColorManagedViewSettings.bl_rna.properties['look'].enum_items] else 'None'
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(out/'original-complete-tree-NOT-GAME.png')
(out/'source-geometry.json').write_text(json.dumps({'objects':rows,'triangles':sum(r['triangles'] for r in rows),'bounds':[list(lo),list(hi)],'actual_source_primitive_geometry':True,'gameplay':'NOT_RUN','art':'NOT_ACCEPTED','render':'offline neutral diagnostic only'},indent=2))
bpy.ops.render.render(write_still=True)
