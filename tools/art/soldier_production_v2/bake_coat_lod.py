"""Bake real complete-coat surface relief onto skinned LOD. No synthetic noise."""
import bpy,sys,pathlib,json
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
high=bpy.data.objects['V2_complete_coat_fit'];low=high.copy();low.data=high.data.copy();low.name='V2_complete_coat_runtime';bpy.context.collection.objects.link(low)
for ob in bpy.context.selected_objects:ob.select_set(False)
low.select_set(True);bpy.context.view_layer.objects.active=low
# Decimation operates before skin. Keep source and all its UV/folds separately.
arm=next(m for m in low.modifiers if m.type=='ARMATURE');low.modifiers.remove(arm)
d=low.modifiers.new('Runtime complete garment LOD','DECIMATE');d.ratio=.15;bpy.ops.object.modifier_apply(modifier=d.name)
for ob in [high,low]:ob.hide_set(False);ob.hide_render=False
im=bpy.data.images.new('Professional complete coat tangent relief',width=2048,height=2048,alpha=False);im.colorspace_settings.name='Non-Color';im.filepath_raw=str(out/'coat-normal.png');im.file_format='PNG'
m=bpy.data.materials.new('V2 matte indigo source-fold cloth');m.use_nodes=True;bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.10,.17,.21,1);bs.inputs['Roughness'].default_value=.82
tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im;m.node_tree.nodes.active=tex;low.data.materials.clear();low.data.materials.append(m)
for p in low.data.polygons:p.material_index=0
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=8;s.render.bake.use_selected_to_active=True;s.render.bake.cage_extrusion=.012;s.render.bake.max_ray_distance=.04;s.render.bake.margin=16
for ob in bpy.context.selected_objects:ob.select_set(False)
high.select_set(True);low.select_set(True);bpy.context.view_layer.objects.active=low
bpy.ops.object.bake(type='NORMAL');im.save()
n=m.node_tree.nodes.new('ShaderNodeNormalMap');m.node_tree.links.new(tex.outputs['Color'],n.inputs['Color']);m.node_tree.links.new(n.outputs['Normal'],bs.inputs['Normal'])
a=low.modifiers.new('Shared MH163 skin','ARMATURE');a.object=bpy.data.objects['MH163'];high.hide_render=True;high.hide_set(True)
low.data.calc_loop_triangles();high.data.calc_loop_triangles()
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(out/'natural-full-coat-lod.blend'))
(out/'lod-report.json').write_text(json.dumps({'high_triangles':len(high.data.loop_triangles),'runtime_coat_triangles':len(low.data.loop_triangles),'source_uv_preserved':True,'normal_space':'tangent OpenGL +Y','normal_origin':'actual fitted complete professional coat geometry','texture_resolution':[2048,2048],'skin':'MH163 existing full influences interpolated by decimator; motion NOT_VALIDATED','visual_acceptance':False,'godot':'NOT_RUN'},indent=2)+'\n')
