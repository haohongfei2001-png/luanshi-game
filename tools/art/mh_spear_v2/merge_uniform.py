"""Read-only two-source merge: complete uniform + same MH163 spear actions/weapon."""
import bpy,sys,json,hashlib,os,runpy
from pathlib import Path
from mathutils import Matrix
args=sys.argv[sys.argv.index('--')+1:];uniform,actions,out=map(Path,args[:3]);runtime_only='--runtime-only' in args[3:];out.mkdir(parents=True,exist_ok=True)
contract=json.loads((actions.parent/'action-contract.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(uniform),use_scripts=False,load_ui=False);rig=bpy.data.objects['MH163']
original_actions=[a.name for a in bpy.data.actions];bones_before={b.name:[list(x) for x in b.matrix_local] for b in rig.data.bones}
existing=set(bpy.data.objects)
with bpy.data.libraries.load(str(actions),link=False) as (data_from,data_to):
 data_to.actions=[name for name in contract['new_actions'] if name not in bpy.data.actions];data_to.objects=['Spear_Shaft','Spear_Blade_Draft']
for action in data_to.actions:action.use_fake_user=True
for obj in data_to.objects:
 bpy.context.scene.collection.objects.link(obj);obj.parent=rig;obj.parent_type='BONE';obj.parent_bone='wrist.R';obj.matrix_parent_inverse=Matrix.Identity(4);obj.matrix_basis=Matrix(contract['weapon_parent_local'][obj.name]);obj.hide_render=False;obj.hide_set(False)
 if obj.name=='Spear_Shaft' and not any(m.type=='TRIANGULATE' for m in obj.modifiers):obj.modifiers.new('TriangulateCapsForTangents','TRIANGULATE')
for obj in list(bpy.data.objects):
 if obj not in existing and obj.type=='ARMATURE':
  assert set(obj.data.bones.keys())==set(rig.data.bones.keys()), 'Different source skeleton requires explicit retarget'
  assert all(max(abs(x-y) for ra,rb in zip(obj.data.bones[n].matrix_local,rig.data.bones[n].matrix_local) for x,y in zip(ra,rb))<1e-6 for n in rig.data.bones.keys()), 'Rest skeleton mismatch'
  bpy.data.objects.remove(obj,do_unlink=True)
# Object append can pull the source rig's active Action as an orphan .001.
for action in list(bpy.data.actions):
 if action.name not in original_actions and action.name not in contract['new_actions']:
  assert action.name.rsplit('.',1)[0] in contract['new_actions'], 'Unexpected extra action dependency'
  bpy.data.actions.remove(action)
for image in bpy.data.images:
 if image.filepath:image.filepath=bpy.path.abspath(image.filepath)
bpy.context.scene.render.fps=int(contract['fps']);bpy.context.scene.render.fps_base=1.0
rig.animation_data_create();rig.animation_data.action=bpy.data.actions['Spear_Idle_V2_DRAFT'];bpy.context.scene.frame_set(0)
assert bones_before=={b.name:[list(x) for x in b.matrix_local] for b in rig.data.bones}
assert all(x in bpy.data.actions for x in original_actions)
if not runtime_only:bpy.ops.wm.save_as_mainfile(filepath=str(out/'uniform-spear-v2-editable.blend'))
(out/'merge-report.json').write_text(json.dumps({'uniform_source_sha256':hashlib.sha256(uniform.read_bytes()).hexdigest(),'action_source_sha256':hashlib.sha256(actions.read_bytes()).hexdigest(),'original_actions_retained':original_actions,'spear_actions_added':contract['new_actions'],'bone_rest_unchanged':True,'weapon_parent':'MH163/wrist.R','source_files_modified':False,'art_status':'WIP_NOT_ACCEPTED','native_gameplay':'NOT_RUN'},indent=2))

if runtime_only:
 os.environ['LUANSHI_USE_LOADED_SCENE']='1'
 sys.argv=['export_complete.py','--',str(uniform),str(out/'runtime-verified')]
 runpy.run_path(str(Path(__file__).with_name('export_complete.py')),run_name='__main__')
