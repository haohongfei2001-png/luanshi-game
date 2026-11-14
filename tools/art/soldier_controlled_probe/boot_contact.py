"""Author-evaluated complete boot surfaces. Flat diagnostic, not terrain/contact PASS."""
import bpy,json,sys,pathlib,hashlib
from mathutils import Vector
walk,thrust,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:3])
report={'art_pass':False,'contact_pass':False,'ground_y':0,'method':'Connected boot islands matched once to original DEF-foot.L/R at first sample, then fixed topology identities throughout each clip; no position correction','limitations':['Flat source-space surface diagnostic, not actual map Ground.deck_height','Does not establish stance or horizontal foot lock','Original boots have MeshDeform and only Group, no foot vertex groups'],'clips':[]}
for name,source,count in [('walk',walk,33),('thrust',thrust,37)]:
 bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
 scene=bpy.context.scene;rig=bpy.data.objects['rig'];o=bpy.data.objects['GEO-bootsLT.001'];o.modifiers['Multires'].levels=1
 action=rig.animation_data.action;first,last=map(float,action.frame_range);labels={};rows=[]
 for si in range(count):
  f=first+(last-first)*si/(count-1);scene.frame_set(int(f),subframe=f%1);bpy.context.view_layer.update();ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();points=[ev.matrix_world@v.co for v in me.vertices]
  if not labels:
   adj=[[] for _ in me.vertices]
   for e in me.edges:a,b=e.vertices;adj[a].append(b);adj[b].append(a)
   seen=set();components=[]
   for i in range(len(adj)):
    if i in seen:continue
    todo=[i];seen.add(i);ids=[]
    while todo:
     k=todo.pop();ids.append(k)
     for j in adj[k]:
      if j not in seen:seen.add(j);todo.append(j)
    components.append(ids)
   assert len(components)==2, 'Unexpected boot topology: do not guess sides'
   anchors={s:rig.matrix_world@rig.pose.bones['DEF-foot.'+s].head for s in 'LR'}
   for ids in components:
    center=sum((points[i] for i in ids),Vector())/len(ids);side=min(anchors,key=lambda s:(center-anchors[s]).length)
    assert side not in labels,'Ambiguous boot anatomical assignment'
    labels[side]=ids
  assert sum(map(len,labels.values()))==len(points)
  row={'phase':si/(count-1),'source_frame':f,'feet':{}}
  for s,ids in labels.items():
   minimum=min(points[i].z for i in ids);band=[points[i] for i in ids if points[i].z<=minimum+.005];center=sum(band,Vector())/len(band)
   row['feet'][s]={'surface_min_y':minimum,'lowest_5mm_centroid_godot':[center.x,center.z,-center.y],'lowest_5mm_vertices':len(band)}
  rows.append(row);ev.to_mesh_clear()
 report['clips'].append({'name':name,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'island_vertices':{s:len(x) for s,x in labels.items()},'samples':rows,'surface_range':{s:[min(x['feet'][s]['surface_min_y'] for x in rows),max(x['feet'][s]['surface_min_y'] for x in rows)] for s in 'LR'}})
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,indent=2));print('BOOT_SURFACE_DIAGNOSTIC',[(c['name'],c['surface_range']) for c in report['clips']],flush=True)
