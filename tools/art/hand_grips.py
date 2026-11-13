"""Read the Blender grip master, then append it to existing hand-bound weapon surfaces."""
from functools import lru_cache
import json
from pathlib import Path
import struct

from figure_atlas import uv

SOURCE=Path(__file__).with_name("source")/"hand_grips.glb"

@lru_cache(maxsize=1)
def library():
    raw=SOURCE.read_bytes()
    assert raw[:4]==b"glTF"
    length=struct.unpack_from("<I",raw,12)[0]
    doc=json.loads(raw[20:20+length])
    body=raw[28+length:]
    def read(i):
        a=doc["accessors"][i];v=doc["bufferViews"][a["bufferView"]]
        code={5121:"B",5123:"H",5125:"I",5126:"f"}[a["componentType"]]
        width={"SCALAR":1,"VEC3":3}[a["type"]]
        record=struct.Struct("<"+code*width)
        stride=v.get("byteStride",record.size)
        pos=v.get("byteOffset",0)+a.get("byteOffset",0)
        return [record.unpack_from(body,pos+n*stride) for n in range(a["count"])]
    meshes={}
    for mesh in doc["meshes"]:
        part=mesh["primitives"][0]
        verts=read(part["attributes"]["POSITION"])
        flat=[k for k, in read(part["indices"])]
        assert len(flat)%3==0 and len(flat)>60
        meshes[mesh["name"]]=(verts,list(zip(flat[::3],flat[1::3],flat[2::3])))
    assert len(meshes)==9
    return meshes

def field_hands(surface,kit,lod):
    for side,bone in ((-1,5),(1,8)):
        style=("BowPalm" if side>0 else "Nock") if kit==5 else "Haft"
        vertices,triangles=library()[style+lod]
        offset=len(surface.positions)
        for x,y,z in vertices:
            p=(side*(.273+x),.943+y,.075+z)
            surface.vertex(p,uv("skin",.52+.20*max(-1.,min(1.,x/.07)),
                                .55+.19*max(-1.,min(1.,y/.07))),bone)
        # Mirroring the left local mesh also reverses its winding.
        if side<0:
            surface.faces.extend((offset+a,offset+c,offset+b) for a,b,c in triangles)
        else:
            surface.faces.extend((offset+a,offset+b,offset+c) for a,b,c in triangles)
