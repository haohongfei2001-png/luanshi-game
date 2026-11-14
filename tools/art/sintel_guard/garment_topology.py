"""Identify real authored seam boundaries before any costume adaptation."""
import bpy,sys,pathlib,json,collections,hashlib
args=sys.argv[sys.argv.index('--')+1:];src,out=map(pathlib.Path,args[:2]);sha=hashlib.sha256(src.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False);rows=[]
for name in ['GEO-topLT','GEO-pantsLT.001','GEO-bootsLT.001','GEO-torso-beltsLT.001','GEO-toplaceLT.001','GEO-sashDG.001']:
 obj=bpy.data.objects[name];mesh=obj.data;count=collections.Counter(tuple(sorted(e)) for f in mesh.polygons for e in f.edge_keys)
 boundary=[e for e,n in count.items() if n==1];adj=collections.defaultdict(set)
 for a,b in boundary:adj[a].add(b);adj[b].add(a)
 pending=set(adj);components=[]
 while pending:
  stack=[pending.pop()];group=set(stack)
  while stack:
   for q in adj[stack.pop()]:
    if q in pending:pending.remove(q);group.add(q);stack.append(q)
  pts=[mesh.vertices[i].co for i in group]
  components.append({'vertex_ids':sorted(group),'closed_loop':all(len(adj[i])==2 for i in group),'local_min':[min(p[j] for p in pts) for j in range(3)],'local_max':[max(p[j] for p in pts) for j in range(3)]})
 rows.append({'object':name,'vertices':len(mesh.vertices),'faces':len(mesh.polygons),'boundary_components':components,'nonmanifold_edges_over_two_faces':sum(n>2 for n in count.values()),'notes':'Original control topology only. MeshDeform transforms local positions; do not use these bounds as evaluated world coordinates. Open garment cuffs are not automatically defects.'})
assert hashlib.sha256(src.read_bytes()).hexdigest()==sha
out.write_text(json.dumps({'source_sha256':sha,'source_unchanged':True,'garments':rows},indent=2)+'\n')
print([(r['object'],len(r['boundary_components']),r['nonmanifold_edges_over_two_faces']) for r in rows])
