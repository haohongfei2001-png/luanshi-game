"""Original cage pose oracle with exact corresponding vertex/index/UV order.
No fitted armature exists here; this never reports runtime deformation parity.
"""
import bpy,pathlib,sys,json,hashlib,numpy as np
args=sys.argv[sys.argv.index('--')+1:];src,out=map(pathlib.Path,args[:2]);out.mkdir(parents=True,exist_ok=True);sha=hashlib.sha256(src.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
rig=bpy.data.objects['rig'];top=bpy.data.objects['GEO-topLT'];mr=next(m for m in top.modifiers if m.type=='MULTIRES');mr.levels=1
poses=[('rest',0,0),('elbow',-.25,.9),('shoulder',-.8,.3),('combined',-.55,1.2)]
rows=[];arrays={};index_hash=None;baseline=None
for label,upper,fore in poses:
 for side,sign in [('L',1),('R',-1)]:
  rig.pose.bones['hand_ik.'+side]['ik']=0.
  for prefix,value in [('upper_arm.',upper),('forearm.',fore)]:
   p=rig.pose.bones[prefix+side];p.rotation_mode='XYZ';p.rotation_euler=(0,0,value*sign)
 bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();ev=top.evaluated_get(dg);me=ev.to_mesh();me.calc_loop_triangles()
 points=np.array([tuple(ev.matrix_world@v.co) for v in me.vertices],dtype=np.float64);indices=np.array([t.vertices[:] for t in me.loop_triangles],dtype=np.int32);uv=np.array([v.uv[:] for v in me.uv_layers.active.data],dtype=np.float64)
 polygon_loops=np.array([l.vertex_index for l in me.loops],dtype=np.int32)
 signature=hashlib.sha256(polygon_loops.tobytes()+uv.tobytes()).hexdigest()
 if index_hash is None:index_hash=signature;baseline=points.copy();rest_indices=indices.copy()
 assert signature==index_hash and points.shape==baseline.shape and np.isfinite(points).all()
 displacement=np.linalg.norm(points-baseline,axis=1);arrays[label]=points;arrays[label+'_evaluated_triangles']=indices.copy()
 rows.append({'name':label,'upper_arm_local_z':upper,'forearm_local_z':fore,'vertex_count':len(points),'index_uv_sha256':signature,'max_displacement_m':float(displacement.max()),'rms_displacement_m':float(np.sqrt(np.mean(displacement**2)))})
 ev.to_mesh_clear()
np.savez_compressed(out/'exact-native-top-pose-reference.npz',**arrays,rest_triangles=rest_indices,loop_uv=uv)
report={'source_sha256':sha,'source_unchanged':hashlib.sha256(src.read_bytes()).hexdigest()==sha,'rig_bones':len(rig.data.bones),'deform_bones':sum(b.use_deform for b in rig.data.bones),'poses':rows,'same_vertex_polygon_loop_uv_order':True,'triangulation_note':'Geometry-dependent quad diagonal can change with pose; compare original polygon loops, not tessellator triangle order. First strict triangle hash failure retained.','source':'original bound MeshDeform and level1 native Multires evaluated after native FK controls','runtime_armature_fit':'NOT_IMPLEMENTED','runtime_error':'NOT_MEASURED','art_pass':False}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(report,flush=True)
