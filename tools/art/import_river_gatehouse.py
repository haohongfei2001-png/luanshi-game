#!/usr/bin/env python3
"""Fit the original 0 A.D. Han gate to the River Gate moat, wall walk and camera."""
from collections import defaultdict
from hashlib import md5
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageFilter
from figure_mesh import Library
from import_garrison_issues import source_file

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/third_party/wildfire_gate"
FRAME = ("meshes/structural/han_wall_gate_struct.dae", "5312a78095cdfc55550c94ffb93d3867de9c7497")
PAINT = ("textures/skins/structural/han_struct_02.png", "5af91f43b3ea9fc73ebeda6f1517b98df0d3a57a")

def read_frame(path):
    doc = ET.parse(path).getroot()
    for node in doc.iter():
        node.tag = node.tag.split("}")[-1]
    geometry = doc.find(".//geometry")
    mesh = geometry.find("mesh")
    tri = mesh.find("triangles")
    if tri is None:
        tri=mesh.find("polylist")
        if tri is None or set(tri.findtext("vcount").split())!={"3"}:
            raise ValueError("The architectural master must consist of triangles")
    slots = {s.attrib["semantic"]+s.get("set",""):s for s in tri.findall("input")}
    def source(label):
        data = slots[label]
        key = data.attrib["source"][1:]
        if label == "VERTEX":
            key = mesh.find("vertices[@id='"+key+"']/input").attrib["source"][1:]
        node = mesh.find("source[@id='"+key+"']")
        width = int(node.find("technique_common/accessor").get("stride"))
        values = np.fromstring(node.find("float_array").text, sep=" ").reshape(-1,width)
        return values, int(data.attrib["offset"])
    pos, pi = source("VERTEX")
    normal, ni = source("NORMAL")
    uv, ui = source("TEXCOORD0")
    width = 1 + max(int(node.get("offset")) for node in tri.findall("input"))
    corners = np.fromstring(tri.find("p").text, dtype=int,sep=" ").reshape(-1,3,width)
    # Cameras and lights sometimes precede the mesh in the active COLLADA scene.
    # Follow the instance of this geometry and accumulate only its ancestors.
    active = doc.find("./scene/instance_visual_scene").get("url")[1:]
    scene = doc.find(".//visual_scene[@id='"+active+"']")
    paths = []
    def locate(parent, parents):
        for child in parent.findall("node"):
            branch = parents + [child]
            for inst in child.findall("instance_geometry"):
                if inst.get("url") == "#"+geometry.get("id"):
                    paths.append(branch)
            locate(child, branch)
    locate(scene, [])
    if len(paths) != 1:
        raise ValueError(f"Expected one active geometry instance in {path}, found {len(paths)}")
    transform = np.eye(4)
    for child in paths[0]:
        for component in child:
            if component.tag == "matrix":
                transform = transform @ np.fromstring(component.text, sep=" ").reshape(4,4)
            elif component.tag in ("rotate", "translate", "scale", "skew", "lookat"):
                raise ValueError(f"Unsupported {component.tag} on the geometry instance in {path}")
    pos = pos@transform[:3,:3].T + transform[:3,3]
    normal = normal@np.linalg.inv(transform[:3,:3])
    return pos,normal,uv,corners[:,:,[pi,ni,ui]]

def fit(pos):
    # The sculpt's actual inner jamb is 3.1 source units from centre. Preserve
    # the 8 m military passage, compress only the stone piers beyond the jamb.
    span,depth,height=pos
    span_out=np.interp(abs(span),[0.,3.1,6.2,12.,18.4],[0.,4.,5.45,7.65,10.68])
    y=np.interp(height,[-3.82,0.,8.1,12.,20.,26.0],[-1.53,0.,3.88,5.03,8.0,9.82])
    return (float(-depth*.55),float(y),float(np.copysign(span_out,span)))

def clip_pitch(face, sign):
    # Clip a roof, beam or floor triangle on the ridge. Keeping the entire
    # triangle on the centroid side leaves diagonal splinters above the doorway.
    polygon=[]
    prev=face[-1]
    for curr in face:
        prev_in=sign*prev[0]>=0.
        curr_in=sign*curr[0]>=0.
        if prev_in!=curr_in:
            edge=prev+(curr-prev)*(prev[0]/(prev[0]-curr[0]))
            edge[0]=0.
            polygon.append(edge)
        if curr_in:
            polygon.append(curr)
        prev=curr
    return [np.array((polygon[0],polygon[i],polygon[i+1])) for i in range(1,len(polygon)-1)]

def mesh_library(cache):
    pos,normals,uv,tris=read_frame(source_file(cache,*FRAME))
    fitted=np.asarray([fit(p) for p in pos])
    delta=.003
    axes=np.eye(3)*delta
    inverse=[]
    for point in pos:
        jac=np.column_stack([(np.asarray(fit(point+a))-np.asarray(fit(point-a)))/(2*delta) for a in axes])
        inverse.append(np.linalg.inv(jac).T)
    shells=defaultdict(list)
    for tri in tris:
        # The river-axis conversion changes handedness. A roof's exterior
        # is the lit face, as are the neighbouring curtain-wall roofs.
        rows=[]
        for pi,ni,ui in tri[[0,2,1]]:
            n=inverse[pi]@normals[ni]
            rows.append(np.r_[fitted[pi],n/max(np.linalg.norm(n),1e-9),uv[ui][0],1.-uv[ui][1]])
        face=np.asarray(rows)
        y=face[:,1]
        if y.max()<3.91 or (y.min()<3.77 and y.mean()<3.82):
            shells["Piers"].append(face)
            continue
        shells["WatchHall"].append(face)
        x=face[:,0]
        if x.max()<=0.:
            shells["WestPitch"].append(face)
        elif x.min()>=0.:
            shells["EastPitch"].append(face)
        else:
            shells["WestPitch"].extend(clip_pitch(face,-1))
            shells["EastPitch"].extend(clip_pitch(face,1))
    assert len(shells["WatchHall"])+len(shells["Piers"])==7258
    def area(name):
        face=np.array(shells[name])[:,:,:3]
        return np.linalg.norm(np.cross(face[:,1]-face[:,0],face[:,2]-face[:,0]),axis=1).sum()*.5
    assert abs(area("WatchHall")-area("WestPitch")-area("EastPitch"))<.00001
    assert all(f[:,0].max()<1e-9 for f in shells["WestPitch"])
    assert all(f[:,0].min()>-1e-9 for f in shells["EastPitch"])
    library=Library()
    for name in ("Piers","WatchHall","WestPitch","EastPitch"):
        vertices=[]; directions=[]; tex=[]; indices=[]; used={}
        for face in shells[name]:
            for corner in face:
                key=tuple(np.round(corner,7))
                if key not in used:
                    used[key]=len(vertices)
                    vertices.append(corner[:3])
                    n=corner[3:6]
                    directions.append(n/max(np.linalg.norm(n),1e-9))
                    tex.append(corner[6:])
                indices.append((used[key],))
        attr={"POSITION":library.accessor(vertices,"f",3,True),"NORMAL":library.accessor(directions,"f",3),"TEXCOORD_0":library.accessor(tex,"f",2)}
        idx=library.accessor(indices,"H",1)
        key=len(library.doc["meshes"])
        library.doc["meshes"].append({"name":name,"primitives":[{"attributes":attr,"indices":idx}]})
        library.doc["nodes"].append({"mesh":key,"name":name})
        library.doc["scenes"][0]["nodes"].append(key)
        print("PASSAGE_MESH",name,len(indices)//3,len(vertices))
    library.save(OUT/"river_gate.glb")

def atlas(cache):
    source=Image.open(source_file(cache,*PAINT)).convert("RGB").resize((1024,1024),Image.Resampling.LANCZOS)
    # Retain the authored roof ribs and timber seams, grouping their paint into
    # wider midtones. No normal-map glitter or specular map is used in game.
    grain=np.asarray(source.filter(ImageFilter.SMOOTH),dtype=float)/255.
    light=grain@np.array([.27,.59,.14])
    laid=np.interp(light,[0.,.12,.25,.43,.69,1.],[.085,.225,.345,.475,.69,.855])
    chroma=grain-light[:,:,None]
    coloured=chroma*.69+laid[:,:,None]
    # Tint the neutral fired tile towards the same blue-grey as the corner
    # towers. Pigmented brick, raw wood and plaster retain their diffuse hue.
    neutral=np.clip(1.-np.ptp(grain,axis=2)/.16,0.,1.)
    cool=neutral*np.clip(1.-abs(light-.21)/.33,0.,1.)
    coloured+=cool[:,:,None]*np.array([-.014,.022,.058])
    # Bring white plaster back towards warm unglazed clay at the sunlit value.
    warm=np.maximum(0.,(laid-.56)/.44)[:,:,None]*np.array([.027,.009,-.028])
    dst=np.clip(coloured+warm,0.,1.)
    target=OUT/"gate_clay_and_timber.png"
    Image.fromarray(np.rint(255*dst).astype('uint8')).save(target,optimize=True)
    relative="res://"+target.relative_to(ROOT).as_posix()
    imported="res://.godot/imported/"+target.name+"-"+md5(relative.encode()).hexdigest()+".ctex"
    config=f'''[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://ch5heguangate"
path="{imported}"
metadata={{"vram_texture": false}}

[deps]

source_file="{relative}"
dest_files=["{imported}"]

[params]

compress/mode=0
mipmaps/generate=true
mipmaps/limit=-1
detect_3d/compress_to=0
'''
    target.with_suffix(".png.import").write_text(config)

if __name__=="__main__":
    cache=Path(sys.argv[1])
    cache.mkdir(parents=True,exist_ok=True)
    OUT.mkdir(parents=True,exist_ok=True)
    mesh_library(cache)
    atlas(cache)
