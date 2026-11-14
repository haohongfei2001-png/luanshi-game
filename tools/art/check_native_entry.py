"""Measure the candidate's local foot travel through actual fixed-step phase."""
import json
from math import dist
from pathlib import Path
from company_motion import *

def main():
    rows=[]
    for kit,windup,recovery in ((0,.20,.34),(1,.28,.41)):
        record={"kit":kit,"windup_seconds":windup,"recovery_seconds":recovery,"source_support_side":"left","boundaries":{}}
        for clip,duration in ((2,windup),(6,recovery)):
            frames=[]
            for tick in range(int(duration/.05)+2):
                progress=max(0.,min(1.,(tick*.05-.009)/duration))
                bones=pose(kit,clip,progress)
                frames.append({"phase":progress,
                               "L":trans(bones[LB],leg_nodes(-1)[2]),
                               "R":trans(bones[RB],leg_nodes(1)[2])})
            record["boundaries"][str(clip)]={"frames":frames,"max_local_ankle_step_m":{side:max(dist(a[side],b[side]) for a,b in zip(frames,frames[1:])) for side in ("L","R")}}
        rows.append(record)
    out=Path("docs/evidence/river-gate-v1-rc23/native-chain/overhead/entry-audit.json")
    out.write_text(json.dumps({"kind":"diagnosis, no visual acceptance asserted","rows":rows},indent=2)+"\n")
    print("NATIVE_ENTRY_DIAGNOSIS",json.dumps(rows))

if __name__=="__main__": main()
