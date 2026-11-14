"""Blender source-only geometry gate, never a visual acceptance assertion."""
import bpy,json,sys,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
source,output=map(Path,sys.argv[sys.argv.index('--')+1:]);bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
meshes=[o for o in bpy.data.objects if o.type=='MESH' and any(m and m.name=='masonry' for m in o.data.materials)]
verts=[];tris=[]
for o in meshes:
 o.data.calc_loop_triangles();offset=len(verts);verts.extend(o.matrix_world@v.co for v in o.data.vertices);tris.extend(tuple(offset+i for i in t.vertices) for t in o.data.loop_triangles)
bvh=BVHTree.FromPolygons(verts,tris,all_triangles=True)
def ray(p,d,length):return bvh.ray_cast(Vector((p[0],-p[2],p[1])),Vector((d[0],-d[2],d[1])),length)[0]
opening=0
for z in [-3.9,-2,0,2,3.9]:
 for y in [.25,1.8,4.15]:
  assert ray((44,y,z),(1,0,0),12) is None,('MASONRY_BLOCKS_GATE',y,z);opening+=1
walk=0
for x in [49.5,50.5,52.5]:
 for z in [-7.8,-5,5,7.8]:
  assert ray((x,3.3,z),(0,1,0),2.1) is None,('MASONRY_BLOCKS_WALK',x,z);walk+=1
bearing=0
for z in [-7.0,-5.0,-3.5,0,3.5,5,7]:
 for x in [48.0,53.1]:
  hit=ray((x,5.8,z),(0,-1,0),.45)
  assert hit is not None and hit.z>=5.55,('UNSUPPORTED_UPPER_FACADE',x,z,hit);bearing+=1
uv_faces=0
for o in meshes:
 if not o.name.startswith('GateContinuousSpandrel'):continue
 uv=o.data.uv_layers.active
 for t in o.data.loop_triangles:
  a,b,c=[uv.data[i].uv.copy() for i in t.loops]
  area=abs((b-a).cross(c-a))/2
  if t.area>1e-8:assert area>1e-10,('DEGENERATE_MASONRY_UV',o.name,t.index)
  uv_faces+=1
report={'source_blend_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'opening_clear_rays':opening,'walkway_clear_rays':walk,'upper_facade_bearing_rays':bearing,'nondegenerate_new_spandrel_uv_triangles':uv_faces,'scope':'SOURCE_GEOMETRY_ONLY; no runtime collision/gameplay/image acceptance','art':'NOT_ACCEPTED'}
output.write_text(json.dumps(report,indent=2));print('GATE_BEARING_GEOMETRY_PASS',json.dumps(report))
