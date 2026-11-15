"""Actual v2 mother geometry/semantic consistency; not art/native gameplay proof."""
import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
source,contractfile,output=map(Path,sys.argv[sys.argv.index('--')+1:]);bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False);c=json.loads(contractfile.read_text())
vs=[];tris=[]
for o in bpy.data.objects:
 if o.type!='MESH' or (o.parent and o.parent.name=='GateDoor'):continue
 o.data.calc_loop_triangles();offset=len(vs);vs.extend(o.matrix_world@v.co for v in o.data.vertices);tris.extend(tuple(offset+i for i in t.vertices) for t in o.data.loop_triangles)
bvh=BVHTree.FromPolygons(vs,tris,all_triangles=True)
def ray(p,d,length):return bvh.ray_cast(Vector((p[0],-p[2],p[1])),Vector((d[0],-d[2],d[1])),length)
checks=[]
for z in [-.15,.5,2,3,4,5.5,6.15]:
 for y in [1.25,2.2,3.8,4.6,6.55]:
  hit=ray((26.9,y,z),(1,0,0),6.2)[0];assert hit is None,('gate_aperture_blocked',y,z,hit)
  checks.append([y,z])
# Walk deck is only an explicitly declared surface, never the topmost roof.
deck=[]
for x in [-6.8,-4,-1,0,1,4,6.8]:
 for z in [-3.4,-1.7,0,1.7,3.4]:
  hit=ray((x,1.3,z),(0,-1,0),.6)[0];assert hit is not None,('missing_deck',x,z)
  assert .92<=hit.z<=1.025,('deck_height',x,z,hit.z)
  head=ray((x,1.05,z),(0,1,0),3.5)[0];assert head is None,('bridge_headroom',x,z,head)
  deck.append([x,z,hit.z])
# Original inner shoulder is NOT coupled to old x48 ground constants.
assert c['gate_dynamic']['pivot']==[30,1.2,3]
assert len(c['walk_surfaces'])==2 and not c['upper_routes_walkable']
assert len(c['solid_obstacles'])>=10
r={'status':'PASS_SOURCE_GATEWAY_CONTRACT_NOT_GAME_ART','gate_clear_rays':len(checks),'gate_min_width':6.4,'gate_min_height':5.4,'deck_and_headroom_samples':len(deck),'deck_top_min_max':[min(a[2] for a in deck),max(a[2] for a in deck)],'ordinary_count_per_side':c['ordinary_count_per_side'],'muster':'NOT_RUN','scope':'finite actual mother mesh rays, actual source solid orientation, semantic contract; no claim full battle/native visual/performance acceptance'}
output.write_text(json.dumps(r,indent=2));print(json.dumps(r))
