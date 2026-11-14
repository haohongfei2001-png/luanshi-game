"""Measure complete native cage pipeline; reject LBS folding of original DQ rig.
Read-only original source. No production rig, cloth, material or camera changes.
"""
import bpy, pathlib, sys, json, hashlib, time
import numpy as np
from mathutils import Matrix
args=sys.argv[sys.argv.index('--')+1:]; src, response, out=map(pathlib.Path,args[:3]);out.mkdir(parents=True,exist_ok=True)
sha=hashlib.sha256(src.read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
rig=bpy.data.objects['rig'];top=bpy.data.objects['GEO-topLT'];mdef=next(m for m in top.modifiers if m.type=='MESH_DEFORM');cage=mdef.object;arm=next(m for m in cage.modifiers if m.type=='ARMATURE');next(m for m in top.modifiers if m.type=='MULTIRES').levels=0
z=np.load(response);H=z['coefficients'];C0=z['cage_rest'];P0=z['top_rest'];A=z['cage_to_top_linear'];raw=np.array([v.co[:] for v in cage.data.vertices]);names=[g.name for g in cage.vertex_groups];W=np.zeros((len(raw),len(names)))
for v in cage.data.vertices:
 for g in v.groups: W[v.index,g.group]=g.weight
assert all(n in rig.data.bones and rig.data.bones[n].use_deform for n in names)
# Blender's LBS reference normalizes accumulated deformation by weight sum.
# Retain original W verbatim, no influence truncation or modified source weights.
sums=W.sum(axis=1);assert np.all(sums>0);WN=W/sums[:,None]
hom=np.column_stack([raw,np.ones(len(raw))]);fold=np.einsum('vc,cb,ck->vbk',H,WN,hom)
original_volume=arm.use_deform_preserve_volume

def pts(ob):
 ev=ob.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();p=np.array([v.co[:] for v in me.vertices]);ev.to_mesh_clear();return p

def err(x,y):
 d=np.linalg.norm(x-y,axis=1);return {'max_m':float(d.max()),'rms_m':float(np.sqrt(np.mean(d*d)))}

def qmul(a,b):
 w,x,y,z=a;v,i,j,k=b
 return np.array([w*v-x*i-y*j-z*k,w*i+x*v+y*k-z*j,w*j-x*k+y*v+z*i,w*k+x*j-y*i+z*v])
def dq_cage(mats):
 qr=np.array([Matrix(m.tolist()).to_quaternion()[:] for m in mats]);qd=np.array([.5*qmul(np.r_[0.,m[:3,3]],q) for m,q in zip(mats,qr)])
 result=[]
 for v,weights in zip(raw,W):
  ids=np.flatnonzero(weights);ref=qr[ids[0]];sign=np.where(qr[ids]@ref<0,-1.,1.);rw=weights[ids]*sign
  real=rw@qr[ids];dual=rw@qd[ids];length=np.linalg.norm(real);real/=length;dual/=length
  conjugate=real*np.array([1,-1,-1,-1]);result.append(qmul(qmul(real,np.r_[0.,v]),conjugate)[1:]+2*qmul(dual,conjugate)[1:])
 return np.array(result)
rng=np.random.default_rng(20261114);rows=[];saved={};start=time.perf_counter()
for i in range(25):
 for side,sign in [('L',1),('R',-1)]:
  rig.pose.bones['hand_ik.'+side]['ik']=0.
  for prefix in ['upper_arm.','forearm.']:
   p=rig.pose.bones[prefix+side];p.rotation_mode='XYZ';p.rotation_euler=tuple(rng.uniform(-.7,.7,3)) if i else (0,0,0)
 # Native controller translation as well as arbitrary non-keyframe rotations.
 p=rig.pose.bones['torso'];p.location=tuple(rng.uniform(-.05,.05,3)) if i else (0,0,0)
 bpy.context.view_layer.update();native_c=pts(cage);native_t=pts(top)
 local_from_rig=cage.matrix_world.inverted()@rig.matrix_world
 rig_from_local=rig.matrix_world.inverted()@cage.matrix_world
 mats=np.array([local_from_rig@rig.pose.bones[n].matrix@rig.data.bones[n].matrix_local.inverted()@rig_from_local for n in names])
 dq=dq_cage(mats)
 scale_error=max(float(np.max(np.abs(m[:3,:3].T@m[:3,:3]-np.eye(3)))) for m in mats)
 lbs=np.einsum('cb,bij,cj->ci',WN,mats,hom)[:,:3]
 folded=np.einsum('vbj,bij->vi',fold,mats)[:,:3]
 predicted=P0+(H@(native_c-C0))@A.T
 predicted_lbs=P0+(folded-H@C0)@A.T
 arm.use_deform_preserve_volume=False;bpy.context.view_layer.update();native_lbs=pts(cage);arm.use_deform_preserve_volume=original_volume;bpy.context.view_layer.update()
 rows.append({'pose':i,'dq_cage_vs_original':err(dq,native_c),'dq_response_top':err(P0+(H@(dq-C0))@A.T,native_t),'max_matrix_nonrigidity':scale_error,'cage_matrix_lbs_vs_native_lbs':err(lbs,native_lbs),'original_dq_vs_lbs':err(lbs,native_c),'fold_algebra':err(folded,H@lbs),'original_cage_response_top':err(predicted,native_t),'folded_lbs_vs_original_top':err(predicted_lbs,native_t)})
 saved[f'pose_{i}_cage']=native_c;saved[f'pose_{i}_top']=native_t;saved[f'pose_{i}_matrices']=mats
report={'source_sha256':sha,'source_unchanged':hashlib.sha256(src.read_bytes()).hexdigest()==sha,'rig_bones':len(rig.data.bones),'deform_bones':len(names),'cage_vertices':len(raw),'top_vertices':len(P0),'preserve_volume':original_volume,'all_raw_weights_retained':True,'raw_weight_sum_range':[float(sums.min()),float(sums.max())],'nonzero_influences':int(np.count_nonzero(W)),'max_influences':int(np.count_nonzero(W,axis=1).max()),'bytes_float32':{'H_shared':int(H.size*4),'folded_bind_shared':int(fold.size*4),'cage_per_actor_frame':int(len(raw)*3*4),'matrices_79_per_actor_frame':int(len(names)*12*4)},'dense_cage_response_vec3_macs_per_actor_frame':int(H.size*3),'poses':rows,'probe_wall_seconds':time.perf_counter()-start,'scope':'level0 cage positional representation only; no multires, normals, GPU or army-performance acceptance','runtime':'OFF'}
report['gates']={'dq_cage_2um':max(r['dq_cage_vs_original']['max_m'] for r in rows)<2e-6,'dq_response_top_100um':max(r['dq_response_top']['max_m'] for r in rows)<1e-4,'rigid_transform_1e_5':max(r['max_matrix_nonrigidity'] for r in rows)<1e-5,'reject_lbs_fold':max(r['folded_lbs_vs_original_top']['max_m'] for r in rows)>1e-4}
report['exact_nonzero_H_entries']=int(np.count_nonzero(H))
np.savez_compressed(out/'complete-cage-runtime-reference.npz',raw_weights=W,normalized_lbs_reference_weights=WN,bone_names=np.array(names),folded_bind=fold,raw_cage=raw,**saved)
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report),flush=True)
