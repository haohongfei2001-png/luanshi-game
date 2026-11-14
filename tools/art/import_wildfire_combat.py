"""Extract complete Wildfire armed joint chains for measured motion comparison."""
import hashlib
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
import numpy as np
from import_company_combat import as_quaternion
from import_company_march import quat_matrix, sample
from import_garrison_issues import source_file, read_dae, UPSTREAM

SOURCES=(
    ("shield_cut_01","animation/biped/infantry/swordsman/attack_melee_shield_01.dae","c4cae448aeb20d5945cb8f94f354729062815084"),
    ("shield_cut_02","animation/biped/infantry/swordsman/attack_melee_shield_02.dae","32ace1da919078a25f156a0fbb80131af477e1ff"),
    ("shield_cut_03","animation/biped/infantry/swordsman/attack_melee_shield_03.dae","5eda4275dd86bb68eda2e4af934d4314fee5889c"),
    ("spear_01","animation/biped/infantry/spearman/attack_melee_01.dae","85946cb89231cc8063a726eee75bfc29b5e1410f"),
)
JOINTS={"hips":"hip","spine.001":"spine","spine.002":"spine1","spine.003":"chest","head":"head"}
for side in ("L","R"):
    JOINTS.update({"upper_arm."+side:"arm_"+side,"forearm."+side:"forearm_"+side,
                  "hand."+side:"hand_"+side,"thigh."+side:"thigh_"+side,
                  "shin."+side:"leg_"+side,"foot."+side:"foot_"+side})
JOINTS.update({"weapon.R":"weapon_R","shield":"shield","finger.L":"finger_L","finger.R":"finger_R"})
AXES=np.array([[-1.,0.,0.],[0.,0.,1.],[0.,-1.,0.]])

def rotation(m):
    u,_,v=np.linalg.svd(m[:3,:3])
    r=u@v
    if np.linalg.det(r)<0: raise ValueError("Reflected source bone")
    return r

def extract(path):
    doc=ET.parse(path).getroot()
    for item in doc.iter(): item.tag=item.tag.split("}")[-1]
    arrays={}
    for node in doc.findall(".//source"):
        floats=node.find("float_array")
        if floats is not None:
            stride=int(node.find("technique_common/accessor").get("stride","1"))
            arrays[node.get("id")]=np.fromstring(floats.text,sep=" ").reshape(-1,stride)
    samplers={node.get("id"):{i.get("semantic"):i.get("source")[1:] for i in node.findall("input")}
              for node in doc.findall(".//sampler")}
    tracks={}
    for node in doc.findall(".//channel"):
        target=node.get("target")
        if not target.endswith("/transform"): continue
        sampler=samplers[node.get("source")[1:]]
        times=arrays[sampler["INPUT"]].ravel()
        matrices=arrays[sampler["OUTPUT"]].reshape(-1,4,4)
        quaternions=np.array([as_quaternion(rotation(m)) for m in matrices])
        tracks[target.split("/")[0]]=(times,matrices,quaternions)
    scene=doc.find(".//visual_scene")
    local={}
    parent={}
    by_name={}
    def collect(node,ancestor=None):
        key=node.get("id")
        by_name[node.get("name")]=key
        local[key]=np.fromstring(node.findtext("matrix"),sep=" ").reshape(4,4)
        parent[key]=ancestor
        for child in node.findall("node"): collect(child,key)
    for node in scene.findall("node"): collect(node)
    def world(t=None):
        result={}
        def matrix(key):
            if key in result: return result[key]
            m=local[key].copy()
            if t is not None and key in tracks:
                times,matrices,quaternions=tracks[key]
                r=quat_matrix(sample(times,quaternions,t,True))
                sizes=np.linalg.norm(matrices[:,:3,:3],axis=1)
                m[:3,:3]=r@np.diag(sample(times,sizes,t,False))
                m[:3,3]=sample(times,matrices[:,:3,3],t,False)
            result[key]=(matrix(parent[key])@m) if parent[key] else m
            return result[key]
        return {name:matrix(key) for name,key in by_name.items()}
    rest=world()
    skin=doc.find(".//controller/skin")
    links={i.get("semantic"):i.get("source")[1:] for i in skin.find("joints").findall("input")}
    names=skin.find("source[@id='"+links["JOINT"]+"']/Name_array").text.split()
    inverse=dict(zip(names,arrays[links["INV_BIND_MATRIX"]].reshape(-1,4,4)))
    bind_error=max(float(np.max(np.abs(rest[name]@m-np.eye(4)))) for name,m in inverse.items())
    origin=(rest["foot_L"][:3,3]+rest["foot_R"][:3,3])*.5
    scale=1.304/float((rest["head"][:3,3]-origin)[2])
    def point(p): return AXES@(p-origin)*scale+np.array([0.,.123,0.])
    rest_points={name:point(rest[bone][:3,3]).round(7).tolist() for name,bone in JOINTS.items()}
    rest_rotation={name:rotation(rest[bone]) for name,bone in JOINTS.items()}
    points,_,_,_,weights,_=read_dae(path,need_bind_positions=False)
    feet={}
    for side in ("L","R"):
        candidates=[i for i,w in enumerate(weights) if sum(v for name,v in w if name=="foot_"+side)>.8]
        if not candidates: raise ValueError("Source boot vertices missing")
        low=min(points[i,2] for i in candidates)
        feet[side]=[i for i in candidates if points[i,2]<=low+.12]
    start=min(float(t[0][0]) for t in tracks.values())
    finish=max(float(t[0][-1]) for t in tracks.values())
    records=[]
    for frame in range(65):
        w=world(start+(finish-start)*frame/64.)
        p,q={},{}
        for name,bone in JOINTS.items():
            p[name]=point(w[bone][:3,3]).round(6).tolist()
            r=rotation(w[bone])
            value=as_quaternion(AXES@r@rest_rotation[name].T@AXES.T)
            if records and np.dot(value,records[-1]["q"][name])<0: value=-value
            q[name]=value.round(7).tolist()
        prop=rotation(w["weapon_R"])
        weapon=as_quaternion(AXES@prop@np.diag([-1.,1.,1.]))
        sole={}
        for side,indices in feet.items():
            transformed=[]
            for i in indices:
                v=np.append(points[i],1.)
                posed=sum((w[name]@inverse[name]@v)*weight for name,weight in weights[i])
                transformed.append(point(posed[:3]))
            sole[side]=np.asarray(transformed).round(6).tolist()
        records.append({"p":p,"q":q,"weapon":weapon.round(7).tolist(),"sole":sole})
    return {"duration":finish-start,"start":start,"scale_m":scale,"bind_matrix_error":bind_error,
            "rest_points":rest_points,"frames":records,
            "source_boot_vertices":{s:len(v) for s,v in feet.items()}}

def main():
    cache=Path(sys.argv[1])
    cache.mkdir(parents=True,exist_ok=True)
    result={"authors":"Wildfire Games contributors","license":"CC BY-SA 3.0","upstream":UPSTREAM,
            "game_basis":AXES.tolist(),"curves":{}}
    summary=[]
    for name,path,blob in SOURCES:
        source=source_file(cache,path,blob)
        curve=extract(source)
        curve["source_path"]=path
        curve["source_blob"]=blob
        result["curves"][name]=curve
        row={"clip":name,"duration":curve["duration"],"bind_matrix_error":curve["bind_matrix_error"],
             "source_boot_vertices":curve["source_boot_vertices"],
             "hip_travel_m":np.ptp([f["p"]["hips"] for f in curve["frames"]],axis=0).round(4).tolist(),
             "foot_travel_m":{s:np.ptp([f["p"]["foot."+s] for f in curve["frames"]],axis=0).round(4).tolist() for s in ("L","R")},
             "sole_min_max_y":{s:[min(p[1] for f in curve["frames"] for p in f["sole"][s]),
                                  max(min(p[1] for p in f["sole"][s]) for f in curve["frames"])] for s in ("L","R")}}
        summary.append(row)
        print("WILDFIRE_COMBAT_SOURCE",json.dumps(row),flush=True)
    out=Path("tools/art/source/wildfire_combat_curves.json")
    out.write_text(json.dumps(result,separators=(",",":"))+"\n")
    proof=Path("docs/evidence/river-gate-v1-rc23/native-chain")
    proof.mkdir(parents=True,exist_ok=True)
    (proof/"source-comparison.json").write_text(json.dumps(summary,indent=2)+"\n")

if __name__=="__main__": main()
