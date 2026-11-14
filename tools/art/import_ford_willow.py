#!/usr/bin/env python3
"""Adapt the mature 0 A.D. willow at the main river crossing to River Gate's terrain batch."""
from hashlib import md5
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageFilter
from figure_mesh import Library
from import_garrison_issues import source_file

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/third_party/wildfire_willow"
TREE=("meshes/gaia/trees/willow_a.dae","88fffd3d5f319b27e03f464d70dc9f772777585c")
ATLAS=("textures/skins/gaia/willow_green.png","394245aef453fb83995098a182b32d654cc754ec")

def geometry(cache):
    root=ET.parse(source_file(cache,*TREE)).getroot()
    for n in root.iter():
        n.tag=n.tag.split("}")[-1]
    mesh=root.find(".//geometry/mesh")
    faces=mesh.find("polylist")
    slots={a.get("semantic"):a for a in faces.findall("input")}
    def stream(name,width):
        source=slots[name].get("source")[1:]
        if name=="VERTEX": source=mesh.find(f"vertices[@id='{source}']/input").get("source")[1:]
        data=mesh.find(f"source[@id='{source}']/float_array").text
        return np.fromstring(data,sep=" ").reshape(-1,width)
    p,n,uv=stream("VERTEX",3),stream("NORMAL",3),stream("TEXCOORD",2)
    matrix=np.fromstring(root.find(".//visual_scene/node/matrix").text,sep=" ").reshape(4,4)
    p=p@matrix[:3,:3].T+matrix[:3,3]
    n=n@np.linalg.inv(matrix[:3,:3])
    height=float(p[:,2].max())
    assert height>12. and p[:,2].min()<0.
    # Zero is the original planting line. The root flare extends into the bank.
    p=p[:,[0,2,1]]/height
    p[:,2]*=-1
    n=n[:,[0,2,1]]
    n[:,2]*=-1
    assert set(map(int,faces.find("vcount").text.split()))=={3}
    corners=np.fromstring(faces.find("p").text,sep=" ",dtype=int).reshape(-1,3,3)
    assert len(corners)==783
    # Retain the complete artist mesh, including its real trunk and connected
    # boughs. The previous adapter repeated one crown ten times and imposed
    # disconnected dome silhouettes at every graft.
    data=[]; normals=[]; tex=[]; bindings=[]; indices=[]
    found={}
    for face in corners:
        leaf=uv[face[:,2],0].mean()<.62
        for pi,ni,ti in face:
            key=(int(pi),int(ni),int(ti),bool(leaf))
            if key not in found:
                found[key]=len(data)
                point=p[pi]
                normal=n[ni]
                if leaf:
                    # Crown normals are broad and outward, shared across both
                    # sides of each folded spray. Preserve real alpha cuts.
                    outward=np.array([point[0],.24+point[1]*.32,point[2]])
                    normal=.45*normal+.55*outward/np.linalg.norm(outward)
                data.append(point.tolist())
                normals.append((normal/np.linalg.norm(normal)).tolist())
                tex.append((float(uv[ti,0]),float(1.-uv[ti,1])))
                wind=max(0.,float(point[1])-.18)*(.62 if leaf else .035)
                bindings.append((wind,16.+float(point[1]) if leaf else 18.))
            indices.append((found[key],))
    lib=Library()
    attr={"POSITION":lib.accessor(data,"f",3,True),"NORMAL":lib.accessor(normals,"f",3),
          "TEXCOORD_0":lib.accessor(tex,"f",2),"TEXCOORD_1":lib.accessor(bindings,"f",2)}
    lib.doc["meshes"].append({"name":"Willow","primitives":[{"attributes":attr,"indices":lib.accessor(indices,"H",1)}]})
    lib.doc["nodes"].append({"mesh":0,"name":"Willow"})
    lib.doc["scenes"][0]["nodes"]=[0]
    lib.save(OUT/"ford_willow.glb")
    assert len(indices)//3==783
    print("FORD_WILLOW_COMPLETE",len(indices)//3,np.round(np.array(data).min(axis=0),3),np.round(np.array(data).max(axis=0),3))

def colour(cache):
    raw=Image.open(source_file(cache,*ATLAS)).convert("RGBA")
    raw.thumbnail((1024,1024),Image.Resampling.LANCZOS)
    src=np.asarray(raw,dtype=float)/255.
    alpha=src[:,:,3]
    assert .10<(alpha>.45).mean()<.95
    # Preserve the source's individual slender leaves and open space between
    # hanging shoots. No downsample-and-thicken step or painted opaque canopy.
    rgb=src[:,:,:3].copy()
    leaf_columns=np.arange(alpha.shape[1])/alpha.shape[1]<.62
    leaves=rgb[:,leaf_columns,:]
    value=leaves@np.array([.27,.58,.15])
    olive=np.stack([value*.97,value*.96,value*.57],axis=-1)
    rgb[:,leaf_columns,:]=np.clip(leaves*.56+olive*.44,0.,1.)
    rgba=np.dstack((rgb,alpha))
    target=OUT/"ford_willow.png"
    Image.fromarray(np.rint(255*rgba).astype("uint8")).save(target,optimize=True)
    srcpath="res://"+target.relative_to(ROOT).as_posix()
    result="res://.godot/imported/"+target.name+"-"+md5(srcpath.encode()).hexdigest()+".ctex"
    target.with_suffix(".png.import").write_text(f'''[remap]
importer="texture"
type="CompressedTexture2D"
uid="uid://cfordingwillw"
path="{result}"
metadata={{"vram_texture": false}}

[deps]
source_file="{srcpath}"
dest_files=["{result}"]

[params]
compress/mode=0
mipmaps/generate=true
mipmaps/limit=-1
process/fix_alpha_border=true
detect_3d/compress_to=0
''')

if __name__=="__main__":
    cache=Path(sys.argv[1]);cache.mkdir(parents=True,exist_ok=True)
    OUT.mkdir(parents=True,exist_ok=True)
    geometry(cache);colour(cache)
