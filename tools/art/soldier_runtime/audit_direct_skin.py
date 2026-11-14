"""Read-only complete source LBS candidates, not clothing/runtime/art acceptance.
Run Blender --background --disable-autoexec --python-exit-code 1 --python ... -- SOURCE EXPECTED_SHA OUT
Keeps original weights. Reports raw/residual/normalized semantics separately.
"""
import bpy,sys,pathlib,hashlib,json,numpy as np
source,expected,out=sys.argv[sys.argv.index('--')+1:]
source=pathlib.Path(source);out=pathlib.Path(out);out.mkdir(parents=True,exist_ok=True)
assert hashlib.sha256(source.read_bytes()).hexdigest()==expected,'Source drift: never use branch-latest mother silently'
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
scene=bpy.context.scene;rig=bpy.data.objects['rig'];action=rig.animation_data.action;first,last=map(float,action.frame_range)
meshes=[];excluded=[]
for obj in sorted(scene.objects,key=lambda o:o.name):
 if obj.type!='MESH' or obj.hide_render or not obj.visible_get():continue
 mods=[m for m in obj.modifiers if m.show_viewport]
 if len(mods)!=1 or mods[0].type!='ARMATURE' or mods[0].use_deform_preserve_volume or obj.data.shape_keys:
  excluded.append({'name':obj.name,'reason':'not plain single LBS Armature, or has shape keys','stack':[m.type for m in mods]});continue
 arm=mods[0].object;bones=list(arm.data.bones);lookup={b.name:i for i,b in enumerate(bones)}
 groups=[[ (lookup[obj.vertex_groups[g.group].name],float(g.weight)) for g in v.groups if obj.vertex_groups[g.group].name in lookup and bones[lookup[obj.vertex_groups[g.group].name]].use_deform and g.weight>0] for v in obj.data.vertices]
 width=max(map(len,groups));joints=np.zeros((len(groups),width),np.int32);weights=np.zeros((len(groups),width),np.float64)
 for v,gs in enumerate(groups):
  for j,(bone,w) in enumerate(gs):joints[v,j]=bone;weights[v,j]=w
 points=np.array([tuple(v.co)+(1.,) for v in obj.data.vertices],np.float64)
 meshes.append({'obj':obj,'arm':arm,'bones':bones,'joints':joints,'weights':weights,'points':points,'counts':np.array(list(map(len,groups)),np.int32),'rows':[]})
report={'source_sha256':expected,'source_file_bytes':source.stat().st_size,'blender':bpy.app.version_string,'action':action.name,'source_frame_range':[first,last],'scope':'Positions only, exact source weights retained. No proof of normals/materials/GPU/cloth/foot contact.','art_pass':False,'runtime_ready':False,'excluded':excluded,'meshes':[]}
for probe_index,phase in enumerate([.13,.47,.83,.47]):
 frame=first+(last-first)*phase;scene.frame_set(int(frame),subframe=frame%1)
 stress=[]
 if probe_index==3:
  # Separate synthetic tail-weight excitation, never an authored/action claim.
  for entry in meshes:
   for vertex in np.flatnonzero(entry['counts']>8):
    bone=entry['bones'][int(entry['joints'][vertex,8])].name;pb=entry['arm'].pose.bones[bone]
    pb.rotation_mode='XYZ';pb.rotation_euler=(.12,-.08,.06);pb.location=(.015,-.007,.011)
    if bone not in stress:stress.append(bone)
 bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get()
 for entry in meshes:
  obj,arm=entry['obj'],entry['arm'];oe=obj.evaluated_get(dg);ae=arm.evaluated_get(dg);M=ae.matrix_world.inverted()@oe.matrix_world
  matrices=np.array([np.array(M.inverted()@ae.pose.bones[b.name].matrix@b.matrix_local.inverted()@M) for b in entry['bones']],np.float64)
  transformed=np.einsum('vwab,vb->vwa',matrices[entry['joints']],entry['points'])[:,:,:3]
  total=entry['weights'].sum(axis=1);raw=(transformed*entry['weights'][:,:,None]).sum(axis=1)
  residual=raw+entry['points'][:,:3]*(1-total[:,None]);normalized=np.divide(raw,total[:,None],out=entry['points'][:,:3].copy(),where=total[:,None]>0)
  me=oe.to_mesh();actual=np.array([tuple(v.co) for v in me.vertices],np.float64);oe.to_mesh_clear();assert actual.shape==raw.shape and np.isfinite(actual).all()
  dropped=entry['weights'].copy()
  if dropped.shape[1]>8:dropped[:,8:]=0
  truncated=(transformed*dropped[:,:,None]).sum(axis=1)
  dropped_total=dropped.sum(axis=1);truncated=np.divide(truncated,dropped_total[:,None],out=entry['points'][:,:3].copy(),where=dropped_total[:,None]>0)
  row={'probe':'synthetic_tail_rotation_translation' if probe_index==3 else 'authored_walk','synthetic_bones':stress,'dropped_tail_normalized_max_error_m':float(np.linalg.norm(truncated-actual,axis=1).max()),'phase':phase,'frame':frame,'vertices':len(actual),'over8_points':int((entry['counts']>8).sum()),'max_position_error_m':{name:float(np.linalg.norm(value-actual,axis=1).max()) for name,value in [('raw_full_weights',raw),('residual_full_weights',residual),('normalized_full_weights',normalized)]}}
  entry['rows'].append(row)
  print('DIRECT_SOURCE_POSE',obj.name,json.dumps(row),flush=True)
for index,entry in enumerate(meshes):
 obj=entry['obj'];weights=entry['weights'];groups=[[{'group':obj.vertex_groups[g.group].name,'weight':float(g.weight)} for g in v.groups] for v in obj.data.vertices]
 payload={'position':entry['points'][:,:3],'joints':entry['joints'],'weights':weights,'influence_counts':entry['counts']}
 for layer in obj.data.uv_layers:payload['uv_'+layer.name]=np.array([tuple(x.uv) for x in layer.data],np.float32)
 payload['loop_vertex_ids']=np.array([x.vertex_index for x in obj.data.loops],np.int32)
 obj.data.calc_loop_triangles();payload['triangle_loops']=np.array([tuple(x.loops) for x in obj.data.loop_triangles],np.int32)
 filename=f'direct-{index}.npz';np.savez_compressed(out/filename,**payload)
 bind={'name':obj.name,'parent':obj.parent.name if obj.parent else None,'parent_type':obj.parent_type,'parent_bone':obj.parent_bone,'bones':[{'name':b.name,'deform':b.use_deform,'rest_matrix':list(map(list,b.matrix_local))} for b in entry['bones']],'all_original_vertex_groups':groups}
 (out/f'direct-{index}-bindings.json').write_text(json.dumps(bind,separators=(',',':')))
 report['meshes'].append({'name':obj.name,'vertices':len(weights),'bones':len(entry['bones']),'max_influences':weights.shape[1],'over8_vertices':int((entry['counts']>8).sum()),'weight_sum_range':[float(weights.sum(axis=1).min()),float(weights.sum(axis=1).max())],'data':filename,'data_sha256':hashlib.sha256((out/filename).read_bytes()).hexdigest(),'rows':entry['rows']})
report['position_gate_2e5']=bool(meshes) and all(row['max_position_error_m']['raw_full_weights']<2e-5 for m in report['meshes'] for row in m['rows'])
report['source_bytes_unchanged']=hashlib.sha256(source.read_bytes()).hexdigest()==expected
assert report['position_gate_2e5'] and report['source_bytes_unchanged'],'Complete source position gate failed'
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print('DIRECT_SOURCE_AUDIT_COMPLETE',len(meshes),flush=True)
