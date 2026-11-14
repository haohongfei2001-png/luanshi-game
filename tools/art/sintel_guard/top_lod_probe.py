"""Static whole-top LOD/bake diagnostic. NOT animated export or accepted garment.
Original rig/cage/source remain intact; derive separate evaluated copies only.
"""
import bpy,sys,pathlib,json,hashlib
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];src,out=map(pathlib.Path,args[:2]);out.mkdir(parents=True,exist_ok=True);sha=hashlib.sha256(src.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
source=bpy.data.objects['GEO-topLT'];mr=next(m for m in source.modifiers if m.type=='MULTIRES');original=mr.levels
copies=[]
for label,level in [('high',mr.render_levels),('low',1)]:
 mr.levels=level;bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();ev=source.evaluated_get(dg)
 mesh=bpy.data.meshes.new_from_object(ev,preserve_all_data_layers=True,depsgraph=dg);ob=bpy.data.objects.new('DERIVED_TOP_'+label,mesh);bpy.context.collection.objects.link(ob);ob.matrix_world=source.matrix_world.copy();mesh.calc_loop_triangles();copies.append(ob)
mr.levels=original
high,low=copies
for ob in bpy.context.scene.objects:
 if ob not in copies:ob.hide_render=True;ob.hide_set(True)
for ob in copies:ob.hide_set(False);ob.hide_render=False;ob.data.materials.clear()
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16
image=bpy.data.images.new('Whole_top_tangent_normal',width=1024,height=1024,alpha=False);image.colorspace_settings.name='Non-Color';image.filepath_raw=str(out/'whole-top-normal.png');image.file_format='PNG'
mat=bpy.data.materials.new('LOD normal bake target');mat.use_nodes=True;nodes=mat.node_tree.nodes;bs=nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.28,.34,.38,1);bs.inputs['Roughness'].default_value=.8
tex=nodes.new('ShaderNodeTexImage');tex.image=image;nodes.active=tex;low.data.materials.append(mat)
for ob in bpy.context.selected_objects:ob.select_set(False)
high.select_set(True);low.select_set(True);bpy.context.view_layer.objects.active=low
scene.render.bake.use_selected_to_active=True;scene.render.bake.cage_extrusion=.04;scene.render.bake.max_ray_distance=.08;scene.render.bake.margin=12
bpy.ops.object.bake(type='NORMAL');image.save()
n=nodes.new('ShaderNodeNormalMap');mat.node_tree.links.new(tex.outputs['Color'],n.inputs['Color']);mat.node_tree.links.new(n.outputs['Normal'],bs.inputs['Normal'])
highmat=bpy.data.materials.new('Source detail clay');highmat.use_nodes=True;h=highmat.node_tree.nodes.get('Principled BSDF');h.inputs['Base Color'].default_value=(.28,.34,.38,1);h.inputs['Roughness'].default_value=.8;high.data.materials.append(highmat)
scene.use_nodes=False;scene.world=bpy.data.worlds.new('LOD review world');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.3
bpy.ops.object.light_add(type='AREA',location=(2,-3,4));bpy.context.object.data.energy=500;bpy.context.object.data.size=3
bpy.ops.object.camera_add(location=(2,-3,2));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.02,1.5))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=1.6;scene.camera=cam
scene.render.resolution_x=1000;scene.render.resolution_y=700;scene.render.resolution_percentage=100
for label,obj in [('high',high),('low',low)]:
 high.hide_render=obj!=high;low.hide_render=obj!=low;scene.render.filepath=str(out/(label+'-close-not-game.png'));bpy.ops.render.render(write_still=True)
report={'source_sha256':sha,'source_unchanged':hashlib.sha256(src.read_bytes()).hexdigest()==sha,'source_modifiers_restored':mr.levels==original,'high_triangles':len(high.data.loop_triangles),'low_triangles':len(low.data.loop_triangles),'uv_layers':[u.name for u in low.data.uv_layers],'method':'complete original top subdiv level1 vs native Multires render4, tangent normal bake selected-to-active','normal_resolution':[1024,1024],'cage_extrusion_m':.04,'ray_distance_m':.08,'pose':'source rest only','animated_skin':'NOT_IMPLEMENTED','rig_changed':False,'godot_test':'NOT_RUN','art_pass':False}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(report,flush=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'whole-top-lod-diagnostic.blend'))
