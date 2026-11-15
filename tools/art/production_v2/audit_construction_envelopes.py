import bpy,sys,json
from pathlib import Path
from mathutils import Vector
mother,report,prior_contract,current_contract,output=map(Path,sys.argv[sys.argv.index('--')+1:]);bpy.ops.wm.open_mainfile(filepath=str(mother),load_ui=False)
r=json.loads(report.read_text());old=json.loads(prior_contract.read_text());new=json.loads(current_contract.read_text())
for k in ['walk_surfaces','solid_obstacles','support_profiles','gate_dynamic','retreat_portal','upper_routes_walkable']:
 assert old[k]==new[k],('topology_contract_changed',k)
faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
def volume(p):
 return abs(sum(p[f[0]].dot(p[f[i]].cross(p[f[i+1]]))/6 for f in faces for i in range(1,len(f)-1)))
rows=[]
for original in r['prior_wall_envelopes']:
 p=list(map(Vector,original['vertices']));center=sum(p,Vector())/8;planes=[]
 for f in faces:
  a,b,c=[p[i] for i in f[:3]];n=(b-a).cross(c-a).normalized()
  if n.dot(center-a)>0:n=-n
  planes.append((n,a))
 children=[o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith(original['name']+'_construction_')];assert len(children)==9
 total=0;max_out=0
 for ob in children:
  vs=[ob.matrix_world@v.co for v in ob.data.vertices];total+=volume(vs)
  for v in vs:
   for n,a in planes:max_out=max(max_out,n.dot(v-a))
 ratio=abs(total-volume(p))/volume(p)
 assert max_out<.0001,('outside_envelope',original['name'],max_out)
 assert ratio<.0001,('solid_volume_changed',original['name'],ratio)
 rows.append({'wall':original['name'],'cells':len(children),'volume_relative_error':ratio,'max_outside_m':max_out})
result={'result':'PASS_SAME_OUTER_ENVELOPE_AND_NAV_CONTRACT','wall_segments':len(rows),'closed_cells':len(r['cells']),'rows':rows,'scope':'actual mother geometry and exact prior semantic data; not visual/gameplay acceptance'}
output.write_text(json.dumps(result,indent=2));print(result['result'],len(rows))
