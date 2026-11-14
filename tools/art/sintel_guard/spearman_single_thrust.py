"""One authored continuous thrust/recovery on source controls, not gameplay timing.
Full actor, no hand-painted image interpolation; grip/error gate remains unaccepted.
"""
import bpy,sys,pathlib,math,json,hashlib
from mathutils import Matrix,Vector,Quaternion
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);r=bpy.data.objects['rig'];scene=bpy.context.scene
axis0=Vector((.5,0,.8660254));center0=Vector((0,-.36,1.40));aim=Vector((.12,-.987,.105)).normalized();turn=axis0.rotation_difference(aim)
root=bpy.data.objects.new('CONTROL one continuous spear thrust',None);bpy.context.collection.objects.link(root);root.location=center0;bpy.context.view_layer.update()
for o in list(bpy.context.scene.objects):
 if o.name.startswith('SPEAR '):
  w=o.matrix_world.copy();o.parent=root;o.matrix_parent_inverse=Matrix.Identity(4);o.matrix_basis=root.matrix_world.inverted()@w
r.animation_data.action=bpy.data.actions.new('EXPERIMENT one spear thrust and exact recovery')
base={s:r.pose.bones['hand_ik.'+s].matrix.copy() for s in ['L','R']}
records=[];scene.render.fps=24;scene.frame_start=0;scene.frame_end=36
# Blend weapon axis ready->aim, translate a short finite attack, then exact return.
def smooth(t):return t*t*(3-2*t)
for i in range(37):
 t=i/36
 if t<.30:q=smooth(t/.30);extension=0
 elif t<.52:q=1;extension=smooth((t-.30)/.22)
 elif t<.70:q=1;extension=1-smooth((t-.52)/.18)
 else:q=1-smooth((t-.70)/.30);extension=0
 rotation=Quaternion().slerp(turn,q);axis=rotation@axis0;center=center0+Vector((0,.20*q-.07*extension,0))
 root.rotation_mode='QUATERNION';root.rotation_quaternion=rotation;root.location=center
 for side in ['L','R']:
  p=r.pose.bones['hand_ik.'+side];p['ik']=1.;m=base[side].copy();local=m.translation-center0
  m=rotation.to_matrix().to_4x4()@m;m.translation=center+rotation@local;p.matrix=m
 bpy.context.view_layer.update()
 errors={s:(r.pose.bones['DEF-hand.'+s].head-r.pose.bones['hand_ik.'+s].head).length for s in ['L','R']}
 records.append({'frame':i,'phase':t,'axis':list(axis),'center':list(center),'wrist_error_m':errors})
 for side in ['L','R']:
  p=r.pose.bones['hand_ik.'+side]
  p.keyframe_insert('location',frame=i);p.keyframe_insert('rotation_quaternion' if p.rotation_mode=='QUATERNION' else 'rotation_euler',frame=i);p.keyframe_insert('scale',frame=i)
 root.keyframe_insert('location',frame=i);root.keyframe_insert('rotation_quaternion',frame=i)
for f in r.animation_data.action.fcurves:
 for k in f.keyframe_points:k.interpolation='LINEAR'
scene.frame_set(0);bpy.ops.wm.save_as_mainfile(filepath=str(out/'soldier-single-thrust.blend'))
for o in list(bpy.data.objects):
 if o.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(o,do_unlink=True)
scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=False;scene.view_layers[0].material_override=None
scene.world=bpy.data.worlds.new('Single thrust review');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=5
bpy.ops.object.camera_add(location=(3.5,-5,3.8));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.4,1.1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.5;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
for i in [0,18,36]:
 scene.frame_set(i);scene.render.filepath=str(out/f'thrust-{i:02d}-BLENDER-NOT-GAME.png');bpy.ops.render.render(write_still=True)
maxerr=max(v for x in records for v in x['wrist_error_m'].values())
(out/'report.json').write_text(json.dumps({'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'duration_seconds':1.5,'samples':records,'max_wrist_error_m':maxerr,'kinematic_target_reachable_3cm':maxerr<.03,'art_pass':False,'game_tested':False,'combat_timing_changed':False,'fingers_and_body_clearance_accepted':False},indent=2)+'\n')
