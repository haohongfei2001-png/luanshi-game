"""Bounded native finger-control experiment; no geometry edits, no automatic acceptance."""
import bpy,sys,pathlib,json,numpy as np
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False);rig=bpy.data.objects['rig'];hand=bpy.data.objects['GEO-HandsJA.001'];shaft=bpy.data.objects['SPEAR whole unbroken wood shaft no tassel']
base={s:rig.pose.bones['hand_ik.'+s].matrix.copy() for s in ['L','R']};rows=[]
for curl in [.72,.8,.88]:
 for offset in [-.012,0,.012]:
  for side in ['L','R']:
   b=rig.pose.bones['hand_ik.'+side];m=base[side].copy();m.translation+=m.to_3x3().col[2]*offset;b.matrix=m
   for stem in ['finger_index.','finger_middle.','finger_ring.','finger_pinky.']:rig.pose.bones[stem+side].scale[1]=curl
  bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();se=shaft.evaluated_get(dg);sm=se.to_mesh();v=np.array([tuple(se.matrix_world@p.co) for p in sm.vertices]);se.to_mesh_clear();center=v.mean(axis=0);_,_,vh=np.linalg.svd(v-center,full_matrices=False);axis=vh[0];a=(v-center)@axis;lo,hi=a.min(),a.max();radius=np.median(np.linalg.norm(v-center-a[:,None]*axis,axis=1))
  ev=hand.evaluated_get(dg);me=ev.to_mesh();p=np.array([tuple(ev.matrix_world@v.co) for v in me.vertices]);ev.to_mesh_clear();a=(p-center)@axis;d=np.linalg.norm(p-center-a[:,None]*axis,axis=1)-radius;mask=(a>=lo)&(a<=hi)
  rows.append({'finger_native_scale_y':curl,'wrist_local_z_offset_m':offset,'inside_over_1mm':int(np.sum(mask&(d<-.001))),'near_2mm':int(np.sum(mask&(abs(d)<=.002))),'max_penetration_m':float(max(0,-d[mask].min()))})
(out/'sweep.json').write_text(json.dumps({'art_pass':False,'accepted_candidate':None,'limitation':'Surface vertices only, not triangle contact or natural pose proof; thumb unchanged; no candidate applied to pipeline','samples':rows},indent=2)+'\n');print(rows)
