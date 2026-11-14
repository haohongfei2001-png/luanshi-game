"""Inventory the already licensed Quaternius Standard humanoid animation source."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import zipfile
from import_company_march import ARCHIVE_SHA256, NAME

def main():
    archive=Path(sys.argv[1])
    digest=hashlib.sha256(archive.read_bytes()).hexdigest()
    if digest!=ARCHIVE_SHA256:
        raise ValueError("The verified Quaternius Standard archive changed: "+digest)
    with zipfile.ZipFile(archive) as source:
        notice=source.read("Animation Library[Standard]/License.txt").decode("utf-8-sig")
        if "CC0" not in notice: raise ValueError("The source CC0 notice is absent")
        raw=source.read(NAME)
    size=struct.unpack_from("<I",raw,12)[0]
    document=json.loads(raw[20:20+size])
    binary=raw[28+size:]
    def accessor(index):
        a=document["accessors"][index]
        view=document["bufferViews"][a["bufferView"]]
        width={"SCALAR":1,"VEC3":3,"VEC4":4,"MAT4":16}[a["type"]]
        if a["componentType"]!=5126: raise ValueError(a)
        start=view.get("byteOffset",0)+a.get("byteOffset",0)
        stride=view.get("byteStride",width*4)
        return [struct.unpack_from("<"+"f"*width,binary,start+i*stride) for i in range(a["count"])]
    clips=[]
    for anim in document["animations"]:
        end=max(accessor(sampler["input"])[-1][0] for sampler in anim["samplers"])
        clips.append({"name":anim["name"],"seconds":end,"channels":len(anim["channels"])})
    out=Path("docs/evidence/river-gate-v1-rc23/native-combat")
    out.mkdir(parents=True,exist_ok=True)
    result={"author":"Quaternius","license":"CC0","archive_sha256":digest,
            "source_glb_sha256":hashlib.sha256(raw).hexdigest(),
            "source_file":NAME,"clips":clips,
            "nodes":[{"index":i,"name":n.get("name"),"children":n.get("children",[])} for i,n in enumerate(document["nodes"])]}
    (out/"source-survey.json").write_text(json.dumps(result,indent=2)+"\n")
    (out/"source-license.txt").write_text(notice)
    print("VERIFIED_COMBAT_SOURCE",json.dumps({"archive_sha256":digest,"clips":clips}),flush=True)

if __name__=="__main__": main()
