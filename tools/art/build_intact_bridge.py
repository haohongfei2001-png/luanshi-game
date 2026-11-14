"""Build an intact bridge span from a complete CC0 authored pier section."""
from pathlib import Path
import json,struct
import numpy as np
from figure_mesh import Library
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/"assets/river_gate/world/masters/modular_wooden_pier"
OUT=ROOT/"assets/river_gate/world/bridge"
def main():
    doc=json.loads((SOURCE/"modular_wooden_pier.gltf").read_text())
    buffers=[(SOURCE/b["uri"]).read_bytes() for b in doc["buffers"]]
    def values(index):
        a=doc["accessors"][index];v=doc["bufferViews"][a["bufferView"]]
        width={"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4}[a["type"]]
        dtype={5126:"<f4",5125:"<u4",5123:"<u2",5121:"u1"}[a["componentType"]]
        size=np.dtype(dtype).itemsize*width
        offset=v.get("byteOffset",0)+a.get("byteOffset",0)
        return np.ndarray((a["count"],width),dtype=dtype,buffer=buffers[v["buffer"]],offset=offset,strides=(v.get("byteStride",size),np.dtype(dtype).itemsize)).copy()
    node=next(n for n in doc["nodes"] if n["name"]=="modular_wooden_pier_section_02")
    lib=Library();lib.doc["images"]=[{**i,"uri":"../masters/modular_wooden_pier/"+i["uri"]} for i in doc["images"]]
    for key in ("textures","materials","samplers","extensionsUsed"):
        if key in doc:lib.doc[key]=doc[key]
    result=[];triangle_count=0
    for p in doc["meshes"][node["mesh"]]["primitives"]:
        data={k:values(v) for k,v in p["attributes"].items()}
        positions=data["POSITION"]
        faces=values(p["indices"]).reshape(-1,3).astype(int)
        y=positions[faces,1]
        selected=faces[(y.min(axis=1)>2.48)&(y.max(axis=1)<2.73)]
        if len(selected)==0:continue
        used,indices=np.unique(selected,return_inverse=True)
        assert len(used)<65536
        attrs={}
        for name in ("POSITION","NORMAL","TEXCOORD_0"):
            vals=data[name][used];attrs[name]=lib.accessor(vals.tolist(),"f",vals.shape[1],name=="POSITION")
        result.append({"attributes":attrs,"indices":lib.accessor(indices[:,None],"H",1),"material":p["material"]})
        triangle_count+=len(selected)
    assert triangle_count>1000,triangle_count
    lib.doc["meshes"]=[{"name":"IntactBridgeSpan","primitives":result}]
    lib.doc["nodes"]=[{"name":"IntactBridgeSpan","mesh":0}]
    lib.doc["scenes"][0]["nodes"]=[0]
    OUT.mkdir(parents=True,exist_ok=True)
    lib.save(OUT/"intact_bridge_span.glb")
    source=json.loads((SOURCE/"SOURCE.json").read_text())
    source.update(derived_component="modular_wooden_pier_section_02",selection="Complete deck and its actual side thickness, source height 2.48 to 2.73 metres",triangles=triangle_count)
    (OUT/"SOURCE.json").write_text(json.dumps(source,indent=2)+"\n")
    (OUT/"NOTICE.txt").write_text("Complete editable timber deck derived from Modular Wooden Pier by Rico Cilliers, Poly Haven, CC0-1.0. Original source and hashes in SOURCE.json.\n")
    print("INTACT_BRIDGE_TRIANGLES",triangle_count,flush=True)
if __name__=="__main__":main()
