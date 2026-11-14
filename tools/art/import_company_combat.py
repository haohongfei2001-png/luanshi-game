"""Inventory the already licensed Quaternius Standard humanoid animation source."""
import hashlib
import json
import math
import numpy as np
from pathlib import Path
import struct
import sys
import zipfile
from import_company_march import ARCHIVE_SHA256, NAME, quat_matrix, sample


def as_quaternion(matrix):
    # Symmetric eigenvalue form remains stable for half turns.
    m=matrix
    k=np.array([[m[0,0]-m[1,1]-m[2,2],m[1,0]+m[0,1],m[2,0]+m[0,2],m[2,1]-m[1,2]],
                [m[1,0]+m[0,1],m[1,1]-m[0,0]-m[2,2],m[2,1]+m[1,2],m[0,2]-m[2,0]],
                [m[2,0]+m[0,2],m[2,1]+m[1,2],m[2,2]-m[0,0]-m[1,1],m[1,0]-m[0,1]],
                [m[2,1]-m[1,2],m[0,2]-m[2,0],m[1,0]-m[0,1],np.trace(m)]])/3.
    values,vectors=np.linalg.eigh(k)
    q=vectors[:,np.argmax(values)]
    return q if q[3]>=0. else -q

def extract_combat(document, accessor, digest):
    nodes=document["nodes"]
    names={n["name"]:i for i,n in enumerate(nodes) if "name" in n}
    parents={child:i for i,n in enumerate(nodes) for child in n.get("children",[])}
    selected=("hips","spine.003","head","upper_arm.L","forearm.L","hand.L","upper_arm.R","forearm.R","hand.R",
              "thigh.L","shin.L","foot.L","toe.L","thigh.R","shin.R","foot.R","toe.R")
    def world(tracks,t):
        result={}
        def matrix(index):
            if index in result: return result[index]
            node=nodes[index]
            if "matrix" in node:
                local=np.asarray(node["matrix"]).reshape((4,4)).T.copy()
            else:
                def component(key,default):
                    if (index,key) in tracks:
                        times,values=tracks[index,key]
                        return sample(times,values,t,key=="rotation")
                    return np.asarray(node.get(key,default),float)
                local=np.eye(4)
                local[:3,3]=component("translation",[0,0,0])
                local[:3,:3]=quat_matrix(component("rotation",[0,0,0,1]))@np.diag(component("scale",[1,1,1]))
            result[index]=matrix(parents[index])@local if index in parents else local
            return result[index]
        return {name:matrix(names["DEF-"+name]) for name in selected}
    rest=world({},0.)
    up=np.array([0.,1.,0.])
    right=rest["upper_arm.R"][:3,3]-rest["upper_arm.L"][:3,3]
    right[1]=0.
    right/=np.linalg.norm(right)
    forward=np.cross(right,up)
    toes=rest["toe.L"][:3,3]+rest["toe.R"][:3,3]-rest["foot.L"][:3,3]-rest["foot.R"][:3,3]
    if np.dot(toes,forward)<0: forward=-forward
    axes=np.stack((right,up,forward))
    origin=(rest["foot.L"][:3,3]+rest["foot.R"][:3,3])*.5
    size=(1.427-.123)/((rest["head"][:3,3]-origin)@up)
    rest_rotation={}
    for name,m in rest.items():
        rest_rotation[name]=m[:3,:3]/np.linalg.norm(m[:3,:3],axis=0)[None,:]
    curves={}
    for title in ("Sword_Attack","Sword_Idle","Hit_Chest","Hit_Head"):
        animation=next(a for a in document["animations"] if a["name"]==title)
        tracks={}
        duration=0.
        for channel in animation["channels"]:
            sampler=animation["samplers"][channel["sampler"]]
            if sampler.get("interpolation","LINEAR")!="LINEAR": raise ValueError(sampler)
            time=np.asarray(accessor(sampler["input"]),float).ravel()
            values=np.asarray(accessor(sampler["output"]),float)
            tracks[channel["target"]["node"],channel["target"]["path"]]=(time,values)
            duration=max(duration,float(time[-1]))
        records=[]
        for frame in range(65):
            transformed=world(tracks,duration*frame/64.)
            points,rotations={},{}
            for name,m in transformed.items():
                p=axes@(m[:3,3]-origin)*size+np.array([0.,.123,0.])
                r=m[:3,:3]/np.linalg.norm(m[:3,:3],axis=0)[None,:]
                q=as_quaternion(axes@r@rest_rotation[name].T@axes.T)
                if records and np.dot(q,records[-1]["q"][name])<0: q=-q
                points[name]=p.round(6).tolist()
                rotations[name]=q.round(7).tolist()
            records.append({"p":points,"q":rotations})
        hand=np.asarray([row["p"]["hand.R"] for row in records])
        contact=int(np.argmax(hand[:,2]))/64.
        curves[title]={"duration":duration,"forward_hand_phase":contact,"frames":records}
        print("COMBAT_CURVE",title,"duration",duration,"contact candidate",contact,
              "hand extent",np.ptp(hand,axis=0).round(4).tolist(),
              "feet extent",{side:np.ptp([r["p"]["foot."+side] for r in records],axis=0).round(4).tolist() for side in ("L","R")},flush=True)
    target=Path("tools/art/source/combat_curves.json")
    target.write_text(json.dumps({"author":"Quaternius","license":"CC0","source_sha256":digest,
                                 "scale_m":size,"game_basis":axes.tolist(),"curves":curves},separators=(",",":"))+"\n")

def main():
    archive=Path(sys.argv[1])
    digest=hashlib.sha256(archive.read_bytes()).hexdigest()
    if digest!=ARCHIVE_SHA256:
        raise ValueError("The verified Quaternius Standard archive changed: "+digest)
    with zipfile.ZipFile(archive) as source:
        notice=source.read("Animation Library[Standard]/License.txt").decode("utf-8-sig")
        if "CC0" not in notice: raise ValueError("The source CC0 notice is absent")
        raw=source.read(NAME)
    size=struct.unpack_from("<I",raw,12)[0]
    document=json.loads(raw[20:20+size])
    binary=raw[28+size:]
    def accessor(index):
        a=document["accessors"][index]
        view=document["bufferViews"][a["bufferView"]]
        width={"SCALAR":1,"VEC3":3,"VEC4":4,"MAT4":16}[a["type"]]
        if a["componentType"]!=5126: raise ValueError(a)
        start=view.get("byteOffset",0)+a.get("byteOffset",0)
        stride=view.get("byteStride",width*4)
        return [struct.unpack_from("<"+"f"*width,binary,start+i*stride) for i in range(a["count"])]
    clips=[]
    for anim in document["animations"]:
        end=max(accessor(sampler["input"])[-1][0] for sampler in anim["samplers"])
        clips.append({"name":anim["name"],"seconds":end,"channels":len(anim["channels"])})
    out=Path("docs/evidence/river-gate-v1-rc23/native-combat")
    out.mkdir(parents=True,exist_ok=True)
    result={"author":"Quaternius","license":"CC0","archive_sha256":digest,
            "source_glb_sha256":hashlib.sha256(raw).hexdigest(),
            "source_file":NAME,"clips":clips,
            "nodes":[{"index":i,"name":n.get("name"),"children":n.get("children",[])} for i,n in enumerate(document["nodes"])]}
    (out/"source-survey.json").write_text(json.dumps(result,indent=2)+"\n")
    (out/"source-license.txt").write_text(notice)
    extract_combat(document,accessor,result["source_glb_sha256"])
    print("VERIFIED_COMBAT_SOURCE",json.dumps({"archive_sha256":digest,"clips":clips}),flush=True)

if __name__=="__main__": main()
