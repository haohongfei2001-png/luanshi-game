"""Read-only two-source merge: complete uniform + same MH163 spear actions/weapon."""
import bpy,sys,json,hashlib
from pathlib import Path
from mathutils import Matrix
uniform,actions,out=map(Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
contract=json.loads((actions.parent/'action-contract.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(uniform),use_scripts=False,load_ui=False);rig=bpy.data.objects['MH163']
original_actions=[a.name for a in bpy.data.actions];bones_before={b.name:[list(x) for x in b.matrix_local] for b in rig.data.bones}
existing=set(bpy.data.objects)
with bpy.data.libraries.load(str(actions),link=False) as (data_from,data_to):
 data_to.actions=list(contract['new_actions']);data_to.objects=['Spear_Shaft','Spear_Blade_Draft']
for action in data_to.actions:action.use_fake_user=True
for obj in data_to.objects:
 bpy.context.scene.collection.objects.link(obj);obj.parent=rig;obj.parent_type='BONE';obj.parent_bone='wrist.R';obj.matrix_parent_inverse=Matrix.Identity(4);obj.matrix_basis=Matrix(contract['weapon_parent_local'][obj.name]);obj.hide_render=False;obj.hide_set(False)
for obj in list(bpy.data.objects):
 if obj not in existing and obj.type=='ARMATURE':bpy.data.objects.remove(obj,do_unlink=True)
for image in bpy.data.images:
 if image.filepath:image.filepath=bpy.path.abspath(image.filepath)
bpy.context.scene.render.fps=int(contract['fps']);bpy.context.scene.render.fps_base=1.0
rig.animation_data_create();rig.animation_data.action=bpy.data.actions['Spear_Idle_V2_DRAFT'];bpy.context.scene.frame_set(0)
assert bones_before=={b.name:[list(x) for x in b.matrix_local] for b in rig.data.bones}
assert all(x in bpy.data.actions for x in original_actions)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'uniform-spear-v2-editable.blend'))
(out/'merge-report.json').write_text(json.dumps({'uniform_source_sha256':hashlib.sha256(uniform.read_bytes()).hexdigest(),'action_source_sha256':hashlib.sha256(actions.read_bytes()).hexdigest(),'original_actions_retained':original_actions,'spear_actions_added':contract['new_actions'],'bone_rest_unchanged':True,'weapon_parent':'MH163/wrist.R','source_files_modified':False,'art_status':'WIP_NOT_ACCEPTED','native_gameplay':'NOT_RUN'},indent=2))
