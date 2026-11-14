"""Check all carried sockets against the actual baked texture, and keep hit frames identical."""
from pathlib import Path
from math import dist
from PIL import Image
from figure_mesh import add
from check_company_motion import decoded, planted_drift
from company_motion import CARRY_KITS,CARRY_CLIPS,REACTIONS,MOUNTED_BASIC,CLIPS,FRAMES,LF,LH,RF,RH,arm_nodes,grip,trans,cycling
import json, sys
dest=Path(__file__).resolve().parents[2]/"assets/river_gate/figures/company_motion.png"
bank=Image.open(dest).convert("RGBA")
assert bank.size==((FRAMES+1)*16,(9*CLIPS+len(CARRY_KITS)*2*len(CARRY_CLIPS)+9*len(REACTIONS)+len(MOUNTED_BASIC))*4)
if len(sys.argv)>1:
    old=Image.open(sys.argv[1]).convert("RGBA")
    assert old.tobytes()==bank.crop((0,0,*old.size)).tobytes(), "existing animation pixels changed"
worst=0.; impact=0.; tip_span={}
for ki,kit in enumerate(CARRY_KITS):
    for ci,clip in enumerate(CARRY_CLIPS):
        for variant in range(2):
            lane=9*CLIPS+(ki*2+variant)*len(CARRY_CLIPS)+ci
            for frame in range(FRAMES):
                for s,fore,hand in ((-1,LF,LH),(1,RF,RH)):
                    w=arm_nodes(s)[2]
                    worst=max(worst,dist(trans(decoded(bank,fore,0,lane,frame),w),trans(decoded(bank,hand,0,lane,frame),w)))
                if (2<=clip<=5 and frame==FRAMES-1) or (6<=clip<=9 and frame==0):
                    for bone in range(16):
                        a=decoded(bank,bone,0,lane,frame); b=decoded(bank,bone,kit,clip,frame)
                        for p in ((0,0,0),(.273,.943,.075),(.273,.943,1.50)):
                            impact=max(impact,dist(trans(a,p),trans(b,p)))
            if clip==1:
                socket=RH if kit!=7 else LH
                end=add(grip(1 if kit!=7 else -1),(0.,0.,1.62) if kit!=7 else (0.,.36,.112))
                prev=trans(decoded(bank,socket,kit,clip,0),end)
                now=trans(decoded(bank,socket,0,lane,0),end)
                tip_span[str((kit,variant+1))]=round(dist(prev,now),3)
report={"alternate_strips":len(CARRY_KITS)*2*len(CARRY_CLIPS),"max_baked_wrist_m":worst,"impact_error_m":impact,"planted_original_m":planted_drift(bank),"distance_from_regular_carry_m":tip_span}
print("FIELD_CARRIES_AUDIT",json.dumps(report),flush=True)
assert worst<.0022 and impact<.00001 and report["planted_original_m"]<.0022
assert min(tip_span.values())>.05
