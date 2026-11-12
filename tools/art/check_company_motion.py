#!/usr/bin/env python3
"""Measure the visible forearm-to-hand seam in every authored weapon and state."""
import argparse
import json
from math import dist, sqrt
from pathlib import Path
from PIL import Image
from company_motion import CLIPS, FRAMES, LF, LH, RF, RH, NOCK, arm_nodes, grip, pose, trans
from figure_mesh import add

def decoded(bank,b,kit,clip,frame):
    x=frame%8*48+b*3;y=(kit*16+clip)*4+frame//8
    hi=bank.getpixel((x+1,y));lo=bank.getpixel((x+2,y))
    tails=(hi[3]>>4,hi[3]%16,lo[3]>>4,lo[3]%16)
    q=[((v*16+tail)/4095)*2-1 for v,tail in zip(bank.getpixel((x,y)),tails)]
    length=sqrt(sum(v*v for v in q))
    t=tuple(((hi[k]*256+lo[k])/65535-.5)*6 for k in range(3))
    return tuple(v/length for v in q),t

def measure():
    bank=Image.open(Path(__file__).resolve().parents[2]/"assets/river_gate/figures/company_motion.png").convert("RGBA")
    rows=[]
    for kit in range(9):
        gaps=[]; nocks=[]; baked=[]
        for clip in range(CLIPS):
            for frame in range(FRAMES):
                phase=frame/(FRAMES if clip in (0,1,12,15) else FRAMES-1)
                bones=pose(kit,clip,phase)
                for side,fore,hand in ((-1,LF,LH),(1,RF,RH)):
                    wrist=arm_nodes(side)[2]
                    gaps.append(dist(trans(bones[fore],wrist),trans(bones[hand],wrist)))
                    baked.append(dist(trans(decoded(bank,fore,kit,clip,frame),wrist),trans(decoded(bank,hand,kit,clip,frame),wrist)))
                if kit==5 and clip!=15:
                    nocks.append(dist(trans(bones[NOCK],add(grip(1),(0,0,-.159))),trans(bones[LH],grip(-1))))
        gaps.sort()
        rows.append(dict(kit=kit,measurements=len(gaps),p95_m=round(gaps[int(.95*len(gaps))-1],6),
                         worst_wrist_m=round(gaps[-1],6),baked_wrist_m=round(max(baked),6),worst_nock_m=round(max(nocks,default=0.),6)))
    return rows

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report-only",action="store_true")
    args=parser.parse_args()
    rows=measure()
    print("RIVER_GRIP_AUDIT",json.dumps(rows))
    if not args.report_only and any(r["worst_wrist_m"]>.008 or r["worst_nock_m"]>.0001 or r["baked_wrist_m"]>.0022 for r in rows):
        raise SystemExit("Forearm or nocking point lost contact with its working hand")
