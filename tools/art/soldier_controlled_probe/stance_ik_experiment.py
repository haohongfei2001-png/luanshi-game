"""Isolated source-phase-gated shoe collision constraint; never global lift/frozen feet."""
import bpy,json,sys,pathlib,hashlib
from mathutils import Vector
src,phasefile,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:3]);out.mkdir(parents=True,exist_ok=True)
phase=json.loads(phasefile.read_text());assert len(phase['samples'])==33
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False);scene=bpy.context.scene;rig=bpy.data.objects['rig'];boot=bpy.data.objects['GEO-bootsLT.001'];boot.modifiers['Multires'].levels=1
original=rig.animation_data.action;rig.animation_data.action=original.copy();rig.animation_data.action.name='EXPERIMENT source-phase shoe IK constraint NOT ACCEPTED'
first,last=map(float,original.frame_range);labels={};rows=[]
def feet():
 bpy.context.view_layer.update();ev=boot.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();p=[ev.matrix_world@v.co for v in me.vertices]
 if not labels:
  adj=[[] for v in me.vertices]
  for e in me.edges:a,b=e.vertices;adj[a].append(b);adj[b].append(a)
  seen=set()
  for i in range(len(p)):
   if i in seen:continue
   todo=[i];seen.add(i);ids=[]
   while todo:
    k=todo.pop();ids.append(k)
    for j in adj[k]:
     if j not in seen:seen.add(j);todo.append(j)
   center=sum((p[i] for i in ids),Vector())/len(ids);side=min('LR',key=lambda s:(center-rig.matrix_world@rig.pose.bones['DEF-foot.'+s].head).length)
   assert side not in labels;labels[side]=ids
  assert set(labels)==set('LR')
 result={s:min(p[i].z for i in ids) for s,ids in labels.items()};ev.to_mesh_clear();return result
for i in range(33):
 frame=first+(last-first)*i/32;scene.frame_set(int(frame),subframe=frame%1);before=feet();saved={s:rig.pose.bones['foot_ik.'+s].matrix.copy() for s in 'LR'};shift={s:0. for s in 'LR'}
 for attempt in range(6):
  measured=feet();changed=False
  for s in 'LR':
   # Donor surface near/below its verified T-pose plane is a stance candidate.
   # Preserve airborne trajectory; this does not declare the source contact valid.
   if phase['samples'][i]['feet'][s.lower()]['surface_min_z']>.004:continue
   delta=.002-measured[s]
   if delta<=.00005:continue
   assert shift[s]+delta<.06, 'Bound exceeded; do not force pose'
   bone=rig.pose.bones['foot_ik.'+s];m=bone.matrix.copy();m.translation+=rig.matrix_world.to_3x3().inverted()@Vector((0,0,delta));bone.matrix=m;shift[s]+=delta;changed=True
  if not changed:break
 after=feet()
 for s in 'LR':
  b=rig.pose.bones['foot_ik.'+s];q0=saved[s].to_quaternion();q1=b.matrix.to_quaternion();assert q0.rotation_difference(q1).angle<.0007
  assert abs(b.matrix.translation.x-saved[s].translation.x)<1e-5 and abs(b.matrix.translation.y-saved[s].translation.y)<1e-5
  b.keyframe_insert('location',frame=frame)
 rows.append({'phase':i/32,'before_min_z':before,'after_min_z':after,'per_foot_vertical_ik_shift':shift,'knee_world':{s:list(rig.matrix_world@rig.pose.bones['DEF-shin.'+s+'.01'].head) for s in 'LR'}})
# Check inter-key poses, not only the explicitly corrected sample keys.
intermediate=[]
for i in range(65):
 f=first+(last-first)*i/64;scene.frame_set(int(f),subframe=f%1);intermediate.append({'phase':i/64,'surface_min_z':feet()})
scene.frame_set(0);bpy.ops.wm.save_as_mainfile(filepath=str(out/'stance-ik-editable.blend'))
r={'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'default_enabled':False,'art_pass':False,'contact_accepted':False,'method':'Only source near-ground phase candidates; target complete boot surface unilateral native leg IK constraint. Target foot orientation and horizontal IK trajectory retained, no global lift or frozen coordinates.','source_plane_evidence':'A_TPose source sole0.461mm; Idle -0.102..0.460mm; Walk source itself penetrates26.56mm','rows':rows,'intermediate65':intermediate,'minimum_after_m':min(v for x in intermediate for v in x['surface_min_z'].values()),'max_vertical_correction_m':max(v for x in rows for v in x['per_foot_vertical_ik_shift'].values()),'limitations':['Source stance not validated against root-motion horizontal foot lock','Between-key penetration may remain','Knee continuity and original-speed visual review required','Only flat source-plane not terrain Ground.deck_height','No shipping or combat integration']}
(out/'report.json').write_text(json.dumps(r,indent=2));print('STANCE_IK_RESULT',r['minimum_after_m'],r['max_vertical_correction_m'],flush=True)
