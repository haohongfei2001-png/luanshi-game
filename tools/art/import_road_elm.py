"""Fit two redistributable 0 A.D. elm masters to the existing roadside planting."""
from hashlib import md5
from pathlib import Path
import sys
import numpy as np
from PIL import Image, ImageFilter
from import_river_gatehouse import read_frame
from import_garrison_issues import source_file
from figure_mesh import Library

ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/"assets/third_party/wildfire_elm"
MASTERS=(("RoadElm","tree_elm_01.dae","6a2f1eca2f7d5b60d7f9903b6180ed826e3aca92"),
         ("YoungElm","tree_elm_02.dae","71507c7c47670e09b5b627f88568d0ab0bbacdd2"))
PAINT=("textures/skins/gaia/tree_elm_01.png","76d494660eaba54f6c3926b5a1614d9c7adbfef5")

def master(lib,cache,label,name,signature):
    p,n,uv,tri=read_frame(source_file(cache,"meshes/gaia/"+name,signature))
    top=p[:,2].max()
    root=p[np.abs(p[:,2])<top*.08,:2]
    root_pos=(root.min(axis=0)+root.max(axis=0))*.5
    p[:,:2]-=root_pos
    p=p[:,[0,2,1]]/top
    p[:,2]*=-1.
    n=n[:,[0,2,1]]
    n[:,2]*=-1.
    # The crown retains the model's folded canopies. A single integrated
    # normal for each cutout keeps the two sides of a leaf the same colour.
    coords=[]; norms=[]; uvs=[]; wind=[]; index=[]; seen={}
    for face in tri:
        for pi,ni,ti in face:
            key=(int(pi),int(ni),int(ti))
            if key not in seen:
                seen[key]=len(coords)
                pos=p[pi]; normal=n[ni]
                h=pos[1]
                if h>.38:
                    outward=pos-np.array([.013,.50,-.040])
                    outward[1]+=.17
                    normal=outward/max(np.linalg.norm(outward),.001)
                coords.append(pos);norms.append(normal/max(np.linalg.norm(normal),.001))
                uvs.append((uv[ti,0],1.-uv[ti,1]))
                wind.append((float(np.clip((h-.40)*.83,0,.49)),20.+h))
            index.append((seen[key],))
    attr={"POSITION":lib.accessor(coords,"f",3,True),"NORMAL":lib.accessor(norms,"f",3),
          "TEXCOORD_0":lib.accessor(uvs,"f",2),"TEXCOORD_1":lib.accessor(wind,"f",2)}
    part=len(lib.doc["meshes"])
    lib.doc["meshes"].append({"name":label,"primitives":[{"attributes":attr,"indices":lib.accessor(index,"H",1)}]})
    lib.doc["nodes"].append({"name":label,"mesh":part})
    lib.doc["scenes"][0]["nodes"].append(part)
    print("ROADSIDE_ELM",label,len(index)//3,len(coords))

def palette(cache):
    atlas=Image.open(source_file(cache,*PAINT)).convert("RGBA")
    atlas.thumbnail((768,768),Image.Resampling.LANCZOS)
    smooth=atlas.convert("RGB").filter(ImageFilter.GaussianBlur(1.0))
    rgb=np.asarray(smooth,dtype=float)/255.
    light=rgb@np.array([.25,.58,.17])
    # Use three broad diffuse values for green clumps. Bark keeps its own hue,
    # so the fork and branches remain legible even where sunlight crosses them.
    green=np.clip((rgb[:,:,1]-rgb[:,:,0]+.025)*8.,0.,1.)*np.clip((rgb[:,:,1]-rgb[:,:,2])*7.,0.,1.)
    paint=np.stack([np.interp(light,[.04,.23,.43,.67,.91],r) for r in
                    ([.16,.22,.29,.39,.50],[.22,.29,.36,.43,.51],[.18,.21,.24,.27,.31])],axis=-1)
    bark=np.clip(rgb*.76+.042,0.,1.)
    pigment=green[:,:,None]*paint+(1.-green[:,:,None])*bark
    raw=atlas.getchannel("A")
    grouped=raw.resize((256,256),Image.Resampling.LANCZOS).resize(raw.size,Image.Resampling.BICUBIC)
    alpha=np.clip((.72*np.asarray(grouped)+.28*np.asarray(raw)-20.)/215.,0.,1.)
    tex=DEST/"elm.png"
    Image.fromarray(np.rint(255*np.dstack((pigment,alpha))).astype(np.uint8)).save(tex,optimize=True)
    path="res://"+tex.relative_to(ROOT).as_posix()
    imp="res://.godot/imported/elm.png-"+md5(path.encode()).hexdigest()+".ctex"
    tex.with_suffix(".png.import").write_text(f'''[remap]
importer="texture"
type="CompressedTexture2D"
uid="uid://briverroadelm"
path="{imp}"
metadata={{"vram_texture": false}}

[deps]
source_file="{path}"
dest_files=["{imp}"]

[params]
compress/mode=0
mipmaps/generate=true
process/fix_alpha_border=true
detect_3d/compress_to=0
''')

if __name__=="__main__":
    cache=Path(sys.argv[1])
    cache.mkdir(parents=True,exist_ok=True)
    DEST.mkdir(parents=True,exist_ok=True)
    lib=Library()
    for label,name,signature in MASTERS:
        master(lib,cache,label,name,signature)
    lib.save(DEST/"road_elms.glb")
    palette(cache)
