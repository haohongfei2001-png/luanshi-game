#!/usr/bin/env python3
"""Measure the visible forearm-to-hand seam in every authored weapon and state."""
import argparse
import json
from math import cos, dist, pi, sin, sqrt
from pathlib import Path
from PIL import Image
from company_motion import CLIPS, FRAMES, LF, LH, RF, RH, NOCK, LB, arm_nodes, grip, leg_nodes, pose, trans
from figure_mesh import add

def decoded(bank,b,kit,clip,frame):
    # Reconstruct the value sampled by a linearly filtered shader, including subkeys.
    x=b*(FRAMES+1)+int(frame)
    y=(kit*CLIPS+clip)*4
    fraction=frame-int(frame)
    def raw(row):
        a=bank.getpixel((x,y+row))
        if fraction==0: return a
        n=bank.getpixel((x+1,y+row))
        return [first*(1-fraction)+last*fraction for first,last in zip(a,n)]
    q_hi,q_lo,t_hi,t_lo=[raw(row) for row in range(4)]
    q=[(hi*256+lo)/65535*2-1 for hi,lo in zip(q_hi,q_lo)]
    length=sqrt(sum(v*v for v in q))
    t=tuple(((t_hi[k]*256+t_lo[k])/65535-.5)*6 for k in range(3))
    return tuple(v/length for v in q),t

def planted_drift(bank):
    worst=0.
    for i in range(16):
        running=i>=8
        clip=23+i%8 if running else (0 if i==0 else 15+i)
        heading=(i%8)*pi/4
        stance=.355 if running else .51
        metres_per_cycle=1/(.42 if running else .68)
        points=[]
        for subkey in range(FRAMES*8):
            frame=subkey/8
            phase=frame/FRAMES
            if not .25*stance<=phase<=.70*stance: continue
            foot=trans(decoded(bank,LB,3,clip,frame),leg_nodes(-1)[2])
            points.append(add(foot,(sin(heading)*phase*metres_per_cycle,0.,cos(heading)*phase*metres_per_cycle)))
        worst=max(worst,max(dist(points[0],v) for v in points))
    return worst

def measure():
    bank=Image.open(Path(__file__).resolve().parents[2]/"assets/river_gate/figures/company_motion.png").convert("RGBA")
    rows=[]
    for kit in range(9):
        gaps=[]; nocks=[]; baked=[]; bow_release=[]; carry_spacing=[]; fallen_brace=[]
        for clip in range(CLIPS):
            for frame in range(FRAMES):
                phase=frame/(FRAMES if clip in (0,1,12,15) or clip>=16 else FRAMES-1)
                bones=pose(kit,clip,phase)
                for side,fore,hand in ((-1,LF,LH),(1,RF,RH)):
                    wrist=arm_nodes(side)[2]
                    gaps.append(dist(trans(bones[fore],wrist),trans(bones[hand],wrist)))
                    baked.append(dist(trans(decoded(bank,fore,kit,clip,frame),wrist),trans(decoded(bank,hand,kit,clip,frame),wrist)))
                if kit==5 and clip!=15:
                    string=trans(bones[NOCK],add(grip(1),(0,0,-.159)))
                    fingers=trans(bones[LH],grip(-1))
                    # At the instant the missile leaves, the string recoils but
                    # a loose hand must finish behind the cheek. During the set
                    # and the pull the nock still meets the fingers exactly.
                    if clip<2 or (clip>=10 and clip!=14) or (clip<=5 and phase<.92):
                        nocks.append(dist(string,fingers))
                    if clip==2 and frame==FRAMES-1:
                        bow_release.append(dist(string,trans(bones[RH],add(grip(1),(0,0,-.159)))))
                    if clip==14 and frame==FRAMES-1:
                        fallen_brace.append(dist(string,trans(bones[RH],add(grip(1),(0,0,-.159)))))
                    if clip==1:
                        other=trans(bones[RH],grip(1))
                        carry_spacing.append(dist(fingers,other))
        gaps.sort()
        rows.append(dict(kit=kit,measurements=len(gaps),p95_m=round(gaps[int(.95*len(gaps))-1],6),
                         worst_wrist_m=round(gaps[-1],6),baked_wrist_m=round(max(baked),6),worst_nock_m=round(max(nocks,default=0.),6),
                         released_brace_m=round(max(bow_release,default=0.),6),
                         fallen_brace_m=round(max(fallen_brace,default=0.),6),
                         gripping_span_m=round(min(carry_spacing,default=0.),6)))
    return rows

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report-only",action="store_true")
    args=parser.parse_args()
    rows=measure()
    print("RIVER_GRIP_AUDIT",json.dumps(rows))
    bank=Image.open(Path(__file__).resolve().parents[2]/"assets/river_gate/figures/company_motion.png").convert("RGBA")
    drift=planted_drift(bank)
    print("PLANTED_GAIT_METRES",round(drift,6))
    bow=rows[5]
    if not args.report_only and (bow["released_brace_m"]>.0001 or bow["fallen_brace_m"]>.0001 or bow["gripping_span_m"]<.18):
        raise SystemExit("The released bow or travelling hand spacing is wrong")
    if not args.report_only and drift>.0022: raise SystemExit("A planted shoe slid during its weight-bearing phase")
    if not args.report_only and any(r["worst_wrist_m"]>.008 or r["worst_nock_m"]>.0001 or r["baked_wrist_m"]>.0022 for r in rows):
        raise SystemExit("Forearm or nocking point lost contact with its working hand")
