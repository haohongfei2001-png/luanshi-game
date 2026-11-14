"""Isolate optional evidence failures without promoting the delivery to PASS."""
import json
from pathlib import Path

def attempt(label, action, failures, receipt):
    try:
        action()
    except Exception as exc:
        failures.append({'step':label,'error_type':type(exc).__name__,'error':str(exc)})
        Path(receipt).write_text(json.dumps({'status':'NOT_PASSED','failures':failures},indent=2)+'\n')
        return False
    return True
