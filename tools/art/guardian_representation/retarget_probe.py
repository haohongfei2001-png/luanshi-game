"""Rest-aware UAL motion on intact Guardian controls. Experimental, no shipping.
No source bone/rest/weight edits. Original rig evaluates all 308 controls/79 deform bones.
"""
import bpy,pathlib,sys,json,hashlib,math,numpy as np
from mathutils import Matrix,Vector
args=sys.argv[sys.argv.index('--')+1:];source,ual,out=map(pathlib.Path,args[:3]);out.mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();before=sha(source)
bpy.ops.wm.open_mainfile(filepath=str(source),use_scripts=False,load_ui=False);target=bpy.data.objects['rig']
# Keep author rig/rest, constraints, all mesh modifiers and weights untouched.
bpy.ops.import_scene.gltf(filepath=str(ual));donor=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE' and o!=target)
for o in [donor,*donor.children_recursive]:o.hide_render=True
for track in donor.animation_data.nla_tracks:track.mute=True
source_rest={b.name:b.matrix_local.copy() for b in donor.data.bones};target_rest={b.name:b.matrix_local.copy() for b in target.data.bones}
leg_source=sum(donor.data.bones[n].length for n in ['thigh_l','calf_l']);leg_target=sum(target.data.bones[n].length for n in ['thigh.L','shin.L']);ratio=leg_target/leg_source
# Anatomical limb lengths, not arbitrary copied source translations.
rot_map=[('spine_01','torso'),('neck_01','neck'),('Head','head'),('upperarm_l','upper_arm.L'),('lowerarm_l','forearm.L'),('hand_l','hand.L'),('upperarm_r','upper_arm.R'),('lowerarm_r','forearm.R'),('hand_r','hand.R')]
rot_map=[(s,t) for s,t in rot_map if s in donor.pose.bones and t in target.pose.bones]
for side in ['L','R']:
 target.pose.bones['hand_ik.'+side]['ik']=0.
 target.pose.bones['foot_ik.'+side]['ik']=1.
# Rotation transfer uses source global rest delta and target rest axes. Parent
# pose and Blender inherit transforms are explicitly inverted; local location
# is not copied from the different-proportioned donor.
def set_rotation(name,desired):
 p=target.pose.bones[name];parent=p.parent
 local=p.bone.convert_local_to_pose(desired,p.bone.matrix_local,parent_matrix=parent.matrix if parent else Matrix.Identity(4),parent_matrix_local=parent.bone.matrix_local if parent else Matrix.Identity(4),invert=True)
 p.rotation_mode='QUATERNION';p.rotation_quaternion=local.to_quaternion();bpy.context.view_layer.update()
rows=[];poses=[]
for clip in ['Idle_Loop','Walk_Loop']:
 action=next((a for a in bpy.data.actions if a.name==clip+'_Armature'),None)
 if action is None:raise RuntimeError('Missing exact source action '+clip)
 donor.animation_data.action=action;length=float(action.frame_range[1]-action.frame_range[0]);cliprows=[]
 for i in range(25):
  frame=length*i/24.;bpy.context.scene.frame_set(int(frame),subframe=frame-int(frame))
  for p in target.pose.bones:p.matrix_basis=Matrix.Identity(4)
  for side in ['L','R']:target.pose.bones['hand_ik.'+side]['ik']=0.;target.pose.bones['foot_ik.'+side]['ik']=1.
  bpy.context.view_layer.update()
  for s,t in rot_map:
   desired=(donor.pose.bones[s].matrix.to_quaternion()@source_rest[s].to_quaternion().inverted()).to_matrix().to_4x4()@target_rest[t]
   set_rotation(t,desired)
  hip_delta=donor.pose.bones['pelvis'].matrix.translation-source_rest['pelvis'].translation
  target.pose.bones['torso'].location=target_rest['torso'].to_3x3().inverted()@(hip_delta*ratio)
  for side,small in [('L','l'),('R','r')]:
   s='foot_'+small;t='foot_ik.'+side
   rest=target_rest[t];delta=donor.pose.bones[s].matrix.translation-source_rest[s].translation
   q=donor.pose.bones[s].matrix.to_quaternion()@source_rest[s].to_quaternion().inverted()@rest.to_quaternion()
   desired=q.to_matrix().to_4x4();desired.translation=rest.translation+delta*ratio;target.pose.bones[t].matrix=desired
  bpy.context.view_layer.update()
  record={'clip':clip,'phase':i/24.,'source_frame':frame,'feet':{s:list(target.pose.bones['DEF-foot.'+s].head) for s in ['L','R']},'hands':{s:list(target.pose.bones['DEF-hand.'+s].head) for s in ['L','R']}}
  cliprows.append(record);poses.append({b.name:[list(row) for row in b.matrix] for b in target.pose.bones if b.bone.use_deform})
  if clip=='Walk_Loop' and i in [0,12]:
   # Source remains untouched; isolated editable derivative includes authored rig.
   bpy.ops.wm.save_as_mainfile(filepath=str(out/(clip+'-'+str(i)+'.blend')),copy=True)
 rows+=cliprows
report={'source_sha256':before,'source_unchanged':sha(source)==before,'ual_glb_sha256':sha(ual),'limb_length_ratio':ratio,'rotation_mapping':rot_map,'rig_bones':len(target.data.bones),'deform_bones':sum(b.use_deform for b in target.data.bones),'pose_samples':rows,'limitations':['Not foot-contact accepted','No source weapon grip curve','All19 meshes still native modifier evaluation oracle, not an approved crowd runtime','Original legacy materials not yet fully migrated'],'default_enabled':False}
(out/'retarget-report.json').write_text(json.dumps(report,indent=2));(out/'deform-poses.json').write_text(json.dumps(poses));print('RETARGET',ratio,len(rows),flush=True)
