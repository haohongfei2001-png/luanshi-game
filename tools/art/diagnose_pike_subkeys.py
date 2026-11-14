"""Diagnose sub-key continuity before spending another rendered comparison."""
import json,math
from pathlib import Path
from PIL import Image
from company_motion import *
from check_company_motion import decoded
bake_motion(Path("assets/river_gate/figures"))
bank=Image.open("assets/river_gate/figures/company_motion.png").convert("RGBA")
worst=[]
for clip in (1,2,6):
    for n in range(249):
        at=n/8.
        for side,fore,hand in ((-1,LF,LH),(1,RF,RH)):
            w=arm_nodes(side)[2]
            gap=math.dist(trans(decoded(bank,fore,3,clip,at),w),trans(decoded(bank,hand,3,clip,at),w))
            worst.append({"clip":clip,"frame":at,"side":side,"gap":gap})
rows=sorted(worst,key=lambda x:x["gap"],reverse=True)[:12]
details=[]
for row in rows[:3]:
    clip=row["clip"];frame=int(row["frame"])
    samples=[]
    for f in (frame,frame+.5,frame+1):
        phase=(PIKE_CONTACT*f/31. if clip==2 else PIKE_CONTACT+(1-PIKE_CONTACT)*f/31.)
        raw=native_chain_pose(phase,NATIVE_PIKE,PIKE_REST)
        final=native_pike_pose(phase)
        p,q,weapon,sole=native_sample(phase,NATIVE_PIKE)
        samples.append({"f":f,"phase":phase,"source_points":p,"weapon_q":weapon,
            "raw":raw,"final":final})
    details.append({"row":row,"samples":samples})
out=Path("docs/evidence/river-gate-v1-rc25/native-spear/draft")
out.mkdir(parents=True,exist_ok=True)
(out/"subkey-diagnostic.json").write_text(json.dumps({"worst":rows,"details":details},indent=2)+"\n")
print("SUBKEY_GAPS",json.dumps(rows),flush=True)
