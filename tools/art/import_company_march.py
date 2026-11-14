"""Transfer the CC0 master pelvis and shoulder motion into metre/degree marching curves.

Only upper-body travel is retargeted here. Game foot contacts, weapon grips, combat
animations and timing are kept by the existing two-link soldier rig and GPU palette.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
import zipfile

import numpy as np

ARCHIVE_SHA256 = "18ff1a7215f4852b320203e8aaf02a1578b5c8eef9027fbaedfcedc7b85a3ac2"
NAME = "Animation Library[Standard]/Godot/AnimationLibrary_Godot_Standard.glb"
CLIPS = ("Walk_Loop", "Walk_Formal_Loop", "Jog_Fwd_Loop")
FRAMES = 32

def quat_matrix(q):
    x,y,z,w=q/np.linalg.norm(q)
    return np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],
                     [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],
                     [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])

def sample(keys, values, t, rotation):
    i=min(max(0,int(np.searchsorted(keys,t,side="right"))-1),len(keys)-1)
    if i==len(keys)-1: return values[i]
    u=float(np.clip((t-keys[i])/(keys[i+1]-keys[i]),0,1))
    a,b=values[i],values[i+1]
    if not rotation: return a*(1-u)+b*u
    dot=float(np.dot(a,b))
    if dot<0: b,dot=-b,-dot
    angle=math.acos(min(1,dot))
    if angle<.001: return a*(1-u)+b*u
    return (a*math.sin((1-u)*angle)+b*math.sin(u*angle))/math.sin(angle)

def capture(g, binary):
    nodes=g["nodes"]
    by_name={n["name"]:i for i,n in enumerate(nodes) if "name" in n}
    parents={c:i for i,n in enumerate(nodes) for c in n.get("children",[])}
    def values(index):
        a=g["accessors"][index]
        view=g["bufferViews"][a["bufferView"]]
        if a["componentType"]!=5126: raise ValueError("Non-float animation data")
        stride={"SCALAR":1,"VEC3":3,"VEC4":4}[a["type"]]
        arr=np.ndarray(shape=(a["count"],stride),dtype="<f4",buffer=binary,
                       offset=view.get("byteOffset",0)+a.get("byteOffset",0),
                       strides=(view.get("byteStride",stride*4),4))
        return arr.astype(float)
    def get_points(tracks, t):
        world={}
        def mat(j):
            if j in world: return world[j]
            node=nodes[j]
            m=np.eye(4)
            if "matrix" in node:
                m=np.asarray(node["matrix"]).reshape(4,4).T.copy()
            else:
                def component(k,default):
                    if (j,k) in tracks:
                        tms,raw=tracks[j,k]
                        return sample(tms,raw,t,k=="rotation")
                    return np.asarray(node.get(k,default),float)
                m[:3,3]=component("translation",[0,0,0])
                m[:3,:3]=quat_matrix(component("rotation",[0,0,0,1])) @ np.diag(component("scale",[1,1,1]))
            world[j]=mat(parents[j]) @ m if j in parents else m
            return world[j]
        names=("hips","thigh.R","thigh.L","upper_arm.R","upper_arm.L","head","foot.L","foot.R","toe.L","toe.R","hand.L")
        return {n:mat(by_name["DEF-"+n])[:3,3] for n in names}
    rest=get_points({},0.)
    up=np.array([0.,1.,0.])
    right=rest["upper_arm.R"]-rest["upper_arm.L"]
    right[1]=0.
    right/=np.linalg.norm(right)
    forward=np.cross(right,up)
    toes=rest["toe.L"]+rest["toe.R"]-rest["foot.L"]-rest["foot.R"]
    if np.dot(toes,forward)<0: forward=-forward
    stature=(rest["head"]-(rest["foot.L"]+rest["foot.R"])*.5)@up
    if not .5<stature<300: raise ValueError(f"Unknown author scale {stature}")
    size=1.52/stature
    result={}
    for clip in CLIPS:
        anim=next(a for a in g["animations"] if a["name"]==clip)
        tracks={}
        end=0.
        for channel in anim["channels"]:
            sampler=anim["samplers"][channel["sampler"]]
            if sampler.get("interpolation","LINEAR")!="LINEAR": raise ValueError("Unsupported motion interpolation")
            keys=values(sampler["input"]).ravel()
            path=channel["target"]["path"]
            tracks[channel["target"]["node"],path]=(keys,values(sampler["output"]))
            end=max(end,float(keys[-1]))
        poses=[get_points(tracks,end*i/128.) for i in range(128)]
        start=int(np.argmax([(w["foot.L"]-w["hips"])@forward for w in poses]))
        def tilt(span): return math.degrees(math.atan2(span@up,span@right))
        def twist(span): return -math.degrees(math.atan2(span@forward,span@right))
        def describe(p):
            hips=p["thigh.R"]-p["thigh.L"]
            shoulders=p["upper_arm.R"]-p["upper_arm.L"]
            # In-place source locomotion; remove its clip-average below.
            return [size*(p["hips"]@right),size*(p["hips"]@up),twist(hips),twist(shoulders),
                    tilt(hips),tilt(shoulders)]
        records=np.array([describe(poses[(start+i*4)%128]) for i in range(FRAMES)])
        records-=records.mean(axis=0)
        if any(np.max(np.abs(records),axis=0)>np.array([.2,.15,50,55,35,40])): raise ValueError((clip,np.ptp(records,axis=0)))
        if np.max(np.abs(records[:,2:4]))<1: raise ValueError("Lost source twist")
        result[clip]=records.round(5).tolist()
        print("MARCH_TRANSFER",clip,round(end,3),"left strike phase",start/128,"peak to peak",np.ptp(records,axis=0).round(4).tolist())
    return result

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive",type=Path)
    parser.add_argument("output",type=Path)
    args=parser.parse_args()
    if hashlib.sha256(args.archive.read_bytes()).hexdigest()!=ARCHIVE_SHA256:
        raise ValueError("Source animation archive changed")
    with zipfile.ZipFile(args.archive) as z:
        license_text=z.read("Animation Library[Standard]/License.txt").decode("utf-8-sig")
        if "CC0" not in license_text: raise ValueError(license_text)
        data=z.read(NAME)
    j=struct.unpack_from("<I",data,12)[0]
    g=json.loads(data[20:20+j])
    curves=capture(g,data[28+j:])
    args.output.parent.mkdir(parents=True,exist_ok=True)
    out={"author":"Quaternius","source_sha256":hashlib.sha256(data).hexdigest(),
         "channels":["pelvis_side_m","pelvis_rise_m","pelvis_yaw_deg","shoulder_yaw_deg","pelvis_roll_deg","shoulder_roll_deg"],
         "curves":curves}
    args.output.write_text(json.dumps(out,indent=2)+"\n")

if __name__=="__main__":
    main()
