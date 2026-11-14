"""Independent layer8 derivative: original Eyes alpha only; source is not CI b0a4."""
import bpy,sys,pathlib,hashlib,json
src,dest=sys.argv[sys.argv.index('--')+1:];src=pathlib.Path(src);dest=pathlib.Path(dest);dest.parent.mkdir(parents=True,exist_ok=True)
assert hashlib.sha256(src.read_bytes()).hexdigest()=='56f64a46051e75c84630d372d9a19f6b800706ba2d98bc6a010851e576ff55f7'
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False)
changed=[]
for eye in [o for o in bpy.data.objects if o.type=='MESH' and o.name=='Eyes']:
 for mat in eye.data.materials:
  bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');tex=bs.inputs['Base Color'].links[0].from_node
  assert tex.type=='TEX_IMAGE' and tex.image.channels==4
  mat.node_tree.links.new(tex.outputs['Alpha'],bs.inputs['Alpha']);mat.surface_render_method='DITHERED';changed.append(mat.name)
assert changed
bpy.ops.wm.save_as_mainfile(filepath=str(dest))
(dest.parent/'source-recovery.json').write_text(json.dumps({'input_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'output_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'operation':'945b original Eyes RGBA alpha restoration on separately retained layer8; no geometry/rest/weight edits','materials':changed,'same_bytes_as_CI_mother':False,'art_pass':False},indent=2)+'\n')
