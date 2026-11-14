"""Keep recording closure separate from actual route completion and art acceptance."""
import json, sys
from pathlib import Path

def validate(path):
    rows = [json.loads(line) for line in Path(path).read_text().splitlines() if line.strip()]
    results = [r for r in rows if r.get('kind') == 'traversal_result']
    if len(results) != 1:
        raise ValueError('Exactly one explicit traversal result required')
    result = results[0]
    if result.get('status') != 'ROUTE_COMPLETED_REQUIRES_VISUAL_REVIEW' or result.get('reached') != result.get('required') or not isinstance(result.get('required'), int) or result['required'] < 2:
        raise ValueError('Route NOT_COMPLETED: '+json.dumps(result))
    return {'route_status':'COMPLETED','route_result':result,'art_status':'NOT_ACCEPTED',
            'full_combat_actions':'NOT_EVALUATED','M5':'DEVICE_NOT_RUN'}

if __name__ == '__main__':
    try: print(json.dumps(validate(sys.argv[1])))
    except Exception as e:
        print(json.dumps({'route_status':'NOT_ACCEPTED','error':str(e)}));raise SystemExit(1)
