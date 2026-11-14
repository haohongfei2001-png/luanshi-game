"""Read donor foot surfaces and phases before proposing any target shoe correction."""
import bpy,json,sys,pathlib
source,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
donor=bpy.data.objects['Armature'];assert len(donor.data.bones)==65
body=next(o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' and m.object==donor for m in o.modifiers))
labels={s:[] for s in 'lr'}
for v in body.data.vertices:
 for s in labels:
  w=sum(g.weight for g in v.groups if body.vertex_groups[g.group].name in ['foot_'+s,'ball_'+s,'ball_leaf_'+s])
  if w>.5:labels[s].append(v.index)
assert all(labels.values());action=donor.animation_data.action;first,last=map(float,action.frame_range);rows=[]
for i in range(33):
 frame=first+(last-first)*i/32;bpy.context.scene.frame_set(int(frame),subframe=frame%1);bpy.context.view_layer.update();ev=body.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh()
 assert len(me.vertices)==len(body.data.vertices),'Cannot guess source to evaluated indices'
 feet={}
 for s,ids in labels.items():
  points=[ev.matrix_world@me.vertices[i].co for i in ids];feet[s]={'surface_min_z':min(p.z for p in points),'ankle_world':list(donor.matrix_world@donor.pose.bones['foot_'+s].head)}
 rows.append({'phase':i/32,'frame':frame,'feet':feet});ev.to_mesh_clear()
r={'kind':'Donor source-space surface diagnostic only; no target correction or stance accepted','donor_object':donor.name,'mesh':body.name,'foot_surface_vertex_counts':{s:len(v) for s,v in labels.items()},'samples':rows,'ranges':{s:[min(x['feet'][s]['surface_min_z'] for x in rows),max(x['feet'][s]['surface_min_z'] for x in rows)] for s in labels}}
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(r,indent=2));print('SOURCE_SURFACES',r['ranges'],flush=True)
