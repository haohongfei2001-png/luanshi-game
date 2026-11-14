import bpy,json,math,sys
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];bpy.ops.wm.open_mainfile(filepath=args[0]);report=[]
def segments(o,high):
 m=o.data;vs=[o.matrix_world@v.co for v in m.vertices];y=(max if high else min)(v.y for v in vs);out=[];matrix=o.matrix_world.to_3x3().inverted().transposed()
 for poly in m.polygons:
  ids=list(poly.loop_indices)
  for ia,ib in zip(ids,ids[1:]+ids[:1]):
   a,b=vs[m.loops[ia].vertex_index],vs[m.loops[ib].vertex_index]
   if abs(a.y-y)<1e-5 and abs(b.y-y)<1e-5 and (a-b).length>1e-7:out.append((a,b,(matrix@m.corner_normals[ia].vector).normalized(),(matrix@m.corner_normals[ib].vector).normalized()))
 return out
pairs=[]
for side in ['East','West']:
 names=sorted(o.name for o in bpy.data.objects if o.name.startswith('Roof_'+side+'_central_'))
 pairs.extend([(side+'-north', 'Roof_'+side+'_north',names[0]),(side+'-internal',names[0],names[1]),(side+'-south',names[-1],'Roof_'+side+'_south')])
for side,left_name,right_name in pairs:
 left=segments(bpy.data.objects[left_name],True);right=segments(bpy.data.objects[right_name],False);samples=[]
 for source,target in [(left,right),(right,left)]:
  for a,b,na,nb in source:
   for t in [0.,.25,.5,.75,1.]:
    p=a.lerp(b,t);n=na.lerp(nb,t).normalized();candidates=[]
    for c,d,nc,nd in target:
     u=max(0.,min(1.,(p-c).dot(d-c)/(d-c).length_squared));q=c.lerp(d,u);candidates.append(((p-q).length,nc.lerp(nd,u).normalized()))
    best=min(x[0] for x in candidates);angle=min(math.degrees(n.angle(other)) for gap,other in candidates if gap<best+1e-5)
    samples.append({'gap':best,'angle':angle,'p':list(p)})
 report.append({'side':side,'segments':[len(left),len(right)],'samples':len(samples),'max_surface_gap_m':max(x['gap'] for x in samples),'mean_surface_gap_m':sum(x['gap'] for x in samples)/len(samples),'max_matched_normal_degrees':max(x['angle'] for x in samples),'mean_matched_normal_degrees':sum(x['angle'] for x in samples)/len(samples),'worst':sorted(samples,key=lambda x:x['gap'],reverse=True)[:6],'scope':'bidirectional closest segment/interpolated corner-normal audit, not nearest-vertex approximation'})
open(args[1],'w').write(json.dumps(report,indent=2));print(json.dumps(report))
assert all(r['max_surface_gap_m']<.001 and r['max_matched_normal_degrees']<6. for r in report),'Native band seam integrity failed; not a visual acceptance test'
