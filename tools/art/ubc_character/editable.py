"""Import actual full-rig runtime prototype as an editable Blender scene, scripts disabled."""
import bpy,sys,pathlib
root=pathlib.Path(sys.argv[sys.argv.index('--')+1]).resolve()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps=120
bpy.ops.import_scene.gltf(filepath=str(root/'ubc_animated.glb'))
for text in list(bpy.data.texts):bpy.data.texts.remove(text)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(root/'source'/'ubc_animated_editable.blend'))
print('UBC_EDITABLE',[(o.name,o.type,len(o.data.bones) if o.type=='ARMATURE' else len(o.data.vertices) if o.type=='MESH' else 0) for o in bpy.context.scene.objects])
