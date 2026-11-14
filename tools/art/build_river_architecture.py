"""Restore complete authored Han buildings, including their original UV2/AO.

Create the replacement battlefield's structural library from pinned Wildfire
Games COLLADA masters. Keep the native diffuse artwork and its matching baked
occlusion instead of repainting every face or synthesizing building silhouettes.
"""
from pathlib import Path
import json,shutil,sys
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image
from figure_mesh import Library
from import_garrison_issues import source_file
from import_river_gatehouse import read_frame,fit
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/river_gate/world/architecture"
def second_uv(path):
    root=ET.parse(path).getroot()
    for node in root.iter():node.tag=node.tag.split("}")[-1]
    mesh=root.find(".//geometry/mesh")
    faces=mesh.find("triangles")
    if faces is None:faces=mesh.find("polylist")
    slot=faces.find("input[@semantic='TEXCOORD'][@set='1']")
    if slot is None:return None,None
    source=mesh.find("source[@id='"+slot.get("source")[1:]+"']")
    values=np.fromstring(source.findtext("float_array"),sep=" ").reshape(-1,2)
    stride=1+max(int(n.get("offset")) for n in faces.findall("input"))
    indices=np.fromstring(faces.findtext("p"),sep=" ",dtype=int).reshape(-1,3,stride)
    return values,indices[:,:,int(slot.get("offset"))]
def rest_frame(path,cache):
    # The source stores the closed timber leaves in its skin bind geometry.
    # Bake that exact bind-space shape while keeping its native diffuse UVs.
    root=ET.parse(path).getroot()
    for node in root.iter():node.tag=node.tag.split("}")[-1]
    geometry=root.find(".//geometry")
    skin=root.find(".//skin")
    scene=root.find(".//visual_scene")
    for child in list(scene):scene.remove(child)
    node=ET.SubElement(scene,"node",{"id":"closed_gate","type":"NODE"})
    ET.SubElement(node,"matrix").text=skin.findtext("bind_shape_matrix")
    ET.SubElement(node,"instance_geometry",{"url":"#"+geometry.get("id")})
    baked=cache/"closed_gate_bind_geometry.dae"
    ET.ElementTree(root).write(baked)
    return read_frame(baked)

def main(cache):
    cache.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((Path(__file__).with_name("source")/"river_architecture.json").read_text())
    base=source_file(cache,"textures/skins/structural/han_struct_02.png","5af91f43b3ea9fc73ebeda6f1517b98df0d3a57a")
    Image.open(base).convert("RGB").save(OUT/"native_clay_tiles_timber.png")
    lib=Library()
    lib.doc["images"]=[{"uri":"native_clay_tiles_timber.png"}]
    lib.doc["textures"]=[{"source":0}]
    lib.doc["materials"]=[]
    receipt=[]
    for row in manifest["models"]:
        if row["name"]=="han_wall_gate_gutters":continue
        path=source_file(cache,"meshes/structural/"+row["name"]+".dae",row["sha"])
        pos,norm,uv,faces=rest_frame(path,cache) if row["name"]=="han_wall_gate" else read_frame(path)
        ao_uv,ao_corners=second_uv(path)
        height=float(pos[:,2].max())
        if row["name"] in ("han_wall_gate_struct","han_wall_gate"):
            fitted=np.asarray([fit(p) for p in pos])
            # Keep the passage's physical lintel, with an unbroken upper frame.
            upper=np.maximum(fitted[:,1]-3.88,0.)
            fitted[:,1]-=.10*upper
            matrix=np.array([[0.,-.55,0.],[0.,0.,.40],[.58,0.,0.]])
        else:
            target={"han_wall_long":4.2,"han_wall_tower":6.8,"han_barracks":5.4,"han_house_a":4.2,"han_house_b":4.3,"han_storehouse":4.6,"han_fortress":8.8}[row["name"]]
            scale=target/max(height,1.)
            matrix=np.array([[0.,-scale,0.],[0.,0.,scale],[scale,0.,0.]])
            fitted=pos@matrix.T
        material={"name":row["name"],"doubleSided":True,"pbrMetallicRoughness":{"baseColorTexture":{"index":0},"metallicFactor":0.,"roughnessFactor":.96}}
        if row["ao"] and ao_uv is not None:
            ao=source_file(cache,"textures/skins/structural/ao/"+row["ao_file"],row["ao"])
            image=row["name"]+"_ao.png";shutil.copyfile(ao,OUT/image)
            image_index=len(lib.doc["images"]);lib.doc["images"].append({"uri":image})
            texture_index=len(lib.doc["textures"]);lib.doc["textures"].append({"source":image_index})
            material["occlusionTexture"]={"index":texture_index,"texCoord":1,"strength":.90}
        material_index=len(lib.doc["materials"]);lib.doc["materials"].append(material)
        vertices=[];normal=[];uv0=[];uv1=[];indices=[];found={}
        direction=norm@np.linalg.inv(matrix)
        direction/=np.maximum(np.linalg.norm(direction,axis=1)[:,None],1.e-9)
        for t,face in enumerate(faces):
            for corner in (0,2,1):
                pi,ni,ti=face[corner]
                ai=int(ao_corners[t,corner]) if ao_corners is not None else int(ti)
                key=(int(pi),int(ni),int(ti),ai)
                if key not in found:
                    found[key]=len(vertices)
                    vertices.append(fitted[pi]);normal.append(direction[ni]);uv0.append((uv[ti,0],1.-uv[ti,1]))
                    v=ao_uv[ai] if ao_uv is not None else uv[ti];uv1.append((v[0],1.-v[1]))
                indices.append((found[key],))
        attributes={"POSITION":lib.accessor(vertices,"f",3,True),"NORMAL":lib.accessor(normal,"f",3),"TEXCOORD_0":lib.accessor(uv0,"f",2),"TEXCOORD_1":lib.accessor(uv1,"f",2)}
        primitive={"attributes":attributes,"indices":lib.accessor(indices,"I",1),"material":material_index}
        number=len(lib.doc["meshes"])
        lib.doc["meshes"].append({"name":row["name"],"primitives":[primitive]})
        lib.doc["nodes"].append({"name":row["name"],"mesh":number})
        lib.doc["scenes"][0]["nodes"].append(number)
        receipt.append({"name":row["name"],"triangles":len(indices)//3,"source_sha":row["sha"],"has_native_ao":ao_uv is not None,"bounds":[fitted.min(axis=0).tolist(),fitted.max(axis=0).tolist()]})
        print("COMPLETE_BUILDING",json.dumps(receipt[-1]),flush=True)
    lib.save(OUT/"river_fort.glb")
    (OUT/"SOURCE.json").write_text(json.dumps({"upstream":manifest["upstream"],"authors":"Wildfire Games contributors","license":"CC BY-SA 3.0","models":receipt},indent=2)+"\n")
    (OUT/"NOTICE.txt").write_text("Complete Han architectural meshes, diffuse artwork and matched UV2 occlusion from Wildfire Games 0 A.D. contributors.\nCC BY-SA 3.0 https://creativecommons.org/licenses/by-sa/3.0/\nhttps://github.com/0ad/0ad/tree/"+manifest["upstream"]+"/binaries/data/mods/public/art\nCoordinate fitting and library conversion for River Gate, distributed under the same CC BY-SA 3.0 license. All source blobs and transformations are recorded.\n")
if __name__=="__main__":main(Path(sys.argv[1]))
