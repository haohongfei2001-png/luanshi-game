"""Check a complete authored force chain and unchanged non-candidate clips."""
import json
from math import dist
from pathlib import Path
import sys
from PIL import Image
from company_motion import *
from check_company_motion import decoded

def main():
    original=Image.open(sys.argv[1]).convert("RGBA")
    current=Image.open("assets/river_gate/figures/company_motion.png").convert("RGBA")
    assert original.size==(528,1668)
    assert current.size==(528,1684)
    changed={1,2,6,32,33,37}
    for strip in range(417):
        if strip not in changed:
            assert original.crop((0,strip*4,528,strip*4+4)).tobytes()==current.crop((0,strip*4,528,strip*4+4)).tobytes(),strip
    for index,(kit,clip) in enumerate(MOUNTED_BASIC):
        before=kit*31+clip
        assert original.crop((0,before*4,528,before*4+4)).tobytes()==current.crop((0,(417+index)*4,528,(418+index)*4)).tobytes()
    rows=[]
    for kit in (0,1):
        windup_end,recovery_start=pose(kit,2,1.),pose(kit,6,0.)
        release=max(dist(trans(x,p),trans(y,p)) for x,y in zip(windup_end,recovery_start) for p in ((0,0,0),(.3,1.,.5)))
        assert release<1.e-8
        gaps=[]
        for clip in (2,6):
            for n in range(129):
                bones=pose(kit,clip,n/128.)
                for side,fore,hand,shin,boot in ((-1,LF,LH,LS,LB),(1,RF,RH,RS,RB)):
                    wrist=arm_nodes(side)[2]
                    gaps.append(dist(trans(bones[fore],wrist),trans(bones[hand],wrist)))
                    ankle=leg_nodes(side)[2]
                    gaps.append(dist(trans(bones[shin],ankle),trans(bones[boot],ankle)))
        probes={HIPS:[(0.,.86,0.)],CHEST:[(0.,1.24,0.)],HEAD:[(0.,1.57,.02)],NOCK:[grip(-1)]}
        for side,ids in ((-1,(LU,LF,LH,LT,LS,LB)),(1,(RU,RF,RH,RT,RS,RB))):
            a,b,c=arm_nodes(side)
            d,e,f=leg_nodes(side)
            for bone,points in zip(ids,((a,b),(b,c),(c,grip(side)),(d,e),(e,f),(f,add(f,(0.,-.117,.187))))):
                probes[bone]=points
        ready=[]
        for n in range(33):
            idle=pose(kit,1,n/32.)
            first=pose(kit,2,0.)
            ready.append(max(dist(trans(idle[bone],p),trans(first[bone],p)) for bone,points in probes.items() for p in points))
        assert max(ready)<.055,max(ready)
        feet=[]
        for n in range(65):
            phase=n/64.
            bones=native_chain_pose(phase)
            # The original left foot is the persistent supporting leg.
            feet.append(trans(bones[LB],add(leg_nodes(-1)[2],(0.,-.117,0.))))
        support=max(dist(feet[0],p) for p in feet)
        assert max(gaps)<.0015, max(gaps)
        assert support<.012,support
        rows.append({"kit":kit,"source_contact_phase":NATIVE_CONTACT[kit],"source_contact_seconds":NATIVE_CONTACT[kit]*NATIVE_CUT["duration"],
                     "maximum_wrist_ankle_gap_m":max(gaps),"supporting_left_sole_span_m":support,
                     "release_boundary_gap_m":release,"release_tip_m":blade_tip(kit,windup_end),
                     "maximum_ready_to_cut_probe_gap_m":max(ready),"source_clip":"shield_cut_02","source_license":"CC BY-SA 3.0",
                     "old_world_grip_constraint":False})
    report={"preserved_strips":411,"candidate_strips":sorted(changed),"preserved_mounted_strips":4,
            "palette":[528,1684],"runtime_bones":16,"new_runtime_samples":0,"rows":rows}
    out=Path("docs/evidence/river-gate-v1-rc23/native-chain/chain-check.json")
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,indent=2)+"\n")
    print("NATIVE_CHAIN_CHECK",json.dumps(report))

if __name__=="__main__":main()
