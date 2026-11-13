"""Compare motion sampled from the exact source and candidate GPU textures."""
import json
import sys
from math import atan2, degrees, dist
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parent))
from check_company_motion import decoded, planted_drift
from company_motion import (CARRY_CLIPS,CARRY_KITS,CHEST,CLIPS,FRAMES,HIPS,
                            LB,RB,LF,LH,RF,RH,REACTIONS,arm_nodes,leg_nodes,trans)
from figure_mesh import sub

before,after=[Image.open(f).convert("RGBA") for f in sys.argv[1:3]]
assert before.size==after.size
lanes=[(kit,clip,0,0) for kit in range(9) for clip in range(CLIPS)]
lanes.extend((kit,clip,load,0) for kit in CARRY_KITS for load in (1,2) for clip in CARRY_CLIPS)
lanes.extend((kit,clip,0,side) for kit in range(9) for clip,side in REACTIONS)
assert len(lanes)*4==after.height
changed=[]
for i,(kit,clip,load,side) in enumerate(lanes):
    rect=(0,4*i,after.width,4*i+4)
    differs=before.crop(rect).tobytes()!=after.crop(rect).tobytes()
    walk=clip in (0,1) or clip>=16
    if differs:
        assert walk and side==0,(kit,clip,load,side)
        changed.append(i)
    for boot in (LB,RB):
        first=(FRAMES+1)*boot
        verts=(first,4*i,first+FRAMES+1,4*i+4)
        assert before.crop(verts).tobytes()==after.crop(verts).tobytes(),(kit,clip,boot)
assert len(changed)>80
def read_frame(bank,lane,frame):
    def at(bone,point):
        return trans(decoded(bank,bone,0,lane,frame),point)
    g=sub(at(HIPS,leg_nodes(1)[0]),at(HIPS,leg_nodes(-1)[0]))
    r=sub(at(CHEST,arm_nodes(1)[0]),at(CHEST,arm_nodes(-1)[0]))
    shoulder=at(CHEST,(0.,1.405,-.012))
    hip=at(HIPS,(0.,.858,-.012))
    def yaw(p): return degrees(atan2(-p[2],p[0]))
    def roll(p): return degrees(atan2(p[1],p[0]))
    return (yaw(g),yaw(r),roll(r),yaw(r)-yaw(g),degrees(atan2(shoulder[2]-hip[2],shoulder[1]-hip[1])),hip[0])
def stats(bank,kit,clip):
    frames=[read_frame(bank,kit*CLIPS+clip,i) for i in range(FRAMES)]
    return dict(zip(("pelvis_yaw_deg","shoulder_yaw_deg","shoulder_roll_deg","chest_hip_twist_deg","trunk_lean_deg","pelvis_side_m"),
                    [round(max(series)-min(series),4) for series in zip(*frames)]))
rows={}
for kit in (0,3,5,6,7):
    rows[kit]={}
    for clip,label in ((0,"walk"),(23,"run"),(1,"halt")):
        rows[kit][label]={"before":stats(before,kit,clip),"after":stats(after,kit,clip)}
wrist=0.
for lane in changed:
    for frame in range(FRAMES):
        for side,fore,palm in ((-1,LF,LH),(1,RF,RH)):
            joint=arm_nodes(side)[2]
            a=trans(decoded(after,fore,0,lane,frame),joint)
            b=trans(decoded(after,palm,0,lane,frame),joint)
            wrist=max(wrist,dist(a,b))
drift=planted_drift(after)
print(json.dumps({"banks":[before.size,after.size],"fields":rows,"changed_travel_idle_lanes":len(changed),"matched_nontravel_lanes":len(lanes)-len(changed),"boot_pairs_byte_equal":len(lanes)*2,"worst_changed_wrist_gap_m":wrist,"planted_stance_m":drift},indent=2))
assert wrist<.0022 and drift<.0022
