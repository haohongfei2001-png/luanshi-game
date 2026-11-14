import bpy,json,sys
from mathutils import Vector
result=[]
for o in bpy.data.objects:
 if o.type!='MESH':continue
 pts=[o.matrix_world@v.co for v in o.data.vertices]
 result.append({'name':o.name,'bounds':[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]],'materials':[(m.name,tuple(m.diffuse_color)) for m in o.data.materials if m],'polygons':len(o.data.polygons)})
open(sys.argv[-1],'w').write(json.dumps(result,ensure_ascii=False,indent=2))
