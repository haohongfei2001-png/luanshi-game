#!/usr/bin/env python3
"""Fit Wildfire Games' dressed meshes to the River Gate field bind.

Read the artists' COLLADA positions, UV seams and skin weights directly. Output
the derivative clothing separately from the local faces, arms and footwear.
"""
import hashlib
import json
import math
from pathlib import Path
import sys
from urllib.request import urlopen
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image, ImageFilter
from company_figures import HIPS, CHEST, HEAD, LU, LF, RU, RF, LT, RT, arm_nodes
from figure_mesh import Library, Surface
from figure_atlas import NAMES as MATERIALS
from company_figures import costume as close_costume
from company_line import costume as line_costume

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets" / "third_party" / "wildfire_garments"
UPSTREAM = "61a3b9507d974084e6badb88a0826bd89a6d5b8b"
BASE = f"https://raw.githubusercontent.com/0ad/0ad/{UPSTREAM}/binaries/data/mods/public/art/"
ISSUES = [
    ("Regular", "m_pants_tunic_long", "93b7f7324cc1981dd4db93badf3831856b499913",
     "lamellar_01_lacquered_01", "585ce31b0d9668561b64c314c8dc08d8c3ccdabe"),
    ("Guard", "m_armor_tunic_long", "a1aaccd4806d6fc0f8962e0e0fb111a0bcc2ebc6",
     "lamellar_02_lacquered_01", "08bb71ccc4aac5ed99d95252bfbd2a9f857dd03e"),
    ("Archer", "m_tunic_short", "b983b5615d9ae8fb4400679e80c375cafa9d8fc5",
     "tunic_01_01", "77d91e23287c2ee0f767889fde104d10e7e47281"),
]
NAMES = {"hip":HIPS, "spine":HIPS, "spine1":CHEST, "chest":CHEST,
         "neck":CHEST, "head":HEAD, "shoulder_L":CHEST, "shoulder_R":CHEST}
for suffix, arm, fore, thigh in [("L",LU,LF,LT), ("R",RU,RF,RT)]:
    NAMES.update({"arm_"+suffix:arm, "forearm_"+suffix:fore, "thigh_"+suffix:thigh,
                  "leg_"+suffix:thigh, "hand_"+suffix:fore})

def source_file(cache, name, signature):
    path = cache / Path(name).name
    if not path.exists():
        with urlopen(BASE+name, timeout=40) as response:
            path.write_bytes(response.read())
    raw = path.read_bytes()
    key = b"blob " + str(len(raw)).encode() + b"\0" + raw
    if hashlib.sha1(key).hexdigest() != signature:
        raise ValueError(f"Upstream blob mismatch at {name}")
    return path

def read_dae(path):
    root = ET.parse(path).getroot()
    for node in root.iter():
        node.tag = node.tag.split("}")[-1]
    geometry = root.find(".//geometry/mesh")
    skin = root.find(".//controller/skin")
    def by_id(container, source):
        ident = source.removeprefix("#")
        return container.find(f"source[@id='{ident}']")
    def array(src, stride, kind=float):
        data=src.find("float_array" if kind==float else "Name_array").text.split()
        return np.asarray(data, dtype=kind).reshape((-1,stride))
    triangles = geometry.find("triangles")
    inp = {v.get("semantic"):v for v in triangles.findall("input")}
    verts = geometry.find("vertices/input").get("source")
    points = array(by_id(geometry,verts),3)
    uvs = array(by_id(geometry,inp["TEXCOORD"].get("source")),2)
    uvs[:,1] = 1.-uvs[:,1]
    stride = 1 + max(int(v.get("offset")) for v in inp.values())
    faces = np.fromstring(triangles.findtext("p"),dtype=int,sep=" ").reshape((-1,3,stride))
    joints = {v.get("semantic"):v.get("source") for v in skin.find("vertex_weights").findall("input")}
    names = array(by_id(skin,joints["JOINT"]),1,str).ravel()
    values = array(by_id(skin,joints["WEIGHT"]),1).ravel()
    w = skin.find("vertex_weights")
    pairs = np.fromstring(w.findtext("v"),dtype=int,sep=" ").reshape((-1,2))
    counts = np.fromstring(w.findtext("vcount"),dtype=int,sep=" ")
    weights = []
    index = 0
    for count in counts:
        weights.append([(str(names[j]),float(values[k])) for j,k in pairs[index:index+count]])
        index += count
    world = {}
    def walk(node, parent):
        matrix=np.fromstring(node.findtext("matrix"),sep=" ").reshape((4,4))
        transform = parent @ matrix
        world[node.get("name")] = transform[:3,3]
        for child in node.findall("node"):
            walk(child,transform)
    walk(root.find(".//visual_scene/node"),np.identity(4))
    return points, uvs, faces[:,:,int(inp["VERTEX"].get("offset"))], faces[:,:,int(inp["TEXCOORD"].get("offset"))], weights, world

def change_axis(p):
    # The source left arm has positive X, its forward axis is negative Y.
    return np.asarray([-p[0],p[2],-p[1]])

def segment_frame(axis):
    axis=axis/np.linalg.norm(axis)
    side=np.cross(axis,[0.,0.,1.])
    side/=np.linalg.norm(side)
    return np.stack([side,np.cross(axis,side),axis],axis=1)

def fit_arm(p, source_a, source_b, dest_a, dest_b):
    first, second = source_b-source_a, dest_b-dest_a
    local = segment_frame(first).T @ (p-source_a)
    local[2] *= np.linalg.norm(second)/np.linalg.norm(first)
    local[:2] *= .418
    return dest_a + segment_frame(second) @ local

def fit_garment(path, role, slot):
    points, uvs, triangles, uv_triangles, weights, joints=read_dae(path)
    old={name: change_axis(v) for name,v in joints.items()}
    arm_binds={}
    for label,side in (("L",-1),("R",1)):
        shoulder,elbow,wrist=map(np.asarray,arm_nodes(side))
        arm_binds["arm_"+label]=(old["arm_"+label],old["forearm_"+label],shoulder,elbow)
        arm_binds["forearm_"+label]=(old["forearm_"+label],old["hand_"+label],elbow,wrist)
    s=Surface()
    source_indices={}
    if role=="Guard":
        # Keep the made breast, divided waist and shoulder seam recognisable
        # at 22 m. The long shield coat has more padding below its lames than
        # the light thrusting soldier's; broaden the body, not the skeleton.
        chest_scale,hem_scale=1.045,1.085
    elif role=="Archer":
        chest_scale,hem_scale=.990,1.025
    else:
        chest_scale,hem_scale=1.012,1.025
    def fitted(i):
        p=change_axis(points[i])
        central=np.array([p[0]*(.49 if role=="Guard" else .466),
                          np.interp(p[1],[1.28,2.194,2.81,3.4,3.75,3.90],
                                    [.492,.942,1.205,1.405,1.490,1.521]),
                          p[2]*.456-.014])
        t=float(np.clip((central[1]-.83)/.30,0,1))
        central[[0,2]]*=hem_scale*(1.-t)+chest_scale*t
        pos=np.zeros(3)
        bones={}
        for name,w in weights[i]:
            if w<.00001:
                continue
            j=NAMES.get(name,CHEST)
            bones[j]=bones.get(j,0.)+w
            if name in arm_binds:
                pos+=w*fit_arm(p,*arm_binds[name])
            else:
                pos+=w*central
        total=sum(bones.values())
        two=sorted(bones,key=bones.get,reverse=True)[:2]
        if len(two)==1: two.append(two[0])
        return pos/total,(two[0],two[1],1. if two[0]==two[1] else bones[two[0]]/(bones[two[0]]+bones[two[1]]))
    for tri,uvtri in zip(triangles,uv_triangles):
        st=uvs[uvtri]
        u,v=st.mean(axis=0)
        # Upper quarter of the artist's map holds exposed hands and feet as
        # well as sleeves. Preserve the sleeve down below its elbow joint.
        if v<.249 and (u<.5 or u>.738):
            continue
        # The source maps a pale breech panel below the hem to a separate UV
        # island (upper-left). Keep the project's actual fitted trouser legs.
        if max(st[:,0])<=.501 and max(st[:,1])<=.251:
            continue
        # Remove neck skin. The existing rig supplies the head, throat, arms,
        # breeches and boots. Do not render the coarse source hands over it.
        if points[tri,2].min()>3.67 or points[tri,2].max()<1.31:
            continue
        ids=[]
        for i,k in zip(tri,uvtri):
            u,v=(float(a) for a in uvs[k])
            key=(int(i),round(u,6),round(v,6))
            if key not in source_indices:
                p,b=fitted(i)
                # UV.x in [2,3) marks the separate Wildfire garment atlas.
                # A two-pixel replicated gutter prevents bleed between three issues.
                gutter,edge=4,256
                ux=((slot%2)*(edge+2*gutter)+gutter+max(0.,min(1.,u))*(edge-1)+.5)/528.
                vy=((slot//2)*(edge+2*gutter)+gutter+max(0.,min(1.,v))*(edge-1)+.5)/528.
                source_indices[key]=s.vertex(tuple(p),(2.+ux,vy),b)
            ids.append(source_indices[key])
        # Changing handedness negates the winding. Restore outward normals.
        s.faces.append((ids[0],ids[2],ids[1]))
    if not 200<len(s.faces)<750:
        raise ValueError(f"{role}: {len(s.faces)} triangles out of range")
    bounds=np.array(s.positions)
    if not .42<bounds[:,1].min()<.83 or not 1.44<bounds[:,1].max()<1.55:
        raise ValueError((role,bounds.min(axis=0),bounds.max(axis=0)))
    return s

def cloth(source,role):
    # Upstream alpha carries the player's dye, not transparency. Preserve the
    # fitted artwork: overlapping metal courses, shoulder straps, crossed robe.
    img=Image.open(source).convert("RGBA").resize((256,256),Image.Resampling.LANCZOS)
    source_rgb=np.asarray(img.convert("RGB"),dtype=float)
    source_a=np.asarray(img.getchannel("A"),dtype=float)/255
    # Keep major albedo transitions. Average fine weave and tiny plate holes
    # below the size of a game pixel before the ordinary generated mip chain.
    smooth=np.asarray(img.convert("RGB").filter(ImageFilter.GaussianBlur(.82)),dtype=float)
    rgb=.52*smooth+.48*source_rgb
    pixel=np.indices(source_a.shape)[1]
    tex_y=np.indices(source_a.shape)[0]
    dye=np.clip((1.-source_a)*1.20,0,1)
    bright=np.mean(rgb,axis=2)
    # The upper four rows, exposed skin, leather ties and lames retain their own
    # hues. Even a naturally neutral bolt gets team dye on garment textile.
    neutral=(np.max(rgb,axis=2)-np.min(rgb,axis=2)<24)
    textile=np.clip((bright-100)/65,0,1)*neutral
    dye=np.maximum(dye,textile*(.83 if role=="Archer" else .91))
    if role=="Archer":
        # Leave the pale working shirt visible and reserve the deepest dye for
        # the collar / sleeves. The quiver stays a dark readable diagonal.
        sleeve=(tex_y<64)&(pixel>=128)&(pixel<218)
        dye*=np.where(sleeve,1.0,.68)
    # The lower hem of the long coats has a narrow underfold. It is coarse
    # unbleached wool in the source sheet; a pure undyed stripe cut across an
    # entire formation at 22 m. Carry a deeper piece of the same issued dye
    # around the bound hem as in the facing at the neck and cuff.
    hem=(tex_y>=210)&(np.mean(rgb,axis=2)>86)
    brown=(rgb[:,:,0]>=rgb[:,:,1])&(rgb[:,:,1]>=rgb[:,:,2])
    dye=np.where(hem & brown,np.maximum(dye,.91),dye)
    luminance=.25*rgb[:,:,0]+.56*rgb[:,:,1]+.19*rgb[:,:,2]
    # Translate photographic black iron into three broad, blue-grey values;
    # keep the lighter edge of each lacing row and warm leather distinct.
    iron=(1.-np.clip((luminance-49)/55,0,1))*(1.-dye)
    new_iron=np.stack([54.+luminance*.49,59.+luminance*.48,58.+luminance*.43],axis=-1)
    rgb=rgb*(1.-iron[:,:,None])+new_iron*iron[:,:,None]
    rgb=np.clip(rgb,0,255)
    tile=np.dstack([rgb,255.*dye]).round().astype(np.uint8)
    return Image.fromarray(np.pad(tile,((4,4),(4,4),(0,0)),mode="edge"),"RGBA")

def body_under_issue(look, lod):
    # Copy only fitted heads, wrists, trousers and boots. The old breastplates,
    # coats and sleeves are absent. Keeping this mesh separate also preserves the
    # original CC0 / project provenance of every visible face and both hands.
    if lod=="Close":
        source=close_costume(look.lower(),True)
    else:
        source=line_costume(look.lower(),rank=lod=="Rank")
    s=Surface()
    used={}
    for face in source.faces:
        p=np.asarray([source.positions[i] for i in face])
        x,y,z=p.mean(axis=0)
        uv=source.tex[face[0]]
        mat=MATERIALS[int(uv[0]*8)+8*int(uv[1]*4)]
        preserve_head=y>1.45 or (mat=="skin" and abs(x)<.09 and y>1.38)
        preserve_fore=abs(x)>.164 and .86<y<1.177 and mat in ("skin","binding","leather","headcloth")
        preserve_legs=y<.865 and mat in ("felt","binding","boots") and abs(x)<.249 and z<.202
        if not (preserve_head or preserve_fore or preserve_legs):
            continue
        ids=[]
        for i in face:
            if i not in used:
                a,b,w=decode_joints(source.joints[i])
                used[i]=s.vertex(source.positions[i],source.tex[i],(a,b,w))
            ids.append(used[i])
        s.faces.append(tuple(ids))
    if not s.faces: raise ValueError((look,lod))
    return s

def decode_joints(encoded):
    packed=int(encoded[0]*1024)
    return packed//32,packed%32,encoded[1]

def main():
    cache=Path(sys.argv[1])
    cache.mkdir(parents=True,exist_ok=True)
    OUTPUT.mkdir(parents=True,exist_ok=True)
    library=Library()
    bodies=Library()
    atlas=Image.new("RGBA",(528,528))
    for slot,(look,mesh,blob,albedo,paint_sha) in enumerate(ISSUES):
        skin=source_file(cache,"meshes/skeletal/new/"+mesh+".dae",blob)
        texture=source_file(cache,"textures/skins/skeletal/han/"+albedo+".png",paint_sha)
        s=fit_garment(skin,look,slot)
        library.insert(look+"Issue",s,check_tiles=False)
        for lod in ("Close","Line","Rank"):
            bodies.insert(look+lod+"Body",body_under_issue(look,lod))
        atlas.paste(cloth(texture,look),(264*(slot%2),264*(slot//2)))
        print("WILDFIRE_GARMENT",look,len(s.faces),len(s.positions))
    library.save(OUTPUT/"field_issues.glb")
    atlas.save(OUTPUT/"field_colours.png")
    bodies.save(ROOT/"assets/river_gate/figures/garrison_bodies.glb")
if __name__=="__main__":
    main()
