"""MH163 spear action authoring draft. Source read-only; full original rig/actions retained.
Blender --disable-autoexec --python author.py -- SOURCE OUTPUT_DIRECTORY
This is authored input, not an art-pass or geometry parity gate.
"""
import bpy,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
source,out=map(Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
rig=bpy.data.objects['MH163'];scene=bpy.context.scene
original_actions=[a.name for a in bpy.data.actions]
rig.animation_data.action=bpy.data.actions['Idle_Loop'];scene.frame_set(0);bpy.context.view_layer.update()
base={p.name:p.matrix_basis.copy() for p in rig.pose.bones}
root_reference=rig.pose.bones['root'].head.copy()
# Native source is120fps; do not retime or overwrite its nine existing actions.
scene.render.fps=120
axis=Vector((.10,-.35,.05)).normalized()
rear=Vector((-.20,-.03,1.05));front=rear+axis*.365
constraints=[];targets={};orientations={};grip_local={}
for side in ['L','R']:
 w=rig.data.bones['wrist.'+side]
 bases=[rig.data.bones[f'finger{i}-1.{side}'].head_local for i in range(2,6)]
 mid=sum(bases,Vector())/4
 long=(mid-w.head_local).normalized()
 width=(bases[0]-bases[-1]);width=(width-long*width.dot(long)).normalized();normal=width.cross(long).normalized()
 source_basis=Matrix((width,long,normal)).transposed()
 desired_width=axis*(1 if side=='R' else -1)
 desired_long=Vector((1 if side=='R' else -1,0,-.1));desired_long=(desired_long-desired_width*desired_long.dot(desired_width)).normalized()
 desired_normal=desired_width.cross(desired_long).normalized()
 q=(Matrix((desired_width,desired_long,desired_normal)).transposed()@source_basis.transposed()).to_quaternion()
 orientations[side]=q@w.matrix_local.to_quaternion()
 # Place shaft inside palm, proximal to finger-base row, not at wrist origin.
 center=mid-long*.022
 grip_local[side]=w.matrix_local.inverted()@center
# Editable proxy shaft, no tassel on ordinary infantry. Final licensed weapon mesh
# can replace this without changing the measured axis and hand attachment.
def mat(name,col,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*col,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.6;return m
wood=mat('Spear draft ash wood',(.23,.12,.055));steel=mat('Spear draft steel',(.28,.32,.34),.7)
bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=.014,depth=2.5)
shaft=bpy.context.object;shaft.name='Spear_Shaft';shaft.data.materials.append(wood)
shaft.modifiers.new('TriangulateCapsForTangents','TRIANGULATE')
shaft.rotation_mode='QUATERNION';shaft.rotation_quaternion=Vector((0,0,1)).rotation_difference(axis)
bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=.045,radius2=0,depth=.24)
blade=bpy.context.object;blade.name='Spear_Blade_Draft';blade.data.materials.append(steel);blade.rotation_mode='QUATERNION';blade.rotation_quaternion=shaft.rotation_quaternion
all_records={};created=[]
# Explicit authored pull -> straight thrust -> recovery. Peak measured from the
# new shaft, never imported from Guardian. Feet stay on the original idle base.
def extension(f):
 keys=[(0,0.),(9,-.055),(26,.245),(31,.245),(54,.035),(84,0.)]
 for (a,x),(b,y) in zip(keys,keys[1:]):
  if a<=f<=b:
   t=(f-a)/(b-a);t=t*t*(3-2*t);return x+(y-x)*t
 return 0.
plans=[('Spear_Thrust_V2_DRAFT','Idle_Loop',84,True),('Spear_Idle_V2_DRAFT','Idle_Loop',300,False),('Spear_Walk_V2_DRAFT','Walk_Loop',160,False),('Spear_Jog_V2_DRAFT','Jog_Fwd_Loop',112,False),('Spear_Sprint_V2_DRAFT','Sprint_Loop',80,False)]
for name,source_name,end_frame,is_thrust in plans:
 source_action=bpy.data.actions[source_name];new=bpy.data.actions.new(name);new.use_fake_user=True;created.append(name);records=[]
 for f in sorted(set(list(range(0,end_frame+1,1 if is_thrust else 4))+[end_frame])):
  rig.animation_data.action=source_action;scene.frame_set(0 if is_thrust else f);bpy.context.view_layer.update()
  base={p.name:p.matrix_basis.copy() for p in rig.pose.bones};root_delta=rig.pose.bones['root'].head-root_reference
  rig.animation_data.action=new;scene.frame_set(f)
  for c in constraints:c.mute=False
  for p in rig.pose.bones:p.matrix_basis=base[p.name].copy()
  ext=extension(f) if is_thrust else 0.;grips={'R':rear+axis*ext+root_delta,'L':front+root_delta}
  bpy.context.view_layer.update()
  for side in ['L','R']:
   q=orientations[side];target=grips[side]-q@grip_local[side]
   names=[x+'.'+side for x in ['upperarm01','upperarm02','lowerarm01','lowerarm02']]
   lengths=[rig.data.bones[n].length for n in names]
   shoulder=rig.pose.bones[names[0]].head.copy();delta=target-shoulder
   l1=sum(lengths[:2]);l2=sum(lengths[2:]);d=min(delta.length,l1+l2-.0001);direction=delta.normalized()
   distance=(l1*l1-l2*l2+d*d)/(2*d);height=max(0.,l1*l1-distance*distance)**.5
   pole=Vector((.8 if side=='L' else -.8,.3,-.45));pole=(pole-direction*pole.dot(direction)).normalized()
   elbow=shoulder+direction*distance+pole*height
   points=[shoulder,shoulder+(elbow-shoulder)*(lengths[0]/l1),elbow,elbow+(target-elbow)*(lengths[2]/l2),target]
   for i,name in enumerate(names):
    b=rig.data.bones[name];rest_axis=(b.tail_local-b.head_local).normalized();wanted=(points[i+1]-points[i]).normalized()
    rotation=rest_axis.rotation_difference(wanted)@b.matrix_local.to_quaternion()
    matrix=rotation.to_matrix().to_4x4();matrix.translation=points[i];rig.pose.bones[name].matrix=matrix;bpy.context.view_layer.update()
   p=rig.pose.bones['wrist.'+side];m=q.to_matrix().to_4x4();m.translation=target;p.matrix=m
  bpy.context.view_layer.update()
  # Finger chains wrap the actual shaft circle; no arbitrary local-X curl.
  for side in ['L','R']:
   for number in range(2,6):
    first=rig.pose.bones[f'finger{number}-1.{side}'];point=first.head.copy()
    rod=rear+axis*ext+root_delta;radial=point-rod-axis*(point-rod).dot(axis)
    radius=max(.024,radial.length,max(rig.data.bones[f'finger{number}-{j}.{side}'].length*.51 for j in range(1,4)))
    radial=radial.normalized()*radius;center=point-radial
    for segment in range(1,4):
     p=rig.pose.bones[f'finger{number}-{segment}.{side}'];length=p.bone.length
     angle=2*math.asin(min(1.,length/(2*radius)))*(1 if side=='L' else -1)
     next_radial=Quaternion(axis,angle)@radial;endpoint=center+next_radial
     m=p.matrix.copy();old_axis=(p.tail-p.head).normalized();new_axis=(endpoint-point).normalized()
     q=old_axis.rotation_difference(new_axis)@m.to_quaternion();n=q.to_matrix().to_4x4();n.translation=point;p.matrix=n;bpy.context.view_layer.update()
     point=endpoint;radial=next_radial
  bpy.context.view_layer.update()
  evaluated=rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
  matrices={p.name:p.matrix.copy() for p in evaluated.pose.bones}
  for c in constraints:c.mute=True
  # Pose hierarchy insertion order is parent-first in the official MH rig.
  for p in rig.pose.bones:p.matrix=matrices[p.name]
  bpy.context.view_layer.update()
  for p in rig.pose.bones:
   p.rotation_mode='QUATERNION';p.keyframe_insert('location',frame=f,group=p.name);p.keyframe_insert('rotation_quaternion',frame=f,group=p.name);p.keyframe_insert('scale',frame=f,group=p.name)
  shaft.location=rear+axis*(ext+.55);blade.location=rear+axis*(ext+1.92)
  records.append({'frame':f,'seconds':f/120,'extension_m':ext,'grips':{s:list(rig.pose.bones['wrist.'+s].matrix@grip_local[s]) for s in ['L','R']},'shaft_axis':list(axis),'shaft_rear':list(rear+axis*ext+root_delta),'tip':list(blade.location+axis*.12)})
 all_records[name]=records
# Parent rigid weapon to the actual right wrist, without separate animation caches.
rig.animation_data.action=bpy.data.actions['Spear_Thrust_V2_DRAFT'];scene.frame_set(0);bpy.context.view_layer.update()
wrist=rig.pose.bones['wrist.R'];bone_parent=rig.matrix_world@wrist.matrix@Matrix.Translation((0,wrist.bone.length,0))
for obj,offset in [(shaft,.55),(blade,1.92)]:
 desired=Vector((0,0,1)).rotation_difference(axis).to_matrix().to_4x4();desired.translation=rear+axis*offset
 obj.animation_data_clear();obj.parent=rig;obj.parent_type='BONE';obj.parent_bone='wrist.R';obj.matrix_parent_inverse=Matrix.Identity(4);obj.matrix_basis=bone_parent.inverted()@desired
scene.frame_start=0;scene.frame_end=84;scene.frame_set(26);bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'mh-spear-v2-draft.blend'))
(out/'action-contract.json').write_text(json.dumps({'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'source_actions_retained':original_actions,'new_actions':created,'fps':120,'thrust_frames':[0,84],'peak_frames':[26,31],'status':'DRAFT_REQUIRES_ACTUAL_MESH_VISUAL_REVIEW','rig':'MH163','bone_count':len(rig.data.bones),'weapon_parent_bone':'wrist.R','weapon_parent_local':{o.name:[list(row) for row in o.matrix_basis] for o in [shaft,blade]},'clips':all_records},indent=2))
print('MH_SPEAR_DRAFT_SAVED_NOT_ACCEPTED')
