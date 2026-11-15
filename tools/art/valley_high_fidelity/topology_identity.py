"""Schema1 navigation identity. Visual/author prose never enters the digest."""
import hashlib,json
FIELDS={
 'surfaces':('id','walkable','agent_clearance_m','vertices','triangles'),
 'solids':('id','gate_id','xz_polygon','min_y','max_y'),
 'portals':('id','from_surface','to_surface','endpoints3D','width','clearance','gate_id'),
 'spawn_regions':('id','team','surface_id','xz_polygon','reserved_corridor_z'),
 'retreat_regions':('id','surface_id','xz_polygon'),
 'goal_regions':('id','surface_id','xz_polygon','center','radius'),
}
def numbers(value):
 if isinstance(value,bool) or value is None or isinstance(value,str):return value
 if isinstance(value,(int,float)):
  result=round(value,6)
  return int(result) if result==int(result) else result
 if isinstance(value,list):return [numbers(v) for v in value]
 if isinstance(value,dict):return {k:numbers(v) for k,v in value.items()}
 raise TypeError(type(value))
def normalized(topology):
 out={'schema_version':1,'coordinate_quantization_m':0.000001}
 for collection,fields in FIELDS.items():
  out[collection]=sorted([{k:v for k,v in entry.items() if k in fields} for entry in topology.get(collection,[])],key=lambda v:v['id'])
 if topology.get('gate_dynamic'):
  gate=topology['gate_dynamic'];out['gate_dynamic']={k:gate[k] for k in ('id','entry','exit','width','clear_height','pivot') if k in gate}
 if topology.get('gate_dynamic',{}).get('closed_blocker'):
  out['gate_dynamic']['closed_blocker']={k:v for k,v in topology['gate_dynamic']['closed_blocker'].items() if k in ('xz_polygon','min_y','max_y')}
 return numbers(out)
def topology_digest(topology):
 return hashlib.sha256(json.dumps(normalized(topology),sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
if __name__=='__main__':
 import copy
 base={'surfaces':[{'id':'ground','vertices':[[0,1,2]],'triangles':[],'walkable':True,'agent_clearance_m':9}], 'solids':[{'id':'wall','role':'stone','xz_polygon':[[1,2]],'min_y':0,'max_y':3}], 'gate_dynamic':{'id':'main','entry':[1,0,2],'exit':[2,0,2],'width':4,'visual_group':'GateDoor','open_action':'hide'}}
 modified=copy.deepcopy(base);modified['visual_revision']=99;modified['authored_source_sha256']='new material';modified['solids'][0]['role']='new comment';modified['gate_dynamic']['visual_group']='RenamedMesh';modified['gate_dynamic']['open_action']='different prose';modified['surfaces'][0]['vertices'][0]=[0.,1.,2.]
 assert topology_digest(base)==topology_digest(modified)
 modified['surfaces'][0]['vertices'][0][1]=1.01
 assert topology_digest(base)!=topology_digest(modified)
 print('TOPOLOGY_IDENTITY_PASS: prose/material/float spelling invariant; 1cm support change invalidates')
