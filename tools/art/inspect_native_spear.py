"""Measure original complete pike chains before selecting a two-handed action."""
import json
from pathlib import Path
import sys
import numpy as np
from import_wildfire_combat import extract
from import_garrison_issues import source_file, UPSTREAM
from import_company_march import quat_matrix

SOURCES=(
    ("pike_ready","animation/biped/infantry/pikeman/idle_ready_01.dae","4a2e1615826fefa534d730e3a45d91f0be9023f6"),
    ("pike_01","animation/biped/infantry/pikeman/attack_melee_01.dae","a09187eb845f48b9bd0840463821f51c01aba8ec"),
    ("pike_02","animation/biped/infantry/pikeman/attack_melee_02.dae","1f319000b3e49a12bf85262a553442472feca293"),
    ("pike_03","animation/biped/infantry/pikeman/attack_melee_03.dae","d2410e4984ca435090cbaa8b0ada0d156553cd6f"),
    ("spear_ready","animation/biped/infantry/spearman/idle_ready.dae","b7af5b0137bbfbb972a2ddb1ee42c1e0a60a70ee"),
    ("spear_01","animation/biped/infantry/spearman/attack_melee_01.dae","85946cb89231cc8063a726eee75bfc29b5e1410f"),
)

def main():
    cache=Path(sys.argv[1])
    output=Path("docs/evidence/river-gate-v1-rc25/native-spear/source")
    output.mkdir(parents=True,exist_ok=True)
    records=[]
    for label,path,blob in SOURCES:
        original=source_file(cache,path,blob)
        curve=extract(original)
        curve.update(source_path=path,source_blob=blob,upstream=UPSTREAM,authors="Wildfire Games and contributors",license="CC BY-SA 3.0")
        (output/(label+".json")).write_text(json.dumps(curve,separators=(",",":"))+"\n")
        grip=[]
        tips=[]
        for frame in curve["frames"]:
            point={name:np.asarray(p) for name,p in frame["p"].items()}
            axis=quat_matrix(frame["weapon"])@np.array([0.,0.,1.])
            between=point["finger.L"]-point["finger.R"]
            along=float(between@axis)
            grip.append({"along":along,"off_axis":float(np.linalg.norm(between-along*axis))})
            tips.append(point["weapon.R"]+axis*2.0)
        points=np.asarray(tips)
        max_reach=int(np.argmax(points[:,2]))
        foot={side:np.asarray([f["p"]["foot."+side] for f in curve["frames"]]) for side in ("L","R")}
        row={"clip":label,"duration":curve["duration"],"source":path,"blob":blob,
             "bind_matrix_error":curve["bind_matrix_error"],
             "source_hip_travel_m":np.ptp([f["p"]["hips"] for f in curve["frames"]],axis=0).tolist(),
             "source_ankle_travel_m":{s:np.ptp(p,axis=0).tolist() for s,p in foot.items()},
             "maximum_tip_reach_phase":max_reach/64.,"maximum_tip_reach_m":points[max_reach].tolist(),
             "finger_joint_axis_offset_m":{"min":min(g["off_axis"] for g in grip),"max":max(g["off_axis"] for g in grip)},
             "finger_joint_along_m":{"min":min(g["along"] for g in grip),"max":max(g["along"] for g in grip)},
             "poses":[{"frame":i,"p":curve["frames"][i]["p"],"weapon":curve["frames"][i]["weapon"]} for i in (0,16,32,48,64)]}
        records.append(row)
        print("NATIVE_PIKE_SOURCE",label,curve["duration"],row["finger_joint_axis_offset_m"],row["maximum_tip_reach_phase"],flush=True)
    (output/"audit.json").write_text(json.dumps(records,indent=2)+"\n")

if __name__=="__main__":
    main()
