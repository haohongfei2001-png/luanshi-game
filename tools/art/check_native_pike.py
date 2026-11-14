"""Measure full spear force chain and exact isolation from the adopted RC24 bank."""
import json,sys
from pathlib import Path
from math import dist
from PIL import Image
from company_motion import *
from check_company_motion import decoded

def main():
    old=Image.open(sys.argv[1]).convert("RGBA")
    now=Image.open("assets/river_gate/figures/company_motion.png").convert("RGBA")
    assert old.size==(528,1684) and now.size==(528,1756)
    changed={3*31+c for c in (1,2,6)}
    changed.update(279+variant*17+CARRY_CLIPS.index(clip) for variant in range(2) for clip in (1,2,6))
    for strip in range(421):
        if strip not in changed:
            assert old.crop((0,strip*4,528,(strip+1)*4)).tobytes()==now.crop((0,strip*4,528,(strip+1)*4)).tobytes(),strip
    for n,clip in enumerate((2,6)):
        assert old.crop((0,(93+clip)*4,528,(94+clip)*4)).tobytes()==now.crop((0,(421+n)*4,528,(422+n)*4)).tobytes()
    wrist=[];baked=[];axis_gap=[];correction=[];span=[];legs=[];hips=[];tips=[]
    for n in range(257):
        phase=n/256.
        m=native_pike_pose(phase)
        original=native_chain_pose(phase,NATIVE_PIKE,PIKE_REST)
        hands=[trans(m[bone],grip(side)) for side,bone in ((-1,LH),(1,RH))]
        axis=rot(m[RH][0],(0.,0.,1.))
        gap=sub(hands[0],hands[1]);along=dot(gap,axis)
        axis_gap.append(sqrt(dot(sub(gap,mul(axis,along)),sub(gap,mul(axis,along)))))
        span.append(along)
        for side,fore,hand,boot in ((-1,LF,LH,LB),(1,RF,RH,RB)):
            w=arm_nodes(side)[2]
            wrist.append(dist(trans(m[fore],w),trans(m[hand],w)))
            correction.append(dist(trans(m[hand],grip(side)),trans(original[hand],grip(side))))
        legs.append({s:trans(m[b],leg_nodes(d)[2]) for s,d,b in (("L",-1,LB),("R",1,RB))})
        hips.append(trans(m[HIPS],(0.,.86,0.)))
        tips.append(pike_tip(m))
    for clip in (1,2,6):
        for n in range(1985):
            phase=n/1984.
            if clip==1:
                lane=3*31+clip
                at=phase*32.
            else:
                sub=phase*PIKE_SEGMENTS
                segment=min(int(sub),PIKE_SEGMENTS-1)
                lane=PIKE_DENSE_BASE+(PIKE_SEGMENTS if clip==6 else 0)+segment
                at=(sub-segment)*31.
            for side,fore,hand in ((-1,LF,LH),(1,RF,RH)):
                w=arm_nodes(side)[2]
                baked.append(dist(trans(decoded(now,fore,0,lane,at),w),trans(decoded(now,hand,0,lane,at),w)))
    a,b=pose(3,2,1.),pose(3,6,0.)
    hit=max(dist(trans(x,p),trans(y,p)) for x,y in zip(a,b) for p in ((0.,0.,0.),(.2,1.,.2)))
    ready=max(dist(trans(pose(3,1,0.)[j],p),trans(pose(3,2,0.)[j],p)) for j in range(16) for p in ((0.,0.,0.),(.2,1.,.2)))
    report={"source":NATIVE_PIKE["source_path"],"source_blob":NATIVE_PIKE["source_blob"],"source_duration":NATIVE_PIKE["duration"],
        "contact_phase":PIKE_CONTACT,"existing_windup_s":.22,"existing_recovery_s":.48,"changed_strips":sorted(changed),
        "preserved_rc24_strips":421-len(changed),"legacy_mounted_spear_copies":2,"same_runtime_bones":16,"same_texture_reads_per_joint":4,"dense_segments_per_spear_action":PIKE_SEGMENTS,"palette":[528,1756],
        "wrist_gap_m":max(wrist),"baked_interpolated_wrist_gap_m":max(baked),"left_grip_axis_error_m":max(axis_gap),
        "sliding_support_hand_range_m":[min(span),max(span)],"maximum_fk_grip_fit_m":max(correction),
        "release_boundary_gap_m":hit,"ready_boundary_gap_m":ready,"max_extension_tip":tips[round(PIKE_CONTACT*256)],
        "hips":hips,"ankles":legs,"tip":tips,"full_art_acceptance":False}
    target=Path("docs/evidence/river-gate-v1-rc25/native-spear/draft")
    target.mkdir(parents=True,exist_ok=True)
    (target/"chain-check.json").write_text(json.dumps(report,indent=2)+"\n")
    print("PIKE_CHAIN_CHECK",json.dumps({k:v for k,v in report.items() if k not in ("hips","ankles","tip")}),flush=True)
    assert max(wrist)<.0015 and max(baked)<.0022 and max(axis_gap)<1.e-8 and hit<1.e-8 and ready<1.e-8

if __name__=="__main__":main()
