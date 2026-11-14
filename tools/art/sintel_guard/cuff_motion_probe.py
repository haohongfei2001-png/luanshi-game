"""Measure original sewn boundary loops in author rest/carry; never relocate cuffs."""
import bpy,sys,pathlib,json,hashlib
from mathutils import Vector
source,grip,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:3]);labels={};rows=[]
for name,path in [('source',source),('carry',grip)]:
 bpy.ops.wm.open_mainfile(filepath=str(path),use_scripts=False,load_ui=False)
 o=bpy.data.objects['GEO-topLT-recut'];r=bpy.data.objects['rig']
 for m in o.modifiers:
  if m.type in ['SOLIDIFY','BEVEL']:m.show_viewport=False
 bpy.context.view_layer.update();ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();points=[ev.matrix_world@v.co for v in me.vertices]
 if len(points)!=len(o.data.vertices):raise RuntimeError('Expected exact sewn boundary vertex identity')
 if not labels:
  edges={}
  for f in o.data.polygons:
   ids=list(f.vertices)
   for a,b in zip(ids,ids[1:]+ids[:1]):key=tuple(sorted([a,b]));edges[key]=edges.get(key,0)+1
  adj={}
  for (a,b),n in edges.items():
   if n==1:adj.setdefault(a,[]).append(b);adj.setdefault(b,[]).append(a)
  seen=set();loops=[]
  for start in adj:
   if start in seen:continue
   stack=[start];seen.add(start);ids=[]
   while stack:
    v=stack.pop();ids.append(v)
    for x in adj[v]:
     if x not in seen:seen.add(x);stack.append(x)
   if all(len(adj[i])==2 for i in ids):loops.append(ids)
  for side in 'LR':
   wrist=r.matrix_world@r.pose.bones['DEF-hand.'+side].head
   ids=min(loops,key=lambda ids:(sum((points[i] for i in ids),Vector())/len(ids)-wrist).length)
   labels[side]=ids
 result={}
 for side,ids in labels.items():
  wrist=r.matrix_world@r.pose.bones['DEF-hand.'+side].head;center=sum((points[i] for i in ids),Vector())/len(ids)
  result[side]={'source_vertex_ids':ids,'center_minus_wrist_m':list(center-wrist),'center_distance_m':(center-wrist).length,'radii_m':[min((points[i]-center).length for i in ids),max((points[i]-center).length for i in ids)]}
 rows.append({'pose':name,'sha256':hashlib.file_digest(path.open('rb'),'sha256').hexdigest(),'cuffs':result});ev.to_mesh_clear()
out.write_text(json.dumps({'rows':rows,'contact_pass':False,'limitation':'Boundary centers only, not hand/cloth surface intersection or complete animation coverage'},indent=2));print([(row['pose'],{s:d['center_distance_m'] for s,d in row['cuffs'].items()}) for row in rows])
