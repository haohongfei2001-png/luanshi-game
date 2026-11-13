#!/usr/bin/env python3
"""Fit Wildfire Games' Han cavalry horse to the existing River Gate carriage and saddle."""
from collections import defaultdict
import json
from pathlib import Path
import struct
import sys
import numpy as np
from PIL import Image, ImageFilter
from figure_mesh import Library, Surface
from import_garrison_issues import read_dae, source_file

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/third_party/wildfire_remounts"
TACK = ROOT / "assets/art/mounts"
MESHES = [
    ("meshes/skeletal/horse_persian.dae","fa5cc4662b5eddf93202f368b05b509ddf2785fc"),
    ("meshes/props/horse/hair_mane_01.dae","445e99c5098ef3c61f2222c71ad903985fb5857d"),
    ("meshes/props/horse/hair_tail_01.dae","88c879e61edb80efce07ce59d5bfd48bbb63ce49"),
]
PIGMENTS = [
    ("horse_brown", "fb2dd588f87fc8c02054a835718bff2ab1adc039"),
    ("horse_gray", "b50e698205d14a9e6c008d5fd3071bcc9e8812bf"),
    ("horse_dark_chestnut", "c43b9931619c818064229c3587ec806c82f83898"),
    ("horse_fading_black", "c169fd23a153b6a7a8e2e45100e6bf71a5ad5468"),
]

def fit(point):
    x,forward,height=point
    # The original DAE is Z-up with its muzzle toward -Y. Fit the crown
    # separately above the seat so the rider and the bit retain their sockets.
    y=np.interp(height,[-.01,2.6,4.01,4.55,5.554],[.012,.915,1.369,1.628,1.993])
    z=np.interp(forward,[-3.992,-3.03,-1.66,-.05,1.57,2.99],[1.187,.785,.480,-.048,-.573,-1.082])
    return (float(x*.418),float(y),float(z))

def leg_group(name):
    if name.startswith("Horse_Tail"): return 12
    if any(k in name for k in ("_Neck","_Head","_ear","_Hair")): return 11
    if not name.endswith(("_L","_R")): return 0
    right=int(name.endswith("_L")) # Positive X is the existing second leg channel.
    if any(k in name for k in ("shoulder","upperarm","_Arm","_Forearm","_Hand","_Hoof_")) and "back" not in name:
        return 1+right
    if any(k in name for k in ("_Femur","_Thigh","_Leg","_Shin","_Foot","_Hoof_back")): return 3+right
    return 0

def make_hide(cache):
    surface=Surface()
    for slot,(path,sha) in enumerate(MESHES):
        pts,uv,faces,uvfaces,weights,_=read_dae(source_file(cache,path,sha),need_bind_positions=False)
        used={}
        for corners,seams in zip(faces,uvfaces):
            ids=[]
            for vertex,st in zip(corners,seams):
                # Join duplicate UV values, retaining the artist's intentional seams.
                u,v=uv[st]
                key=(int(vertex),round(float(u),6),round(float(v),6))
                if key not in used:
                    p=fit(pts[vertex])
                    influences=defaultdict(float)
                    for name,w in weights[vertex]:
                        influences[leg_group(name)]+=w
                    group=max((g for g in influences if g),key=influences.get,default=0)
                    strength=influences[group]/max(sum(influences.values()),1e-10)
                    if group==12:
                        strength*=float(np.clip((1.38-p[1])/.72,0,1))
                    elif group==11:
                        strength*=float(np.clip((p[2]-.27)*1.05+(p[1]-1.14)*.90,0,1))
                    mapped=(float(np.clip(u,.0005,.9995))+(2 if slot==0 else 3),float(np.clip(v,.0005,.9995)))
                    used[key]=surface.vertex(p,mapped,0)
                    surface.joints[-1]=((group+.5)/32.,strength)
                ids.append(used[key])
            surface.faces.append(tuple(ids))
    lib=Library()
    lib.insert("Remount",surface,check_tiles=False)
    lib.save(OUT/"hide.glb")
    print("REMOUNT_HIDE",len(surface.faces),len(surface.positions))

def pigments(cache):
    size=512
    atlas=Image.new("RGB",(size*2,size*2))
    for i,(name,sha) in enumerate(PIGMENTS):
        path=source_file(cache,"textures/skins/skeletal/"+name+".png",sha)
        # Preserve the actual eyes, nostrils, hooves and individual pigments;
        # keep broad plane transitions at the gameplay camera.
        value=Image.open(path).convert("RGB").resize((size,size),Image.Resampling.LANCZOS)
        filtered=value.filter(ImageFilter.SMOOTH)
        value=Image.blend(value,filtered,.45)
        atlas.paste(value,((i%2)*size,(i//2)*size))
    atlas.save(OUT/"horse_coats.png",optimize=True)
    hair=source_file(cache,"textures/skins/props/horse/hair_black.png","8953d4300305148b46a419b62836722ee8bf87e3")
    plume=Image.open(hair).convert("RGBA")
    if plume.getextrema()[3][0]==255: raise ValueError("Missing hair coverage")
    plume.save(OUT/"horse_hair.png",optimize=True)

def isolate_tack():
    # Each source triangle samples a single project atlas tile. Keep actual
    # saddlery, reins, iron, cart, and wheels. The generated coat, mane and
    # markings are replaced with one independent, attributed source mesh.
    doc=json.loads((TACK/"mounts.gltf").read_text())
    raw=(TACK/"mounts.bin").read_bytes()
    lib=Library()
    def values(index):
        a=doc["accessors"][index]
        bv=doc["bufferViews"][a["bufferView"]]
        fmt={5126:"f",5123:"H"}[a["componentType"]]
        width={"VEC3":3,"VEC2":2,"SCALAR":1}[a["type"]]
        it=struct.iter_unpack("<"+fmt*width,raw[bv["byteOffset"]:bv["byteOffset"]+bv["byteLength"]])
        return [tuple(v/65535. for v in row) for row in it] if a.get("normalized") else list(it)
    for obj in doc["meshes"]:
        entry=obj["primitives"][0]
        attrs=entry["attributes"]
        xyz,uv,rig=(values(attrs[tag]) for tag in ("POSITION","TEXCOORD_0","TEXCOORD_1"))
        indices=[r[0] for r in values(entry["indices"])]
        local=Surface()
        used={}
        for a in range(0,len(indices),3):
            face=indices[a:a+3]
            tiles={int(uv[i][0]*4)+4*int(uv[i][1]*4) for i in face}
            if len(tiles)!=1: raise ValueError("Tack UV crossed material")
            if not 6<=tiles.pop()<=13: continue
            for index in face:
                if index not in used:
                    used[index]=local.vertex(xyz[index],uv[index],0)
                    local.joints[-1]=rig[index]
            local.faces.append(tuple(used[i] for i in face))
        lib.insert(obj["name"],local,check_tiles=False)
    lib.save(TACK/"field_tack.glb")

if __name__=="__main__":
    cache=Path(sys.argv[1])
    cache.mkdir(parents=True,exist_ok=True)
    OUT.mkdir(parents=True,exist_ok=True)
    make_hide(cache)
    pigments(cache)
    isolate_tack()
