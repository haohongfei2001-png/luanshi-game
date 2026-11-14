"""Recording closure is not traversal success. Preserve failures, then reject them."""
import json,sys
from pathlib import Path
def validate(path):
 rows=[json.loads(line) for line in Path(path).read_text().splitlines() if line.strip()]
 results=[row for row in rows if row.get('kind')=='traversal_result']
 if len(results)!=1:raise ValueError('Exactly one explicit traversal result required')
 result=results[0]
 if result.get('status')!='ROUTE_COMPLETED_REQUIRES_VISUAL_REVIEW' or result.get('reached')!=result.get('required') or not isinstance(result.get('required'),int) or result['required']<2:
  raise ValueError('Route NOT_COMPLETED: '+json.dumps(result))
 return {'route_status':'COMPLETED','route_result':result,'art_status':'NOT_ACCEPTED','action_animation_acceptance':'NOT_EVALUATED','recording_complete_is_not_route_success':True}
if __name__=='__main__':
 try:print(json.dumps(validate(sys.argv[1])))
 except Exception as error:print(json.dumps({'route_status':'NOT_ACCEPTED','error':str(error)}));raise SystemExit(1)
