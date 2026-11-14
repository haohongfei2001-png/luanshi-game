"""Validate the native sword retarget against the current wrists, soles and release."""
import json
from math import dist,isfinite
from pathlib import Path
from company_motion import *

def main():
    worst_gap=0.
    failing=[]
    floor=10.
    release_error=0.
    boundary=0.
    rows=[]
    for kit in (0,1,7):
        for loadout in ((0,1,2) if kit==7 else (0,)):
            for clip in (2,6):
                for frame in range(65):
                    t=frame/64.
                    bones=pose(kit,clip,t,loadout)
                    assert all(isfinite(v) for q,p in bones for v in (*q,*p))
                    for side,upper,fore,hand in ((-1,LU,LF,LH),(1,RU,RF,RH)):
                        elbow,wrist=arm_nodes(side)[1:]
                        gap=max(dist(trans(bones[upper],elbow),trans(bones[fore],elbow)),
                                dist(trans(bones[fore],wrist),trans(bones[hand],wrist)))
                        worst_gap=max(worst_gap,gap)
                        if gap>.008: failing.append({"kit":kit,"loadout":loadout,"clip":clip,"phase":t,"arm":side,"gap":gap,
                            "shoulder":trans(bones[CHEST],arm_nodes(side)[0]),"wrist":trans(bones[hand],wrist)})
                    for side,thigh,shin,boot in ((-1,LT,LS,LB),(1,RT,RS,RB)):
                        knee,ankle=leg_nodes(side)[1:]
                        gap=dist(trans(bones[shin],ankle),trans(bones[boot],ankle))
                        worst_gap=max(worst_gap,dist(trans(bones[thigh],knee),trans(bones[shin],knee)),gap)
                        if gap>.008: failing.append({"kit":kit,"loadout":loadout,"clip":clip,"phase":t,"leg":side,"gap":gap,"hip":trans(bones[HIPS],leg_nodes(side)[0]),"ankle":trans(bones[boot],ankle)})
                        for dx in (-.05,.05):
                            for dz in (-.072,.187):
                                foot=trans(bones[boot],add(ankle,(dx,-.117,dz)))
                                floor=min(floor,foot[1])
            a=pose(kit,2,1.,loadout)
            b=pose(kit,6,0.,loadout)
            boundary=max(boundary,max(dist(trans(x,(.2,1.,.1)),trans(y,(.2,1.,.1))) for x,y in zip(a,b)))
            old=procedural_pose(kit,2,1.,loadout)
            error=max(dist(trans(a[RH],grip(1)),trans(old[RH],grip(1))),
                      dist(trans(a[RH],add(grip(1),(0.,0.,.8))),trans(old[RH],add(grip(1),(0.,0.,.8)))))
            release_error=max(release_error,error)
            rows.append({"kit":kit,"loadout":loadout,"release_socket_error_m":error})
    report={"max_connected_joint_gap_m":worst_gap,"minimum_sole_y_m":floor,
            "release_socket_error_m":release_error,"windup_recovery_seam_m":boundary,"kits":rows,"failed_joint_samples":sorted(failing,key=lambda x:x["gap"],reverse=True)[:8]}
    out=Path("docs/evidence/river-gate-v1-rc23/native-combat/retarget-metrics.json")
    out.write_text(json.dumps(report,indent=2)+"\n")
    print("NATIVE_COMBAT_CHECK",json.dumps(report),flush=True)
    assert worst_gap<.008,report
    assert floor>=.0059,report
    assert release_error<.0022 and boundary<.0002,report

if __name__=="__main__": main()
