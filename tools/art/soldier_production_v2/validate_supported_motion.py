"""Remove faulty live micro-bevel and audit real POSE geometry across all actions.
Not a render/performance/art acceptance. No limbs or visible surfaces are hidden.
"""
import bpy,sys,pathlib,json,hashlib,math,numpy as np
src,spear,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);rig=bpy.data.objects['MH163'];rig.animation_data_create();bpy.context.scene.render.fps=120;bpy.context.scene.render.fps_base=1
removed=[]
for o in bpy.context.scene.objects:
 if o.type=='MESH' and not o.hide_render and o.name.startswith('V3'):
  for m in list(o.modifiers):
   if m.type=='BEVEL':removed.append({'object':o.name,'modifier':m.name,'width_m':m.width});o.modifiers.remove(m)
with bpy.data.libraries.load(str(spear),link=False) as (a,b):b.actions=[n for n in a.actions if n.startswith('Spear_') and n not in bpy.data.actions]
for action in b.actions:
 if action:action.use_fake_user=True
objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render];rest={};issues=[]
def geometry(o):
 ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());m=ev.to_mesh();p=np.empty(len(m.vertices)*3,dtype=np.float64);m.vertices.foreach_get('co',p);p=p.reshape(-1,3);e=np.empty(len(m.edges)*2,dtype=np.int32);m.edges.foreach_get('vertices',e);e=e.reshape(-1,2);ev.to_mesh_clear();return p,e
rig.data.pose_position='REST';bpy.context.view_layer.update()
for o in objects:
 p,e=geometry(o);length=np.linalg.norm(p[e[:,0]]-p[e[:,1]],axis=1);rest[o.name]=(e,length,p)
# Source groups are also checked, so a finite skeleton cannot hide bad skin data.
for o in objects:
 for v in o.data.vertices:
  weights=[(o.vertex_groups[g.group].name,float(g.weight)) for g in v.groups if g.weight>0]
  if not weights or any(name not in rig.data.bones or not math.isfinite(w) or w>1.0001 for name,w in weights):issues.append({'kind':'invalid_source_weights','object':o.name,'vertex':v.index,'weights':weights})
rig.data.pose_position='POSE';summary=[];worst={};bbox_all=[]
for action in sorted(bpy.data.actions,key=lambda a:a.name):
 if action.name not in ['Idle_Loop','Walk_Loop','Jog_Fwd_Loop','Sprint_Loop','Hit_Chest','Hit_Head','Death01','Sword_Idle','Sword_Attack'] and not action.name.startswith('Spear_'):continue
 rig.animation_data.action=action;lo,hi=map(int,action.frame_range);frames=sorted(set([lo,hi]+[round(lo+(hi-lo)*t) for t in [.125,.25,.375,.5,.625,.75,.875]]))
 if 'Thrust' in action.name:frames=sorted(set(frames+[min(hi,f) for f in [12,26,31,42,63,84]]))
 for frame in frames:
  bpy.context.scene.frame_set(frame);bpy.context.view_layer.update();mins=[];maxs=[]
  for o in objects:
   p,e=geometry(o);re,rl,rp=rest[o.name]
   if len(e)!=len(re) or not np.array_equal(e,re):issues.append({'kind':'animated_topology_changed','object':o.name,'action':action.name,'frame':frame});continue
   if not np.isfinite(p).all():issues.append({'kind':'nonfinite_vertices','object':o.name,'action':action.name,'frame':frame});continue
   lengths=np.linalg.norm(p[e[:,0]]-p[e[:,1]],axis=1);ratios=lengths/np.maximum(rl,1e-6);valid=rl>1e-5;idx=int(np.argmax(lengths));maxedge=float(lengths[idx]);ratio=float(ratios[idx]);max_ratio=float(np.max(ratios[valid])) if valid.any() else 0
   record={'action':action.name,'frame':frame,'max_edge_m':maxedge,'same_edge_rest_m':float(rl[idx]),'same_edge_growth':ratio,'max_edge_growth_any':max_ratio,'edge_vertices':e[idx].tolist()}
   if o.name not in worst or maxedge>worst[o.name]['max_edge_m']:worst[o.name]=record
   bad=np.flatnonzero((lengths>.12)&(ratios>4)&valid)
   if len(bad):issues.append({'kind':'edge_stretch','object':o.name,**record,'bad_count':int(len(bad)), 'failing_edges':[{'vertices':e[k].tolist(),'rest_m':float(rl[k]),'posed_m':float(lengths[k]),'growth':float(ratios[k]),'rest_positions':rp[e[k]].tolist()} for k in bad[:16]]})
   world=np.asarray(o.matrix_world);wp=p@world[:3,:3].T+world[:3,3];mins.append(wp.min(axis=0));maxs.append(wp.max(axis=0))
  low=np.min(mins,axis=0);high=np.max(maxs,axis=0);extent=high-low;bbox_all.append({'action':action.name,'frame':frame,'min':low.tolist(),'max':high.tolist(),'extent':extent.tolist()})
  if max(extent)>3.0:issues.append({'kind':'actor_bounds_over_3m','action':action.name,'frame':frame,'extent':extent.tolist()})
 print(json.dumps({'completed_action':action.name,'issues_so_far':len(issues)}),flush=True)
 summary.append({'action':action.name,'source_frame_range':[lo,hi],'duration_s':(hi-lo)/120,'sampled_frames':frames})
rig.animation_data.action=bpy.data.actions['Idle_Loop'];bpy.context.scene.frame_set(1);bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(out/'supported-uniform-editable.blend'))
r={'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'spear_source_sha256':hashlib.sha256(spear.read_bytes()).hexdigest(),'removed_faulty_live_bevels':removed,'actions':summary,'tested_poses':len(bbox_all),'worst_edges_by_object':worst,'bounds':bbox_all,'issues':issues,'technical_gate_pass':not issues,'visual_pass':False,'gpu':'NOT_RUN','edge_failure_rule':'actual edge >.12m AND >4x exact same rest edge; finite vertices; stable topology; actor extent <=3m; known finite positive bone weights'}
(out/'motion-gate.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({'technical_gate_pass':not issues,'poses':len(bbox_all),'issues':len(issues)}),flush=True)
if issues:raise RuntimeError('Actual full-motion gate failed; inspect report')
