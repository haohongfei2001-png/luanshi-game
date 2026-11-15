"""One rigid yaw+translation shared by authoring visuals and all map semantics.
Godot metres, Y up. No scale, roll, pitch, hidden rounding, or independent edits.
"""
import copy,hashlib,json,math
from pathlib import Path
POINT_FIELDS={'center','pivot','entry','exit','west_foot','east_foot'}
ABSOLUTE_Y_FIELDS={'y','ground_y','foundation_bottom','top_y','min_y','max_y','body_step_height','platform_y'}
def matrix(yaw_degrees,translation):
 vals=[float(yaw_degrees)]+list(map(float,translation))
 if len(vals)!=4 or not all(math.isfinite(v) for v in vals):raise ValueError('Finite yaw and exactly3 translation coordinates required')
 a=math.radians(vals[0]);c,s=math.cos(a),math.sin(a);x,y,z=vals[1:]
 return [[c,0,s,x],[0,1,0,y],[-s,0,c,z],[0,0,0,1]]
def point(p,m):
 if len(p)!=3:raise ValueError('Expected XYZ point')
 return [sum(m[i][j]*float(p[j]) for j in range(3))+m[i][3] for i in range(3)]
def transform_contract(contract,yaw_degrees,translation):
 if contract.get('placement',{}).get('applied'):raise ValueError('Already placed contract: use immutable author-local input, not double-transform')
 m=matrix(yaw_degrees,translation);dy=m[1][3]
 def visit(v,key=None):
  if key=='xz_polygon':return [[q[0],q[2]] for q in [point([p[0],0,p[1]],m) for p in v]]
  if key in POINT_FIELDS and isinstance(v,list) and len(v)==3:return point(v,m)
  if key=='axis_endpoints':
   if len(v)!=6:raise ValueError('Expected two XYZ axis endpoints')
   return point(v[:3],m)+point(v[3:],m)
  if key=='top_y_endpoints':return [float(y)+dy for y in v]
  if key in ABSOLUTE_Y_FIELDS and isinstance(v,(float,int)):return float(v)+dy
  if isinstance(v,dict):return {k:visit(value,k) for k,value in v.items()}
  if isinstance(v,list):return [visit(value) for value in v]
  return copy.deepcopy(v)
 out=visit(contract)
 out['placement']={'applied':True,'yaw_degrees':float(yaw_degrees),'translation_xyz':list(map(float,translation)),'godot_matrix_row_major':m,'visual_parent':'ProductionV2Architecture','scale':1,'authoring_to_blender':'B(x,y,z)=(x,-z,y); parent matrix B*M*inverse(B)','rule':'same matrix for visual and all solid/support/walk/gate/portal data; original author-local source unchanged','profile_regeneration_required':True}
 out['coordinates']='placed map-world Godot metres XZ/Yup; one recorded rigid parent transform'
 return out

def write_sidecar(input_path,output_path,yaw_degrees,translation):
 raw=Path(input_path).read_bytes();c=json.loads(raw);out=transform_contract(c,yaw_degrees,translation);out['placement']['author_local_contract_sha256']=hashlib.sha256(raw).hexdigest();Path(output_path).write_text(json.dumps(out,indent=2)+'\n');return out
