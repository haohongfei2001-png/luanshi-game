import bpy,json,sys
from mathutils import Vector
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=sys.argv[-2])
result=[]
for o in bpy.data.objects:
 if o.type!='MESH':continue
 pts=[o.matrix_world@v.co for v in o.data.vertices]
 result.append({'name':o.name,'verts':len(pts),'bounds':[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]],'materials':[m.name for m in o.data.materials]})
bpy.ops.wm.save_as_mainfile(filepath=sys.argv[-1]+'.blend')
open(sys.argv[-1]+'.json','w').write(json.dumps(result,indent=2))
