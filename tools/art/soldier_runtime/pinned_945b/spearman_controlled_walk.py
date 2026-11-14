"""Same intact actor/rig, genuine source locomotion. Independent authoring diagnostic.
Original donor rest deltas and leg-length ratio; no free-generated animation frames.
Not a contact/visual PASS. Source finger grip remains explicitly unaccepted.
"""
import bpy,sys,pathlib,math,json,hashlib
from mathutils import Matrix,Vector
src,ual,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:3]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);target=bpy.data.objects['rig'];before=set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=str(ual));added=set(bpy.data.objects)-before
# Important: the pre-existing full MH163 face rig is NOT the newly imported donor.
donor=next(o for o in added if o.type=='ARMATURE')
for o in added:o.hide_render=True
for track in donor.animation_data.nla_tracks:track.mute=True
S={b.name:b.matrix_local.copy() for b in donor.data.bones};T={b.name:b.matrix_local.copy() for b in target.data.bones}
ratio=sum(target.data.bones[n].length for n in ['thigh.L','shin.L'])/sum(donor.data.bones[n].length for n in ['thigh_l','calf_l'])
action=next(a for a in bpy.data.actions if a.name=='Walk_Loop_Armature');donor.animation_data.action=action
start,end=map(float,action.frame_range);length=end-start
hands={s:target.pose.bones['hand_ik.'+s].matrix.copy() for s in ['L','R']}
weapon=bpy.data.objects.new('CONTROL whole spear carry motion',None);bpy.context.collection.objects.link(weapon)
for o in list(bpy.context.scene.objects):
 if o.name.startswith('SPEAR '):w=o.matrix_world.copy();o.parent=weapon;o.matrix_world=w
# Preserve animation_data.drivers. Only add an independently editable action.
target.animation_data.action=bpy.data.actions.new('EXPERIMENT full-rig source Walk with unaccepted spear grip')
scene=bpy.context.scene;scene.render.fps=24;scene.frame_start=0;scene.frame_end=math.ceil(length)
records=[]
def rotate_control(name,source_name):
 p=target.pose.bones[name];parent=p.parent
 desired=(donor.pose.bones[source_name].matrix.to_quaternion()@S[source_name].to_quaternion().inverted()).to_matrix().to_4x4()@T[name]
 local=p.bone.convert_local_to_pose(desired,p.bone.matrix_local,parent_matrix=parent.matrix if parent else Matrix.Identity(4),parent_matrix_local=parent.bone.matrix_local if parent else Matrix.Identity(4),invert=True)
 p.rotation_mode='QUATERNION';p.rotation_quaternion=local.to_quaternion();bpy.context.view_layer.update()
for i in range(33):
 donor_frame=start+length*i/32;scene.frame_set(int(donor_frame),subframe=donor_frame%1)
 rotate_control('torso','spine_01');rotate_control('neck.01','neck_01')
 if 'Head' in S:rotate_control('head','Head')
 hip_delta=(donor.pose.bones['pelvis'].matrix.translation-S['pelvis'].translation)*ratio
 target.pose.bones['torso'].location=T['torso'].to_3x3().inverted()@hip_delta
 for side,small in [('L','l'),('R','r')]:
  t='foot_ik.'+side;s='foot_'+small;target.pose.bones[t]['ik']=1.
  delta=(donor.pose.bones[s].matrix.translation-S[s].translation)*ratio
  q=donor.pose.bones[s].matrix.to_quaternion()@S[s].to_quaternion().inverted()@T[t].to_quaternion()
  desired=q.to_matrix().to_4x4();desired.translation=T[t].translation+delta;target.pose.bones[t].matrix=desired
  target.pose.bones['hand_ik.'+side]['ik']=1.
  hm=hands[side].copy();hm.translation+=hip_delta;target.pose.bones['hand_ik.'+side].matrix=hm
 weapon.location=hip_delta
 bpy.context.view_layer.update()
 controls=['torso','neck.01','head','foot_ik.L','foot_ik.R','hand_ik.L','hand_ik.R']
 for n in controls:
  p=target.pose.bones[n]
  p.keyframe_insert('location',frame=length*i/32)
  p.keyframe_insert('rotation_quaternion' if p.rotation_mode=='QUATERNION' else 'rotation_euler',frame=length*i/32)
  p.keyframe_insert('scale',frame=length*i/32)
 weapon.keyframe_insert('location',frame=length*i/32)
 records.append({'phase':i/32,'source_frame':donor_frame,'feet':{s:list(target.pose.bones['DEF-foot.'+s].head) for s in ['L','R']},'hands':{s:list(target.pose.bones['DEF-hand.'+s].head) for s in ['L','R']},'source_feet':{s:list(donor.pose.bones['foot_'+s].head) for s in ['l','r']}})
# No interpolation between hand-generated pictures. These are evaluated rig keys.
for curve in target.animation_data.action.fcurves:
 for key in curve.keyframe_points:key.interpolation='LINEAR'
scene.frame_set(0);bpy.ops.wm.save_as_mainfile(filepath=str(out/'soldier-controlled-walk.blend'))
for o in list(bpy.data.objects):
 if o.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(o,do_unlink=True)
scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=False;scene.view_layers[0].material_override=None
scene.world=bpy.data.worlds.new('Walk source review');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=5
bpy.ops.object.camera_add(location=(2.5,-5,3.2));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.1,1.1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.2;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
for i in [0,8,16,24]:
 f=length*i/32;scene.frame_set(int(f),subframe=f%1);scene.render.filepath=str(out/f'walk-{i:02d}-BLENDER-NOT-GAME.png');bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps({'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'donor_sha256':hashlib.sha256(ual.read_bytes()).hexdigest(),'leg_length_ratio':ratio,'duration_seconds':length/24,'output_key_count':33,'source_body_rig_bones':len(target.data.bones),'complete_face_rig_bones':len(bpy.data.objects['MH163'].data.bones),'samples':records,'art_pass':False,'game_tested':False,'limitations':['Source stance contact not corrected for target foot/shoe shape','Hand fingers not contact accepted','Clothing/armor still rejected','No attack/death clips claimed','Source donor added hidden for recovery, not runtime skeleton']},indent=2)+'\n')
