from pathlib import Path
import sys,tempfile,json
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools/art/gate_structure'))
from validate_traversal import validate
with tempfile.TemporaryDirectory() as directory:
 p=Path(directory)/'frames.jsonl'
 for result in [None,{'kind':'traversal_result','status':'NOT_COMPLETED','reached':1,'required':2}]:
  rows=[{'kind':'end','reason':'review_complete'}]+([result] if result else [])
  p.write_text('\n'.join(map(json.dumps,rows)))
  try:validate(p)
  except ValueError:pass
  else:raise AssertionError('Closed recording incorrectly accepted as completed route')
 p.write_text(json.dumps({'kind':'traversal_result','status':'ROUTE_COMPLETED_REQUIRES_VISUAL_REVIEW','reached':2,'required':2}))
 assert validate(p)['route_status']=='COMPLETED'
print('TRAVERSAL_RESULT_SEMANTICS_PASS')
