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
    # The old river crossing has its own swept trunk and roots over water.
    # Dress its actual seven bough ends with fitted Wildfire willow sprays.
    # Keep the artist's original folded geometry and alpha silhouette per spray.
    roots=np.arange(len(p))
    def root(i):
        while roots[i]!=i: i=roots[i]
        return i
    for face in corners:
        a,b,c=face[:,0]
        roots[root(a)]=root(b)
        roots[root(a)]=root(c)
    # Fork centre, outer reach, width, pendant length, source island.
    sprays=[
        ((3.18,4.18,-1.55),(1.,-.29),2.59,2.18,469),
        ((-.25,4.51,2.30),(-.32,1.),2.34,1.82,435),
        ((-1.78,4.22,-2.18),(-.72,-.76),2.26,1.65,504),
        ((3.82,4.38,1.58),(.86,.48),2.54,2.27,560),
        ((2.48,5.28,-.60),(.93,.12),2.37,1.70,434),
        ((-.54,5.07,1.34),(-.72,.79),2.08,1.55,490),
        ((1.07,4.85,-2.39),(.03,-1.),2.36,1.88,481),
        # Short leaf fans over the inner forks link the crown while leaving
        # passages of daylight beside the trunk and underneath the leaders.
        ((.77,5.03,.05),(-.87,-.30),1.94,1.14,463),
        ((1.90,4.61,.54),(.68,.80),1.89,1.23,522),
        ((.35,4.53,-.58),(-.52,-.85),1.76,1.21,547),
    ]
    data=[]; normals=[]; tex=[]; bindings=[]; indices=[]
    for location,ray,breadth,fall,part in sprays:
        faces=[face for face in corners if root(face[0,0])==part]
        assert faces and all(uv[face[:,2],0].mean()<.62 for face in faces)
        used=sorted({i for face in faces for i in face[:,0]})
        shape=p[used]
        horizontal=shape[:,[0,2]]
        center=horizontal.mean(axis=0)
        _,_,axes=np.linalg.svd(horizontal-center,full_matrices=False)
        along=(horizontal-center)@axes[0]
        thick=(horizontal-center)@axes[1]
        width=max(np.ptp(along),.01)
        fold=max(np.ptp(thick),.01)
        top,bottom=shape[:,1].max(),shape[:,1].min()
        forward=np.array(ray)/np.linalg.norm(ray)
        across=np.array([-forward[1],forward[0]])
        found={}
        for face in faces:
            for pi,ni,ti in face:
                key=(int(pi),int(ni),int(ti))
                if key not in found:
                    found[key]=len(data)
                    xy=p[pi,[0,2]]-center
                    span=float((xy@axes[0]-.5*(along.min()+along.max()))/width)
                    depth=float((xy@axes[1]-.5*(thick.min()+thick.max()))/fold)
                    drop=(top-p[pi,1])/max(.01,top-bottom)
                    # Crown starts over the fork, grows towards river and turns
                    # down under its own weight. Each outside edge stays folded.
                    bow=.22+.67*np.sin(drop*np.pi*.68)+.27*depth-.32*span*span
                    xz=np.array([location[0],location[2]])+forward*bow+across*span*breadth
                    vert=np.array([xz[0],location[1]-fall*drop-.22*abs(span),xz[1]])/5.63
                    outward=forward*(.38+.65*drop)+across*span*.93
                    normal=np.array([outward[0],1.21-.82*drop,outward[1]])
                    data.append(vert); normals.append(normal/np.linalg.norm(normal))
                    tex.append((uv[ti,0],1.-uv[ti,1]))
                    bindings.append((.12+.45*drop,16.+float(vert[1])))
                indices.append((found[key],))
    lib=Library()
    attr={"POSITION":lib.accessor(data,"f",3,True),"NORMAL":lib.accessor(normals,"f",3),
          "TEXCOORD_0":lib.accessor(tex,"f",2),"TEXCOORD_1":lib.accessor(bindings,"f",2)}
    lib.doc["meshes"].append({"name":"Willow","primitives":[{"attributes":attr,"indices":lib.accessor(indices,"H",1)}]})
    lib.doc["nodes"].append({"mesh":0,"name":"Willow"})
    lib.doc["scenes"][0]["nodes"]=[0]
    lib.save(OUT/"ford_willow.glb")
    print("FORD_WILLOW",len(indices)//3,np.round(np.array(data).min(axis=0),3),np.round(np.array(data).max(axis=0),3))

def colour(cache):
    raw=Image.open(source_file(cache,*ATLAS)).convert("RGBA")
    raw.thumbnail((1024,1024),Image.Resampling.LANCZOS)
    src=np.asarray(raw,dtype=float)/255.
    alpha=src[:,:,3]
    assert .10<(alpha>.45).mean()<.95
    # Flatten the glare into joined midtones while retaining the author's
    # actual drooping sprays, bark grain, leaf holes and cutout silhouette.
    smooth=np.asarray(raw.convert("RGB").filter(ImageFilter.MedianFilter(3)).filter(ImageFilter.GaussianBlur(1.5)),dtype=float)/255.
    y=smooth@np.array([.24,.60,.16])
    value=np.interp(y,[0.,.17,.34,.52,.72,1.],[.13,.21,.32,.415,.51,.60])
    rgb=np.clip(value[:,:,None]+(smooth-y[:,:,None])*.78,0.,1.)
    # The raw atlas is tuned for very large vistas. Join subpixel cuts into
    # single quiet willow sprays; keep the large gaps between pendant fans.
    leaves=raw.getchannel("A")
    soft=leaves.resize((256,256),Image.Resampling.LANCZOS)
    soft=soft.filter(ImageFilter.GaussianBlur(.34))
    soft=soft.filter(ImageFilter.GaussianBlur(.5)).resize(leaves.size,Image.Resampling.BICUBIC)
    a=np.asarray(soft,dtype=float)/255.
    leaf_columns=np.arange(alpha.shape[1])/alpha.shape[1]<.62
    alpha[:,leaf_columns]=np.clip((.63*a[:,leaf_columns]+.37*alpha[:,leaf_columns]-.14)*1.55,0.,1.)
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
